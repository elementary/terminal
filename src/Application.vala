/*
 * Copyright 2011-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

public class Terminal.Application : Gtk.Application {
    public const int MINIMUM_WIDTH = 600;
    public const int MINIMUM_HEIGHT = 400;

    private string commandline = "\0"; // used to temporary hold the argument to --commandline=
    private uint dbus_id = 0;

    public static GLib.Settings saved_state;
    public static GLib.Settings settings;
    public static GLib.Settings settings_sys;

    public bool is_testing { get; set construct; }

    private static Themes themes;

    public Application () {
        Object (
            application_id: "io.elementary.terminal", /* Ensures only one instance runs */
            flags: ApplicationFlags.HANDLES_COMMAND_LINE | ApplicationFlags.CAN_OVERRIDE_APP_ID
        );
    }

    construct {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        var act = new SimpleAction ("process-finished", VariantType.STRING);
        add_action (act);
        act.activate.connect ((v) => {
            MainWindow window_to_present = (MainWindow)active_window;
            size_t len;
            var tid = v.get_string (out len);
            foreach (var window in (List<MainWindow>) get_windows ()) {
                var terminal = window.get_terminal (tid);
                if (terminal != null) {
                    window.set_active_terminal_tab (terminal.tab);
                    window_to_present = window;
                    break;
                }
            }

            // This is a hack to avoid using Gdk-Xii dependency.  Using present_with_time ()
            // with the current event time does not work either on X11 or Wayland perhaps
            // because the triggering event did not occur on the Terminal window?
            // Using set_keep_above () at least works on X11 but not on Wayland
            //TODO It may well be possible to use present () on Gtk4 so this needs revisiting
            window_to_present.set_keep_above (true);
            window_to_present.present ();
            window_to_present.grab_focus ();
            Idle.add (() => {
                window_to_present.set_keep_above (false);
                return Source.REMOVE;
            });
        });

        add_main_option ("version", 'v', 0, OptionArg.NONE, _("Show version"), null);
        // -n flag forces a new window
        add_main_option ("new-window", 'n', 0, OptionArg.NONE, _("Open a new terminal window"), null);
        // -t flag forces a new tab
        add_main_option ("new-tab", 't', 0, OptionArg.NONE, _("Open a new terminal tab at current working directory"), null);
        // -w flag defines the working directory that the new tab/window uses
        add_main_option ("working-directory", 'w', 0, OptionArg.FILENAME, _("Set shell working directory"), "DIR");
        // -e flag is used for running single strings as a command line
        add_main_option ("execute", 'e', 0, OptionArg.FILENAME_ARRAY, _("Run a program in terminal"), "PROGRAM");
        // -m flag starts terminal in a minimized state
        add_main_option ("minimized", 'm', 0, OptionArg.NONE, _("Open terminal in a minimized state"), null);
        // -x flag is used for using the rest of the command line in the new tab/window
        add_main_option (
            "commandline", 'x', 0, OptionArg.FILENAME, _("Run remainder of line as a command in terminal"), "COMMAND"
        );
    }

    protected override bool local_command_line (ref unowned string[] args, out int exit_status) {
        bool show_help = false;

        for (uint i = 1; args[i] != null; i++) {
            if (args[i][0] != '-') {
                continue;
            }

            // skip iterating if we are printing the version or showing the help page
            if (args[i] == "--version" || args[i][1] != '-' && "v" in args[i]) {
                print ("%s %s\n", Config.PROJECT_NAME, Config.VERSION);
                exit_status = 0;
                return true;
            } else if (args[i] == "--help" || args[i][1] != '-' && "h" in args[i]) {
                show_help = true;
                break;
            }

            /* --commandline behaviour is to use the rest of the command line as a array to execve().
             * we convert theses options to "--" here, since that give us the wanted semanitcs.
             */
            if (args[i][1] == '-') {
                if (args[i][2:] == "commandline" || args[i][2:].has_prefix ("commandline")) {
                    if (args[i].length > 14) {
                        commandline = args[i].substring (14);
                    }

                    args[i] = "--";
                }
            } else if ("x" in args[i]) {
                if ("w" in args[i] || "e" in args[i]) {
                    continue; // GLib.Application will show a error in this case
                }

                if (args[i].length != 2) {
                    args[i] = args[i].replace ("x", "");
                    commandline = args[++i];
                }

                args[i] = "--";
            }

            if (args[i] == "--") {
                break;
            }
        }

        if ("--" in args || show_help) {
            add_main_option (OPTION_REMAINING, '\0', 0, OptionArg.FILENAME_ARRAY, "", _("[-- COMMAND…]"));
        }

        return base.local_command_line (ref args, out exit_status);
    }

    protected override int handle_local_options (VariantDict options) {
        unowned string working_directory;
        unowned string[] args;

        if (options.lookup ("working-directory", "^&ay", out working_directory)) {
            if (working_directory != "\0") {
                Environment.set_current_dir (
                    Utils.sanitize_path (working_directory, Environment.get_current_dir (), false)
                ); // will be sent via platform-data
                options.insert ("new-tab", "b", true);
            }

            options.remove ("working-directory");
        }

        if (options.lookup (OPTION_REMAINING, "^a&ay", out args)) {
            if (commandline != "\0") {
                commandline += " %s".printf (string.joinv (" ", args));
            } else {
                commandline = string.joinv (" ", args);
            }
        }

        if (commandline != "\0") {
            options.insert ("commandline", "^&ay", commandline.escape ());
        }

        return -1;
    }

    protected override bool dbus_register (DBusConnection connection, string object_path) throws Error {
        base.dbus_register (connection, object_path);

        var dbus = new DBus ();
        dbus_id = connection.register_object (object_path, dbus);

        dbus.finished_process.connect ((id, process, exit_status) => {
            TerminalWidget terminal = null;

            foreach (var window in (List<MainWindow>) get_windows ()) {
                if (terminal != null) {
                    break;
                }

                terminal = window.get_terminal (id);
            }

            if (terminal == null) {
                return;
            } else if (!terminal.is_init_complete ()) {
                terminal.set_init_complete ();
                return;
            }

            var process_string = _("Process completed");
            var process_icon = new ThemedIcon ("process-completed-symbolic");
            if (exit_status != 0) {
                process_string = _("Process exited with errors");
                process_icon = new ThemedIcon ("process-error-symbolic");
            }

            if (terminal != terminal.main_window.current_terminal) {
                terminal.tab.icon = process_icon;
            }

            if (!(Gdk.WindowState.FOCUSED in terminal.main_window.get_window ().get_state ())) {
                var notification = new Notification (process_string);
                notification.set_body (process);
                notification.set_icon (process_icon);
                notification.set_default_action_and_target_value ("app.process-finished", new Variant.string (id));
                send_notification ("process-finished-%s".printf (id), notification);

                ulong tab_change_handler = 0;
                ulong focus_in_handler = 0;

                tab_change_handler = terminal.main_window.notify["current-terminal"].connect (() => {
                    withdraw_notification_for_terminal (terminal, id, tab_change_handler, focus_in_handler);
                });

                focus_in_handler = terminal.main_window.focus_in_event.connect (() => {
                    withdraw_notification_for_terminal (terminal, id, tab_change_handler, focus_in_handler);

                    return Gdk.EVENT_PROPAGATE;
                });

            }
        });

        return true;
    }

    private void withdraw_notification_for_terminal (TerminalWidget terminal, string id, ulong tab_change_handler, ulong focus_in_handler) {
        if (terminal.main_window.current_terminal != terminal) {
            return;
        }

        terminal.tab.icon = null;
        withdraw_notification ("process-finished-%s".printf (id));

        terminal.main_window.disconnect (tab_change_handler);
        terminal.main_window.disconnect (focus_in_handler);
    }

    protected override void startup () {
        base.startup ();
        Hdy.init ();

        saved_state = new GLib.Settings ("io.elementary.terminal.saved-state");
        settings = new GLib.Settings ("io.elementary.terminal.settings");
        settings_sys = new GLib.Settings ("org.gnome.desktop.interface");
        themes = new Themes ();

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/io/elementary/terminal/Application.css");

        /* Vte.Terminal itself registers its default styling with the APPLICATION priority:
         * https://gitlab.gnome.org/GNOME/vte/blob/0.68.0/src/vtegtk.cc#L844-847
         * To be able to overwrite their styles, we need to use +1.
         */
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1
        );

        var new_window_action = new SimpleAction ("new-window", null);
        new_window_action.activate.connect (() => {
            string dir = Environment.get_home_dir ();
            if (active_window != null) {
                dir = ((MainWindow)active_window).current_terminal.current_working_directory;
            }

            var new_window = new MainWindow (this, active_window == null);
            new_window.present ();
            new_window.set_size_request (
                active_window.width_request,
                active_window.height_request
            );

            new_window.add_tab_with_working_directory (dir);
        });

        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (close);

        add_action (new_window_action);
        add_action (quit_action);

        set_accels_for_action ("app.new-window", { "<Control><Shift>N" });
        set_accels_for_action ("app.quit", { "<Control><Shift>Q" });

        set_accels_for_action (TerminalWidget.ACTION_COPY, TerminalWidget.ACCELS_COPY);
        set_accels_for_action (TerminalWidget.ACTION_COPY_OUTPUT, TerminalWidget.ACCELS_COPY_OUTPUT);
        set_accels_for_action (TerminalWidget.ACTION_PASTE, TerminalWidget.ACCELS_PASTE);
        set_accels_for_action (TerminalWidget.ACTION_RELOAD, TerminalWidget.ACCELS_RELOAD);
        set_accels_for_action (TerminalWidget.ACTION_SCROLL_TO_COMMAND, TerminalWidget.ACCELS_SCROLL_TO_COMMAND);
        set_accels_for_action (TerminalWidget.ACTION_SELECT_ALL, TerminalWidget.ACCELS_SELECT_ALL);
        set_accels_for_action (TerminalWidget.ACTION_ZOOM_DEFAULT, TerminalWidget.ACCELS_ZOOM_DEFAULT);
        set_accels_for_action (TerminalWidget.ACTION_ZOOM_IN, TerminalWidget.ACCELS_ZOOM_IN);
        set_accels_for_action (TerminalWidget.ACTION_ZOOM_OUT, TerminalWidget.ACCELS_ZOOM_OUT);
    }

    protected override int command_line (ApplicationCommandLine command_line) {
        unowned var options = command_line.get_options_dict ();
        var window = (MainWindow) active_window;
        var is_first_window = window == null;
        bool new_window;

        // Always restore tabs if creating first window, but no extra tab at this stage
        if (is_first_window || options.lookup ("new-window", "b", out new_window) && new_window) {
            window = new MainWindow (this, is_first_window);
        }

        // If a specified working directory is not requested, use the current working directory from the commandline
        unowned var working_directory = command_line.get_cwd ();
        unowned string[] commands;
        unowned string command;
        bool new_tab, minimized;

        options.lookup ("new-tab", "b", out new_tab);

        // If "execute" option or "commandline" option used ignore any "new-tab option
        // because these add new tab(s) already
        if (options.lookup ("execute", "^a&ay", out commands)) {
            for (var i = 0; commands[i] != null; i++) {
                if (commands[i] != "\0") {
                    window.add_tab_with_working_directory (working_directory, commands[i], new_tab);
                }
            }
        } else if (options.lookup ("commandline", "^&ay", out command) && command != "\0") {
            window.add_tab_with_working_directory (working_directory, command, new_tab);
        } else if (new_tab || window.notebook.n_pages == 0) {
            window.add_tab_with_working_directory (working_directory, "", new_tab);
        }

        if (options.lookup ("minimized", "b", out minimized) && minimized) {
            window.iconify ();
        } else {
            window.present ();
        }
        return 0;
    }

    protected override void dbus_unregister (DBusConnection connection, string path) {
        if (dbus_id != 0) {
            connection.unregister_object (dbus_id);
        }

        base.dbus_unregister (connection, path);
    }

    public void close () {
        foreach (var window in get_windows ()) {
            window.close (); // if all windows is closed, the main loop will stop automatically.
        }
    }
}

#if !TESTS
public static int main (string[] args) {
    return new Terminal.Application ().run (args);
}
#endif

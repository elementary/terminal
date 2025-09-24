/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 */

namespace Terminal {
    public class TerminalWidget : Vte.Terminal {
        static string[] terminal_envv = {
            // Export callback command a BASH-specific variable, see "man bash" for details
            "PROMPT_COMMAND=" + SEND_PROCESS_FINISHED_BASH + Environment.get_variable ("PROMPT_COMMAND"),
            // ZSH callback command will be read from ZSH config file supplied by us, see data/
            // TODO: support FISH, see https://github.com/fish-shell/fish-shell/issues/1382
            // Taken from BlackBox
            "TERM=xterm-256color", // This is required for the window-title notify signal to work in Flatpak
            "COLORTERM=truecolor",
            "TERM_PROGRAM=Terminal",
            "VTE_VERSION=%u".printf (
              Vte.MAJOR_VERSION * 10000 + Vte.MINOR_VERSION * 100 + Vte.MICRO_VERSION
            )
        };

        enum DropTargets {
            URILIST,
            STRING,
            TEXT
        }

        internal const string DEFAULT_LABEL = _("Terminal");
        public string terminal_id;
        public string current_working_directory { get; private set; default = "";} // Location of shell
        public string program_string { get; private set; default = ""; } // Corresponds to fg_pid
        static int terminal_id_counter = 0;
        private bool init_complete;
        public bool resized {get; set;}

        GLib.Pid child_pid = -1; // Corresponds to shell process or whatever was initial process spawned
        GLib.Pid fg_pid = -1; // Corresponds to a process spawned by the shell

        public unowned MainWindow main_window { get; construct set; }

        private Terminal.Application app {
            get {
                return main_window.app;
            }
        }

        // There may be no associated tab while made restorable or when closing
        public unowned Adw.TabPage? tab;
        public string? link_uri;

        public string tab_label {
            get {
                return tab != null ? tab.title : "";
            }

            set {
                if (value != null && tab != null) {
                    tab.title = value;
                }
            }
        }

        public const string ACTION_COPY = "term.copy";
        public const string ACTION_COPY_OUTPUT = "term.copy-output";
        public const string ACTION_CLEAR_SCREEN = "term.clear-screen";
        public const string ACTION_RESET = "term.reset";
        public const string ACTION_PASTE = "term.paste";
        public const string ACTION_RELOAD = "term.reload";
        public const string ACTION_SCROLL_TO_COMMAND = "term.scroll-to-command";
        public const string ACTION_SELECT_ALL = "term.select-all";


        public const string[] ACCELS_COPY = { "<Control><Shift>C", null };
        public const string[] ACCELS_COPY_OUTPUT = { "<Alt>C", null };
        public const string[] ACCELS_CLEAR_SCREEN = { "<Control><Shift>L", null };
        public const string[] ACCELS_RESET = { "<Control><Shift>K", null };
        public const string[] ACCELS_PASTE = { "<Control><Shift>V", null };
        public const string[] ACCELS_RELOAD = { "<Control><Shift>R", "<Ctrl>F5", null };
        public const string[] ACCELS_SCROLL_TO_COMMAND = { "<Alt>Up", null };
        public const string[] ACCELS_SELECT_ALL = { "<Control><Shift>A", null };
        // Specify zooming shortcuts for use by tooltips in SettingsPopover. We don't use actions for this.
        public const string[] ACCELS_ZOOM_DEFAULT = { "<control>0", "<Control>KP_0", null };
        public const string[] ACCELS_ZOOM_IN = { "<Control>plus", "<Control>equal", "<Control>KP_Add", null };
        public const string[] ACCELS_ZOOM_OUT = { "<Control>minus", "<Control>KP_Subtract", null };

        public int default_size;
        const string SEND_PROCESS_FINISHED_BASH = "dbus-send --type=method_call " +
                                                  "--session --dest=io.elementary.terminal " +
                                                  "/io/elementary/terminal " +
                                                  "io.elementary.terminal.ProcessFinished " +
                                                  "string:$PANTHEON_TERMINAL_ID " +
                                                  "string:\"$(fc -nl -1 | cut -c 3-)\" " +
                                                  "int32:\$__bp_last_ret_value >/dev/null 2>&1";

        /* Following strings are used to build RegEx for matching URIs */
        const string USERCHARS = "-[:alnum:]";
        const string USERCHARS_CLASS = "[" + USERCHARS + "]";
        const string PASSCHARS_CLASS = "[-[:alnum:]\\Q,?;.:/!%$^*&~\"#'\\E]";
        const string HOSTCHARS_CLASS = "[-[:alnum:]]";
        const string HOST = HOSTCHARS_CLASS + "+(\\." + HOSTCHARS_CLASS + "+)*";
        const string PORT = "(?:\\:[[:digit:]]{1,5})?";
        const string PATHCHARS_CLASS = "[-[:alnum:]\\Q_$.+!*,;:@&=?/~#%\\E]";
        const string PATHTERM_CLASS = "[^\\Q]'.}>) \t\r\n,\"\\E]";
        const string SCHEME = "(?:news:|telnet:|nntp:|file:\\/|https?:|ftps?:|sftp:|webcal:" +
                              "|irc:|sftp:|ldaps?:|nfs:|smb:|rsync:|ssh:|rlogin:|telnet:|git:" +
                              "|git\\+ssh:|bzr:|bzr\\+ssh:|svn:|svn\\+ssh:|hg:|mailto:|magnet:)";

        const string USERPASS = USERCHARS_CLASS + "+(?:" + PASSCHARS_CLASS + "+)?";
        const string URLPATH = "(?:(/" + PATHCHARS_CLASS +
                               "+(?:[(]" + PATHCHARS_CLASS +
                               "*[)])*" + PATHCHARS_CLASS +
                               "*)*" + PATHTERM_CLASS +
                               ")?";

        const string[] REGEX_STRINGS = {
            SCHEME + "//(?:" + USERPASS + "\\@)?" + HOST + PORT + URLPATH,
            "(?:www|ftp)" + HOSTCHARS_CLASS + "*\\." + HOST + PORT + URLPATH,
            "(?:callto:|h323:|sip:)" + USERCHARS_CLASS + "[" + USERCHARS + ".]*(?:" + PORT + "/[a-z0-9]+)?\\@" + HOST,
            "(?:mailto:)?" + USERCHARS_CLASS + "[" + USERCHARS + ".]*\\@" + HOSTCHARS_CLASS + "+\\." + HOST,
            "(?:news:|man:|info:)[[:alnum:]\\Q^_{|}~!\"#$%&'()*+,./;:=?`\\E]+"
        };

        public const double MIN_SCALE = 0.25;
        public const double MAX_SCALE = 4.0;

        public const int SYS_PIDFD_OPEN = 434; // Same on every arch

        public bool child_has_exited {
            get;
            private set;
        }

        public bool killed {
            get;
            private set;
        }

        private unowned Gdk.Clipboard clipboard;

        private GLib.SimpleAction copy_action;
        private GLib.SimpleAction copy_output_action;
        private GLib.SimpleAction clear_screen_action;
        private GLib.SimpleAction reset_action;
        private GLib.SimpleAction paste_action;
        private GLib.SimpleAction scroll_to_command_action;

        private long remembered_position; /* Only need to remember row at the moment */
        private long remembered_command_start_row = 0; /* Only need to remember row at the moment */
        private long remembered_command_end_row = 0; /* Only need to remember row at the moment */
        public bool last_key_was_return = true;

        private Gtk.EventControllerScroll scroll_controller;
        private double scroll_delta = 0.0;

        public signal void cwd_changed ();
        public signal void foreground_process_changed ();

        public TerminalWidget (MainWindow parent_window) {
            Object (
                main_window: parent_window
            );
        }

        construct {
            pointer_autohide = true;
            terminal_id = "%i".printf (terminal_id_counter++);
            init_complete = false;
            child_has_exited = false;
            killed = false;

            update_audible_bell ();
            update_cursor_shape ();
            update_theme ();

            var granite_settings = Granite.Settings.get_default ();
            granite_settings.notify["prefers-color-scheme"].connect (update_theme);
            Application.settings.changed["audible-bell"].connect (update_audible_bell);
            Application.settings.changed["background"].connect (update_theme);
            Application.settings.changed["cursor-color"].connect (update_theme);
            Application.settings.changed["cursor-shape"].connect (update_cursor_shape);
            Application.settings.changed["follow-system-style"].connect (update_theme);
            Application.settings.changed["foreground"].connect (update_theme);
            Application.settings.changed["palette"].connect (update_theme);
            Application.settings.changed["prefer-dark-style"].connect (update_theme);
            Application.settings.changed["theme"].connect (update_theme);

            var motion_controller = new Gtk.EventControllerMotion () {
                propagation_phase = CAPTURE
            };
            motion_controller.enter.connect (pointer_focus);

            // Used only for ctrl-scroll zooming
            scroll_controller = new Gtk.EventControllerScroll (VERTICAL) {
                propagation_phase = TARGET
            };
            scroll_controller.scroll.connect (on_scroll);
            scroll_controller.scroll_end.connect (() => scroll_delta = 0.0);

            var key_controller = new Gtk.EventControllerKey () {
                propagation_phase = CAPTURE
            };
            key_controller.key_pressed.connect (on_key_pressed);

            var focus_controller = new Gtk.EventControllerFocus ();
            focus_controller.leave.connect (() => scroll_controller.flags = NONE);
            focus_controller.enter.connect (() => scroll_controller.flags = VERTICAL);

            var primary_gesture = new Gtk.GestureClick () {
                propagation_phase = TARGET,
                button = Gdk.BUTTON_PRIMARY
            };
            primary_gesture.pressed.connect (primary_pressed);

            var secondary_gesture = new Gtk.GestureClick () {
                propagation_phase = TARGET,
                button = Gdk.BUTTON_SECONDARY
            };

            secondary_gesture.pressed.connect ((n, x, y) => setup_menu (x, y));

            // Accels added by set_accels_for_action in Application do not work for actions
            // in child widgets so use shortcut_controller instead.
            var select_all_shortcut = new Gtk.Shortcut (
                new Gtk.KeyvalTrigger (Gdk.Key.A, CONTROL_MASK | SHIFT_MASK),
                new Gtk.NamedAction ("term.select-all")
            );

            var reload_shortcut = new Gtk.Shortcut (
                new Gtk.AlternativeTrigger (
                    new Gtk.KeyvalTrigger (Gdk.Key.R, CONTROL_MASK | SHIFT_MASK),
                    new Gtk.KeyvalTrigger (Gdk.Key.F5, CONTROL_MASK)
                ),
                new Gtk.NamedAction ("term.reload")
            );

            var scroll_to_command_shortcut = new Gtk.Shortcut (
                new Gtk.KeyvalTrigger (Gdk.Key.Up, ALT_MASK),
                new Gtk.NamedAction ("term.scroll-to-command")
            );

            var copy_output_shortcut = new Gtk.Shortcut (
                new Gtk.KeyvalTrigger (Gdk.Key.C, ALT_MASK),
                new Gtk.NamedAction ("term.copy-output")
            );

            var shortcut_controller = new Gtk.ShortcutController () {
                propagation_phase = CAPTURE,
                propagation_limit = SAME_NATIVE
            };
            shortcut_controller.add_shortcut (select_all_shortcut);
            shortcut_controller.add_shortcut (reload_shortcut);
            shortcut_controller.add_shortcut (scroll_to_command_shortcut);
            shortcut_controller.add_shortcut (copy_output_shortcut);

            add_controller (motion_controller);
            add_controller (scroll_controller);
            add_controller (key_controller);
            add_controller (focus_controller);
            add_controller (secondary_gesture);
            add_controller (primary_gesture);
            add_controller (shortcut_controller);

            selection_changed.connect (() => copy_action.set_enabled (get_has_selection ()));
            // Cannot use copy last output action if window was resized after remembering start position
            notify["height-request"].connect (() => resized = true);
            notify["width-request"].connect (() => resized = true);
            //NOTE Vte.Terminal `current_directory_uri_changed` signal does not work and is deprecated since v0.78
            child_exited.connect (on_child_exited);
            commit.connect ((text, size) => {
                unichar c;
                for (int i = 0; text.get_next_char (ref i, out c);) {
                    UnicodeType t = c.type ();
                    if (t == 0) {
                        on_contents_changed ();
                        break;
                    }
                }
            });

            ulong once = 0;
            once = realize.connect (() => {
                clipboard = Gdk.Display.get_default ().get_clipboard ();
                clipboard.changed.connect (() => { setup_menu (); });
                disconnect (once);
            });

            var drop_target = new Gtk.DropTarget (Type.STRING, Gdk.DragAction.COPY);
            drop_target.drop.connect (on_drop);
            add_controller (drop_target);

            /* Make Links Clickable */
            this.clickable (REGEX_STRINGS);

            // Setup Actions
            var action_group = new GLib.SimpleActionGroup ();
            insert_action_group ("term", action_group);

            copy_action = new GLib.SimpleAction ("copy", null);
            copy_action.set_enabled (false);
            copy_action.activate.connect (() => copy_clipboard.emit ());
            action_group.add_action (copy_action);

            copy_output_action = new GLib.SimpleAction ("copy-output", null);
            copy_output_action.set_enabled (false);
            copy_output_action.activate.connect (copy_output);
            action_group.add_action (copy_output_action);

            clear_screen_action = new GLib.SimpleAction ("clear-screen", null);
            clear_screen_action.set_enabled (true);
            clear_screen_action.activate.connect (action_clear_screen);
            action_group.add_action (clear_screen_action);

            reset_action = new GLib.SimpleAction ("reset", null);
            reset_action.set_enabled (true);
            reset_action.activate.connect (action_reset);
            action_group.add_action (reset_action);

            paste_action = new GLib.SimpleAction ("paste", null);
            paste_action.activate.connect (() => paste_clipboard.emit ());
            action_group.add_action (paste_action);

            var reload_action = new GLib.SimpleAction ("reload", null);
            reload_action.activate.connect (reload);
            action_group.add_action (reload_action);

            scroll_to_command_action = new GLib.SimpleAction ("scroll-to-command", null);
            scroll_to_command_action.set_enabled (false);
            scroll_to_command_action.activate.connect (scroll_to_command);
            action_group.add_action (scroll_to_command_action);

            var select_all_action = new GLib.SimpleAction ("select-all", null);
            select_all_action.activate.connect (select_all);
            action_group.add_action (select_all_action);
        }

        private void pointer_focus () {
            // If this event caused focus-in then we need to suppress following hyperlinks on button release.
            allow_hyperlink = has_focus;
        }


        private void primary_pressed (Gtk.GestureClick gesture, int n_press, double x, double y) {
            link_uri = null;
            if (allow_hyperlink) {
                link_uri = get_link (x, y);

                if (link_uri != null && !get_has_selection ()) {
                   main_window.get_simple_action (MainWindow.ACTION_OPEN_IN_BROWSER).activate (null);
                }
            } else {
                allow_hyperlink = true;
            }
        }

        private bool on_scroll (Gtk.EventControllerScroll controller, double x, double y) {
            // If control is pressed try to emulate a normal scrolling event by summing deltas.
            // Step size of 0.5 chosen to match sensitivity
            var control_pressed = Gdk.ModifierType.CONTROL_MASK in controller.get_current_event_state ();
            if (!control_pressed) {
                return false;
            }

            scroll_delta += y;

            if (scroll_delta >= 0.5) {
                decrease_font_size ();
                scroll_delta = 0.0;
            } else if (scroll_delta <= -0.5) {
                increase_font_size ();
                scroll_delta = 0.0;
            }

            return true;
        }

        private bool on_key_pressed (Gtk.EventControllerKey controller, uint keyval, uint keycode, Gdk.ModifierType modifiers) {
            var control_pressed = CONTROL_MASK in modifiers;
            var shift_pressed = SHIFT_MASK in modifiers;

            switch (keyval) {
                case Gdk.Key.Alt_L:
                case Gdk.Key.Alt_R:
                    // enable/disable the action before we try to use
                    copy_output_action.set_enabled (!resized && get_last_output ().length > 0);
                    break;

                case Gdk.Key.Return:
                    remember_position ();
                    scroll_to_command_action.set_enabled (true);
                    remember_command_end_position ();
                    copy_output_action.set_enabled (false);
                    break;

                case Gdk.Key.Up:
                case Gdk.Key.Down:
                    remember_command_start_position ();
                    break;

                case Gdk.Key.Menu:
                    long col, row;
                    get_cursor_position (out col, out row);

                    var cell_width = get_char_width ();
                    var cell_height = get_char_height ();
                    var vadj = vadjustment.value;
                    setup_menu (col * cell_width, (row - vadj) * cell_height);
                    break;

                case Gdk.Key.plus:
                case Gdk.Key.equal:
                case Gdk.Key.KP_Add:
                    if (control_pressed) {
                        increase_font_size ();
                        return true;
                    }

                    break;

                case Gdk.Key.minus:
                case Gdk.Key.KP_Subtract:
                    if (control_pressed) {
                        decrease_font_size ();
                        return true;
                    }

                    break;

                case Gdk.Key.@0:
                case Gdk.Key.KP_0:
                    if (control_pressed) {
                        default_font_size ();
                        return true;
                    }

                    break;

                default:
                    if (
                        !(control_pressed || shift_pressed) ||
                        !(Gtk.accelerator_get_default_mod_mask () in modifiers)
                    ) {

                        remember_command_start_position ();
                    }
                    break;
            }

            // Use hardware keycodes so the key used is unaffected by internationalized layout
            bool match_keycode (uint keyval, uint code) {
                //TODO Gtk4 Port:Check this works for non-standard keyboard layouts
                Gdk.KeymapKey[] keys;
                uint[] keyvals;
                if (get_display ().map_keycode (code, out keys, out keyvals)) {
                    foreach (var kv in keyvals) {
                        if (kv == keyval) {
                            return true;
                        }
                    }
                }

                return false;
            }

            //NOTE It appears the Vte.Terminal native handling of copy with <Shift><Control>C
            // does not work in Gtk4 so for now handle natural and native.
            var natural = Application.settings.get_boolean ("natural-copy-paste");
            if (control_pressed) {
                if (match_keycode (Gdk.Key.c, keycode)) {
                    //Links not copied unless selected (compare context menu action)
                    if (get_has_selection () && (natural || shift_pressed)) {
                        copy_clipboard ();
                        // Natural copy unselects unless the shift is held down
                        if (natural && !shift_pressed) {
                            unselect_all ();
                        }

                        return true;
                    } else {
                        last_key_was_return = true; // Ctrl-c: Command cancelled
                    }
                } else if (
                    match_keycode (Gdk.Key.v, keycode) && (natural || shift_pressed) &&
                    clipboard.get_formats ().contain_gtype (Type.STRING)
                ) {

                    paste_clipboard ();
                    return true;
                }
            }

            if (CONTROL_MASK in modifiers && SHIFT_MASK in modifiers && match_keycode (Gdk.Key.k, keycode)) {
                action_reset ();
                return true;
            }

            if (CONTROL_MASK in modifiers && SHIFT_MASK in modifiers && match_keycode (Gdk.Key.l, keycode)) {
                action_clear_screen ();
                return true;
            }

            if (ALT_MASK in modifiers && keyval == Gdk.Key.Up) {
                return !scroll_to_command_action.enabled;
            }

            return false;
        }

        private void setup_menu (double x = -1, double y = -1) {
            main_window.update_context_menu ();

            link_uri = get_link (x, y);
            if (link_uri != null) {
                copy_action.set_enabled (true);
            }

            // Update the "Paste" menu option
            var formats = clipboard.get_formats ();
            bool can_paste = false;

            if (formats != null) {
                can_paste = formats.contain_gtype (Type.STRING);
            }

            paste_action.set_enabled (can_paste);

            // Update the "Copy Last Output" menu option
            var has_output = !resized && get_last_output ().length > 0;
            copy_output_action.set_enabled (has_output);

            context_menu_model = main_window.context_menu_model;
        }



        protected override void copy_clipboard () {
            if (link_uri != null && !get_has_selection ()) {
                clipboard.set_text (link_uri);
            } else {
                base.copy_clipboard ();
            }
        }

        private void copy_output () {
            var output = get_last_output ();
            clipboard.set_text (output);
        }

        public delegate void ConfirmedActionCallback (bool confirmed);
        public void confirm_kill_fg_process (
            string primary_text,
            string button_label,
            ConfirmedActionCallback cb
        ) {
            if (has_foreground_process ()) {
                var dialog = new ForegroundProcessDialog (
                    (MainWindow) get_root (),
                    primary_text,
                    button_label
                );

                dialog.response.connect ((res) => {
                    dialog.destroy ();
                    cb (res == Gtk.ResponseType.ACCEPT);
                });
                dialog.present ();
            } else {
                cb (true);
            }
        }

        private void action_clear_screen () {
            if (has_foreground_process ()) {
                // We cannot guarantee the terminal is left in sensible state if we
                // kill foreground process so ignore clear screen request
                return;
            }

            clear_pending_input ();
            feed_child ("clear -x\n".data);

            // We keep the scrollback history, just clear the screen
            // We know there is no foreground process so we can just feed the command in
        }

        private void action_reset () {
            confirm_kill_fg_process (
                _("Are you sure you want to reset the terminal?"),
                _("Reset"),
                (confirmed) => {
                    if (confirmed) {
                        kill_fg ();
                        reset (true, true);
                        // For some reason prompt does not appear unless we clear screen
                        feed_child ("clear -x\n".data);
                    }
                }
            );
        }

        public void reload () {
            var old_loc = get_shell_location ();
            confirm_kill_fg_process (
                _("Are you sure you want to reload this tab?"),
                _("Reload"),
                (confirmed) => {
                    if (confirmed) {
                        term_ps ();
                        //TODO Do we need to deal with cases where shell does not
                        // exit ever?
                        while (child_pid != -1) {
                            MainContext.get_thread_default ().iteration (true);
                        }

                        spawn_shell (old_loc);
                    }
                }
            );
        }

        public void clear_pending_input () {
            // This is hacky but no obvious way to feed in escape sequences to clear the line
            // Assume any pending input is less than 1000 chars.
            string backspaces = string.nfill (1000, '\b');
            feed_child (backspaces.data);
        }


        protected override void paste_clipboard () {
            var content_provider = clipboard.get_content ();
            if (content_provider != null) {
                try {
                    Value val = Value (typeof (string));
                    content_provider.get_value (ref val);
                    var text = val.dup_string ();
                    validated_paste (text);
                } catch (Error e) {
                    warning ("Error getting clipboard content - %s", e.message);
                    return;
                }
            } else {
                clipboard.read_text_async.begin (null, (obj, res) => {
                    try {
                        var text = clipboard.read_text_async.end (res);
                        validated_paste (text);
                    } catch (Error e) {
                        warning ("Error reading text from clipboard - %s", e.message);
                    }
                });
            }
        }

        // Check pasted and dropped text before feeding to child;
        private void validated_paste (string? text) {
            // Do nothing when text is invalid
            if (text == null || !text.validate ()) {
                return;
            }

            // No user interaction because of user's preference
            if (!Application.settings.get_boolean ("unsafe-paste-alert")) {
                paste_text (text);
                return;
            }


            string[]? warn_text_array;

            // No user interaction for safe commands
            if (Utils.is_safe_paste (text, out warn_text_array)) {
                paste_text (text);
                return;
            }

            // Ask user for interaction for unsafe commands
            unowned var toplevel = (MainWindow) get_root ();
            var warn_text = string.joinv ("\n\n", warn_text_array);
            var dialog = new UnsafePasteDialog (toplevel, warn_text, text.strip ());
            dialog.response.connect ((res) => {
                dialog.destroy ();
                if (res == Gtk.ResponseType.ACCEPT) {
                    paste_text (text);
                }
            });

            dialog.present ();
        }

        private void update_current_working_directory (string cwd) {
            if (tab is Adw.TabPage) { // May not be the case if closing tab
                current_working_directory = cwd;
                tab.tooltip = current_working_directory;
                cwd_changed ();
            }
        }

        private void update_theme () {
            var gtk_settings = Gtk.Settings.get_default ();
            var theme_palette = new Gdk.RGBA[Themes.PALETTE_SIZE];
            if (Application.settings.get_boolean ("follow-system-style")) {
                var system_prefers_dark = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
                gtk_settings.gtk_application_prefer_dark_theme = system_prefers_dark;

                if (system_prefers_dark) {
                    theme_palette = Themes.get_rgba_palette (Themes.DARK);
                } else {
                    theme_palette = Themes.get_rgba_palette (Themes.LIGHT);
                }
            } else {
                gtk_settings.gtk_application_prefer_dark_theme = Application.settings.get_boolean ("prefer-dark-style");
                theme_palette = Themes.get_rgba_palette (Application.settings.get_string ("theme"));
            }

            var background = theme_palette[Themes.PALETTE_SIZE - 3];
            var foreground = theme_palette[Themes.PALETTE_SIZE - 2];
            var cursor = theme_palette[Themes.PALETTE_SIZE - 1];
            var palette = theme_palette[0:16];

            set_colors (foreground, background, palette);
            set_opacity (background.alpha);
            set_color_cursor (cursor);
        }

        private void update_audible_bell () {
            audible_bell = Application.settings.get_boolean ("audible-bell");
        }

        private void update_cursor_shape () {
            set_cursor_shape ((Vte.CursorShape) Application.settings.get_enum ("cursor-shape"));
        }

        //NOTE THis is triggered when the shell exits but not when the foreground process exits
        void on_child_exited () {
            child_has_exited = true;
            last_key_was_return = true;
            fg_pid = -1;
            child_pid = -1;
        }

        public void kill_fg () {
            if (has_foreground_process ()) {
                // Give chance to terminate cleanly before killing
                Posix.kill (fg_pid, Posix.Signal.HUP);
                Posix.kill (fg_pid, Posix.Signal.TERM);
                Posix.kill (fg_pid, Posix.Signal.KILL);
            }
        }

        // Terminate the shell process prior to closing the tab
        public void term_ps () {
            kill_fg ();
            // We know there is no foreground process so we can just feed the command in
            // This works with Flatpak as well so is simpler than trying to kill the
            // process.
            feed_child ("exit\n".data);
            killed = true; // Flag that shell was deliberately killed - do not close page
        }

        private string get_shell () {
            var shell = Application.settings.get_string ("shell");
            if (shell == "") {
                shell = Terminal.Application.is_running_in_flatpak ? FlatpakUtils.fp_guess_shell () : Vte.get_user_shell ();
            }

            if (shell == "") {
                critical ("No user shell available - trying bash");
                shell = "/usr/bin/bash";
            }

            return shell;
        }

        public void spawn_shell (
            string _dir = GLib.Environment.get_current_dir (),
            string command = ""
        ) {

            Array<string> argv = new Array<string> ();
            Array<string> envv = new Array<string> ();
            bool flatpak = Terminal.Application.is_running_in_flatpak;
            string[] temp_envv;
            try {
                temp_envv = flatpak ? FlatpakUtils.fp_get_env () : Environ.get ();
            } catch (Error e) {
                temp_envv = Environ.get ();
            }

            // We assume _dir is a valid path?
            var dir = _dir == "" ? "/" : _dir;
            this.program_string = command;
            this.current_working_directory = dir;

            foreach (string s in temp_envv) {
                envv.append_val (s);
            }
            foreach (string s in terminal_envv) {
                envv.append_val (s);
            }

            // Export ID so we can identify the terminal for which the process completion is reported
            envv.append_val ("PANTHEON_TERMINAL_ID=" + terminal_id);

            var shell = get_shell ();

            if (flatpak) {
                // In flatpak we always have to spawn a shell on the host first
                argv.append_val (shell);
                if (command.length > 0) {
                    argv.append_val ("-c");
                    argv.append_val (command);
                }

                this.spawn_on_flatpak_host.begin (
                    dir,
                    argv,
                    envv,
                    (pid, error) => {
                        if (error == null) {
                            after_successful_spawn (pid);
                        } else {
                            warning (error.message);
                            // on_spawn_failed (); //TODO Expose message in UI as toast or otherwise
                            return;
                        }
                    }
                );
            } else {
                // When running natively we just spawn the command
                if (command.length > 0) {
                    argv.append_val (command);
                } else {
                    argv.append_val (shell);
                }

                this.spawn_async (
                    Vte.PtyFlags.DEFAULT,
                    dir,
                    argv.data,
                    envv.data,
                    SpawnFlags.SEARCH_PATH,
                    null,
                    -1,
                    null,
                    (terminal, pid, error) => {
                        if (error == null) {
                            after_successful_spawn (pid);
                        } else {
                            warning (error.message);
                            return;
                        }
                    }
                );
            }
        }

        private void after_successful_spawn (int pid) {
            // Success - reset these flags
            this.child_pid = pid;
            killed = false;
            child_has_exited = false;
            fg_pid = -1;
            // Its a new shell so no need to clear pending input
            // but after respawning the shell, the terminal widget may have extraneous
            // content.
            feed_child ("clear\n".data);
        }

        // delegate void TerminalSpawnAsyncCallback (Terminal terminal, Pid pid, Error error);
        // The following function is derived from the work of [BlackBox] tweaked to make interface
        // more like Vte.spawn_async
        private GLib.Cancellable? fp_spawn_host_command_callback_cancellable = null;
        private delegate void HostSpawnAsyncCallback (Pid pid, Error? e);
        private async void spawn_on_flatpak_host (
            string? cwd,
            Array<string> argv,
            Array<string> envv,
            HostSpawnAsyncCallback cb) {

            fp_spawn_host_command_callback_cancellable = new GLib.Cancellable ();
            var pty_slaves = new int[3];
            Vte.Pty _ppty;

            try {
                make_pty_and_slaves (out _ppty, ref pty_slaves);
            } catch (Error e) {
                warning ("creating pty slaves failed");
                cb (-1, e);
            }

            int p = -1;
            try {
                yield Terminal.FlatpakUtils.send_host_command (
                    cwd,
                    argv,
                    envv,
                    pty_slaves,
                    (pid, status) => {
                        warning ("host command exited pid %u, %u status", pid, status);
                        // This does not get emitted automatically in Flatpak so do it ourselves
                        child_exited ((int)pid);
                    },
                    fp_spawn_host_command_callback_cancellable,
                    out p
                );

                this.pty = _ppty;
                cb (p, null);
            } catch (Error e) {
                warning ("send host command failed: %s", e.message);
                cb (-1, e);
            }
        }

        private void make_pty_and_slaves (out Vte.Pty vte_pty, ref int[] pty_slaves) throws Error {
            vte_pty = new Vte.Pty.sync (Vte.PtyFlags.NO_CTTY, null);

            int pty_master = vte_pty.get_fd ();

            if (Posix.grantpt (pty_master) != 0) {
                throw (new FileError.FAILED ("Failed granting access to slave pseudoterminal device"));
            }

            if (Posix.unlockpt (pty_master) != 0) {
                throw (new FileError.FAILED ("Failed unlocking slave pseudoterminal device"));
            }

            pty_slaves[0] = Posix.open (Posix.ptsname (pty_master), Posix.O_RDWR | Posix.O_CLOEXEC);

            if (pty_slaves[0] < 0) {
                throw (new FileError.FAILED ("Failed opening slave pseudoterminal device"));
            }

            pty_slaves[1] = Posix.dup (pty_slaves [0]);
            pty_slaves[2] = Posix.dup (pty_slaves [0]);
        }

        private int try_get_foreground_pid () {
            if (child_has_exited) {
                return -1;
            }

            try {
                int pty = get_pty ().fd;
                if (Terminal.Application.is_running_in_flatpak) {
                    return FlatpakUtils.fp_get_foreground_pid (child_pid);
                } else {
                    //TODO Use same method as Flatpak as we can get name at same time
                    return Posix.tcgetpgrp (pty);
                }
            } catch (Error e) {
                warning ("Error getting foreground process pid. %s", e.message);
                return -1;
            }
        }

        public bool has_foreground_process () {
            int _fg_pid = try_get_foreground_pid ();
            if (_fg_pid != this.child_pid && _fg_pid != -1) {
                fg_pid = _fg_pid;
                return true;
            } else {
                return false;
            }
        }

        public int calculate_width (int column_count) {
            int width = (int) (this.get_char_width ()) * column_count;
            return width;
        }

        public int calculate_height (int row_count) {
            int height = (int) (this.get_char_height ()) * row_count;
            return height;
        }

        private void clickable (string[] str) {
            foreach (unowned string exp in str) {
                try {
                    var regex = new Vte.Regex.for_match (exp, -1, PCRE2.Flags.MULTILINE);
                    int id = this.match_add_regex (regex, 0);
                    this.match_set_cursor_name (id, "pointer");
                } catch (GLib.Error error) {
                    warning (error.message);
                }
            }
        }

        private string? get_link (double x = -1, double y = -1) {
            int tag = 0;
            return check_match_at (x, y, out tag);
        }

        // Get current working directory of shell
        public string get_shell_location () {
            int pid = (!) (this.child_pid);
            if (Terminal.Application.is_running_in_flatpak) {
                string? cwd = FlatpakUtils.fp_get_current_directory_uri (pid, null);
                return cwd;
            } else {
                try {
                    return GLib.FileUtils.read_link ("/proc/%d/cwd".printf (pid));
                } catch (GLib.FileError error) {
                    /* Tab name disambiguation may call this before shell location available. */
                    /* No terminal warning needed */
                    return "";
                }
            }
        }

        public string get_pid_exe_name (int pid) {
            try {
                string exe;
                if (Terminal.Application.is_running_in_flatpak) {
                    exe = FlatpakUtils.fp_get_exe_name (pid);
                } else {
                    exe = GLib.FileUtils.read_link ("/proc/%d/exe".printf (pid));
                }
                return Path.get_basename (exe);
            } catch (GLib.Error e) {
                return "";
            }
        }

        public new void increase_font_size () {
            font_scale += 0.1;
        }

        public new void decrease_font_size () {
            font_scale -= 0.1;
        }

        public void default_font_size () {
            font_scale = 1.0;
        }

        public bool is_init_complete () {
            return init_complete;
        }

        public void set_init_complete () {
            init_complete = true;
        }

        private bool on_drop (Value val, double x, double y) {
            var uris = Uri.list_extract_uris (val.dup_string ());
            string path;
            File file;

            for (var i = 0; i < uris.length; i++) {
                try {
                    if (Uri.is_valid (uris[i], UriFlags.PARSE_RELAXED)) {
                        file = File.new_for_uri (uris[i]);
                        if ((path = file.get_path ()) != null) {
                            uris[i] = Shell.quote (path) + " ";
                        }

                        feed_child (uris[i].data);
                    }
                } catch (Error e) {
                    // Validate non-uri text for safety before feeding
                    validated_paste (uris[i]);
                }
            }

            return true;
        }

        public void remember_position () {
            long col, row;
            get_cursor_position (out col, out row);
            remembered_position = row;
        }

        public void remember_command_start_position () {
            if (!last_key_was_return || has_foreground_process ()) {
                return;
            }

            long col, row;
            get_cursor_position (out col, out row);
            remembered_command_start_row = row;
            last_key_was_return = false;
            resized = false;
        }

        public void remember_command_end_position () {
            if (last_key_was_return && !has_foreground_process ()) {
                return;
            }

            long col, row;
            get_cursor_position (out col, out row);
            /* Password entry will be on next line, or, if an incorrect password is given, two lines ahead */
            /* This restriction is required for `include_command = false to work` (although not currently used) */
            if (row - remembered_command_end_row <= 2) {
                remembered_command_end_row = row;
            }

            last_key_was_return = true;
        }

        // This is only ever called privately with the default parameter at the moment
        private string get_last_output (bool include_command = true) {
            long output_end_col, output_end_row, start_row;
            get_cursor_position (out output_end_col, out output_end_row);

            var command_lines = remembered_command_end_row - remembered_command_start_row;

            if (!include_command) {
                start_row = remembered_command_end_row + 1;
            } else {
                start_row = remembered_command_start_row;
            }

            if (output_end_row - start_row < (include_command ? command_lines + 1 : 1)) {
                return "";
            }

            last_key_was_return = true;

            /* get text to the beginning of current line (to omit last prompt)
             * Note that using end_row, 0 for the end parameters results in the first
             * character of the prompt being selected for some reason. We assume a nominal
             * maximum line length rather than determine the actual length.  */
            size_t len = 0;
            return get_text_range_format (Vte.Format.TEXT, start_row, 0, output_end_row - 1, 1000, out len) + "\n";
        }

        private void scroll_to_command (GLib.SimpleAction action, GLib.Variant? parameter) {
            long row, delta;

            get_cursor_position (null, out row);
            delta = remembered_position - row;

            vadjustment.value += (int) delta + height_request / get_char_height () - 1;
            action.set_enabled (false); // Repeated presses are ignored
        }

        // Note that this handler is triggered by *any* change in the visible appearance of
        // the terminal including resizing or moving so is not very efficient
        // BlackBox just polls the terminal at regular intervals.
        // Unfortunately, the `current_directory_uri` signal does not currently work in Vte.
        private uint contents_changed_timeout_id = 0;
        private const int CONTENTS_CHANGED_DELAY_MSEC = 200;
        private bool contents_changed_continue = true;
        private void on_contents_changed () {
            // Ignore any changes during reloading
            if (killed) {
                return;
            }
            contents_changed_continue = true;
            if (contents_changed_timeout_id > 0) {
                return;
            }

            contents_changed_timeout_id = Timeout.add (
                CONTENTS_CHANGED_DELAY_MSEC,
                () => {
                    if (contents_changed_continue) {
                        contents_changed_continue = false;
                        return Source.CONTINUE;
                    }

                    contents_changed_timeout_id = 0;
                    return check_cwd_and_fg_pid ();
                }
            );

        }

        private bool check_cwd_and_fg_pid () {
            if (killed || child_has_exited) {
                return Source.REMOVE;
            }

            var cwd = get_shell_location ();
            if (cwd != current_working_directory) {
                update_current_working_directory (cwd);
            }

            int pid = fg_pid;
            int _fg_pid;
            debug ("current fg_pid %i, child_pid %i", fg_pid, child_pid);
            // Signal if foreground process just started or just finished
            if (has_foreground_process ()) {
                if (pid != fg_pid) { // has a new foreground process
                    debug ("process started");
                    program_string = get_pid_exe_name (fg_pid);
                    foreground_process_changed ();
                }

                return Source.CONTINUE; // Continue to poll while there is a fg process to detect it ending.
            } else if (fg_pid != child_pid && fg_pid != -1) { // Process just ended
                debug ("process finished");
                fg_pid = -1;
                program_string = "";
                foreground_process_changed ();
            }

            debug ("now fg_pid %i, child_pid %i", fg_pid, child_pid);
            return Source.REMOVE;
        }

        public void prepare_to_close () {
            if (contents_changed_timeout_id > 0) {
                Source.remove (contents_changed_timeout_id);
                contents_changed_timeout_id = 0;
            }
        }
    }
}

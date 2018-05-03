// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
* Copyright (c) 2011-2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3, as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace PantheonTerminal {
    public class PantheonTerminalApp : Gtk.Application {
        private GLib.List <PantheonTerminalWindow> windows;

        public static string? working_directory = null;
        /* command_e (-e) is used for running commands independently (not inside a shell) */
        [CCode (array_length = false, array_null_terminated = true)]
        private static string[]? command_e = null;

        public int minimum_width;
        public int minimum_height;

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
            application_id = "io.elementary.terminal";  /* Ensures only one instance runs */

            Intl.setlocale (LocaleCategory.ALL, "");
        }

        public PantheonTerminalApp () {
            Granite.Services.Logger.initialize ("PantheonTerminal");
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

            windows = new GLib.List <PantheonTerminalWindow> ();

            saved_state = new SavedState ();
            settings = new Settings ();
        }

        public void new_window () {
            var window = get_last_window ();

            if (window == null) {
                new PantheonTerminalWindow (this).present ();
            } else {
                new PantheonTerminalWindow (this, false).present ();
            }
        }

        public PantheonTerminalWindow new_window_with_coords (int x, int y, bool should_recreate_tabs = true, bool ensure_tab = false) {
            var window = new PantheonTerminalWindow.with_coords (this, x, y, should_recreate_tabs, ensure_tab);

            return window;
        }

        public override int command_line (ApplicationCommandLine command_line) {
            // keep the application running until we are done with this commandline
            hold ();
            int res = _command_line (command_line);
            release ();
            return res;
        }

        public override void window_added (Gtk.Window window) {
            windows.append (window as PantheonTerminalWindow);
            base.window_added (window);
        }

        public override void window_removed (Gtk.Window window) {
            windows.remove (window as PantheonTerminalWindow);
            base.window_removed (window);
        }

        public override bool dbus_register (DBusConnection connection, string object_path) throws Error {
            base.dbus_register (connection, object_path);

            var dbus = new DBus ();
            connection.register_object (object_path, dbus);

            dbus.finished_process.connect ((id, process, exit_status) => {
                foreach (var window in windows) {
                    foreach (var terminal in window.terminals) {
                        if (terminal.terminal_id == id) {

                            if (!terminal.is_init_complete ()) {
                                terminal.set_init_complete ();
                            } else {

                                if (terminal != window.current_terminal) {
                                    if (exit_status == 0) {
                                        terminal.tab.icon = new ThemedIcon ("process-completed-symbolic");
                                    } else {
                                        terminal.tab.icon = new ThemedIcon ("process-error-symbolic");
                                    }
                                }

                                if ((window.get_window ().get_state () & Gdk.WindowState.FOCUSED) == 0) {
                                    var notification = new Notification (_("Task finished"));
                                    notification.set_body (process);
                                    notification.set_icon (new ThemedIcon ("utilities-terminal"));
                                    send_notification (null, notification);
                                }
                            }

                        }
                    }
                }
            });

            return true;
        }

        private int _command_line (ApplicationCommandLine command_line) {
            var context = new OptionContext ("File");
            context.add_main_entries (entries, "pantheon-terminal");
            context.add_group (Gtk.get_option_group (true));

            string[] args = command_line.get_arguments ();

            try {
                unowned string[] tmp = args;
                context.parse (ref tmp);
            } catch (Error e) {
                stdout.printf ("pantheon-terminal: ERROR: " + e.message + "\n");
                return 0;
            }

            if (command_e != null) {
                run_commands (command_e);

            } else if (working_directory != null) {
                start_terminal_with_working_directory (working_directory);

            } else {
                new_window ();
            }

            // Do not save the value until the next instance of
            // Pantheon Terminal is started
            command_e = null;
            working_directory = null;

            return 0;
        }

        private void run_commands (string[] commands) {
            PantheonTerminalWindow? window;
            window = get_last_window ();

            if (window == null) {
                window = new PantheonTerminalWindow (this, false);
            }

            foreach (string command in commands) {
                window.add_tab_with_command (command);
            }
        }

        private void start_terminal_with_working_directory (string working_directory) {
            PantheonTerminalWindow? window;
            window = get_last_window ();

            if (window != null) {
                window.add_tab_with_working_directory (working_directory);
                window.present ();
            } else
                new PantheonTerminalWindow.with_working_directory (this, working_directory, true);
        }

        private PantheonTerminalWindow? get_last_window () {
            uint length = windows.length ();

            return length > 0 ? windows.nth_data (length - 1) : null;
        }

        private const OptionEntry[] entries = {
            { "execute", 'e', 0, OptionArg.STRING_ARRAY, ref command_e, N_("Run a program in terminal"), "" },
            { "working-directory", 'w', 0, OptionArg.FILENAME, ref working_directory, N_("Set shell working directory"), "" },
            { null }
        };

        public static int main (string[] args) {
            var app = new PantheonTerminalApp ();
            return app.run (args);
        }
    }
}

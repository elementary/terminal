// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2013 Pantheon Terminal Developers
    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
***/

namespace PantheonTerminal {

    public class PantheonTerminalApp : Granite.Application {

        private GLib.List <PantheonTerminalWindow> windows;

        private static string app_cmd_name;
        public static string? working_directory = null;
        /* command_e (-e) is used for running commands independently (not inside a shell) */
        [CCode (array_length = false, array_null_terminated = true)]
        private static string[]? command_e = null;

        private static bool print_version = false;

        public int minimum_width;
        public int minimum_height;

        construct {
            flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
            build_data_dir = Constants.DATADIR;
            build_pkg_data_dir = Constants.PKGDATADIR;
            build_release_name = Constants.RELEASE_NAME;
            build_version = Constants.VERSION;
            build_version_info = Constants.VERSION_INFO;

            program_name = app_cmd_name;
            exec_name = app_cmd_name.down ().replace (" ", "-");
            app_years = "2011-2013";
            app_icon = "utilities-terminal";
            app_launcher = "pantheon-terminal.desktop";
            application_id = "net.launchpad.pantheon-terminal";
            main_url = "https://launchpad.net/pantheon-terminal";
            bug_url = "https://bugs.launchpad.net/pantheon-terminal";
            help_url = "https://answers.launchpad.net/pantheon-terminal";
            translate_url = "https://translations.launchpad.net/pantheon-terminal";
            about_authors = { "David Gomes <david@elementaryos.org",
                              "Mario Guerriero <mario@elementaryos.org>",
                              "Akshay Shekher <voldyman666@gmail.com>" };

            //about_documenters = {"",""};
            about_artists = { "Daniel Foré <daniel@elementaryos.org>" };
            about_translators = "Launchpad Translators";
            about_license_type = Gtk.License.GPL_3_0;
        }

        public PantheonTerminalApp () {
            Granite.Services.Logger.initialize ("PantheonTerminal");
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;

            windows = new GLib.List <PantheonTerminalWindow> ();

            saved_state = new SavedState ();
            settings = new Settings ();
        }

        public void new_window () {
            new PantheonTerminalWindow (this);
        }

        public PantheonTerminalWindow new_window_with_coords (int x, int y, bool should_recreate_tabs=true) {
            var window = new PantheonTerminalWindow.with_coords (this, x, y, should_recreate_tabs);

            return window;
        }

        public override int command_line (ApplicationCommandLine command_line) {
            // keep the application running until we are done with this commandline
            this.hold ();
            int res = _command_line (command_line);
            this.release ();
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

            if (command_e != null)
                run_commands (command_e);
            else if (working_directory != null)
                start_terminal_with_working_directory (working_directory);
            else 
                new_window ();

            // Do not save the value until the next instance of
            // Pantheon Terminal is started
            command_e = null;

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
                new PantheonTerminalWindow.with_working_directory (this, working_directory, false);
        }

        private PantheonTerminalWindow? get_last_window () {
            uint length = windows.length ();

            return length > 0 ? windows.nth_data (length - 1) : null;
        }

        static const OptionEntry[] entries = {
            { "version", 'v', 0, OptionArg.NONE, out print_version, N_("Print version info and exit"), null },
            { "execute" , 'e', 0, OptionArg.STRING_ARRAY, ref command_e, N_("Run a program in terminal"), "" },
            { "working-directory", 'w', 0, OptionArg.STRING, ref working_directory, N_("Set shell working directory"), "" },
            { null }
        };

        public static int main (string[] args) {
            app_cmd_name = "Pantheon Terminal";

            var context = new OptionContext ("Terminal");
            context.add_main_entries (entries, Constants.GETTEXT_PACKAGE);

            string[] args_primary_instance = args;

            try {
                context.parse(ref args);
            } catch (Error e) {
                stdout.printf ("pantheon-terminal: ERROR: " + e.message + "\n");

                return 0;
            }

            if (print_version) {
                stdout.printf ("Pantheon Terminal %s\n", Constants.VERSION);
                stdout.printf ("Copyright 2011-2013 Pantheon Terminal Developers.\n");

                return 0;
            }

            var app = new PantheonTerminalApp ();
            return app.run (args_primary_instance);
        }
    }
} // Namespace

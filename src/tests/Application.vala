/*
 * Copyright 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

namespace Terminal.Test.Application {
    Terminal.Application application = null;

    delegate void LocalOptionsCallback (VariantDict options);
    delegate void CommandLineCallback (ApplicationCommandLine command_line);
    delegate void ActivateCallback ();

    private void setup () {
        application = new Terminal.Application () {
            application_id = "io.elementary.terminal.tests.application"
        };

        application.window_added.connect ((win) => win.show.connect (() => win.hide ()));

        application.shutdown.connect (() => {
            application.get_windows ().foreach ((win) => win.destroy ());
            application = null;
        });
    }

    private void cli (string[] args, LocalOptionsCallback callback) {
        setup ();

        application.handle_local_options.connect_after ((dict) => {
            callback (dict);
            application.quit ();
            return 0;
        });

        application.run (args);
    }

    private void option (string options, string platform_data, CommandLineCallback callback) {
        ulong oneshot = 0;
        setup ();

        oneshot = application.command_line.connect ((nil) => {
            application.disconnect (oneshot);
            application.command_line (nil);

            var cmdline = (ApplicationCommandLine) Object.new (
                typeof (ApplicationCommandLine),
                "options", new Variant.parsed (options),
                "platform-data", new Variant.parsed (platform_data)
            );

            // using a idle callback here, so that it's get called after command_line() finished
            Idle.add (() => {
                callback (cmdline);
                application.quit ();
                return Source.REMOVE;
            });

            return application.command_line (cmdline);
        });

        application.run (null);
    }

    private void action (string name, Variant? @value, ActivateCallback callback) {
        ulong oneshot = 0;
        setup ();

        oneshot = application.command_line.connect ((nill) => {
            application.disconnect (oneshot);
            application.command_line (nill);

            assert_true (application.has_action (name));
            application.activate_action (name, @value);

            // using a idle callback here, so that we call the callback after activate_action() finished
            Idle.add (() => {
                callback ();
                application.quit ();
                return Source.REMOVE;
            });

            return 0;
        });

        if (application.run (null) != 0) {
            GLib.Test.fail ();
        }
    }

    public static int main (string[] args) {
        Intl.setlocale (LocaleCategory.ALL, "");

        GLib.Test.init (ref args);

        /* MainWindow always create a tab in home, make it the current dir
         * so that we don't create a extra tab during tests
         */
        Environment.set_current_dir (Environment.get_home_dir ());

        // local command line: any instance from terminal
        GLib.Test.add_func ("/application/cli/commandline", () => {
            cli ({ "io.elementary.terminal", "--commandline=true" }, (dict) => {
                assert_true ("commandline" in dict);
                unowned var commandline = dict.lookup_value ("commandline", null).get_bytestring ();
                assert_cmpstr (commandline, CompareOperator.EQ, "true");
            });

            cli ({ "io.elementary.terminal", "-x", "echo", "-e", "true\tfalse" }, (dict) => {
                assert_true ("commandline" in dict);
                unowned var commandline = dict.lookup_value ("commandline", null).get_bytestring ();
                assert_cmpstr (commandline, CompareOperator.EQ, "echo -e true\\tfalse");
            });

            cli ({ "io.elementary.terminal", "--commandline", "echo", "true" }, (dict) => {
                assert_true ("commandline" in dict);
                unowned var commandline = dict.lookup_value ("commandline", null).get_bytestring ();
                assert_cmpstr (commandline, CompareOperator.EQ, "echo true");
            });
        });

        GLib.Test.add_func ("/application/cli/working-directory", () => {
            unowned var working_directory = GLib.Test.get_dir (GLib.Test.FileType.DIST);
            var cwd = Environment.get_current_dir ();

            cli ({ "io.elementary.terminal", "-w", working_directory }, (dict) => {
                assert_false ("working-dir" in dict);
                var current_directory = Environment.get_current_dir ();
                assert_cmpstr (current_directory, CompareOperator.EQ, working_directory);
            });

            Environment.set_current_dir (cwd);
        });

        // primary command line: first instance from terminal. any instance from dbus.
        GLib.Test.add_func ("/application/command-line/new-tab", () => {
            option ("{'new-tab':<true>}", "@a{sv} {}", () => {
                unowned var window = (MainWindow) application.active_window;
                assert_nonnull (window);
                var n_tabs = (int) window.terminals.length ();
                assert_cmpint (n_tabs, CompareOperator.EQ, 2);
            });

            option ("{'new-tab':<false>}", "@a{sv} {}", () => {
                unowned var window = (MainWindow) application.active_window;
                assert_nonnull (window);
                var n_tabs = (int) window.terminals.length ();
                assert_cmpint (n_tabs, CompareOperator.EQ, 1);
            });
        });

        GLib.Test.add_func ("/application/command-line/new-window", () => {
            option ("{'new-window':<true>}", "@a{sv} {}", () => {
                var n_windows = (int) application.get_windows ().length ();
                assert_cmpint (n_windows, CompareOperator.EQ, 2);
            });

            option ("{'new-window':<false>}", "@a{sv} {}", () => {
                var n_windows = (int) application.get_windows ().length ();
                assert_cmpint (n_windows, CompareOperator.EQ, 1);
            });
        });

        GLib.Test.add_func ("/application/command-line/execute", () => {
            string[] execute = { "true", "echo test", "echo -e te\\tst", "false" };

            // valid
            option ("{'execute':<[b'%s']>}".printf (string.joinv ("',b'", execute)), "@a{sv} {}", () => {
                unowned var window = (MainWindow) application.active_window;
                assert_nonnull (window);
                var n_tabs = (int) window.terminals.length ();
                assert_cmpint (n_tabs, CompareOperator.EQ, 5); // include the guaranted extra tab
            });

            // invalid
            option ("{'execute':<[b'',b'',b'']>}", "@a{sv} {}", () => {
                unowned var window = (MainWindow) application.active_window;
                assert_nonnull (window);
                var n_tabs = (int) window.terminals.length ();
                assert_cmpint (n_tabs, CompareOperator.EQ, 1);
            });
        });

        //FIXME: cannot test the commandline option without a way to get the terminal command
        GLib.Test.add_func ("/application/command-line/commandline", () => GLib.Test.skip ());

        GLib.Test.add_func ("/application/command-line/platform-data/cwd", () => {
            unowned var working_directory = GLib.Test.get_dir (GLib.Test.FileType.DIST);

            option ("{'new-tab':<true>}", "{'cwd':<b'%s'>}".printf (working_directory), () => {
                unowned var window = (MainWindow) application.active_window;
                assert_nonnull (window);
                var terminal_directory = window.current_terminal.get_shell_location ();
                assert_cmpstr (terminal_directory, CompareOperator.EQ, working_directory);
            });
        });

        // actions
        GLib.Test.add_func ("/application/action/new-window", () => {
            action ("new-window", null, () => {
                // include the extra window from terminal launching
                var n_windows = (int) application.get_windows ().length ();
                assert_cmpint (n_windows, CompareOperator.EQ, 2);
            });
        });

        GLib.Test.add_func ("/application/action/quit", () => {
            action ("quit", null, () => {
                assert_null (application.active_window);
            });
        });

        return GLib.Test.run ();
    }
}

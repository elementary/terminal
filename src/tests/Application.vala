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
            application_id = "io.elementary.terminal.tests.application",
            is_testing = true
        };

        application.shutdown.connect (() => {
            application.close ();
        });
    }

    private void iterate_context () {
        unowned var context = MainContext.default ();
        bool done = false;
        Timeout.add (200, () => {
            done = true;
            context.wakeup ();
            return Source.REMOVE;
        });

        while (!done) {
            context.iteration (true);
        }
    }

    private void cli (string[] args, LocalOptionsCallback callback) {
        setup ();

        application.handle_local_options.connect_after ((dict) => {
            callback (dict);
            application.quit ();
            return 0;
        });

        if (application.run (args) != 0) {
            GLib.Test.fail ();
        }
    }

    private void option (string? options, string platform_data, CommandLineCallback callback) {
        ulong oneshot = 0;
        setup ();
stdout.printf ("#Enter option after setup\n");
        oneshot = application.command_line.connect ((nil) => {
stdout.printf ("#oneshot callback\n");
            application.disconnect (oneshot);
stdout.printf ("#calling commandline with nil\n");
            // Opens primary instance (no options)
            application.command_line (nil);
            ApplicationCommandLine? cmdline = null;
            if (options != null) {
                cmdline = (ApplicationCommandLine) Object.new (
                    typeof (ApplicationCommandLine),
                    "options", new Variant.parsed (options),
                    "platform-data", new Variant.parsed (platform_data)
                );
    stdout.printf ("# calling commandline with cmdline\n");
                // Invoke commandline again with required options
                application.command_line (cmdline);
            }

stdout.printf ("# about to iterate\n");
            iterate_context ();
stdout.printf ("# calling callback with cmdline\n");
            callback (cmdline);
stdout.printf ("# quit app\n");
            application.quit ();
            return 0;
        });

        if (application.run (null) != 0) {
            GLib.Test.fail ();
        }
    }

    private void action (string name, Variant? @value, ActivateCallback callback) {
        ulong oneshot = 0;
        setup ();
        oneshot = application.command_line.connect ((nill) => {
            application.disconnect (oneshot);
            application.command_line (nill);
            assert_true (application.has_action (name));
            application.activate_action (name, @value);
            iterate_context ();
            callback ();

            application.close ();

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
        // GLib.Test.add_func ("/application/cli/commandline", () => {
        //     cli ({ "io.elementary.terminal", "--commandline=true" }, (dict) => {
        //         assert_true ("commandline" in dict);
        //         unowned var commandline = dict.lookup_value ("commandline", null).get_bytestring ();
        //         assert_cmpstr (commandline, CompareOperator.EQ, "true");
        //     });

        //     cli ({ "io.elementary.terminal", "-x", "echo", "-e", "true\tfalse" }, (dict) => {
        //         assert_true ("commandline" in dict);
        //         unowned var commandline = dict.lookup_value ("commandline", null).get_bytestring ();
        //         assert_cmpstr (commandline, CompareOperator.EQ, "echo -e true\\tfalse");
        //     });

        //     cli ({ "io.elementary.terminal", "--commandline", "echo", "true" }, (dict) => {
        //         assert_true ("commandline" in dict);
        //         unowned var commandline = dict.lookup_value ("commandline", null).get_bytestring ();
        //         assert_cmpstr (commandline, CompareOperator.EQ, "echo true");
        //     });
        // });

        // GLib.Test.add_func ("/application/cli/working-directory", () => {
        //     unowned var working_directory = GLib.Test.get_dir (GLib.Test.FileType.DIST);
        //     var cwd = Environment.get_current_dir ();

        //     cli ({ "io.elementary.terminal", "-w", working_directory }, (dict) => {
        //         assert_false ("working-dir" in dict);
        //         var current_directory = Environment.get_current_dir ();
        //         assert_cmpstr (current_directory, CompareOperator.EQ, working_directory);
        //     });

        //     Environment.set_current_dir (cwd);
        // });

        // primary command line: first instance from terminal. any instance from dbus.
        GLib.Test.add_func ("/application/command-line/new-tab", () => {
            int default_tabs = 0;
            option (null, "@a{sv} {}", () => {
stdout.printf ("#null option callback\n");
                unowned var window = (MainWindow) application.active_window;
                assert_nonnull (window);
                default_tabs = (int) window.notebook.n_pages;
            });

//             option ("{'new-tab':<true>}", "@a{sv} {}", () => {
// stdout.printf ("new tab true callback\n");
//                 unowned var window = (MainWindow) application.active_window;
//                 assert_nonnull (window);
//                 var n_tabs = (int) window.notebook.n_pages;
//                 assert_cmpint (n_tabs - default_tabs, CompareOperator.EQ, 1);
//             });

//             option ("{'new-tab':<false>}", "@a{sv} {}", () => {
//                 unowned var window = (MainWindow) application.active_window;
//                 assert_nonnull (window);
//                 var n_tabs = (int) window.notebook.n_pages;
//                 assert_cmpint (n_tabs, CompareOperator.EQ, default_tabs);
//             });
        });

//         GLib.Test.add_func ("/application/command-line/new-window", () => {
//             option ("{'new-window':<true>}", "@a{sv} {}", () => {
// stdout.printf ("in callback\n");
//                 var n_windows = (int) application.get_windows ().length ();
// stdout.printf ("got n windows %i\n", n_windows);
//                 assert_cmpint (n_windows, CompareOperator.EQ, 2);
//             });

//             option ("{'new-window':<false>}", "@a{sv} {}", () => {
//                 var n_windows = (int) application.get_windows ().length ();
//                 assert_cmpint (n_windows, CompareOperator.EQ, 1);
//             });
//         });

        GLib.Test.add_func ("/application/command-line/execute", () => {
            int default_tabs = 0;
            option (null, "@a{sv} {}", () => {
stdout.printf ("#null option callback\n");
                unowned var window = (MainWindow) application.active_window;
                assert_nonnull (window);
                default_tabs = (int) window.notebook.n_pages;
            });

            // Execute 4 processes in separate tabs
            string[] processes = { "true", "echo test", "echo -e te\\tst", "false" };
            string options = "{'execute':<[b'%s']>}".printf (string.joinv ("',b'", processes));
            //valid
            option (options, "@a{sv} {}", () => {
                unowned var window = (MainWindow) application.active_window;
                assert_nonnull (window);
                var n_tabs = (int) window.notebook.n_pages;
                assert_cmpint (n_tabs, CompareOperator.EQ, default_tabs + 4);
            });

        //     // invalid
        //     option ("{'execute':<[b'',b'',b'']>}", "@a{sv} {}", () => {
        //         unowned var window = (MainWindow) application.active_window;
        //         assert_nonnull (window);
        //         var n_tabs = (int) window.notebook.n_pages;
        //         assert_cmpint (n_tabs, CompareOperator.EQ, 1);
        //     });
        });

        // //FIXME: cannot test the commandline option without a way to get the terminal command
        // GLib.Test.add_func ("/application/command-line/commandline", () => GLib.Test.skip ());

        // GLib.Test.add_func ("/application/command-line/platform-data/cwd", () => {
        //     unowned var working_directory = GLib.Test.get_dir (GLib.Test.FileType.DIST);

        //     option ("{'new-tab':<true>}", "{'cwd':<b'%s'>}".printf (working_directory), () => {
        //         unowned var window = (MainWindow) application.active_window;
        //         assert_nonnull (window);
        //         var terminal_directory = window.current_terminal.get_shell_location ();
        //         assert_cmpstr (terminal_directory, CompareOperator.EQ, working_directory);
        //     });
        // });

        // // actions
        // GLib.Test.add_func ("/application/action/new-window", () => {
        //     action ("new-window", null, () => {
        //         // include the extra window from terminal launching
        //         var n_windows = (int) application.get_windows ().length ();
        //         assert_cmpint (n_windows, CompareOperator.EQ, 2);
        //     });
        // });

        // GLib.Test.add_func ("/application/action/quit", () => {
        //     action ("quit", null, () => {
        //         assert_null (application.active_window);
        //     });
        // });

        return GLib.Test.run ();
    }
}

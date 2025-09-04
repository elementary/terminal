/*
 * Copyright 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

namespace Terminal.Test.ApplicationOptions {
    delegate void CommandLineCallback (Terminal.Application app);

    private Terminal.Application setup (string id) {
        var application = new Terminal.Application ("io.elementary.terminal.tests.application.options." + id);
        return application;
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

    private void option (string id, string options, string platform_data, CommandLineCallback callback) {
        ulong oneshot = 0;
        var application = setup (id);

        oneshot = application.command_line.connect ((nil) => {
            application.disconnect (oneshot);
            application.command_line (nil);

            var cmdline = (ApplicationCommandLine) Object.new (
                typeof (ApplicationCommandLine),
                "options", new Variant.parsed (options),
                "platform-data", new Variant.parsed (platform_data)
            );

            application.command_line (cmdline);
            iterate_context ();
            callback (application);
            application.quit ();
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

        // primary command line: first instance from terminal. any instance from dbus.
        GLib.Test.add_func ("/application/command-line/new-tab", () => {
            option ("new-tab-true", "{'new-tab':<true>}", "@a{sv} {}", (app) => {
                assert_nonnull (app);
                unowned var window = (MainWindow) app.active_window;
                assert_nonnull (window);
                var n_tabs = window.notebook.n_pages;
                assert_cmpint (n_tabs, CompareOperator.EQ, 2);
            });

            option ("new-tab-false", "{'new-tab':<false>}", "@a{sv} {}", (app) => {
                assert_nonnull (app);
                unowned var window = (MainWindow) app.active_window;
                assert_nonnull (window);

                var n_tabs = window.notebook.n_pages;
                assert_cmpint (n_tabs, CompareOperator.EQ, 1);
            });
        });

        GLib.Test.add_func ("/application/command-line/new-window", () => {
            option ("new-window-true", "{'new-window':<true>}", "@a{sv} {}", (app) => {
                var n_windows = (int) app.get_windows ().length ();
                assert_cmpint (n_windows, CompareOperator.EQ, 2);
            });

            option ("new-window-false", "{'new-window':<false>}", "@a{sv} {}", (app) => {
                var n_windows = (int) app.get_windows ().length ();
                assert_cmpint (n_windows, CompareOperator.EQ, 1);
            });
        });

        GLib.Test.add_func ("/application/command-line/execute", () => {
            string[] execute = { "true", "echo test", "echo -e te\\tst", "false" };

            //valid
            option ("execute-1", "{'execute':<[b'%s']>}".printf (string.joinv ("',b'", execute)), "@a{sv} {}", (app) => {
                unowned var window = (MainWindow) app.active_window;
                assert_nonnull (window);
                var n_tabs = window.notebook.n_pages;
                assert_cmpint (n_tabs, CompareOperator.EQ, 5); // include the guaranted extra tab
            });

            // invalid
            option ("execute-2", "{'execute':<[b'',b'',b'']>}", "@a{sv} {}", (app) => {
                unowned var window = (MainWindow) app.active_window;
                assert_nonnull (window);
                var n_tabs = window.notebook.n_pages;
                assert_cmpint (n_tabs, CompareOperator.EQ, 1);
            });
        });

        // //FIXME: cannot test the `--commandline=` option without a way to get the terminal command
        GLib.Test.add_func ("/application/command-line/commandline", () => GLib.Test.skip ());

        GLib.Test.add_func ("/application/command-line/platform-data/cwd", () => {
            unowned var working_directory = GLib.Test.get_dir (GLib.Test.FileType.DIST);

            option ("cwd", "{'new-tab':<true>}", "{'cwd':<b'%s'>}".printf (working_directory), (app) => {
                unowned var window = (MainWindow) app.active_window;
                assert_nonnull (window);
                var terminal_directory = window.current_terminal.get_shell_location ();
                assert_cmpstr (terminal_directory, CompareOperator.EQ, working_directory);
            });
        });

        return GLib.Test.run ();
    }
}

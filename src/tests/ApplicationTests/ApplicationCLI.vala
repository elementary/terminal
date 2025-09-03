/*
 * Copyright 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

namespace Terminal.Test.ApplicationCLI {
    delegate void LocalOptionsCallback (VariantDict options);

    private Terminal.Application setup () {
        var application = new Terminal.Application () {
            application_id = "io.elementary.terminal.tests.application.cli"
        };

        return application;
    }

    private void cli (string[] args, LocalOptionsCallback callback) {
        var application = setup ();

        application.handle_local_options.connect_after ((dict) => {
            callback (dict);
            application.quit ();
            return 0;
        });

        if (application.run (args) != 0) {
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
            var working_directory = GLib.Test.get_dir (GLib.Test.FileType.DIST);
            var cwd = Environment.get_current_dir ();
            cli ({ "io.elementary.terminal", "-w", working_directory }, (dict) => {
                assert_false ("working-dir" in dict);
                var current_directory = Environment.get_current_dir ();
                assert_cmpstr (current_directory, CompareOperator.EQ, working_directory);
            });

            Environment.set_current_dir (cwd);
        });

        return GLib.Test.run ();
    }
}

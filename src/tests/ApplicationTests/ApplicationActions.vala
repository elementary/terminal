/*
 * Copyright 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

namespace Terminal.Test.ApplicationActions {
    delegate void ActivateCallback ();

    private Terminal.Application setup (string id) {
        var application = new Terminal.Application ("io.elementary.terminal.tests.application.actions." + id);
        return application;
    }

    private void iterate_context () {
    stdout.printf ("iterate context\n ");
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

    private void action (Terminal.Application application, string name, Variant? @value, ActivateCallback callback) {
        ulong oneshot = 0;
        oneshot = application.command_line.connect ((nill) => {
            application.disconnect (oneshot);
            application.command_line (nill);
            assert_true (application.has_action (name));
            stdout.printf ("activate %s\n", name);
            iterate_context (); // Ensure first shell has spawned
            application.activate_action (name, @value);
            iterate_context ();
            callback ();
            iterate_context ();
            Idle.add (() => {
                stdout.printf ("quitting in idle\n");
                application.quit ();
                return Source.REMOVE;
            });
            return 0;
        });

        if (application.run (null) != 0) {
            GLib.Test.fail ();
        }

        stdout.printf ("# action run finished\n");
    }

    public static int main (string[] args) {
        Intl.setlocale (LocaleCategory.ALL, "");

        GLib.Test.init (ref args);

        /* MainWindow always create a tab in home, make it the current dir
         * so that we don't create a extra tab during tests
         */
        Environment.set_current_dir (Environment.get_home_dir ());

        // actions
        GLib.Test.add_func ("/application/action/new-window", () => {
            var app = setup ("new-window");
            action (app, "new-window", null, () => {
                // include the extra window from terminal launching
                var n_windows = (int) app.get_windows ().length ();
                assert_cmpint (n_windows, CompareOperator.EQ, 2);
            });
        });

        // GLib.Test.add_func ("/application/action/quit", () => {
        //     var app = setup ("quit");
        //     bool has_shutdown = false;
        //     app.shutdown.connect (() => {
        //         stdout.printf ("app has shutdown\n");
        //         has_shutdown = true;
        //         return;
        //     });

        //     action (app, "quit", null, () => {
        //         stdout.printf ("quit callback\n");
        //         assert (true);
        //     });
        // });

        return GLib.Test.run ();
    }
}

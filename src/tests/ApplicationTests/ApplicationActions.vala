/*
 * Copyright 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

namespace Terminal.Test.ApplicationActions {
    delegate void ActivateCallback ();

    private Terminal.Application setup () {
        var application = new Terminal.Application () {
            application_id = "io.elementary.terminal.tests.application.applicationactions"
        };
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

    private void action (Terminal.Application application, string name, Variant? @value, ActivateCallback callback) {
        ulong oneshot = 0;
        oneshot = application.command_line.connect ((nill) => {
            application.disconnect (oneshot);
            application.command_line (nill);
            assert_true (application.has_action (name));
            iterate_context (); // Ensure first shell has spawned
            application.activate_action (name, @value);
            callback ();
            // For actions other than "quit" the callback must close the application
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

        // actions
        GLib.Test.add_func ("/application/action/new-window", () => {
            var app = setup ();
            action (app, "new-window", null, () => {
                // include the extra window from terminal launching
                var n_windows = (int) app.get_windows ().length ();
                assert_cmpint (n_windows, CompareOperator.EQ, 2);
                app.quit ();
            });
        });

        // GLib.Test.add_func ("/application/action/quit", () => {
        //     var app = setup ("quit");
        //     bool has_shutdown = false;
        //     app.shutdown.connect (() => {
        //         has_shutdown = true;
        //         return;
        //     });

        //     action (app, "quit", null, () => {
        //         // Wait for shutdown signal from action
        //         Idle.add (() => {
        //             // The app should already have been shutdown by the action
        //             assert (has_shutdown);
        //             return Source.REMOVE;
        //         });
        //     });
        // });

        return GLib.Test.run ();
    }
}

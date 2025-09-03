/*
 * Copyright 2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

namespace Terminal.Test.ApplicationActions {
    delegate void ActivateCallback (Terminal.Application app);

    private Terminal.Application setup () {
        var application = new Terminal.Application () {
            application_id = "io.elementary.terminal.tests.application"
        };

        application.shutdown.connect (() => {
            application.close ();
            application = null;
        });

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

    private void action (string name, Variant? @value, ActivateCallback callback) {
        ulong oneshot = 0;
        var application = setup ();
        oneshot = application.command_line.connect ((nill) => {
            application.disconnect (oneshot);
            application.command_line (nill);
            assert_true (application.has_action (name));
            application.activate_action (name, @value);
            iterate_context ();
            callback (application);

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

        // actions
        GLib.Test.add_func ("/application/action/new-window", () => {
            action ("new-window", null, (app) => {
                // include the extra window from terminal launching
                var n_windows = (int) app.get_windows ().length ();
                assert_cmpint (n_windows, CompareOperator.EQ, 2);
            });
        });

        GLib.Test.add_func ("/application/action/quit", () => {
            action ("quit", null, (app) => {
                assert_null (app.active_window);
            });
        });

        return GLib.Test.run ();
    }
}

/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2026 elementary, Inc. (https://elementary.io)
 */

namespace Terminal.Widgets.Policies {

    /**
     * IBusDeadKeysPolicy resets the TerminalWidget cursor manually.
     * 
     * Using ibus as input method and having ibus <v1.5.30 will result in a
     * stuck cursor for dead keys. This class manually resets the cursor state
     * by toggling the EventControllerFocus state. It is safe to keep this class
     * in the codebase even if the ibus version gets updated, since the policy
     * checks for the version before doing anything.
     * 
     * @param applies_result saves the result of applies method.
     * @param dead_key_waiting_for_commit will trigger a cursor reset on commit.
     */
    public class IBusDeadKeysPolicy : Object {
        private bool? applies_result = null;
        private bool dead_key_waiting_for_commit = false;

        private bool applies () {
            if (applies_result != null) {
                return applies_result;
            }

            string? im_method = Environment.get_variable ("GTK_IM_MODULE");

            if (im_method == null || im_method != "ibus") {
                applies_result = false;
                return false;
            }

            var ibus_ver = Utils.SemVer(
                IBus.MAJOR_VERSION,
                IBus.MINOR_VERSION,
                IBus.MICRO_VERSION
            );
            var ibus_patched_ver = Utils.SemVer(1, 5, 30);

            if (ibus_ver.is_greater_than_or_equals_to (ibus_patched_ver)) {
                applies_result = false;
                return false;
            }

            applies_result = true;
            return true;
        }

        public void check_dead_key (uint keyval) {
            if (!applies ()) {
                return;
            }

            if (is_dead_key (keyval)) {
                this.dead_key_waiting_for_commit = true;
            }
        } 

        public void reset_cursor_if_needed (Gtk.EventControllerFocus? focus_controller) {
            if (!applies () || focus_controller == null || !this.dead_key_waiting_for_commit) {
                return;
            }

            focus_controller.leave ();
            focus_controller.enter ();

            this.dead_key_waiting_for_commit = false;
        }

        private bool is_dead_key (uint keyval) {
            string? key_name = Gdk.keyval_name (keyval);
            return key_name != null && key_name.has_prefix ("dead_");
        }
    }
}

/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2026 elementary, Inc. (https://elementary.io)
 */

namespace Terminal.Widgets.Policies {
    public class IBusDeadKeysPolicy : Object {
        private bool? applies_result = null;
        private bool dead_key_waiting_for_commit = false;

        private bool applies () {
            if (applies_result != null) {
                return applies_result;
            }

            string? im_method = Environment.get_variable ("GTK_IM_MODULE");

            if (im_method != null && im_method == "ibus") {
                applies_result = true;
                return true;
            }

            applies_result = false;
            return false;
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

/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

private void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/valid", () => {
        string msg;

        // false positive for su
        assert (Terminal.Utils.is_safe_paste ("suspend", out msg));
    });

    Test.add_func ("/invalid", () => {
        string msg;

        // Elevated permissions
        assert (!Terminal.Utils.is_safe_paste ("doas pacman -Syu", out msg));
        assert (!Terminal.Utils.is_safe_paste ("pkexec visudo", out msg));
        assert (!Terminal.Utils.is_safe_paste ("run0 --nice=19 my-task-with-low-priority", out msg));
        assert (!Terminal.Utils.is_safe_paste ("su username", out msg));
        assert (!Terminal.Utils.is_safe_paste ("sudo apt autoremove", out msg));

        // Multi-line commands
        assert (!Terminal.Utils.is_safe_paste ("\n", out msg));
        assert (!Terminal.Utils.is_safe_paste ("&", out msg));
        assert (!Terminal.Utils.is_safe_paste ("|", out msg));
        assert (!Terminal.Utils.is_safe_paste (";", out msg));
    });

    Test.run ();
}

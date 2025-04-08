/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

private void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/valid", () => {
        string[]? msg_array;

        // false positive for su
        assert (Terminal.Utils.is_safe_paste ("suspend", out msg_array));

        // false positive for -y
        assert (Terminal.Utils.is_safe_paste ("--yellow", out msg_array));
    });

    Test.add_func ("/invalid", () => {
        string[]? msg_array;

        // Elevated permissions
        assert (!Terminal.Utils.is_safe_paste ("doas pacman -Syu", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("pkexec visudo", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("run0 --nice=19 my-task-with-low-priority", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("su username", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("sudo apt autoremove", out msg_array));

        // Multi-line commands
        assert (!Terminal.Utils.is_safe_paste ("\n", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("&", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("|", out msg_array));
        assert (!Terminal.Utils.is_safe_paste (";", out msg_array));

        // Skip commands
        assert (!Terminal.Utils.is_safe_paste ("apt install fuse -y", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("apt remove --yes pantheon", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("apt dist-upgrade --assume-yes", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("rm -r --interactive=never /", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("rm -f /", out msg_array));
        assert (!Terminal.Utils.is_safe_paste ("rm --force /", out msg_array));

        // Multiple warnings
        var multiple_warning_command = """
        sudo apt autoremove
        sudo apt install fuse -y""";

        assert (!Terminal.Utils.is_safe_paste (multiple_warning_command, out msg_array));
        assert (msg_array.length == 3);
    });

    Test.run ();
}

/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022-2025 elementary, Inc. (https://elementary.io)
 */

public class Terminal.Dialogs.ShellPreferences : Granite.Dialog {
    private Gtk.Entry shell_entry;

    public ShellPreferences (Gtk.Window? parent) {
        Object (transient_for: parent);
    }

    construct {
        hide_on_close = true;
        resizable = false;
        title = _("Shell Preferences");

        var shell_label = new Gtk.Label (_("Custom shell command")) {
            halign = END
        };

        shell_entry = new Gtk.Entry () {
            placeholder_text = _("Default shell"),
            tooltip_text = _("Use a custom command as a shell"),
            hexpand = true,
            width_chars = 30,
            activates_default = true
        };

        var reset_button = new Gtk.Button.from_icon_name ("edit-clear-symbolic") {
            tooltip_text = _("Reset to default OS shell"),
            valign = CENTER
        };

        reset_button.clicked.connect (() => {
            shell_entry.text = "";
            shell_entry.grab_focus ();
        });

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12
        };


        grid.attach (shell_label, 0, 0);
        grid.attach (shell_entry, 1, 0);
        grid.attach (reset_button, 2, 0);

        get_content_area ().append (grid);



        var cancel_button = (Gtk.Button) add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        cancel_button.clicked.connect (() => close ());

        var apply_button = (Gtk.Button) add_button (_("Apply"), Gtk.ResponseType.APPLY);
        apply_button.add_css_class (Granite.CssClass.SUGGESTED);
        apply_button.clicked.connect (() => {
            var shell_str = shell_entry.text.strip ();
            if (shell_str.length < 1) {
                Application.settings.reset ("shell");
            } else {
                Application.settings.set_string ("shell", shell_entry.text.strip ());
            }
            close ();
        });


        set_default_widget (apply_button);

        reload_entry ();

        show.connect (reload_entry);
    }

    private void reload_entry () {
        shell_entry.text = Application.settings.get_string ("shell");
    }
}

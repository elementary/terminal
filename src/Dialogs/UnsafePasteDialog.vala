/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 */

public class Terminal.UnsafePasteDialog : Granite.MessageDialog {
    public string text_to_paste { get; construct; }
    public UnsafePasteDialog (MainWindow parent, string title_text, string text_to_paste) {
        Object (
            transient_for: parent,
            primary_text: title_text,
            text_to_paste: text_to_paste,
            buttons: Gtk.ButtonsType.NONE
        );
    }

    construct {
        image_icon = new ThemedIcon ("dialog-warning");

        secondary_text =
            _("Copying commands into Terminal can be dangerous. Be sure you understand what each part of the pasted text does before continuing.");
        show_error_details (text_to_paste);

        var show_protection_warnings = new Gtk.CheckButton.with_label (_("Show paste protection warnings"));

        custom_bin.add (show_protection_warnings);
        custom_bin.show_all ();

        add_button (_("Don't Paste"), Gtk.ResponseType.CANCEL);

        var ignore_button = (Gtk.Button) add_button (_("Paste Anyway"), Gtk.ResponseType.ACCEPT);
        ignore_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        set_default_response (Gtk.ResponseType.CANCEL);

        Terminal.Application.settings.bind (
            "unsafe-paste-alert", show_protection_warnings, "active", SettingsBindFlags.DEFAULT
        );
    }
}

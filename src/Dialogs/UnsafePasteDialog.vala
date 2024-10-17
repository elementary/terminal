/*
 * Copyright 2011-2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */


public class Terminal.UnsafePasteDialog : Granite.MessageDialog {
    public UnsafePasteDialog (MainWindow parent, string title_text, string text_to_paste) {
        Object (
            buttons: Gtk.ButtonsType.NONE,
            primary_text: title_text,
            transient_for: parent
        );

        show_error_details (text_to_paste);
    }

    construct {
        image_icon = new ThemedIcon ("dialog-warning");

        secondary_text =
            _("Copying commands into Terminal can be dangerous. Be sure you understand what each part of the pasted text does before continuing.");

        var show_protection_warnings = new Gtk.CheckButton.with_label (_("Show paste protection warnings"));

        custom_bin.append (show_protection_warnings);

        add_button (_("Don't Paste"), Gtk.ResponseType.CANCEL);

        var ignore_button = (Gtk.Button) add_button (_("Paste Anyway"), Gtk.ResponseType.ACCEPT);
        ignore_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
        ignore_button.clicked.connect (on_ignore);

        set_default_response (Gtk.ResponseType.CANCEL);

        Terminal.Application.settings.bind (
            "unsafe-paste-alert", show_protection_warnings, "active", SettingsBindFlags.DEFAULT
        );
    }

    private void on_ignore () {
        var terminal_window = get_transient_for ();
        if (terminal_window is MainWindow) {
            ((MainWindow) terminal_window).unsafe_ignored = true;
        }
    }
}

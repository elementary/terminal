/*
 * Copyright (c) 2011-2024 elementary LLC. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

public class Terminal.ForegroundProcessDialog : Granite.MessageDialog {
    public string button_label { get; construct; }

    public ForegroundProcessDialog (
        MainWindow parent,
        string primary_text,
        string button_label
    ) {
        Object (
            transient_for: parent,
            primary_text: primary_text,
            button_label: button_label,
            buttons: Gtk.ButtonsType.CANCEL
        );
    }

    construct {
        secondary_text = _("There is an active process on this tab. If you continue, the process will end.");
        image_icon = new ThemedIcon ("dialog-warning");

        var close_button = add_button (button_label, Gtk.ResponseType.ACCEPT);
        close_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }
}

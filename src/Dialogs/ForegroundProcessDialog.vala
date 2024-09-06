/*
 * Copyright (c) 2011-2024 elementary LLC. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

public class Terminal.ForegroundProcessDialog : Granite.MessageDialog {
    public string button_label { get; construct; }

    public ForegroundProcessDialog (MainWindow parent) {
        Object (
            transient_for: parent,
            primary_text: _("Are you sure you want to close this tab?"),
            secondary_text:
                _("There is an active process on this tab.") + " " +
                _("If you close it, the process will end."),
            buttons: Gtk.ButtonsType.CANCEL,
            button_label: _("Close Tab")
        );
    }

    public ForegroundProcessDialog.before_close (MainWindow parent) {
        Object (
            transient_for: parent,
            primary_text: _("Are you sure you want to quit Terminal?"),
            secondary_text:
                _("There is an active process on this terminal.") + " " +
                _("If you quit Terminal, the process will end."),
            buttons: Gtk.ButtonsType.CANCEL,
            button_label: _("Quit Terminal")
        );
    }

    public ForegroundProcessDialog.before_tab_reload (MainWindow parent) {
        Object (
            transient_for: parent,
            primary_text: _("Are you sure you want to reload this tab?"),
            secondary_text:
                _("There is an active process on this tab. If you reload it, the process will end."),
            buttons: Gtk.ButtonsType.CANCEL,
            button_label: _("Reload Tab")
        );
    }

    construct {
        image_icon = new ThemedIcon ("dialog-warning");

        var close_button = add_button (button_label, Gtk.ResponseType.ACCEPT);
        close_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }
}

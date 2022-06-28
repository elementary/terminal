// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
* Copyright (c) 2011-2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3 as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
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
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }
}

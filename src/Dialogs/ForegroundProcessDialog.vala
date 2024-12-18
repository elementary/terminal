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
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }
}

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

public class PantheonTerminal.ForegroundProcessDialog : Gtk.Dialog {
    public string button_label { get; construct; }
    public string primary_label { get; construct; }
    public string secondary_label { get; construct; }

    public ForegroundProcessDialog (PantheonTerminalWindow parent) {
        Object (
            border_width: 5,
            deletable: false,
            resizable: false,
            transient_for: parent,
            primary_label: _("Are you sure you want to close this tab?"),
            secondary_label:
                _("There is an active process on this tab.") + " " +
                _("If you close it, the process will end."),
            button_label: _("Close Tab")
        );
    }

    public ForegroundProcessDialog.before_close (PantheonTerminalWindow parent) {
        Object (
            border_width: 5,
            deletable: false,
            resizable: false,
            transient_for: parent,
            primary_label: _("Are you sure you want to quit Terminal?"),
            secondary_label:
                _("There is an active process on this terminal.") + " " +
                _("If you quit Terminal, the process will end."),
            button_label: _("Quit Terminal")
        );
    }

    construct {
        var warning_image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
        warning_image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (primary_label);
        primary_label.max_width_chars = 50;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class ("primary");

        var secondary_label = new Gtk.Label (secondary_label);
        secondary_label.margin_bottom = 12;
        secondary_label.max_width_chars = 50;
        secondary_label.wrap = true;
        secondary_label.xalign = 0;

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 12;
        grid.margin = 5;
        grid.margin_top = 0;
        grid.attach (warning_image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0, 1, 1);
        grid.attach (secondary_label, 1, 1, 1, 1);
        grid.show_all ();

        get_content_area ().add (grid);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var close_button = new Gtk.Button.with_label (button_label);
        close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        add_action_widget (cancel_button, 0);
        add_action_widget (close_button, 1);
        get_action_area ().show_all ();
    }
}

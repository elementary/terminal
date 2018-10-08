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

public class PantheonTerminal.UnsafePasteDialog : Gtk.Dialog {

    public UnsafePasteDialog (PantheonTerminalWindow parent) {
        Object (
            border_width: 5,
            deletable: false,
            resizable: false,
            transient_for: parent
        );
    }

    construct {
        var warning_image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
        warning_image.valign = Gtk.Align.START;

        var primary_label = new Gtk.Label (_("This command is asking for Administrative access to your computer"));
        primary_label.max_width_chars = 50;
        primary_label.wrap = true;
        primary_label.xalign = 0;
        primary_label.get_style_context ().add_class ("primary");

        var secondary_label = new Gtk.Label (
            _("Copying commands into the Terminal can be dangerous.") + "\n" +
            _("Be sure you understand what each part of this command does.")
        );
        secondary_label.xalign = 0;

        var do_not_show_check = new Gtk.CheckButton.with_label (_("Show paste protection warning"));
        do_not_show_check.margin_bottom = 12;
        do_not_show_check.margin_top = 12;
        settings.schema.bind ("unsafe-paste-alert", do_not_show_check, "active", SettingsBindFlags.DEFAULT | SettingsBindFlags.INVERT_BOOLEAN);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 12;
        grid.margin = 5;
        grid.margin_top = 0;
        grid.attach (warning_image, 0, 0, 1, 2);
        grid.attach (primary_label, 1, 0, 1, 1);
        grid.attach (secondary_label, 1, 1, 1, 1);
        grid.attach (do_not_show_check, 1, 2, 1, 1);

        ((Gtk.Box) get_content_area ()).add (grid);

        var cancel_button = new Gtk.Button.with_label (_("Don't Paste"));

        var ignore_button = new Gtk.Button.with_label (_("Paste Anyway"));
        ignore_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        ignore_button.clicked.connect (on_ignore);

        add_action_widget (cancel_button, 1);
        add_action_widget (ignore_button, 0);

        show_all ();
    }

    private void on_ignore () {
        var terminal_window = get_transient_for ();
        if (terminal_window is PantheonTerminalWindow) {
            (terminal_window as PantheonTerminalWindow).unsafe_ignored = true;
        }
    }
}

/*
* Copyright 2011-2018 elementary, Inc. (https://elementary.io)
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

public class Terminal.BlockMultilinePasteDialog : Granite.MessageDialog {
    public BlockMultilinePasteDialog (MainWindow parent) {
        Object (
            buttons: Gtk.ButtonsType.NONE,
            transient_for: parent
        );
    }

    construct {
        image_icon = new ThemedIcon ("dialog-warning");
        primary_text = _("Multiline Paste Blocked");

        secondary_text =
            _("The text you want to paste may be treated as command and could unintentionally be executed.") + " " +
            _("Be sure your paste doesn't contain newline characters.");

        var show_protection_warnings = new Gtk.CheckButton.with_label (_("Show paste protection warnings"));

        custom_bin.add (show_protection_warnings);
        custom_bin.show_all ();

        add_button (_("Don't Paste"), 1);

        var ignore_button = (Gtk.Button) add_button (_("Paste Anyway"), 0);
        ignore_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

        Terminal.Application.settings.bind (
            "block-multiline-paste-alert", show_protection_warnings, "active", SettingsBindFlags.DEFAULT
        );
    }

}

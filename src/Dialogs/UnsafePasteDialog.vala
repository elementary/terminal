/*
* Copyright 2011-2021 elementary, Inc. (https://elementary.io)
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

        custom_bin.add (show_protection_warnings);
        custom_bin.show_all ();

        add_button (_("Don't Paste"), Gtk.ResponseType.CANCEL);

        var ignore_button = (Gtk.Button) add_button (_("Paste Anyway"), Gtk.ResponseType.ACCEPT);
        ignore_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
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

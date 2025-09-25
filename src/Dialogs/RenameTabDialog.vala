/*
* Copyright 2025 elementary, Inc. (https://elementary.io)
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

public class Terminal.RenameTabDialog : Granite.MessageDialog {
    private Gtk.Entry entry;
    public string? custom_label {
        get {
            return entry != null ? entry.text : null;
        }

        set {
            if (entry == null) {
                return;
            }
            if (value == null || value == "") {
                entry.text = "";
            } else {
                entry.text = value;
            }
        }
    }
    public RenameTabDialog (MainWindow parent, string? initial_text) {
        Object (
            transient_for: parent
        );

        custom_label = initial_text;
    }

    construct {
        primary_text = _("Set a short custom label for this tab");
        secondary_text = _("This label will not change until the tab is renamed or closed");

        var apply_button = add_button (_("Rename tab"), Gtk.ResponseType.APPLY);
        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        // Safe to apply by default as it is reversible
        set_default_response (Gtk.ResponseType.APPLY);

        entry = new Gtk.Entry () {
            placeholder_text = _("Enter custom tab label"),
            margin_top = 24,
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER,
            max_length = 20
        };

        custom_bin.add (entry);
        custom_bin.show_all ();
    }
}

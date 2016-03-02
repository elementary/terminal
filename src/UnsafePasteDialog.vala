// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2015 Pantheon Terminal Developers
    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU Lesser General Public License version 3, as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranties of
    MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
    PURPOSE.  See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/>

    END LICENSE
 ***/

namespace PantheonTerminal {

    public class UnsafePasteDialog : Gtk.MessageDialog {

        public UnsafePasteDialog (PantheonTerminalWindow parent) {
            set_transient_for (parent);

            /* get rid of the close button */
            deletable = false;

            use_markup = true;
            set_markup ("<span weight='bold' size='larger'>" +
                        _("This command is asking for Administrative access to your computer") + "</span>\n\n" +
                        _("Copying commands into the Terminal can be dangerous.") + "\n" +
                        _("Be sure you understand what each part of this command does."));

            message_area.set_margin_left (0);
            message_area.set_margin_right (0);
            var cancel_button = new Gtk.Button.with_label (_("Don't Paste"));
            cancel_button.show ();

            var ignore_button = new Gtk.Button.with_label (_("Paste Anyway"));
            ignore_button.get_style_context ().add_class ("destructive-action");
            ignore_button.show ();
            ignore_button.clicked.connect (on_ignore);

            var warning_image = new Gtk.Image.from_icon_name ("dialog-warning",
                                                              Gtk.IconSize.DIALOG);

            add_action_widget (cancel_button, 1);
            add_action_widget (ignore_button, 0);

            set_image (warning_image);
            warning_image.show ();
        }

        private void on_ignore () {
            var terminal_window = get_transient_for ();
            if (terminal_window is PantheonTerminalWindow) {
                (terminal_window as PantheonTerminalWindow).unsafe_ignored = true;
            }
        }

    }
}

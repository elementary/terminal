// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2014 Pantheon Terminal Developers
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

    public class ForegroundProcessDialog : Gtk.MessageDialog {

        public ForegroundProcessDialog () {
            /* get rid of the close button */
            deletable = false;
            use_markup = true;
            set_markup ("<span weight='bold' size='larger'>" +
                      _("Are you sure you want to close this tab?") + "</span>\n\n" +
                      _("There is an active process on this tab.")+"\n"+
                      _("If you close it, the process will end."));
            message_area.set_margin_left (0);
            message_area.set_margin_right (0);

            var button = new Gtk.Button.with_label (_("Cancel"));
            button.show ();
            add_action_widget (button, 0);

            button = new Gtk.Button.with_label (_("Close Tab"));
            button.show ();
            add_action_widget (button, 1);

            var warning_image = new Gtk.Image.from_icon_name ("dialog-warning",
                                                              Gtk.IconSize.DIALOG);
            set_image (warning_image);
            warning_image.show ();
        }

        public ForegroundProcessDialog.before_close () {
            /* get rid of the close button */
            deletable = false;
            use_markup = true;
            set_markup ("<span weight='bold' size='larger'>" +
                      _("Are you sure you want to quit Terminal?") + "</span>\n\n" +
                      _("There is an active process on this terminal.")+"\n"+
                      _("If you quit Terminal, the process will end."));

            var button = new Gtk.Button.with_label (_("Cancel"));
            button.show ();
            add_action_widget (button, 0);

            button = new Gtk.Button.with_label (_("Quit Terminal"));
            button.show ();
            add_action_widget (button, 1);

            var warning_image = new Gtk.Image.from_icon_name ("dialog-warning",
                                                              Gtk.IconSize.DIALOG);
            set_image (warning_image);
            warning_image.show ();
        }
    }
}

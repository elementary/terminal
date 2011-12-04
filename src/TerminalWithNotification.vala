// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011 Adrien Plazas <kekun.plazas@laposte.net>
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

/* TODO
 * Check modifiers keys' state at the creation of the object to avoid bugs such as ^T on Ctrl+Maj+T
 */

using Gtk;
using Gdk;
using Vte;
using Pango;
//~ using Notify;

using Resources;

namespace PantheonTerminal
{
    public class TerminalWithNotification : Terminal
    {
        public signal void task_over ();
        public signal void preferences ();
        public signal void about ();

        private Gtk.Window parent_window;
        public Adjustment adjustment; 

        long last_row_count = 0;
        long last_column_count = 0;

        // Control and Shift keys
        bool ctrlL = false;
        bool ctrlR = false;
        bool shiftL = false;
        bool shiftR = false;

        public TerminalWithNotification (Gtk.Window parent_window)
        {
            this.parent_window = parent_window;

            set_size_request (320, 200);
            window_title_changed.connect (check_for_notification);

            // Set menu
            var menu = new Menu();

            var copy_menuitem = new MenuItem.with_label ("Copy");
            var paste_menuitem = new MenuItem.with_label ("Paste");
            var preferences_menuitem = new MenuItem.with_label ("Preferences");
            var about_menuitem = new MenuItem.with_label ("About");

            menu.append (copy_menuitem);
            menu.append (paste_menuitem);
            menu.append (new MenuItem());
            menu.append (preferences_menuitem);
            menu.append (about_menuitem);
            menu.show_all ();

            copy_menuitem.activate.connect(() => { copy_clipboard(); });
            paste_menuitem.activate.connect(() => { paste_clipboard(); });
            preferences_menuitem.activate.connect(() => { preferences(); });
            about_menuitem.activate.connect(() => { about(); });

            // Pop menu up
            button_press_event.connect((event) => {
                if (event.button == 3) {
                    menu.select_first (true);
                    menu.popup (null, null, null, event.button, event.time);
                }
                return false;
            });
        }

        public override bool key_press_event(EventKey event)
        {
            string key = Gdk.keyval_name(event.keyval);
            if (key == "Control_L")
                ctrlL = true;
            else if (key == "Control_R")
                ctrlR = true;
            else if (key == "Shift_L")
                shiftL = true;
            else if (key == "Shift_R")
                shiftR = true;
            //else if (key == "Tab")
            //    grab_focus();
            else if ((ctrlL || ctrlR) && (shiftL || shiftR))
            {
                if (key == "a" || key == "A")
                    select_all();
                else if (key == "c" || key == "C")
                    copy_clipboard();
                else if (key == "v" || key == "V")
                    paste_clipboard();
                else if (key == "n" || key == "N") {
                    new PantheonTerminal ({});
                    Gtk.main ();
                }
                else
                    return false;
            }
            else
                base.key_press_event(event);

            return false;
        }

        public override bool key_release_event(EventKey event)
        {
            string key = Gdk.keyval_name(event.keyval);
            if (key == "Control_L")
                ctrlL = false;
            else if (key == "Control_R")
                ctrlR = false;
            else if (key == "Shift_L")
                shiftL = false;
            else if (key == "Shift_R")
                shiftR = false;
            else
                base.key_release_event(event);

            return false;
        }

        private void check_for_notification()
        {
            /* Curently I use this trick to know if a task is over, the drawnback is
             * that when the window is resized and a notification should be received,
             * the user will not be notified.
             */

            if (get_row_count() == last_row_count && get_column_count() == last_column_count)
                task_over();

            last_row_count = get_row_count();
            last_column_count = get_column_count();
        }
    }
}

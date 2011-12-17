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

using Gtk;
using Gdk;
using Vte;

namespace PantheonTerminal {

    public class TerminalWithNotification : Terminal {

        public signal void task_over ();
        public signal void preferences ();
        public signal void about ();

        private Menu menu;
        private MenuItem copy_menuitem;
        private MenuItem paste_menuitem;
        private MenuItem select_all_menuitem;
        private MenuItem preferences_menuitem;
        private MenuItem about_menuitem;

        private PantheonTerminalWindow parent_window;

        long last_row_count = 0;
        long last_column_count = 0;

        public TerminalWithNotification (PantheonTerminalWindow parent_window) {

            this.parent_window = parent_window;

            set_size_request (320, 200);
            window_title_changed.connect (check_for_notification);

            apply_settings ();
            setup_ui ();
            connect_signals ();
        }

        private void apply_settings () {
            scrollback_lines = (uint) settings.scrollback_lines;
        }

        private void setup_ui () {

            /* Set up the menu */
            menu = new Menu();
            copy_menuitem = parent_window.main_actions.get_action ("Copy").create_menu_item () as Gtk.MenuItem;
            paste_menuitem = parent_window.main_actions.get_action ("Paste").create_menu_item () as Gtk.MenuItem;
            select_all_menuitem = parent_window.main_actions.get_action ("Select All").create_menu_item () as Gtk.MenuItem;
            preferences_menuitem = parent_window.main_actions.get_action ("Preferences").create_menu_item () as Gtk.MenuItem;
            about_menuitem = new MenuItem.with_label (_("About"));

            menu.append (copy_menuitem);
            menu.append (paste_menuitem);
            menu.append (new MenuItem ());
            menu.append (select_all_menuitem);
            menu.append (new MenuItem ());
            menu.append (preferences_menuitem);
            menu.append (about_menuitem);
            menu.show_all ();
        }

        private void connect_signals () {

            about_menuitem.activate.connect (() => { this.parent_window.app.show_about (parent_window); });

            /* Pop menu up */
            button_press_event.connect ((event) => {
                if (event.button == 3) {
                    menu.select_first (true);
                    menu.popup (null, null, null, event.button, event.time);
                }
                return false;
            });
        }

        private void check_for_notification() {

            /* Curently I use this trick to know if a task is over, the drawback is
             * that when the window is resized and a notification should be received,
             * the user will not be notified.
             */

            if (get_row_count() == last_row_count && get_column_count() == last_column_count) {
                if (!parent_window.is_active) task_over ();
            }

            last_row_count = get_row_count();
            last_column_count = get_column_count();
        }
    }
}

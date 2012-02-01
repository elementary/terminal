// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011-2012 Adrien Plazas <kekun.plazas@laposte.net>
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

        private Menu menu;
        private MenuItem copy_menuitem;
        private MenuItem paste_menuitem;
        private MenuItem select_all_menuitem;
        private MenuItem find_menuitem;
        
        public SeparatorMenuItem separator;
        public MenuItem preferences_menuitem;
        public SeparatorMenuItem separator_;
        public MenuItem about_menuitem;

        public PantheonTerminalWindow parent_window;

        long last_row_count = 0;
        long last_column_count = 0;

        public TerminalWithNotification (PantheonTerminalWindow parent_window) {

            this.parent_window = parent_window;

            set_size_request (320, 200);
            window_title_changed.connect (check_for_notification);

            on_selection_changed ();
            setup_ui ();
            connect_signals ();
            restore_settings ();
            settings.changed.connect (restore_settings);
        }

        private void setup_ui () {

            /* Set up the menu */
            menu = new Menu ();
            copy_menuitem = parent_window.main_actions.get_action ("Copy").create_menu_item () as Gtk.MenuItem;
            paste_menuitem = parent_window.main_actions.get_action ("Paste").create_menu_item () as Gtk.MenuItem;
            select_all_menuitem = parent_window.main_actions.get_action ("Select All").create_menu_item () as Gtk.MenuItem;
            find_menuitem = parent_window.main_actions.get_action ("Search").create_menu_item () as Gtk.MenuItem;
            
            separator = new SeparatorMenuItem ();
            preferences_menuitem = parent_window.main_actions.get_action ("Preferences").create_menu_item () as Gtk.MenuItem;
            separator_ = new SeparatorMenuItem ();
            about_menuitem = parent_window.main_actions.get_action ("About").create_menu_item () as Gtk.MenuItem; 
            
            menu.append (copy_menuitem);
            menu.append (paste_menuitem);
            menu.append (new MenuItem ());
            menu.append (select_all_menuitem);
            menu.append (new MenuItem ());
            menu.append (find_menuitem);
            
            menu.append (separator);
            menu.append (preferences_menuitem);
            menu.append (separator_);
            menu.append (about_menuitem);
           
            menu.show_all ();
            
            if (!settings.show_toolbar) {
                separator.show ();
                preferences_menuitem.show ();
                separator_.show ();
                about_menuitem.show ();
            }
            
        }

        private void connect_signals () {

            /* Pop menu up */
            button_press_event.connect ((event) => {
                if (event.button == 3) {
                    menu.select_first (true);
                    menu.popup (null, null, null, event.button, event.time);
                }
                return false;
            });

            /* Change toolbar copy button sensitivity */
            selection_changed.connect (on_selection_changed);
        }

        private void check_for_notification() {

            /* Curently I use this trick to know if a task is over, the drawback is
             * that when the window is resized and a notification should be received,
             * the user will not be notified.
             */

            if (get_row_count () == last_row_count && get_column_count () == last_column_count) {
                if (!parent_window.is_active) task_over ();
            }

            last_row_count = get_row_count ();
            last_column_count = get_column_count ();
        }

        public void on_selection_changed () {
            parent_window.toolbar.copy_button.sensitive = get_has_selection ();
        }

        void restore_settings () {
            
            //settings.changed["scrollback-lines"].connect (() => {
            scrollback_lines = (uint) settings.scrollback_lines;
            //});

            //settings.changed["background-transparent"].connect (() => {
            background_transparent = settings.background_transparent;
            //});
            
            if (!settings.show_toolbar) {
                separator.show ();
                preferences_menuitem.show ();
                separator_.show ();
                about_menuitem.show ();
            }
            else {
                separator.hide ();
                preferences_menuitem.hide ();
                separator_.hide ();
                about_menuitem.hide ();
            }

        }

    }

} //Namespace

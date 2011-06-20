//  
//  Copyright (C) 2011 Adrien Plazas
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 
// 
//  Authors:
//      Adrien Plazas <kekun.plazas@laposte.net>
//  Artists:
//      Daniel Foré <daniel@elementaryos.org>
// 

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
        public signal void task_over();
        public signal void preferences();
        public signal void about();
        
        long last_row_count = 0;
        long last_column_count = 0;
        
        // Control keys
		bool ctrlL = false;
		bool ctrlR = false;
        bool shiftL = false;
        bool shiftR = false;
        
        public TerminalWithNotification()
        {
            set_size_request(320, 200);
            window_title_changed.connect(check_for_notification);
            
            // Set menu
            var menu = new Menu();
            
            var copy_menuitem = new MenuItem.with_label("Copy");
            var paste_menuitem = new MenuItem.with_label("Paste");
            var preferences_menuitem = new MenuItem.with_label("Preferences");
            var about_menuitem = new MenuItem.with_label("About");
            
            menu.append(copy_menuitem);
            menu.append(paste_menuitem);
            menu.append(new MenuItem());
            menu.append(preferences_menuitem);
            menu.append(about_menuitem);
            menu.show_all();
            
            copy_menuitem.activate.connect(() => { copy_clipboard(); });
            paste_menuitem.activate.connect(() => { paste_clipboard(); });
            preferences_menuitem.activate.connect(() => { preferences(); });
            about_menuitem.activate.connect(() => { about(); });
            
            key_press_event.connect(on_key_press_event);
            key_release_event.connect(on_key_release_event);
            
            // Pop menu up
            button_press_event.connect((event) => {
                if (event.button == 3) {
                    menu.select_first (true);
                    menu.popup (null, null, null, event.button, event.time);
                }
                return false;
            });
        }
        
        public bool on_key_press_event(EventKey event)
		{
            string key = Gdk.keyval_name(event.keyval);
			if (key == "Control_L")
			{ ctrlL = true; }
			if (key == "Control_R")
			{ ctrlR = true; }
            if (key == "Shift_L")
			{ shiftL = true; }
			if (key == "Shift_R")
			{ shiftR = true; }
			if ((key == "c" || key == "C") && (ctrlL || ctrlR) && (shiftL || shiftR))
			{ copy_clipboard(); }
			if ((key == "v" || key == "V") && (ctrlL || ctrlR) && (shiftL || shiftR))
			{ paste_clipboard(); }
            return false;
        }
        
        public bool on_key_release_event(EventKey event)
		{
            string key = Gdk.keyval_name(event.keyval);
			if (key == "Control_L")
			{ ctrlL = false; }
			if (key == "Control_R")
			{ ctrlR = false; }
            if (key == "Shift_L")
			{ shiftL = false; }
			if (key == "Shift_R")
			{ shiftR = false; }
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

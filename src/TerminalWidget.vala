// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011-2012 Mario Guerriero <mefrio.g@gmail.com>
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

using Vte;

namespace PantheonTerminal {

    public class TerminalWidget : Vte.Terminal {

        GLib.Pid child_pid;

        private PantheonTerminalWindow window;
        public TerminalTab tab;

        public TerminalWidget (Gtk.ActionGroup main_actions, Gtk.UIManager ui, PantheonTerminalWindow parent_window) {
            /* Set up the parents */
            this.window = parent_window;

            /* Create a pop menu */
            var menu = ui.get_widget ("ui/AppMenu") as Gtk.Menu;
            menu.show_all ();

            button_press_event.connect ((event) => {
                if (event.button == 3) {
                    menu.select_first (false);
                    menu.popup (null, null, null, event.button, event.time);
                }
                return false;
            });

            window_title_changed.connect ((event) => {
                if (this == window.current_terminal)
                    window.title = window_title;
                tab.set_text(window_title);
            });

            /* Connect to necessary signals */
            child_exited.connect (on_child_exited);

        }

        void on_child_exited () { }
        
        public void kill_ps () {           
            Posix.kill (this.child_pid, 9);
        }
        
        public void kill_ps_and_fg () {
            if (this.has_foreground_process()) 
                Posix.kill (this.get_foreground_pid (), 9);
        }

        public void active_shell (string dir = GLib.Environment.get_current_dir ()) {
            try {
                this.fork_command_full (Vte.PtyFlags.DEFAULT, dir,  { Vte.get_user_shell () }, null, SpawnFlags.SEARCH_PATH, null, out this.child_pid);
            } catch (Error e) {
                warning (e.message);
            }
        }

        public bool has_foreground_process () {
            if (this.get_foreground_pid() !=null)
                return true;
            else
                return false;
        }

        public int calculate_width (int column_count) {
            return (int) (this.get_char_width()) * column_count;
        }

        public int calculate_height (int row_count) {
            return (int) (this.get_char_height()) * row_count;
        }

        public int? get_foreground_pid () {
            int pty = this.pty_object.fd;
            int fgpid = Posix.tcgetpgrp(pty);            
            if (fgpid != this.child_pid && fgpid != -1)
                return fgpid;
            else
                return null;
        } 
        void drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data, uint info, uint time_) {
          print ("[DEBUG] Drag data received.\n");
        }

    }

}

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

// Vte.Terminal.match_check was not well defined in the gtk+-2.0 binding
// before Valac 0.17.2 (see: https://bugzilla.gnome.org/show_bug.cgi?id=676882)
private extern string? vte_terminal_match_check (Vte.Terminal terminal,
                                                    long col, long row,
                                                    out int tag);
namespace PantheonTerminal {

    public class TerminalWidget : Vte.Terminal {

        GLib.Pid child_pid;
        private PantheonTerminalWindow window;
        public Granite.Widgets.Tab tab;

        public TerminalWidget (Gtk.ActionGroup main_actions, Gtk.UIManager ui, PantheonTerminalWindow parent_window) {
            /* Set up the parents */
            this.window = parent_window;

            /* Create a pop menu */
            var menu = ui.get_widget ("ui/AppMenu") as Gtk.Menu;
            menu.show_all ();

            button_press_event.connect ((event) => {
                if (event.button == 1) {
                    string? uri = get_link ((long)event.x, (long)event.y);
                    if (uri != null) {
                        try {
                            Gtk.show_uri (null, (!)uri, Gtk.get_current_event_time());
                            return true;
                        } catch (GLib.Error error) {
                            warning ("Could Not Open link");
                        }
                    }
                }
                if (event.button == 3) {
                    menu.select_first (false);
                    menu.popup (null, null, null, event.button, event.time);
                }
                return false;
            });

            window_title_changed.connect ((event) => {
                if (this == window.current_terminal)
                    window.title = window_title;
                tab.label = window_title;
            });

            /* Connect to necessary signals */
            child_exited.connect (on_child_exited);

            Gtk.TargetEntry target = {"text/uri-list",0,0};
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL,{target},Gdk.DragAction.COPY);

            /*Make Links Clickable */
            this.clickable("""(https?|ftps?)://\S+""");

        }

        void on_child_exited () { }

        public void kill_ps () {
            Posix.kill (this.child_pid, 9);
        }

        public void kill_ps_and_fg () {
            int fg_pid;
            if (this.try_get_foreground_pid (out fg_pid))
                Posix.kill (fg_pid, 9);
            kill_ps ();
        }

        public void active_shell (string dir = GLib.Environment.get_current_dir ()) {
            try {
                this.fork_command_full (Vte.PtyFlags.DEFAULT, dir,  { Vte.get_user_shell () }, null, SpawnFlags.SEARCH_PATH, null, out this.child_pid);
            } catch (Error e) {
                warning (e.message);
            }
        }

        public bool try_get_foreground_pid (out int pid) {
            int pty = this.pty_object.fd;
            int fgpid = Posix.tcgetpgrp (pty);
            if (fgpid != this.child_pid && fgpid != -1) {
                pid = (int) fgpid;
                return true;
            }
            else {
                pid = -1;
                return false;
            }
        }

        public bool has_foreground_process () {
            return try_get_foreground_pid (null);
        }


        public int calculate_width (int column_count) {
            return (int) (this.get_char_width()) * column_count;
        }

        public int calculate_height (int row_count) {
            return (int) (this.get_char_height()) * row_count;
        }

        private void clickable (string str) {
            try {
                var regex = new GLib.Regex (str);
                int id = this.match_add_gregex (regex, 0);

                this.match_set_cursor_type (id, Gdk.CursorType.HAND2);
            } catch (GLib.RegexError error) {
                warning (error.message);
            }
        }

        private string? get_link (long x, long y) {
            long col = x / this.get_char_width ();
            long row = y / this.get_char_height ();
            int tag;

            // Vte.Terminal.match_check need a non-null tag instead of what is
            // written in the doc
            // (see: https://bugzilla.gnome.org/show_bug.cgi?id=676886)
            return vte_terminal_match_check (this, col, row, out tag);

        }
    }
}

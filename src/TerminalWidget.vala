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

        public PantheonTerminalApp app;

        GLib.Pid child_pid;
        private PantheonTerminalWindow window;
        public Granite.Widgets.Tab tab;
        public string? uri;

        public int default_size;
        public double zoom_factor = 1.0;

        static const string regex_string = """((https?|file|ftps?|irc|sftp|ldaps?|nfs|smb|rsync|ssh|rlogin|telnet|git|git\+ssh|bzr|bzr\+ssh|svn|svn\+ssh|hg|mailto|magnet):\/?)?(\~|\/\/?[\~\w\.\-]+)+\/?""";

        public TerminalWidget (Gtk.ActionGroup main_actions, Gtk.UIManager ui,
                               PantheonTerminalWindow parent_window) {

            /* Set up the parents */
            this.window = parent_window;
            app = parent_window.app;

            /* Load configuration */
            int opacity = settings.opacity * 65535;
            set_opacity ((uint16) (opacity / 100));

            Gdk.Color background_color;
            Gdk.Color.parse (settings.background, out background_color);

            Gdk.Color foreground_color;
            Gdk.Color.parse (settings.foreground, out foreground_color);

            string[] hex_palette = {"#000000", "#FF6C60", "#A8FF60", "#FFFFCC", "#96CBFE",
                                    "#FF73FE", "#C6C5FE", "#EEEEEE", "#000000", "#FF6C60",
                                    "#A8FF60", "#FFFFB6", "#96CBFE", "#FF73FE", "#C6C5FE",
                                    "#EEEEEE"};

            string current_string = "";
            int current_color = 0;
            for (var i = 0; i < settings.palette.length; i++) {
                if (settings.palette[i] == ':') {
                    hex_palette[current_color] = current_string;
                    current_string = "";
                    current_color++;
                } else {
                    current_string += settings.palette[i].to_string ();
                }
            }

            Gdk.Color[] palette = new Gdk.Color[16];

            for (int i = 0; i < hex_palette.length; i++) {
                Gdk.Color new_color;
                Gdk.Color.parse (hex_palette[i], out new_color);

                palette[i] = new_color;
            }

            set_colors (foreground_color, background_color, palette);

            Gdk.Color cursor_color;
            Gdk.Color.parse (settings.cursor_color, out cursor_color);
            set_color_cursor (cursor_color);

            /* Load encoding */
            if (settings.encoding != "")
                set_encoding (settings.encoding);

            /* Create a pop menu */
            var menu = ui.get_widget ("ui/AppMenu") as Gtk.Menu;
            menu.show_all ();

            button_press_event.connect ((event) => {
                uri = get_link ((long) event.x, (long) event.y);
                switch (event.button) {
                    case Gdk.BUTTON_PRIMARY:
                        if (uri != null) {
                            try {
                                Gtk.show_uri (null, (!) uri, Gtk.get_current_event_time ());
                                return true;
                            } catch (GLib.Error error) {
                                warning ("Could Not Open link");
                            }
                        }

                        return false;
                    case Gdk.BUTTON_SECONDARY :
                        if (uri != null) {
                            main_actions.get_action ("Copy").set_sensitive (true);
                        }

                        menu.select_first (false);
                        menu.popup (null, null, null, event.button, event.time);

                        return true;
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

            Gtk.TargetEntry target = {"text/uri-list", 0, 0};
            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, {target}, Gdk.DragAction.COPY);

            /* Make Links Clickable */
            this.drag_data_received.connect (drag_received);
            this.clickable(regex_string);
        }

        void on_child_exited () { }

        public void kill_ps () {
            //this.pty_object.close ();
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
                if (settings.shell == "")
                    this.fork_command_full (Vte.PtyFlags.DEFAULT, dir, { Vte.get_user_shell () },
                                            null, SpawnFlags.SEARCH_PATH, null, out this.child_pid);
                else
                    this.fork_command_full (Vte.PtyFlags.DEFAULT, dir, { settings.shell }, null,
                                            SpawnFlags.SEARCH_PATH, null, out this.child_pid);
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
            int width = (int) (this.get_char_width()) * column_count;
            return width;
        }

        public int calculate_height (int row_count) {
            int height = (int) (this.get_char_height()) * row_count;
            return height;
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
            return this.match_check (col, row, out tag);
        }

        public string get_shell_location () {
            int pid = (!) (this.child_pid);

            try {
                return GLib.FileUtils.read_link ("/proc/%d/cwd".printf (pid));
            } catch (GLib.FileError error) {
                warning ("An error occured while fetching the current dir of shell");
                return "";
            }
        }

        public void increment_size () {
            Pango.FontDescription current_font = this.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();
            if (current_font.get_size () > 60000) return;

            zoom_factor += 0.1;
            current_font.set_size ((int) Math.floor (default_size * zoom_factor));
            this.set_font (current_font);
        }

        public void decrement_size () {
            Pango.FontDescription current_font = this.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();
            if (current_font.get_size () < 2048) return;

            zoom_factor -= 0.1;
            current_font.set_size ((int) Math.ceil (default_size * zoom_factor));
            this.set_font (current_font);
        }

        public void set_default_font_size () {
            Pango.FontDescription current_font = this.get_font ();
            if (default_size == 0) default_size = current_font.get_size ();

            zoom_factor = 1.0;
            current_font.set_size (default_size);
            this.set_font (current_font);
        }

        public void drag_received (Gdk.DragContext context, int x, int y,
                                   Gtk.SelectionData selection_data, uint info, uint time_) {

            var uris = selection_data.get_uris ();
            string path;
            File file;
            for (var i = 0; i < uris.length; i++) {
                file = File.new_for_uri (uris[i]);
                if ((path = file.get_path ()) != null) {
                    print (path + "\n");
                    uris[i] = Shell.quote (path);
                }
            }

            string uris_s = string.joinv (" ", uris);
            this.feed_child (uris_s, uris_s.length);
        }
    }
}

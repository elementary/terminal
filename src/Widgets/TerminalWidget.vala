// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
* Copyright (c) 2011-2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3, as published by the Free Software Foundation.
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

namespace Terminal {

    public class TerminalWidget : Vte.Terminal {
        enum DropTargets {
            URILIST,
            STRING,
            TEXT
        }

        internal const string DEFAULT_LABEL = _("Terminal");
        public Terminal.Application app;
        public string terminal_id;
        static int terminal_id_counter = 0;
        private bool init_complete;
        public bool resized {get; set;}

        GLib.Pid child_pid;
        private MainWindow _window;

        public MainWindow window {
            get {
                return _window;
            }

            set {
                this._window = value;
                this.app = value.app;
                this.menu = value.menu;
                this.menu.show_all ();
            }
        }

        private Gtk.Menu menu;
        public Granite.Widgets.Tab tab;
        public string? uri;

        private string _tab_label;
        public string tab_label {
            get {
                return _tab_label;
            }

            set {
                if (value != null) {
                    _tab_label = value;
                    tab.label = tab_label;
                }
            }
        }

        public int default_size;

        const string SEND_PROCESS_FINISHED_BASH = "dbus-send --type=method_call --session --dest=io.elementary.terminal /io/elementary/terminal io.elementary.terminal.ProcessFinished string:$PANTHEON_TERMINAL_ID string:\"$(history 1 | cut -c 8-)\" int32:\$__bp_last_ret_value >/dev/null 2>&1";

        /* Following strings are used to build RegEx for matching URIs */
        const string USERCHARS = "-[:alnum:]";
        const string USERCHARS_CLASS = "[" + USERCHARS + "]";
        const string PASSCHARS_CLASS = "[-[:alnum:]\\Q,?;.:/!%$^*&~\"#'\\E]";
        const string HOSTCHARS_CLASS = "[-[:alnum:]]";
        const string HOST = HOSTCHARS_CLASS + "+(\\." + HOSTCHARS_CLASS + "+)*";
        const string PORT = "(?:\\:[[:digit:]]{1,5})?";
        const string PATHCHARS_CLASS = "[-[:alnum:]\\Q_$.+!*,;:@&=?/~#%\\E]";
        const string PATHTERM_CLASS = "[^\\Q]'.}>) \t\r\n,\"\\E]";
        const string SCHEME = """(?:news:|telnet:|nntp:|file:\/|https?:|ftps?:|sftp:|webcal:
                                 |irc:|sftp:|ldaps?:|nfs:|smb:|rsync:|ssh:|rlogin:|telnet:|git:
                                 |git\+ssh:|bzr:|bzr\+ssh:|svn:|svn\+ssh:|hg:|mailto:|magnet:)""";

        const string USERPASS = USERCHARS_CLASS + "+(?:" + PASSCHARS_CLASS + "+)?";
        const string URLPATH = "(?:(/" + PATHCHARS_CLASS + "+(?:[(]" + PATHCHARS_CLASS + "*[)])*" + PATHCHARS_CLASS + "*)*" + PATHTERM_CLASS + ")?";

        const string[] regex_strings = {
            SCHEME + "//(?:" + USERPASS + "\\@)?" + HOST + PORT + URLPATH,
            "(?:www|ftp)" + HOSTCHARS_CLASS + "*\\." + HOST + PORT + URLPATH,
            "(?:callto:|h323:|sip:)" + USERCHARS_CLASS + "[" + USERCHARS + ".]*(?:" + PORT + "/[a-z0-9]+)?\\@" + HOST,
            "(?:mailto:)?" + USERCHARS_CLASS + "[" + USERCHARS + ".]*\\@" + HOSTCHARS_CLASS + "+\\." + HOST,
            "(?:news:|man:|info:)[[:alnum:]\\Q^_{|}~!\"#$%&'()*+,./;:=?`\\E]+"
        };

        const double MIN_SCALE = 0.2;
        const double MAX_SCALE = 5.0;

        public bool child_has_exited {
            get;
            private set;
        }

        public bool killed {
            get;
            private set;
        }

        private long remembered_position; /* Only need to remember row at the moment */
        private long remembered_command_start_row = 0; /* Only need to remember row at the moment */
        private long remembered_command_end_row = 0; /* Only need to remember row at the moment */
        private Gdk.RGBA background_color = Gdk.RGBA ();
        private Gdk.RGBA cursor_color = Gdk.RGBA ();
        private Vte.CursorBlinkMode remembered_cursor_blink_mode;
        public bool last_key_was_return = true;

        public TerminalWidget (MainWindow parent_window) {
            pointer_autohide = true;

            terminal_id = "%i".printf (terminal_id_counter++);

            init_complete = false;

            restore_settings ();
            settings.changed.connect (restore_settings);

            window = parent_window;
            child_has_exited = false;
            killed = false;

            /* Connect to necessary signals */
            button_press_event.connect ((event) => {
                remembered_cursor_blink_mode = cursor_blink_mode;
                cursor_blink_mode = Vte.CursorBlinkMode.OFF;

                if (event.button == Gdk.BUTTON_PRIMARY && !has_foreground_process ()) {
                    long current_col, current_row, clicked_row, clicked_col;
                    get_cursor_position (out current_col, out current_row);
                    get_cell_clicked (event, out clicked_row, out clicked_col);
                    if (clicked_row < remembered_command_start_row) {
                        return Gdk.EVENT_STOP;
                    }

                    long delta_cells = clicked_col - current_col;
                    var clicked_symbol = get_text_range (clicked_row, clicked_col,
                                                         clicked_row, clicked_col,
                                                         null, null).get_char ();
                    if (clicked_symbol != 0U) {
                        delta_cells += (clicked_row - current_row) * get_column_count ();
                    } else {
                        return Gdk.EVENT_STOP;
                    }

                    /* Synthesise a cursor press - is there a better way? */
                    Gdk.EventKey key_event = (Gdk.EventKey)(new Gdk.Event (Gdk.EventType.KEY_PRESS));
                    key_event.send_event = 1;
                    /* Need to add a ref else crash on second key press - vapi error? */
                    key_event.window = (Gdk.Window)(this.get_window ().ref ());
                    key_event.keyval = delta_cells > 0U ? Gdk.Key.Right : Gdk.Key.Left;
                    key_event.is_modifier = 0;

                    set_color_cursor (background_color);
                    Idle.add (() => { /* wait for button press event to be processed */
                        /* Cursor will move as close as possible to pointer */
                        var n_events = (int) delta_cells.abs ();
                        for (int i = 0; i < n_events; i++) {
                            key_event.time = (uint32)(get_monotonic_time ());
                            key_press_event (key_event);
                        }

                        Gdk.threads_add_idle_full (GLib.Priority.LOW, () => {
                            set_color_cursor (cursor_color);
                            return Source.REMOVE;
                        });

                        return Source.REMOVE;
                    });
                } else if (event.button == Gdk.BUTTON_SECONDARY) {
                    uri = get_link (event);

                    if (uri != null) {
                        window.get_simple_action (MainWindow.ACTION_COPY).set_enabled (true);
                    }

                    menu.select_first (false);
                    menu.popup_at_pointer (event);

                    return Gdk.EVENT_PROPAGATE;
                } else if (event.button == Gdk.BUTTON_MIDDLE) {
                    return window.handle_primary_selection_copy_event ();
                }

                return Gdk.EVENT_STOP;
            });

            button_release_event.connect ((event) => {
                cursor_blink_mode = remembered_cursor_blink_mode;

                if (event.button == Gdk.BUTTON_PRIMARY) {
                    uri = get_link (event);

                    if (uri != null && ! get_has_selection ()) {
                        try {
                            Gtk.show_uri (null, uri, Gtk.get_current_event_time ());
                        } catch (GLib.Error error) {
                            warning ("Could Not Open link");
                        }
                    }
                }

                return false;
            });

            selection_changed.connect (() => {
                window.get_simple_action (MainWindow.ACTION_COPY).set_enabled (get_has_selection ());
            });

            size_allocate.connect (() => {
                resized = true;
            });

            child_exited.connect (on_child_exited);

            /* target entries specify what kind of data the terminal widget accepts */
            Gtk.TargetEntry uri_entry = { "text/uri-list", Gtk.TargetFlags.OTHER_APP, DropTargets.URILIST };
            Gtk.TargetEntry string_entry = { "STRING", Gtk.TargetFlags.OTHER_APP, DropTargets.STRING };
            Gtk.TargetEntry text_entry = { "text/plain", Gtk.TargetFlags.OTHER_APP, DropTargets.TEXT };

            Gtk.TargetEntry[] targets = { };
            targets += uri_entry;
            targets += string_entry;
            targets += text_entry;

            Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, targets, Gdk.DragAction.COPY);

            /* Make Links Clickable */
            this.drag_data_received.connect (drag_received);
            this.clickable (regex_strings);

            Terminal.Application.saved_state.bind ("zoom", this, "font-scale", GLib.SettingsBindFlags.DEFAULT);
        }

        public void restore_settings () {
            /* Load configuration */
            var gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.gtk_application_prefer_dark_theme = settings.prefer_dark_style;

            background_color.parse (settings.background);

            Gdk.RGBA foreground_color = Gdk.RGBA ();
            foreground_color.parse (settings.foreground);

            string[] hex_palette = {
                "#073642", "#dc322f", "#859900", "#b58900",
                "#268bd2", "#ec0048", "#2aa198", "#94a3a5",
                "#586e75", "#cb4b16", "#859900", "#b58900",
                "#268bd2", "#d33682", "#2aa198", "#EEEEEE"
            };

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

            Gdk.RGBA[] palette = new Gdk.RGBA[16];

            for (int i = 0; i < hex_palette.length; i++) {
                Gdk.RGBA new_color= Gdk.RGBA ();
                new_color.parse (hex_palette[i]);

                palette[i] = new_color;
            }

            set_colors (foreground_color, background_color, palette);

            cursor_color.parse (settings.cursor_color);
            set_color_cursor (cursor_color);

            /* Bold font */
            this.allow_bold = settings.allow_bold;

            /* Load encoding */
            if (settings.encoding != "") {
                try {
                    set_encoding (settings.encoding);
                } catch (Error e) {
                    warning ("Failed to set encoding - %s", e.message);
                }
            }

            /* Disable bell if necessary */
            audible_bell = settings.audible_bell;

            /* Cursor shape */
            set_cursor_shape (settings.cursor_shape);
        }

        void on_child_exited () {
            child_has_exited = true;
            last_key_was_return = true;
        }

        public void kill_fg () {
            int fg_pid;
            if (this.try_get_foreground_pid (out fg_pid))
                Posix.kill (fg_pid, Posix.Signal.KILL);
        }

        public void term_ps () {
            killed = true;

            /* Check if the shell process is still alive by sending 0 signals */
            while (Posix.kill (this.child_pid, 0) == 0) {
                Posix.kill (this.child_pid, Posix.Signal.HUP);
                Posix.kill (this.child_pid, Posix.Signal.TERM);
                Thread.usleep (100);
            }
        }

        public void active_shell (string dir = GLib.Environment.get_current_dir ()) {
            string shell = settings.shell;
            string?[] envv = null;

            if (shell == "")
                shell = Vte.get_user_shell ();

            envv = {
                // Export ID so we can identify the terminal for which the process completion is reported
                "PANTHEON_TERMINAL_ID=" + terminal_id,

                // Export callback command a BASH-specific variable, see "man bash" for details
                "PROMPT_COMMAND=" + SEND_PROCESS_FINISHED_BASH + Environment.get_variable ("PROMPT_COMMAND"),

                // ZSH callback command will be read from ZSH config file supplied by us, see data/

                // TODO: support FISH, see https://github.com/fish-shell/fish-shell/issues/1382
            };

            /* Putting this in an Idle loop helps avoid corruption of the prompt on startup with multiple tabs */
            Idle.add_full (GLib.Priority.LOW, () => {
                try {
                    this.spawn_sync (Vte.PtyFlags.DEFAULT, dir, { shell },
                                            envv, SpawnFlags.SEARCH_PATH, null, out this.child_pid, null);
                } catch (Error e) {
                    warning (e.message);
                }
                return false;
            });
        }

        public void run_program (string program_string) {
            try {
                string[]? program_with_args = null;
                Shell.parse_argv (program_string, out program_with_args);

                this.spawn_sync (Vte.PtyFlags.DEFAULT, null, program_with_args,
                                        null, SpawnFlags.SEARCH_PATH, null, out this.child_pid, null);
            } catch (Error e) {
                warning (e.message);
            }
        }

        public bool try_get_foreground_pid (out int pid) {
            if (child_has_exited) {
                pid = -1;
                return false;
            }

            int pty = get_pty ().fd;
            int fgpid = Posix.tcgetpgrp (pty);

            if (fgpid != this.child_pid && fgpid != -1) {
                pid = (int) fgpid;
                return true;
            } else {
                pid = -1;
                return false;
            }
        }

        public bool has_foreground_process () {
            return try_get_foreground_pid (null);
        }

        public int calculate_width (int column_count) {
            int width = (int) (this.get_char_width ()) * column_count;
            return width;
        }

        public int calculate_height (int row_count) {
            int height = (int) (this.get_char_height ()) * row_count;
            return height;
        }

        private void clickable (string[] str) {
            foreach (string exp in str) {
                try {
                    var regex = new GLib.Regex (exp);
                    int id = this.match_add_gregex (regex, 0);

                    this.match_set_cursor_type (id, Gdk.CursorType.HAND2);
                } catch (GLib.RegexError error) {
                    warning (error.message);
                }
            }
        }

        private string? get_link (Gdk.Event event) {
            return this.match_check_event (event, null);
        }

        public string get_shell_location () {
            int pid = (!) (this.child_pid);

            try {
                return GLib.FileUtils.read_link ("/proc/%d/cwd".printf (pid));
            } catch (GLib.FileError error) {
                /* Tab name disambiguation may call this before shell location available. */
                /* No terminal warning needed */
                return "";
            }
        }

        public void increment_size () {
            font_scale = (font_scale + 0.1).clamp (MIN_SCALE, MAX_SCALE);
        }

        public void decrement_size () {
            font_scale = (font_scale - 0.1).clamp (MIN_SCALE, MAX_SCALE);
        }

        public void set_default_font_size () {
            font_scale = 1.0;
        }

        public bool is_init_complete () {
            return init_complete;
        }

        public void set_init_complete () {
            init_complete = true;
        }

        public void drag_received (Gdk.DragContext context, int x, int y,
                                   Gtk.SelectionData selection_data, uint target_type, uint time_) {
            switch (target_type) {
                case DropTargets.URILIST:
                    var uris = selection_data.get_uris ();
                    string path;
                    File file;

                    for (var i = 0; i < uris.length; i++) {
                         file = File.new_for_uri (uris[i]);
                         if ((path = file.get_path ()) != null) {
                             uris[i] = Shell.quote (path) + " ";
                        }
                    }

                    var uris_s = string.joinv ("", uris);
#if UBUNTU_BIONIC_PATCHED_VTE
                    this.feed_child (uris_s, uris_s.length);
#else
                    this.feed_child (uris_s.to_utf8 ());
#endif
                    break;
                case DropTargets.STRING:
                case DropTargets.TEXT:
                    var data = selection_data.get_text ();

                    if (data != null) {
#if UBUNTU_BIONIC_PATCHED_VTE
                        this.feed_child (data, data.length);
#else
                        this.feed_child (data.to_utf8 ());
#endif
                    }

                    break;
            }
        }

        public void remember_position () {
            long col, row;
            get_cursor_position (out col, out row);
            remembered_position = row;
        }

        public void remember_command_start_position () {
            if (!last_key_was_return) {
                return;
            }

            long col, row;
            get_cursor_position (out col, out row);
            remembered_command_start_row = row;
            last_key_was_return = false;
            resized = false;
        }

        public void remember_command_end_position () {
            if (last_key_was_return) {
                return;
            }

            long col, row;
            get_cursor_position (out col, out row);
            remembered_command_end_row = row;
            last_key_was_return = true;
        }

        public string get_last_output (bool include_command = true) {
            long output_end_col, output_end_row, start_row;
            get_cursor_position (out output_end_col, out output_end_row);

            var command_lines = remembered_command_end_row - remembered_command_start_row;

            if (!include_command) {
                start_row = remembered_command_end_row + 1;
            } else {
                start_row = remembered_command_start_row;
            }

            if (output_end_row - start_row < (include_command ? command_lines + 1 : 1)) {
                return "";
            }
            /* get text to the beginning of current line (to omit last prompt)
             * Note that using end_row, 0 for the end parameters results in the first
             * character of the prompt being selected for some reason. We assume a nominal
             * maximum line length rather than determine the actual length.  */
            return get_text_range (start_row, 0, output_end_row - 1, 1000, null, null) + "\n";
        }

        private void get_cell_clicked (Gdk.EventButton event, out long row, out long col) {
            row = (long)(event.y / get_char_height ());
            col = (long)(event.x / get_char_width ());
        }

        public void scroll_to_last_command () {
            long col, row;
            get_cursor_position (out col, out row);
            int delta = (int)(remembered_position - row);
            vadjustment.set_value (vadjustment.get_value () + delta + get_window ().get_height () / get_char_height () - 1);
        }

        public bool has_output () {
            return !resized && get_last_output ().length > 0;
        }
    }
}

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
        public string terminal_id;
        public string current_working_directory { get; private set; default = "";}
        public string? program_string { get; set; default = null; }
        static int terminal_id_counter = 0;
        private bool init_complete;
        public bool resized {get; set;}

        GLib.Pid child_pid;

        public unowned MainWindow main_window { get; construct set; }

        private Terminal.Application app {
            get {
                return main_window.app;
            }
        }

        // There may be no associated tab while made restorable
        public unowned Hdy.TabPage tab;
        public string? link_uri;

        public string tab_label {
            get {
                return tab != null ? tab.title : "";
            }

            set {
                if (value != null && tab != null) {
                    tab.title = value;
                }
            }
        }

        public const string ACTION_COPY = "term.copy";
        public const string ACTION_COPY_OUTPUT = "term.copy-output";
        public const string ACTION_CLEAR_SCREEN = "term.clear-screen";
        public const string ACTION_RESET = "term.reset";
        public const string ACTION_PASTE = "term.paste";
        public const string ACTION_RELOAD = "term.reload";
        public const string ACTION_SCROLL_TO_COMMAND = "term.scroll-to-command";
        public const string ACTION_SELECT_ALL = "term.select-all";
        public const string ACTION_ZOOM_DEFAULT = "term.zoom::default";
        public const string ACTION_ZOOM_IN = "term.zoom::in";
        public const string ACTION_ZOOM_OUT = "term.zoom::out";


        public const string[] ACCELS_COPY = { "<Control><Shift>C", null };
        public const string[] ACCELS_COPY_OUTPUT = { "<Alt>C", null };
        public const string[] ACCELS_CLEAR_SCREEN = { "<Control>L", null };
        public const string[] ACCELS_RESET = { "<Control>K", null };
        public const string[] ACCELS_PASTE = { "<Control><Shift>V", null };
        public const string[] ACCELS_RELOAD = { "<Control><Shift>R", "<Ctrl>F5", null };
        public const string[] ACCELS_SCROLL_TO_COMMAND = { "<Alt>Up", null };
        public const string[] ACCELS_SELECT_ALL = { "<Control><Shift>A", null };
        public const string[] ACCELS_ZOOM_DEFAULT = { "<control>0", "<Control>KP_0", null };
        public const string[] ACCELS_ZOOM_IN = { "<Control>plus", "<Control>equal", "<Control>KP_Add", null };
        public const string[] ACCELS_ZOOM_OUT = { "<Control>minus", "<Control>KP_Subtract", null };

        public int default_size;
        const string SEND_PROCESS_FINISHED_BASH = "dbus-send --type=method_call " +
                                                  "--session --dest=io.elementary.terminal " +
                                                  "/io/elementary/terminal " +
                                                  "io.elementary.terminal.ProcessFinished " +
                                                  "string:$PANTHEON_TERMINAL_ID " +
                                                  "string:\"$(fc -nl -1 | cut -c 3-)\" " +
                                                  "int32:\$__bp_last_ret_value >/dev/null 2>&1";

        /* Following strings are used to build RegEx for matching URIs */
        const string USERCHARS = "-[:alnum:]";
        const string USERCHARS_CLASS = "[" + USERCHARS + "]";
        const string PASSCHARS_CLASS = "[-[:alnum:]\\Q,?;.:/!%$^*&~\"#'\\E]";
        const string HOSTCHARS_CLASS = "[-[:alnum:]]";
        const string HOST = HOSTCHARS_CLASS + "+(\\." + HOSTCHARS_CLASS + "+)*";
        const string PORT = "(?:\\:[[:digit:]]{1,5})?";
        const string PATHCHARS_CLASS = "[-[:alnum:]\\Q_$.+!*,;:@&=?/~#%\\E]";
        const string PATHTERM_CLASS = "[^\\Q]'.}>) \t\r\n,\"\\E]";
        const string SCHEME = "(?:news:|telnet:|nntp:|file:\\/|https?:|ftps?:|sftp:|webcal:" +
                              "|irc:|sftp:|ldaps?:|nfs:|smb:|rsync:|ssh:|rlogin:|telnet:|git:" +
                              "|git\\+ssh:|bzr:|bzr\\+ssh:|svn:|svn\\+ssh:|hg:|mailto:|magnet:)";

        const string USERPASS = USERCHARS_CLASS + "+(?:" + PASSCHARS_CLASS + "+)?";
        const string URLPATH = "(?:(/" + PATHCHARS_CLASS +
                               "+(?:[(]" + PATHCHARS_CLASS +
                               "*[)])*" + PATHCHARS_CLASS +
                               "*)*" + PATHTERM_CLASS +
                               ")?";

        const string[] REGEX_STRINGS = {
            SCHEME + "//(?:" + USERPASS + "\\@)?" + HOST + PORT + URLPATH,
            "(?:www|ftp)" + HOSTCHARS_CLASS + "*\\." + HOST + PORT + URLPATH,
            "(?:callto:|h323:|sip:)" + USERCHARS_CLASS + "[" + USERCHARS + ".]*(?:" + PORT + "/[a-z0-9]+)?\\@" + HOST,
            "(?:mailto:)?" + USERCHARS_CLASS + "[" + USERCHARS + ".]*\\@" + HOSTCHARS_CLASS + "+\\." + HOST,
            "(?:news:|man:|info:)[[:alnum:]\\Q^_{|}~!\"#$%&'()*+,./;:=?`\\E]+"
        };

        public const double MIN_SCALE = 0.25;
        public const double MAX_SCALE = 4.0;

        public const int SYS_PIDFD_OPEN = 434; // Same on every arch

        public bool child_has_exited {
            get;
            private set;
        }

        public bool killed {
            get;
            private set;
        }

        private unowned Gtk.Clipboard clipboard;

        private GLib.SimpleAction copy_action;
        private GLib.SimpleAction copy_output_action;
        private GLib.SimpleAction clear_screen_action;
        private GLib.SimpleAction reset_action;
        private GLib.SimpleAction paste_action;
        private GLib.SimpleAction scroll_to_command_action;

        private long remembered_position; /* Only need to remember row at the moment */
        private long remembered_command_start_row = 0; /* Only need to remember row at the moment */
        private long remembered_command_end_row = 0; /* Only need to remember row at the moment */
        public bool last_key_was_return = true;

        private Gtk.EventControllerMotion motion_controller;
        private Gtk.EventControllerScroll scroll_controller;
        private Gtk.EventControllerKey key_controller;
        private Gtk.GestureMultiPress primary_gesture;
        private Gtk.GestureMultiPress secondary_gesture;

        private bool modifier_pressed = false;
        private double scroll_delta = 0.0;

        public signal void cwd_changed (string cwd);

        public TerminalWidget (MainWindow parent_window) {
            Object (
                main_window: parent_window
            );
        }

        construct {
            pointer_autohide = true;
            terminal_id = "%i".printf (terminal_id_counter++);
            init_complete = false;
            child_has_exited = false;
            killed = false;

            update_audible_bell ();
            update_cursor_shape ();
            update_theme ();

            var granite_settings = Granite.Settings.get_default ();
            granite_settings.notify["prefers-color-scheme"].connect (update_theme);
            Application.settings.changed["audible-bell"].connect (update_audible_bell);
            Application.settings.changed["background"].connect (update_theme);
            Application.settings.changed["cursor-color"].connect (update_theme);
            Application.settings.changed["cursor-shape"].connect (update_cursor_shape);
            Application.settings.changed["follow-system-style"].connect (update_theme);
            Application.settings.changed["foreground"].connect (update_theme);
            Application.settings.changed["palette"].connect (update_theme);
            Application.settings.changed["prefer-dark-style"].connect (update_theme);
            Application.settings.changed["theme"].connect (update_theme);

            motion_controller = new Gtk.EventControllerMotion (this) {
                propagation_phase = CAPTURE
            };
            motion_controller.enter.connect (pointer_focus);

            scroll_controller = new Gtk.EventControllerScroll (this, NONE) {
                propagation_phase = TARGET
            };
            scroll_controller.scroll.connect (scroll);
            scroll_controller.scroll_end.connect (() => scroll_delta = 0.0);

            key_controller = new Gtk.EventControllerKey (this) {
                propagation_phase = NONE
            };
            key_controller.key_pressed.connect (key_pressed);
            key_controller.key_released.connect (() => scroll_controller.flags = NONE);
            key_controller.focus_out.connect (() => scroll_controller.flags = NONE);

            // XXX(Gtk3): This is used to stop the key_pressed() handler from breaking the copy last output action,
            //            when a modifier is pressed, since it won't be in the modifier mask there (neither here).
            //
            // TODO(Gtk4): check if the modifier emission was fixed.
            key_controller.modifiers.connect (() => {
                // if two modifers are pressed in sequence (like <Control> -> <Shift>), modifier_pressed will be false.
                // However, the modifer mask in key_pressed() will already contain the previous modifier.
                modifier_pressed = !modifier_pressed;
                return true;
            });

            primary_gesture = new Gtk.GestureMultiPress (this) {
                propagation_phase = TARGET,
                button = 1
            };
            primary_gesture.pressed.connect (primary_pressed);

            secondary_gesture = new Gtk.GestureMultiPress (this) {
                propagation_phase = TARGET,
                button = 3
            };
            secondary_gesture.released.connect (secondary_released);

            // send events to key controller manually, since key_released isn't emitted in any propagation phase
            event.connect (key_controller.handle_event);

            selection_changed.connect (() => copy_action.set_enabled (get_has_selection ()));
            size_allocate.connect (() => resized = true);
            contents_changed.connect (check_cwd_changed);
            child_exited.connect (on_child_exited);
            ulong once = 0;
            once = realize.connect (() => {
                clipboard = get_clipboard (Gdk.SELECTION_CLIPBOARD);
                clipboard.owner_change.connect (setup_menu);
                disconnect (once);
            });

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
            this.clickable (REGEX_STRINGS);

            // Setup Actions
            var action_group = new GLib.SimpleActionGroup ();
            insert_action_group ("term", action_group);

            copy_action = new GLib.SimpleAction ("copy", null);
            copy_action.set_enabled (false);
            copy_action.activate.connect (() => copy_clipboard.emit ());
            action_group.add_action (copy_action);

            copy_output_action = new GLib.SimpleAction ("copy-output", null);
            copy_output_action.set_enabled (false);
            copy_output_action.activate.connect (copy_output);
            action_group.add_action (copy_output_action);

            clear_screen_action = new GLib.SimpleAction ("clear-screen", null);
            clear_screen_action.set_enabled (true);
            clear_screen_action.activate.connect (action_clear_screen);
            action_group.add_action (clear_screen_action);

            reset_action = new GLib.SimpleAction ("reset", null);
            reset_action.set_enabled (true);
            reset_action.activate.connect (action_reset);
            action_group.add_action (reset_action);

            paste_action = new GLib.SimpleAction ("paste", null);
            paste_action.activate.connect (() => paste_clipboard.emit ());
            action_group.add_action (paste_action);

            var reload_action = new GLib.SimpleAction ("reload", null);
            reload_action.activate.connect (reload);
            action_group.add_action (reload_action);

            scroll_to_command_action = new GLib.SimpleAction ("scroll-to-command", null);
            scroll_to_command_action.set_enabled (false);
            scroll_to_command_action.activate.connect (scroll_to_command);
            action_group.add_action (scroll_to_command_action);

            var select_all_action = new GLib.SimpleAction ("select-all", null);
            select_all_action.activate.connect (select_all);
            action_group.add_action (select_all_action);

            //TODO In Gtk4 replace action with `add_binding_signal ()``
            var zoom_action = new GLib.SimpleAction ("zoom", VariantType.STRING);
            zoom_action.activate.connect ((p) => {
                switch ((string) p) {
                    case "in":
                        increase_font_size ();
                        break;
                    case "out":
                        decrease_font_size ();
                        break;
                    case "default":
                        default_font_size ();
                        break;
                }
            });
            action_group.add_action (zoom_action);
        }

        private void pointer_focus () {
            // If this event caused focus-in then we need to suppress following hyperlinks on button release.
            allow_hyperlink = has_focus;
        }

        private void secondary_released (Gtk.GestureMultiPress gesture, int n_press, double x, double y) {
            link_uri = get_link (gesture.get_last_event (null));

            if (link_uri != null) {
                copy_action.set_enabled (true);
            }

            popup_context_menu ({ (int) x, (int) y });

            gesture.set_state (CLAIMED);
        }

        private void primary_pressed (Gtk.GestureMultiPress gesture, int n_press, double x, double y) {
            link_uri = null;
            if (allow_hyperlink) {
                link_uri = get_link (gesture.get_last_event (null));

                if (link_uri != null && !get_has_selection ()) {
                   main_window.get_simple_action (MainWindow.ACTION_OPEN_IN_BROWSER).activate (null);
                }
            } else {
                allow_hyperlink = true;
            }
        }

        private void scroll (double x, double y) {
            // try to emulate a normal scrolling event by summing deltas. step size of 0.5 chosen to match sensitivity
            scroll_delta += y;

            if (scroll_delta >= 0.5) {
                decrease_font_size ();
                scroll_delta = 0.0;
            } else if (scroll_delta <= -0.5) {
                increase_font_size ();
                scroll_delta = 0.0;
            }
        }

        private bool key_pressed (uint keyval, uint keycode, Gdk.ModifierType modifiers) {
            switch (keyval) {
                case Gdk.Key.Control_R:
                case Gdk.Key.Control_L:
                    scroll_controller.flags = VERTICAL;
                    break;

                case Gdk.Key.Return:
                    remember_position ();
                    scroll_to_command_action.set_enabled (true);
                    remember_command_end_position ();
                    copy_output_action.set_enabled (false);
                    break;

                case Gdk.Key.Up:
                case Gdk.Key.Down:
                    remember_command_start_position ();
                    break;

                case Gdk.Key.Menu:
                    long col, row;

                    get_cursor_position (out col, out row);

                    var cell_width = get_char_width ();
                    var cell_height = get_char_height ();
                    var vadj = vadjustment.value;

                    Gdk.Rectangle rect = {
                        (int) (col * cell_width),
                        (int) ((row - vadj) * cell_height),
                        (int) cell_width,
                        (int) cell_height
                    };

                    popup_context_menu (rect);
                    break;

                case Gdk.Key.Alt_L:
                case Gdk.Key.Alt_R:
                    // enable/disable the action before we try to use
                    copy_output_action.set_enabled (!resized && get_last_output ().length > 0);
                    break;

                default:
                    if (!modifier_pressed || !(Gtk.accelerator_get_default_mod_mask () in modifiers)) {
                        remember_command_start_position ();
                    }
                    break;
            }

            // Use hardware keycodes so the key used is unaffected by internationalized layout
            bool match_keycode (uint keyval, uint code) {
                Gdk.KeymapKey[] keys;

                var keymap = Gdk.Keymap.get_for_display (get_display ());
                if (keymap.get_entries_for_keyval (keyval, out keys)) {
                    foreach (var key in keys) {
                        if (code == key.keycode) {
                            return true;
                        }
                    }
                }

                return false;
            }

            if (CONTROL_MASK in modifiers && Application.settings.get_boolean ("natural-copy-paste")) {
                if (match_keycode (Gdk.Key.c, keycode)) {
                    if (get_has_selection ()) {
                        copy_clipboard ();
                        if (!(SHIFT_MASK in modifiers)) { // Shift not pressed
                            unselect_all ();
                        }
                        return true;
                    } else {
                        last_key_was_return = true; // Ctrl-c: Command cancelled
                    }
                } else if (match_keycode (Gdk.Key.v, keycode) && clipboard.wait_is_text_available ()) {
                    paste_clipboard ();
                    return true;
                }
            }

            if (CONTROL_MASK in modifiers && match_keycode (Gdk.Key.k, keycode)) {
                action_reset ();
                return true;
            }

            if (CONTROL_MASK in modifiers && match_keycode (Gdk.Key.l, keycode)) {
                action_clear_screen ();
                return true;
            }

            if (MOD1_MASK in modifiers && keyval == Gdk.Key.Up) {
                return !scroll_to_command_action.enabled;
            }

            return false;
        }

        private void setup_menu () {
            // Update the "Paste" menu option
            clipboard.request_targets ((clipboard, atoms) => {
                bool can_paste = false;

                if (atoms != null && atoms.length > 0) {
                    can_paste = Gtk.targets_include_text (atoms) || Gtk.targets_include_uri (atoms);
                }

                paste_action.set_enabled (can_paste);
            });

            // Update the "Copy Last Output" menu option
            var has_output = !resized && get_last_output ().length > 0;
            copy_output_action.set_enabled (has_output);
        }

        private void popup_context_menu (Gdk.Rectangle rect) {
            main_window.update_context_menu ();
            setup_menu ();

            // Popup context menu below cursor position
            var context_menu = new Gtk.Menu.from_model (main_window.context_menu_model) {
                attach_widget = this
            };
            context_menu.popup_at_rect (get_window (), rect, SOUTH_WEST, NORTH_WEST);
        }

        protected override void copy_clipboard () {
            if (link_uri != null && !get_has_selection ()) {
                clipboard.set_text (link_uri, link_uri.length);
            } else {
                base.copy_clipboard ();
            }
        }

        private void copy_output () {
            var output = get_last_output ();
            clipboard.set_text (output, output.length);
        }

        private void action_clear_screen () {
            debug ("Clear screen only");
            // Should we clear scrollback too?
            run_program ("clear -x", null);
        }

        private void action_reset () {
            debug ("Reset");
            // This also clears the screen and the scrollback
            run_program ("reset", null);
        }

        protected override void paste_clipboard () {
            clipboard.request_text ((clipboard, text) => {
                validated_feed (text);
            });
        }

        // Check pasted and dropped text before feeding to child;
        private void validated_feed (string? text) {
            // Do nothing when text is invalid
            if (text == null || !text.validate ()) {
                return;
            }

            // No user interaction because of user's preference
            if (!Application.settings.get_boolean ("unsafe-paste-alert")) {
                feed_child (text.data);
                return;
            }

            string? warn_text = null;
            if ("\n" in text) {
                warn_text = _("The pasted text may contain multiple commands");
            } else if ("sudo" in text || "doas" in text) {
                warn_text = _("The pasted text may be trying to gain administrative access");
            }

            // No user interaction for safe commands
            if (warn_text == null) {
                feed_child (text.data);
                return;
            }

            // Ask user for interaction for unsafe commands
            unowned var toplevel = (MainWindow) get_toplevel ();
            var dialog = new UnsafePasteDialog (toplevel, warn_text, text.strip ());
            dialog.response.connect ((res) => {
                dialog.destroy ();
                if (res == Gtk.ResponseType.ACCEPT) {
                    feed_child (text.data);
                }
            });

            dialog.present ();
        }

        private void update_theme () {
            var gtk_settings = Gtk.Settings.get_default ();
            var theme_palette = new Gdk.RGBA[Themes.PALETTE_SIZE];
            if (Application.settings.get_boolean ("follow-system-style")) {
                var system_prefers_dark = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
                gtk_settings.gtk_application_prefer_dark_theme = system_prefers_dark;

                if (system_prefers_dark) {
                    theme_palette = Themes.get_rgba_palette (Themes.DARK);
                } else {
                    theme_palette = Themes.get_rgba_palette (Themes.LIGHT);
                }
            } else {
                gtk_settings.gtk_application_prefer_dark_theme = Application.settings.get_boolean ("prefer-dark-style");
                theme_palette = Themes.get_rgba_palette (Application.settings.get_string ("theme"));
            }

            var background = theme_palette[Themes.PALETTE_SIZE - 3];
            var foreground = theme_palette[Themes.PALETTE_SIZE - 2];
            var cursor = theme_palette[Themes.PALETTE_SIZE - 1];
            var palette = theme_palette[0:16];

            set_colors (foreground, background, palette);
            set_color_cursor (cursor);
        }

        private void update_audible_bell () {
            audible_bell = Application.settings.get_boolean ("audible-bell");
        }

        private void update_cursor_shape () {
            set_cursor_shape ((Vte.CursorShape) Application.settings.get_enum ("cursor-shape"));
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

#if HAS_LINUX
            int pid_fd = Linux.syscall (SYS_PIDFD_OPEN, this.child_pid, 0);
#else
            int pid_fd = -1;
#endif

            Posix.kill (this.child_pid, Posix.Signal.HUP);
            Posix.kill (this.child_pid, Posix.Signal.TERM);

            // pidfd_open isn't supported in Linux kernel < 5.3
            if (pid_fd == -1) {
#if HAS_GLIB_2_74
                // GLib 2.73.2 dropped global GChildWatch, we need to wait ourselves
                Posix.waitpid (this.child_pid, null, 0);
#else
                while (Posix.kill (this.child_pid, 0) == 0) {
                    Thread.usleep (100);
                }
#endif
                return;
            }

            Posix.pollfd pid_pfd[1];
            pid_pfd[0] = Posix.pollfd () {
                fd = pid_fd,
                events = Posix.POLLIN
            };

            // The loop deals the case when SIGCHLD is delivered to us and restarts the call
            while (Posix.poll (pid_pfd, -1) != 1) {}

            Posix.close (pid_fd);
        }

        public void active_shell (string dir = GLib.Environment.get_current_dir ()) {
            string shell = Application.settings.get_string ("shell");
            string?[] envv = null;

            if (shell == "") {
                shell = Vte.get_user_shell ();
            }

            if (shell == "") {
                critical ("No user shell available");
                return;
            }

            if (dir == "") {
                debug ("Using fallback directory");
                dir = "/";
            }

            envv = {
                // Export ID so we can identify the terminal for which the process completion is reported
                "PANTHEON_TERMINAL_ID=" + terminal_id,

                // Export callback command a BASH-specific variable, see "man bash" for details
                "PROMPT_COMMAND=" + SEND_PROCESS_FINISHED_BASH + Environment.get_variable ("PROMPT_COMMAND"),

                // ZSH callback command will be read from ZSH config file supplied by us, see data/

                // TODO: support FISH, see https://github.com/fish-shell/fish-shell/issues/1382
            };

            /* We need opening uri to be available asap when constructing window with working directory
             * so remove idle loop, which appears not to be necessary any longer */
            try {
                this.spawn_sync (Vte.PtyFlags.DEFAULT, dir, { shell },
                                        envv, SpawnFlags.SEARCH_PATH, null, out this.child_pid, null);
            } catch (Error e) {
                warning (e.message);
            }

            check_cwd_changed ();
        }

        public void run_program (string _program_string, string? working_directory) {
            try {
                string[]? program_with_args = null;
                this.program_string = _program_string;
                Shell.parse_argv (program_string, out program_with_args);

                this.spawn_sync (Vte.PtyFlags.DEFAULT, working_directory, program_with_args,
                                        null, SpawnFlags.SEARCH_PATH, null, out this.child_pid, null);
            } catch (Error e) {
                warning (e.message);
                feed ((e.message + "\r\n\r\n").data);
                active_shell (working_directory);
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
            foreach (unowned string exp in str) {
                try {
                    var regex = new Vte.Regex.for_match (exp, -1, PCRE2.Flags.MULTILINE);
                    int id = this.match_add_regex (regex, 0);
                    this.match_set_cursor_name (id, "pointer");
                } catch (GLib.Error error) {
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

        protected override void increase_font_size () {
            font_scale += 0.1;
        }

        protected override void decrease_font_size () {
            font_scale -= 0.1;
        }

        public void default_font_size () {
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
                        // Get unquoted path as some apps may drop uris that are escaped
                        // and quoted.
                        string? unquoted_uri;
                        try {
                            unquoted_uri = Shell.unquote (uris[i]);
                        } catch (Error e) {
                            warning ("Error unquoting %s. %s", uris[i], e.message);
                            unquoted_uri = uris[i];
                        }
                        // Sanitize the path as we do not want the `file://` scheme included
                        // and we assume dropped paths are absolute.
                        file = File.new_for_uri (Utils.sanitize_path (unquoted_uri, "", false));
                        path = file.get_path ();
                        if (path != null) {
                            uris[i] = Shell.quote (path) + " ";
                        } else {
                            // Ignore unvalid paths
                            uris[i] = "";
                        }
                    }

                    var uris_s = string.joinv ("", uris);
                    this.feed_child (uris_s.data);
                    break;

                case DropTargets.STRING:
                case DropTargets.TEXT:
                    var text = selection_data.get_text ();
                    validated_feed (text);
                    break;
            }
        }

        public void remember_position () {
            long col, row;
            get_cursor_position (out col, out row);
            remembered_position = row;
        }

        public void remember_command_start_position () {
            if (!last_key_was_return || has_foreground_process ()) {
                return;
            }

            long col, row;
            get_cursor_position (out col, out row);
            remembered_command_start_row = row;
            last_key_was_return = false;
            resized = false;
        }

        public void remember_command_end_position () {
            if (last_key_was_return && !has_foreground_process ()) {
                return;
            }

            long col, row;
            get_cursor_position (out col, out row);
            /* Password entry will be on next line, or, if an incorrect password is given, two lines ahead */
            /* This restriction is required for `include_command = false to work` (although not currently used) */
            if (row - remembered_command_end_row <= 2) {
                remembered_command_end_row = row;
            }

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

            last_key_was_return = true;

            /* get text to the beginning of current line (to omit last prompt)
             * Note that using end_row, 0 for the end parameters results in the first
             * character of the prompt being selected for some reason. We assume a nominal
             * maximum line length rather than determine the actual length.  */
            return get_text_range (start_row, 0, output_end_row - 1, 1000, null, null) + "\n";
        }

        private void scroll_to_command (GLib.SimpleAction action, GLib.Variant? parameter) {
            long row, delta;

            get_cursor_position (null, out row);
            delta = remembered_position - row;

            vadjustment.value += (int) delta + get_window ().get_height () / get_char_height () - 1;
            action.set_enabled (false); // Repeated presses are ignored
        }

        public void reload () {
            var old_loc = get_shell_location ();

            if (has_foreground_process ()) {
                var dialog = new ForegroundProcessDialog.before_tab_reload ((MainWindow) get_toplevel ());
                dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.ACCEPT) {
                        Posix.kill (child_pid, Posix.Signal.TERM);
                        reset (true, true);
                        active_shell (old_loc);
                    }

                    dialog.destroy ();
                });

                dialog.present ();
                return;
            }

            Posix.kill (child_pid, Posix.Signal.TERM);
            reset (true, true);
            active_shell (old_loc);
        }

        private void check_cwd_changed () {
            var cwd = get_shell_location ();
            if (cwd != current_working_directory) {
                current_working_directory = cwd;
                tab.tooltip = current_working_directory;
                cwd_changed (cwd);
            }
        }
    }
}

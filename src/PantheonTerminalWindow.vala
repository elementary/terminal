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

namespace PantheonTerminal {

    public class PantheonTerminalWindow : Gtk.Window {
        private Pango.FontDescription term_font;
        private Granite.Widgets.DynamicNotebook notebook;
        private Gtk.Clipboard clipboard;
        private Gtk.Clipboard primary_selection;
        private PantheonTerminal.Widgets.SearchToolbar search_toolbar;
        private Gtk.Revealer search_revealer;
        private Gtk.ToggleButton search_button;
        private Gtk.Button zoom_default_button;

        private HashTable<string, TerminalWidget> restorable_terminals;
        private bool is_fullscreen = false;
        private string[] saved_tabs;

        private const string HIGH_CONTRAST_BG = "#fff";
        private const string HIGH_CONTRAST_FG = "#333";
        private const string SOLARIZED_DARK_BG = "rgba(37, 46, 50, 0.95)";
        private const string SOLARIZED_DARK_FG = "#94a3a5";
        private const string SOLARIZED_LIGHT_BG = "rgba(253, 246, 227, 0.95)";
        private const string SOLARIZED_LIGHT_FG = "#586e75";

        public bool unsafe_ignored;
        public bool focus_restored_tabs { get; construct; default = true; }
        public bool recreate_tabs { get; construct; default = true; }
        public bool restore_pos { get; construct; default = true; }
        public PantheonTerminalApp app { get; construct; }
        public SimpleActionGroup actions { get; construct; }
        public TerminalWidget current_terminal { get; private set; default = null; }
        
        public GLib.List <TerminalWidget> terminals = new GLib.List <TerminalWidget> ();

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CLOSE_TAB = "action_close_tab";
        public const string ACTION_COPY = "action_copy";
        public const string ACTION_FULLSCREEN = "action_fullscreen";
        public const string ACTION_NEW_TAB = "action_new_tab";
        public const string ACTION_NEW_WINDOW = "action_new_window";
        public const string ACTION_NEXT_TAB = "action_next_tab";
        public const string ACTION_OPEN_IN_FILES = "action_open_in_files";
        public const string ACTION_PASTE = "action_paste";
        public const string ACTION_PREVIOUS_TAB = "action_previous_tab";
        public const string ACTION_SEARCH = "action_search";
        public const string ACTION_SELECT_ALL = "action_select_all";
        public const string ACTION_ZOOM_DEFAULT_FONT = "action_zoom_default_font";
        public const string ACTION_ZOOM_IN_FONT = "action_zoom_in_font";
        public const string ACTION_ZOOM_OUT_FONT = "action_zoom_out_font";

        private static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const ActionEntry[] action_entries = {
            { ACTION_CLOSE_TAB, action_close_tab },
            { ACTION_COPY, action_copy },
            { ACTION_FULLSCREEN, action_fullscreen },
            { ACTION_NEW_TAB, action_new_tab },
            { ACTION_NEW_WINDOW, action_new_window },
            { ACTION_NEXT_TAB, action_next_tab },
            { ACTION_OPEN_IN_FILES, action_open_in_files },
            { ACTION_PASTE, action_paste },
            { ACTION_PREVIOUS_TAB, action_previous_tab },
            { ACTION_SEARCH, action_search },
            { ACTION_SELECT_ALL, action_select_all },
            { ACTION_ZOOM_DEFAULT_FONT, action_zoom_default_font },
            { ACTION_ZOOM_IN_FONT, action_zoom_in_font },
            { ACTION_ZOOM_OUT_FONT, action_zoom_out_font }
        };

        public PantheonTerminalWindow (PantheonTerminalApp app, bool recreate_tabs = true) {
            Object (
                application: app,
                app: app,
                recreate_tabs: recreate_tabs
            );

            if (!recreate_tabs) {
                new_tab ("");
            }
        }

        public PantheonTerminalWindow.with_coords (PantheonTerminalApp app, int x, int y,
                                                   bool recreate_tabs, bool ensure_tab) {
            Object (
                application: app,
                app: app,
                restore_pos: false,
                recreate_tabs: recreate_tabs
            );

            move (x, y);

            if (!recreate_tabs && ensure_tab) {
                new_tab ("");
            }
        }

        public PantheonTerminalWindow.with_working_directory (PantheonTerminalApp app, string location,
                                                              bool recreate_tabs = true) {
            Object (
                application: app,
                app: app,
                focus_restored_tabs: false,
                recreate_tabs: recreate_tabs
            );

            new_tab (location);
        }

        static construct {
            action_accelerators[ACTION_CLOSE_TAB] = "<Control><Shift>w";
            action_accelerators[ACTION_COPY] = "<Control><Shift>c";
            action_accelerators[ACTION_FULLSCREEN] = "F11";
            action_accelerators[ACTION_NEW_TAB] = "<Control><Shift>t";
            action_accelerators[ACTION_NEW_WINDOW] = "<Control><Shift>n";
            action_accelerators[ACTION_NEXT_TAB] = "<Control><Shift>Right";
            action_accelerators[ACTION_OPEN_IN_FILES] = "<Control><Shift>e";
            action_accelerators[ACTION_PASTE] = "<Control><Shift>v";
            action_accelerators[ACTION_PREVIOUS_TAB] = "<Control><Shift>Left";
            action_accelerators[ACTION_SEARCH] = "<Control><Shift>f";
            action_accelerators[ACTION_SELECT_ALL] = "<Control><Shift>a";
            action_accelerators[ACTION_ZOOM_DEFAULT_FONT] = "<Control>0";
            action_accelerators[ACTION_ZOOM_DEFAULT_FONT] = "<Control>KP_0";
            action_accelerators[ACTION_ZOOM_IN_FONT] = "<Control>plus";
            action_accelerators[ACTION_ZOOM_IN_FONT] = "<Control>KP_Add";
            action_accelerators[ACTION_ZOOM_OUT_FONT] = "<Control>minus";
            action_accelerators[ACTION_ZOOM_OUT_FONT] = "<Control>KP_Subtract";
        }

        construct {
            actions = new SimpleActionGroup ();
            actions.add_action_entries (action_entries, this);
            insert_action_group ("win", actions);

            icon_name = "utilities-terminal";

            foreach (var action in action_accelerators.get_keys ()) {
                app.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
            }

            /* Make GTK+ CSD not steal F10 from the terminal */
            var gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.gtk_menu_bar_accel = null;

            set_visual (Gdk.Screen.get_default ().get_rgba_visual ());

            title = TerminalWidget.DEFAULT_LABEL;
            restore_saved_state (restore_pos);
            if (recreate_tabs) {
                open_tabs ();
            }

            clipboard = Gtk.Clipboard.get (Gdk.Atom.intern ("CLIPBOARD", false));
            update_context_menu ();
            clipboard.owner_change.connect (update_context_menu);

            primary_selection = Gtk.Clipboard.get (Gdk.Atom.intern ("PRIMARY", false));

            setup_ui ();
            show_all ();

            search_revealer.set_reveal_child (false);
            term_font = Pango.FontDescription.from_string (get_term_font ());

            set_size_request (app.minimum_width, app.minimum_height);

            search_button.toggled.connect (on_toggle_search);
            configure_event.connect (on_window_state_change);
            destroy.connect (on_destroy);

            restorable_terminals = new HashTable<string, TerminalWidget> (str_hash, str_equal);
        }

        public void add_tab_with_command (string command) {
            new_tab ("", command);
        }

        public void add_tab_with_working_directory (string location) {
            new_tab (location);
        }

        /** Returns true if the code parameter matches the keycode of the keyval parameter for
          * any keyboard group or level (in order to allow for non-QWERTY keyboards) **/
        protected bool match_keycode (int keyval, uint code) {
            Gdk.KeymapKey [] keys;
            Gdk.Keymap keymap = Gdk.Keymap.get_default ();
            if (keymap.get_entries_for_keyval (keyval, out keys)) {
                foreach (var key in keys) {
                    if (code == key.keycode)
                        return true;
                }
            }

            return false;
        }

        private void setup_ui () {
            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("io/elementary/terminal/Application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            search_button = new Gtk.ToggleButton ();
            search_button.image = new Gtk.Image.from_icon_name ("edit-find-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            search_button.tooltip_text = _("Find…");
            search_button.valign = Gtk.Align.CENTER;

            var zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);
            zoom_out_button.tooltip_text = _("Zoom Out");
            zoom_out_button.action_name = ACTION_PREFIX + ACTION_ZOOM_OUT_FONT;

            zoom_default_button = new Gtk.Button.with_label ("100%");
            zoom_default_button.tooltip_text = _("Default zoom level");
            zoom_default_button.action_name = ACTION_PREFIX + ACTION_ZOOM_DEFAULT_FONT;

            var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
            zoom_in_button.tooltip_text = _("Zoom In");
            zoom_in_button.action_name = ACTION_PREFIX + ACTION_ZOOM_IN_FONT;

            var font_size_grid = new Gtk.Grid ();
            font_size_grid.column_homogeneous = true;
            font_size_grid.hexpand = true;
            font_size_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
            font_size_grid.add (zoom_out_button);
            font_size_grid.add (zoom_default_button);
            font_size_grid.add (zoom_in_button);

            var color_button_white = new Gtk.Button ();
            color_button_white.halign = Gtk.Align.CENTER;
            color_button_white.height_request = 32;
            color_button_white.width_request = 32;
            color_button_white.tooltip_text = _("High Contrast");

            var color_button_white_context = color_button_white.get_style_context ();
            color_button_white_context.add_class ("color-button");
            color_button_white_context.add_class ("color-white");

            var color_button_light = new Gtk.Button ();
            color_button_light.halign = Gtk.Align.CENTER;
            color_button_light.height_request = 32;
            color_button_light.width_request = 32;
            color_button_light.tooltip_text = _("Solarized Light");

            var color_button_light_context = color_button_light.get_style_context ();
            color_button_light_context.add_class ("color-button");
            color_button_light_context.add_class ("color-light");

            var color_button_dark = new Gtk.Button ();
            color_button_dark.halign = Gtk.Align.CENTER;
            color_button_dark.height_request = 32;
            color_button_dark.width_request = 32;
            color_button_dark.tooltip_text = _("Solarized Dark");

            var color_button_dark_context = color_button_dark.get_style_context ();
            color_button_dark_context.add_class ("color-button");
            color_button_dark_context.add_class ("color-dark");

            var style_popover_grid = new Gtk.Grid ();
            style_popover_grid.margin = 12;
            style_popover_grid.column_spacing = 6;
            style_popover_grid.row_spacing = 12;
            style_popover_grid.width_request = 200;
            style_popover_grid.attach (font_size_grid, 0, 0, 3, 1);
            style_popover_grid.attach (color_button_white, 0, 1, 1, 1);
            style_popover_grid.attach (color_button_light, 1, 1, 1, 1);
            style_popover_grid.attach (color_button_dark, 2, 1, 1, 1);
            style_popover_grid.show_all ();

            var style_popover = new Gtk.Popover (null);
            style_popover.add (style_popover_grid);

            var style_button = new Gtk.MenuButton ();
            style_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            style_button.popover = style_popover;
            style_button.tooltip_text = _("Style");
            style_button.valign = Gtk.Align.CENTER;

            var header = new Gtk.HeaderBar ();
            header.show_close_button = true;
            header.get_style_context ().add_class ("default-decoration");
            header.pack_end (style_button);
            header.pack_end (search_button);

            search_toolbar = new PantheonTerminal.Widgets.SearchToolbar (this);

            search_revealer = new Gtk.Revealer ();
            search_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
            search_revealer.add (search_toolbar);

            get_action (ACTION_COPY).set_enabled (false);

            notebook = new Granite.Widgets.DynamicNotebook ();
            notebook.tab_added.connect (on_tab_added);
            notebook.tab_removed.connect (on_tab_removed);
            notebook.tab_switched.connect (on_switch_page);
            notebook.tab_moved.connect (on_tab_moved);
            notebook.tab_reordered.connect (on_tab_reordered);
            notebook.tab_restored.connect (on_tab_restored);
            notebook.tab_duplicated.connect (on_tab_duplicated);
            notebook.close_tab_requested.connect (on_close_tab_requested);
            notebook.new_tab_requested.connect (on_new_tab_requested);
            notebook.allow_new_window = true;
            notebook.allow_duplication = true;
            notebook.allow_restoring = settings.save_exited_tabs;
            notebook.max_restorable_tabs = 5;
            notebook.group_name = "pantheon-terminal";
            notebook.can_focus = false;
            notebook.tab_bar_behavior = settings.tab_bar_behavior;

            var grid = new Gtk.Grid ();
            grid.attach (search_revealer, 0, 0, 1, 1);
            grid.attach (notebook, 0, 1, 1, 1);

            get_style_context ().add_class ("terminal-window");
            set_titlebar (header);
            add (grid);

            color_button_dark.clicked.connect (() => {
                settings.prefer_dark_style = true;
                settings.background = SOLARIZED_DARK_BG;
                settings.foreground = SOLARIZED_DARK_FG;
            });

            color_button_light.clicked.connect (() => {
                settings.prefer_dark_style = false;
                settings.background = SOLARIZED_LIGHT_BG;
                settings.foreground = SOLARIZED_LIGHT_FG;
            });

            color_button_white.clicked.connect (() => {
                settings.prefer_dark_style = false;
                settings.background = HIGH_CONTRAST_BG;
                settings.foreground = HIGH_CONTRAST_FG;
            });

            key_press_event.connect ((e) => {
                switch (e.keyval) {
                    case Gdk.Key.Escape:
                        if (search_toolbar.search_entry.has_focus) {
                            search_button.active = !search_button.active;
                            return true;
                        }
                        break;
                    case Gdk.Key.Return:
                        if (search_toolbar.search_entry.has_focus) {
                            if ((e.state & Gdk.ModifierType.SHIFT_MASK) != 0) {
                                search_toolbar.previous_search ();
                            } else {
                                search_toolbar.next_search ();
                            }
                            return true;
                        }
                        break;
                    case Gdk.Key.@1: //alt+[1-8]
                    case Gdk.Key.@2:
                    case Gdk.Key.@3:
                    case Gdk.Key.@4:
                    case Gdk.Key.@5:
                    case Gdk.Key.@6:
                    case Gdk.Key.@7:
                    case Gdk.Key.@8:
                        if (((e.state & Gdk.ModifierType.MOD1_MASK) != 0) &&
                            settings.alt_changes_tab) {
                            var i = e.keyval - 49;
                            if (i > notebook.n_tabs - 1)
                                return false;
                            notebook.current = notebook.get_tab_by_index ((int) i);
                            return true;
                        }
                        break;
                    case Gdk.Key.@9:
                        if (((e.state & Gdk.ModifierType.MOD1_MASK) != 0) &&
                            settings.alt_changes_tab) {
                            notebook.current = notebook.get_tab_by_index (notebook.n_tabs - 1);
                            return true;
                        }
                        break;
                }

                /* Use hardware keycodes so the key used
                 * is unaffected by internationalized layout */
                if (((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) &&
                                            settings.natural_copy_paste) {
                    uint keycode = e.hardware_keycode;
                    if (match_keycode (Gdk.Key.c, keycode)) {
                        if (current_terminal.get_has_selection ()) {
                            current_terminal.copy_clipboard ();
                            return true;
                        }
                    } else if (match_keycode (Gdk.Key.v, keycode)) {
                        return handle_paste_event ();
                    }
                }

                return false;
            });
        }

        public bool handle_paste_event () {
            if (search_toolbar.search_entry.has_focus) {
                return false;
            } else if (clipboard.wait_is_text_available ()) {
                action_paste ();
                return true;
            }

            return false;
        }

        public bool handle_primary_selection_copy_event () {
            if (search_toolbar.search_entry.has_focus) {
                return false;
            } else if (current_terminal.get_has_selection ()) {
                current_terminal.copy_primary ();
                primary_selection.request_text (on_get_text);
                return true;
            }

            return false;
        }

        private void restore_saved_state (bool restore_pos = true) {
            saved_tabs = saved_state.tabs;
            default_width = PantheonTerminal.saved_state.window_width;
            default_height = PantheonTerminal.saved_state.window_height;

            Gdk.Rectangle geometry;
            get_screen ().get_monitor_geometry (get_screen ().get_primary_monitor (), out geometry);

            if (default_width == -1) {
                default_width = geometry.width * 2 / 3;
            }

            if (default_height == -1) {
                default_height = geometry.height * 3 / 4;
            }

            if (restore_pos) {
                int x = saved_state.opening_x;
                int y = saved_state.opening_y;

                if (x != -1 && y != -1) {
                    move (x, y);
                } else {
                    x = (geometry.width - default_width)  / 2;
                    y = (geometry.height - default_height) / 2;
                    move (x, y);
                }
            }

            if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.MAXIMIZED) {
                maximize ();
            } else if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.FULLSCREEN) {
                fullscreen ();
                is_fullscreen = true;
            }
        }

        private void on_toggle_search () {
            var is_search = search_button.get_active ();
            search_revealer.set_reveal_child (is_search);

            if (is_search) {
                search_toolbar.grab_focus ();
            } else {
                search_toolbar.clear ();
                current_terminal.grab_focus ();
            }
        }

        private void on_tab_added (Granite.Widgets.Tab tab) {
            var t = get_term_widget (tab);
            terminals.append (t);
            t.window = this;
            schedule_name_check ();
        }

        private void on_tab_removed (Granite.Widgets.Tab tab) {
            var t = get_term_widget (tab);
            terminals.remove (t);

            if (notebook.n_tabs == 0) {
                destroy ();
            } else {
                schedule_name_check ();
            }
        }

        private bool on_close_tab_requested (Granite.Widgets.Tab tab) {
            var t = get_term_widget (tab);

            if (t.has_foreground_process ()) {
                var d = new ForegroundProcessDialog (this);
                if (d.run () == 1) {
                    d.destroy ();
                    t.kill_fg ();
                } else {
                    d.destroy ();

                    return false;
                }
            }

            if (!t.child_has_exited) {
                if (notebook.n_tabs >= 2 && settings.save_exited_tabs) {
                    make_restorable (tab);
                } else {
                    t.term_ps ();
                }
            }

            return true;
        }

        private void on_tab_reordered (Granite.Widgets.Tab tab, int new_pos) {
            current_terminal.grab_focus ();
            save_opened_terminals ();
        }

        private void on_tab_restored (string label, string restore_key, GLib.Icon? icon) {
            TerminalWidget term = restorable_terminals.get (restore_key);
            var tab = create_tab (label, icon, term);

            restorable_terminals.remove (restore_key);
            notebook.insert_tab (tab, -1);
            notebook.current = tab;
            term.grab_focus ();
            schedule_name_check ();
        }

        private void on_tab_moved (Granite.Widgets.Tab tab, int x, int y) {
            Idle.add (() => {
                var new_window = app.new_window_with_coords (x, y, false);
                var t = get_term_widget (tab);
                var new_notebook = new_window.notebook;

                notebook.remove_tab (tab);
                new_notebook.insert_tab (tab, -1);
                new_window.current_terminal = t;
                return false;
            });
        }

        private void on_tab_duplicated (Granite.Widgets.Tab tab) {
            var t = get_term_widget (tab);
            new_tab (t.get_shell_location ());
        }

        private void on_new_tab_requested () {
            if (settings.follow_last_tab)
                new_tab (current_terminal.get_shell_location ());
            else
                new_tab (Environment.get_home_dir ());
        }

        private void update_context_menu () {
            clipboard.request_targets (update_context_menu_cb);
        }

        private void update_context_menu_cb (Gtk.Clipboard clipboard_, Gdk.Atom[]? atoms) {
            bool can_paste = false;

            if (atoms != null && atoms.length > 0)
                can_paste = Gtk.targets_include_text (atoms) || Gtk.targets_include_uri (atoms);

            get_action (ACTION_PASTE).set_enabled (can_paste);
        }

        uint timer_window_state_change = 0;

        private bool on_window_state_change (Gdk.EventConfigure event) {
            // triggered when the size, position or stacking of the window has changed
            // it is delayed 400ms to prevent spamming gsettings
            if (timer_window_state_change > 0)
                GLib.Source.remove (timer_window_state_change);

            timer_window_state_change = GLib.Timeout.add (400, () => {
                timer_window_state_change = 0;
                if (get_window () == null)
                    return false;

                /* Save window state */
                if ((get_window ().get_state () & Gdk.WindowState.MAXIMIZED) != 0) {
                    PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.MAXIMIZED;
                } else if ((get_window ().get_state () & Gdk.WindowState.FULLSCREEN) != 0) {
                    PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.FULLSCREEN;
                } else {
                    PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.NORMAL;
                }

                /* Save window size */
                if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.NORMAL) {
                    int width, height;
                    get_size (out width, out height);
                    PantheonTerminal.saved_state.window_width = width;
                    PantheonTerminal.saved_state.window_height = height;
                }

                /* Save window position */
                int root_x, root_y;
                get_position (out root_x, out root_y);
                saved_state.opening_x = root_x;
                saved_state.opening_y = root_y;
                return false;
            });
            return false;
        }

        private void on_switch_page (Granite.Widgets.Tab? old,
                                     Granite.Widgets.Tab new_tab) {

            current_terminal = get_term_widget (new_tab);
            title = current_terminal.tab_label ??  TerminalWidget.DEFAULT_LABEL;
            set_zoom_default_label (current_terminal.zoom_factor);
            new_tab.icon = null;
            Idle.add (() => {
                get_term_widget (new_tab).grab_focus ();
                return false;
            });

            PantheonTerminal.saved_state.focused_tab = notebook.get_tab_position (new_tab);
        }

        private void open_tabs () {
            string[] tabs = {};
            if (settings.remember_tabs) {
                tabs = saved_tabs;
                if (tabs.length == 0) {
                    tabs += Environment.get_home_dir ();
                }
            } else {
                tabs += PantheonTerminalApp.working_directory ?? Environment.get_current_dir ();
            }

            int null_dirs = 0;
            for (int i = 0; i < tabs.length; i++) {
                File file = File.new_for_path (tabs[i]);

                if (file.query_exists () == false) {
                    null_dirs++;
                    tabs[i] = "";
                }

                if (null_dirs == tabs.length) {
                    tabs[0] = PantheonTerminalApp.working_directory ?? Environment.get_current_dir ();
                }
            }

            PantheonTerminal.saved_state.tabs = {};

            int focus = PantheonTerminal.saved_state.focused_tab.clamp(0, tabs.length - 1);
            Idle.add_full (GLib.Priority.LOW, () => {
                focus += notebook.n_tabs;
                foreach (string loc in tabs) {
                    if (loc == "") {
                        focus--;
                        continue;
                    } else {
                        new_tab (loc, null, false);
                    }
                }

                if (focus_restored_tabs) {
                    var tab = notebook.get_tab_by_index (focus.clamp (0, notebook.n_tabs - 1));
                    notebook.current = tab;
                    get_term_widget (tab).grab_focus ();
                }

                return false;
            });
        }

        private void new_tab (string directory, string? program = null, bool focus = true) {
            /*
             * If the user choose to use a specific working directory.
             * Reassigning the directory variable a new value
             * leads to free'd memory being read.
             */
            string location;
            if (directory == "") {
                location = PantheonTerminalApp.working_directory ?? Environment.get_current_dir ();
            } else {
                location = directory;
            }

            /* Set up terminal */
            var t = new TerminalWidget (this);
            t.scrollback_lines = settings.scrollback_lines;

            /* Make the terminal occupy the whole GUI */
            t.vexpand = true;
            t.hexpand = true;


            var tab = create_tab (TerminalWidget.DEFAULT_LABEL, null, t);

            t.child_exited.connect (() => {
                if (!t.killed) {
                    if (program != null) {
                        /* If a program was running, do not close the tab so that output of program
                         * remains visible */
                        t.active_shell (location);
                        /* Allow closing tab with "exit" */
                        program = null;
                    } else {
                        t.tab.close ();
                        return;
                    }
                }

                schedule_name_check ();
            });

            /* This signal is not emitted when the .bashrc is missing or does not force terminal to
             * set its title. So we cannot detect path changes in the shell. Tab name remains "Terminal".
             */
            t.window_title_changed.connect (() => {
                if (t == current_terminal) {
                    title = t.window_title;
                }
                schedule_name_check ();
            });

            t.set_font (term_font);

            int minimum_width = t.calculate_width (80) / 2;
            int minimum_height = t.calculate_height (24) / 2;
            set_size_request (minimum_width, minimum_height);
            app.minimum_width = minimum_width;
            app.minimum_height = minimum_height;

            Gdk.Geometry hints = Gdk.Geometry();
            hints.width_inc = (int) t.get_char_width ();
            hints.height_inc = (int) t.get_char_height ();
            set_geometry_hints (this, hints, Gdk.WindowHints.RESIZE_INC);

            notebook.insert_tab (tab, -1);

            if (focus) {
                notebook.current = tab;
                t.grab_focus ();
            }

            if (program == null) {
                /* Set up the virtual terminal */
                if (location == "") {
                    t.active_shell ();
                } else {
                    t.active_shell (location);
                }
            } else {
                t.run_program (program);
            }
        }

        private Granite.Widgets.Tab create_tab (string label, GLib.Icon? icon, TerminalWidget term) {
            var sw = new Gtk.ScrolledWindow (null, term.get_vadjustment ());
            sw.add (term);
            var tab = new Granite.Widgets.Tab (label, icon, sw);
            term.tab = tab;
            tab.ellipsize_mode = Pango.EllipsizeMode.START;

            return tab;
        }

        private void make_restorable (Granite.Widgets.Tab tab) {
            var term = get_term_widget (tab);
            terminals.remove (term);
            restorable_terminals.insert (term.terminal_id, term);
            tab.restore_data = term.terminal_id;

            ((Gtk.Container)tab.page).remove (term);

            tab.dropped_callback = (() => {
                unowned TerminalWidget t = restorable_terminals.get (tab.restore_data);
                t.term_ps ();
                restorable_terminals.remove (tab.restore_data);
            });
        }

        public void run_program_term (string program) {
            new_tab ("", program);
        }

        static string get_term_font () {
            string font_name;

            if (settings.font == "") {
                var settings_sys = new GLib.Settings ("org.gnome.desktop.interface");
                font_name = settings_sys.get_string ("monospace-font-name");
            } else {
                font_name = settings.font;
            }

            return font_name;
        }

        protected override bool delete_event (Gdk.EventAny event) {
            action_quit ();
            save_opened_terminals ();
            var tabs_to_terminate = new GLib.List <TerminalWidget> ();

            foreach (var t in terminals) {
                t = (TerminalWidget) t;
                if (t.has_foreground_process ()) {
                    var d = new ForegroundProcessDialog.before_close (this);
                    if (d.run () == 1) {
                        t.kill_fg ();
                        d.destroy ();
                    } else {
                        d.destroy ();
                        return true;
                    }
                }

                tabs_to_terminate.append (t);
            }

            foreach (var t in tabs_to_terminate) {
                t.term_ps ();
            }

            return false;
        }

        private void on_destroy () {
            foreach (unowned TerminalWidget t in restorable_terminals.get_values ()) {
                t.term_ps ();
            }
        }

        void on_get_text (Gtk.Clipboard board, string? intext) {
            /* if unsafe paste alert is enabled, show dialog */
            if (settings.unsafe_paste_alert && !unsafe_ignored ) {

                if (intext == null) {
                    return;
                }
                if (!intext.validate()) {
                    warning("Dropping invalid UTF-8 paste");
                    return;
                }
                var text = intext.strip();

                if ((text.index_of ("sudo") > -1) && (text.index_of ("\n") != 0)) {
                    var d = new UnsafePasteDialog (this);
                    if (d.run () == 1) {
                        d.destroy ();
                        return;
                    }
                    d.destroy ();
                }
            }
            if (board == primary_selection) {
                current_terminal.paste_primary ();
            } else {
                current_terminal.paste_clipboard ();
            }
        }

        void action_quit () {

        }

        void action_copy () {
            if (current_terminal.uri != null && ! current_terminal.get_has_selection ())
                clipboard.set_text (current_terminal.uri,
                                    current_terminal.uri.length);
            else
                current_terminal.copy_clipboard ();
        }

        void action_paste () {
            clipboard.request_text (on_get_text);
        }

        void action_select_all () {
            current_terminal.select_all ();
        }

        void action_open_in_files () {
            try {
                string uri = Filename.to_uri (current_terminal.get_shell_location ());

                try {
                     Gtk.show_uri (null, uri, Gtk.get_current_event_time ());
                } catch (Error e) {
                     warning (e.message);
                }

            } catch (ConvertError e) {
                warning (e.message);
            }
        }

        void action_close_tab () {
            current_terminal.tab.close ();
            current_terminal.grab_focus ();
        }

        void action_new_window () {
            app.new_window ();
        }

        void action_new_tab () {
            if (settings.follow_last_tab)
                new_tab (current_terminal.get_shell_location ());
            else
                new_tab (Environment.get_home_dir ());
        }

        void action_zoom_in_font () {
            current_terminal.increment_size ();
            set_zoom_default_label (current_terminal.zoom_factor);
        }

        void action_zoom_out_font () {
            current_terminal.decrement_size ();
            set_zoom_default_label (current_terminal.zoom_factor);
        }

        void action_zoom_default_font () {
            current_terminal.set_default_font_size ();
            set_zoom_default_label (current_terminal.zoom_factor);
        }

        private void set_zoom_default_label (double zoom_factor) {
            zoom_default_button.label = "%.0f%%".printf (current_terminal.zoom_factor * 100);
        }

        void action_next_tab () {
            notebook.next_page ();
        }

        void action_previous_tab () {
            notebook.previous_page ();
        }

        void action_search () {
            search_button.active = !search_button.active;
        }

        void action_fullscreen () {
            if (is_fullscreen) {
                unfullscreen ();
                is_fullscreen = false;
            } else {
                fullscreen ();
                is_fullscreen = true;
            }
        }

        private TerminalWidget get_term_widget (Granite.Widgets.Tab tab) {
            return (TerminalWidget)((Gtk.Bin)tab.page).get_child ();
        }

        uint name_check_timeout_id = 0;
        private void schedule_name_check () {
            if (name_check_timeout_id > 0) {
                Source.remove (name_check_timeout_id);
            }

            name_check_timeout_id = Timeout.add (50, () => {
                save_opened_terminals ();

                if (!check_for_tabs_with_same_name ()) {
                    return true;
                } else {
                    name_check_timeout_id = 0;
                    return false;
                }
            });
        }

        /** Compare every tab label with every other and resolve ambiguities **/
        private bool check_for_tabs_with_same_name () {
            /* Take list copies so foreach clauses can be nested safely*/
            var terms = terminals.copy ();
            var terms2 = terminals.copy ();

            foreach (TerminalWidget terminal in terms) {
                string term_path = terminal.get_shell_location ();
                string term_label = terminal.window_title;

                if (term_label == "") { /* No point in continuing - tabs not finished updating */
                    return false; /* Try again later */
                }

                if (terminal.tab_label == TerminalWidget.DEFAULT_LABEL) { /* Absent or incorrect .bashrc */
                    return true;
                }

                /* Reset tab_name to basename so long name only used when required */
                terminal.tab_label = term_label;

                foreach (TerminalWidget terminal2 in terms2) {
                    string term2_path = terminal2.get_shell_location ();
                    string term2_name = terminal2.window_title;

                    if (terminal2 != terminal && term2_name == term_label) {
                        if (term2_path != term_path) {
                            terminal2.tab_label = disambiguate_label (term2_path, term_path);
                            terminal.tab_label = disambiguate_label (term_path, term2_path);

                            if (terminal == current_terminal) {
                                title = terminal.tab_label;
                            }
                        }
                    }
                }
            }

            return true;
        }

        private void save_opened_terminals () {
            string[] opened_tabs = {};

            notebook.tabs.foreach ((tab) => {
                var term = get_term_widget (tab);
                if (term == null) {
                    return;
                }

                var location = term.get_shell_location ();
                if (location != null && location != "") {
                    opened_tabs += location;
                }
            });

            PantheonTerminal.saved_state.tabs = opened_tabs;
            PantheonTerminal.saved_state.focused_tab = notebook.get_tab_position (notebook.current);
        }

        /** Return enough of @path to distinguish it from @conflict_path **/
        private string disambiguate_label (string path, string conflict_path) {
            string prefix = "";
            string conflict_prefix = "";
            string temp_path = path;
            string temp_conflict_path = conflict_path;
            string basename =  Path.get_basename (path);

            if (basename != Path.get_basename (conflict_path)) {
                return basename;
            }

            /* Add parent directories until path and conflict path differ */
            while (prefix == conflict_prefix) {
                var parent_temp_path = get_parent_path_from_path (temp_path);
                var parent_temp_confict_path = get_parent_path_from_path (temp_conflict_path);
                prefix = Path.get_basename (parent_temp_path) + Path.DIR_SEPARATOR_S + prefix;
                conflict_prefix = Path.get_basename (parent_temp_confict_path) + Path.DIR_SEPARATOR_S + conflict_prefix;
                temp_path = parent_temp_path;
                temp_conflict_path = parent_temp_confict_path;
            }

            return (prefix + basename).replace ("//", "/");
        }

        /*** Simplified version of PF.FileUtils function, with fewer checks ***/
        private string get_parent_path_from_path (string path) {
            if (path.length < 2) {
                return Path.DIR_SEPARATOR_S;
            }

            StringBuilder string_builder = new StringBuilder (path);
            if (path.has_suffix (Path.DIR_SEPARATOR_S)) {
                string_builder.erase (string_builder.str.length - 1,-1);
            }

            int last_separator = string_builder.str.last_index_of (Path.DIR_SEPARATOR_S);
            if (last_separator < 0) {
                last_separator = 0;
            }

            string_builder.erase (last_separator, -1);
            return string_builder.str + Path.DIR_SEPARATOR_S;
        }

        public SimpleAction? get_action (string name) {
            return actions.lookup_action (name) as SimpleAction;
        }
    }
}

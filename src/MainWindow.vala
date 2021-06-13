/*
* Copyright (c) 2011-2021 elementary, Inc. (https://elementary.io)
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
    public class MainWindow : Hdy.Window {
        private Pango.FontDescription term_font;
        private Granite.Widgets.DynamicNotebook notebook;
        private Gtk.Clipboard clipboard;
        private Gtk.Clipboard primary_selection;
        private Terminal.Widgets.SearchToolbar search_toolbar;
        private Gtk.Revealer search_revealer;
        private Gtk.ToggleButton search_button;
        private Gtk.Button zoom_default_button;
        private Granite.AccelLabel open_in_browser_menuitem_label;

        private HashTable<string, TerminalWidget> restorable_terminals;
        private bool is_fullscreen = false;
        private string[] saved_tabs;
        private string[] saved_zooms;

        private const int NORMAL = 0;
        private const int MAXIMIZED = 1;
        private const int FULLSCREEN = 2;

        private const string HIGH_CONTRAST_BG = "#fff";
        private const string HIGH_CONTRAST_FG = "#333";
        private const string DARK_BG = "rgba(46, 46, 46, 0.95)";
        private const string DARK_FG = "#a5a5a5";
        private const string SOLARIZED_LIGHT_BG = "rgba(253, 246, 227, 0.95)";
        private const string SOLARIZED_LIGHT_FG = "#586e75";

        public bool unsafe_ignored;
        public bool focus_restored_tabs { get; construct; default = true; }
        public bool recreate_tabs { get; construct; default = true; }
        public bool restore_pos { get; construct; default = true; }
        public uint focus_timeout { get; private set; default = 0;}
        public Gtk.Menu menu { get; private set; }
        public Terminal.Application app { get; construct; }
        public SimpleActionGroup actions { get; construct; }
        public TerminalWidget current_terminal { get; private set; default = null; }

        public GLib.List <TerminalWidget> terminals = new GLib.List <TerminalWidget> ();

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CLOSE_TAB = "action-close-tab";
        public const string ACTION_FULLSCREEN = "action-fullscreen";
        public const string ACTION_NEW_TAB = "action-new-tab";
        public const string ACTION_DUPLICATE_TAB = "action-duplicate-tab";
        public const string ACTION_NEW_WINDOW = "action-new-window";
        public const string ACTION_NEXT_TAB = "action-next-tab";
        public const string ACTION_PREVIOUS_TAB = "action-previous-tab";
        public const string ACTION_MOVE_TAB_RIGHT = "action-move-tab-right";
        public const string ACTION_MOVE_TAB_LEFT = "action-move-tab-left";
        public const string ACTION_ZOOM_DEFAULT_FONT = "action-zoom-default-font";
        public const string ACTION_ZOOM_IN_FONT = "action-zoom-in-font";
        public const string ACTION_ZOOM_OUT_FONT = "action-zoom-out-font";
        public const string ACTION_COPY = "action-copy";
        public const string ACTION_COPY_LAST_OUTPUT = "action-copy-last-output";
        public const string ACTION_PASTE = "action-paste";
        public const string ACTION_SEARCH = "action-search";
        public const string ACTION_SEARCH_NEXT = "action-search-next";
        public const string ACTION_SEARCH_PREVIOUS = "action-search-previous";
        public const string ACTION_SELECT_ALL = "action-select-all";
        public const string ACTION_SCROLL_TO_LAST_COMMAND = "action-scroll-to-last-command";
        public const string ACTION_OPEN_IN_BROWSER = "action-open-in-browser";

        private static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const ActionEntry[] ACTION_ENTRIES = {
            { ACTION_CLOSE_TAB, action_close_tab },
            { ACTION_FULLSCREEN, action_fullscreen },
            { ACTION_NEW_TAB, action_new_tab },
            { ACTION_DUPLICATE_TAB, action_duplicate_tab },
            { ACTION_NEW_WINDOW, action_new_window },
            { ACTION_NEXT_TAB, action_next_tab },
            { ACTION_PREVIOUS_TAB, action_previous_tab },
            { ACTION_MOVE_TAB_RIGHT, action_move_tab_right},
            { ACTION_MOVE_TAB_LEFT, action_move_tab_left},
            { ACTION_ZOOM_DEFAULT_FONT, action_zoom_default_font },
            { ACTION_ZOOM_IN_FONT, action_zoom_in_font },
            { ACTION_ZOOM_OUT_FONT, action_zoom_out_font },
            { ACTION_COPY, action_copy },
            { ACTION_COPY_LAST_OUTPUT, action_copy_last_output },
            { ACTION_PASTE, action_paste },
            { ACTION_SEARCH, action_search, null, "false" },
            { ACTION_SEARCH_NEXT, action_search_next },
            { ACTION_SEARCH_PREVIOUS, action_search_previous },
            { ACTION_SELECT_ALL, action_select_all },
            { ACTION_SCROLL_TO_LAST_COMMAND, action_scroll_to_last_command },
            { ACTION_OPEN_IN_BROWSER, action_open_in_browser}
        };

        public MainWindow (Terminal.Application app, bool recreate_tabs = true) {
            Object (
                app: app,
                recreate_tabs: recreate_tabs
            );

            if (!recreate_tabs) {
                new_tab ("");
            }
        }

        public MainWindow.with_coords (Terminal.Application app, int x, int y,
                                       bool recreate_tabs, bool ensure_tab) {
            Object (
                app: app,
                restore_pos: false,
                recreate_tabs: recreate_tabs
            );

            move (x, y);

            if (!recreate_tabs && ensure_tab) {
                new_tab ("");
            }
        }

        public MainWindow.with_working_directory (Terminal.Application app, string? location,
                                                  bool recreate_tabs = true, bool create_new_tab = false) {
            Object (
                app: app,
                focus_restored_tabs: false,
                recreate_tabs: recreate_tabs
            );

            add_tab_with_working_directory (location, null, create_new_tab);
        }

        static construct {
            Hdy.init ();

            action_accelerators[ACTION_CLOSE_TAB] = "<Control><Shift>w";
            action_accelerators[ACTION_FULLSCREEN] = "F11";
            action_accelerators[ACTION_NEW_TAB] = "<Control><Shift>t";
            action_accelerators[ACTION_DUPLICATE_TAB] = "<Control><Shift>d";
            action_accelerators[ACTION_NEW_WINDOW] = "<Control><Shift>n";
            action_accelerators[ACTION_NEXT_TAB] = "<Control><Shift>Right";
            action_accelerators[ACTION_NEXT_TAB] = "<Control>Tab";
            action_accelerators[ACTION_PREVIOUS_TAB] = "<Control><Shift>Left";
            action_accelerators[ACTION_PREVIOUS_TAB] = "<Control><Shift>Tab";
            action_accelerators[ACTION_MOVE_TAB_RIGHT] = "<Control><Alt>Right";
            action_accelerators[ACTION_MOVE_TAB_LEFT] = "<Control><Alt>Left";
            action_accelerators[ACTION_ZOOM_DEFAULT_FONT] = "<Control>0";
            action_accelerators[ACTION_ZOOM_DEFAULT_FONT] = "<Control>KP_0";
            action_accelerators[ACTION_ZOOM_IN_FONT] = "<Control>plus";
            action_accelerators[ACTION_ZOOM_IN_FONT] = "<Control>equal";
            action_accelerators[ACTION_ZOOM_IN_FONT] = "<Control>KP_Add";
            action_accelerators[ACTION_ZOOM_OUT_FONT] = "<Control>minus";
            action_accelerators[ACTION_ZOOM_OUT_FONT] = "<Control>KP_Subtract";
            action_accelerators[ACTION_COPY] = "<Control><Shift>c";
            action_accelerators[ACTION_COPY_LAST_OUTPUT] = "<Alt>c";
            action_accelerators[ACTION_PASTE] = "<Control><Shift>v";
            action_accelerators[ACTION_SEARCH] = "<Control><Shift>f";
            action_accelerators[ACTION_SELECT_ALL] = "<Control><Shift>a";
            action_accelerators[ACTION_OPEN_IN_BROWSER] = "<Control><Shift>e";
            action_accelerators[ACTION_SCROLL_TO_LAST_COMMAND] = "<Alt>Up";
        }

        construct {
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            icon_name = "utilities-terminal";

            set_application (app);

            foreach (var action in action_accelerators.get_keys ()) {
                var accels_array = action_accelerators[action].to_array ();
                accels_array += null;

                app.set_accels_for_action (ACTION_PREFIX + action, accels_array);
            }

            set_visual (Gdk.Screen.get_default ().get_rgba_visual ());

            title = TerminalWidget.DEFAULT_LABEL;
            restore_saved_state (restore_pos);

            clipboard = Gtk.Clipboard.get (Gdk.Atom.intern ("CLIPBOARD", false));
            clipboard.owner_change.connect (update_context_menu);

            primary_selection = Gtk.Clipboard.get (Gdk.Atom.intern ("PRIMARY", false));

            var open_in_browser_menuitem = new Gtk.MenuItem () {
                action_name = ACTION_PREFIX + ACTION_OPEN_IN_BROWSER
            };
            open_in_browser_menuitem_label = new Granite.AccelLabel.from_action_name (
                "", open_in_browser_menuitem.action_name
            );
            open_in_browser_menuitem.add (open_in_browser_menuitem_label);

            var copy_menuitem = new Gtk.MenuItem () {
                action_name = ACTION_PREFIX + ACTION_COPY
            };
            copy_menuitem.add (new Granite.AccelLabel.from_action_name (_("Copy"), copy_menuitem.action_name));

            var copy_last_output_menuitem = new Gtk.MenuItem () {
                action_name = ACTION_PREFIX + ACTION_COPY_LAST_OUTPUT
            };
            copy_last_output_menuitem.add (
                new Granite.AccelLabel.from_action_name (_("Copy Last Output"), copy_last_output_menuitem.action_name)
            );

            var paste_menuitem = new Gtk.MenuItem () {
                action_name = ACTION_PREFIX + ACTION_PASTE
            };
            paste_menuitem.add (new Granite.AccelLabel.from_action_name (_("Paste"), paste_menuitem.action_name));

            var select_all_menuitem = new Gtk.MenuItem () {
                action_name = ACTION_PREFIX + ACTION_SELECT_ALL
            };
            select_all_menuitem.add (
                new Granite.AccelLabel.from_action_name (_("Select All"), select_all_menuitem.action_name)
            );

            var search_menuitem = new Gtk.MenuItem () {
                action_name = ACTION_PREFIX + ACTION_SEARCH
            };
            search_menuitem.add (new Granite.AccelLabel.from_action_name (_("Find…"), search_menuitem.action_name));

            menu = new Gtk.Menu ();
            menu.append (open_in_browser_menuitem);
            menu.append (new Gtk.SeparatorMenuItem ());
            menu.append (copy_menuitem);
            menu.append (copy_last_output_menuitem);
            menu.append (paste_menuitem);
            menu.append (select_all_menuitem);
            menu.append (new Gtk.SeparatorMenuItem ());
            menu.append (search_menuitem);
            menu.insert_action_group ("win", actions);

            menu.popped_up.connect (() => {
                update_copy_output_sensitive ();
            });

            setup_ui ();
            show_all ();

            search_revealer.set_reveal_child (false);

            update_font ();
            Application.settings_sys.changed["monospace-font-name"].connect (update_font);
            Application.settings.changed["font"].connect (update_font);

            set_size_request (app.minimum_width, app.minimum_height);

            configure_event.connect (on_window_state_change);
            destroy.connect (on_destroy);
            focus_in_event.connect (() => {
                if (focus_timeout == 0) {
                    focus_timeout = Timeout.add (20, () => {
                        focus_timeout = 0;
                        return Source.REMOVE;
                    });
                }

                return false;
            });

            restorable_terminals = new HashTable<string, TerminalWidget> (str_hash, str_equal);

            if (recreate_tabs) {
                open_tabs ();
            }
        }

        public void add_tab_with_command (string command, string? working_directory = null, bool create_new_tab = false) {
            add_tab_with_working_directory (working_directory, command, create_new_tab);
        }

        public void add_tab_with_working_directory (string? directory, string? command = null, bool create_new_tab = false) {
            /* This requires all restored tabs to be initialized first so that the shell location is available */
            /* Do not add a new tab if location is already open in existing tab */
            string? location = null;

            if (directory == null || directory == "") {
                if (notebook.tabs.first () == null || command != null || create_new_tab) { //Ensure at least one tab
                    new_tab ("", command);
                }

                return;
            } else {
                location = directory;
            }

            /* We can match existing tabs only if there is no command and create_new_tab == false */
            if (command == null && !create_new_tab) {
                var file = File.new_for_commandline_arg (location);
                foreach (Granite.Widgets.Tab tab in notebook.tabs) {
                    var terminal_widget = get_term_widget (tab);
                    var tab_path = terminal_widget.get_shell_location ();
                    /* Detect equialent paths */
                    if (file.equal (File.new_for_path (tab_path))) {
                        /* Just focus the duplicate tab instead */
                        notebook.current = tab;
                        terminal_widget.grab_focus ();
                        return; /* Duplicate found, abandon adding tab */
                    }
                }
            }

            new_tab (location, command);
        }

        /** Returns true if the code parameter matches the keycode of the keyval parameter for
          * any keyboard group or level (in order to allow for non-QWERTY keyboards) **/
#if VALA_0_42
        protected bool match_keycode (uint keyval, uint code) {
#else
        protected bool match_keycode (int keyval, uint code) {
#endif
            Gdk.KeymapKey [] keys;
            var keymap = Gdk.Keymap.get_for_display (get_display ());
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
            // Vte.Terminal itself registers its default styling with the APPLICATION priority:
            // https://gitlab.gnome.org/GNOME/vte/blob/0.52.2/src/vtegtk.cc#L374-377
            // To be able to overwrite their styles, we need to use +1.
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION + 1
            );

            search_button = new Gtk.ToggleButton () {
                action_name = ACTION_PREFIX + ACTION_SEARCH,
                image = new Gtk.Image.from_icon_name ("edit-find-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                valign = Gtk.Align.CENTER,
                tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>f"}, _("Find…"))
            };

            var zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU) {
                action_name = ACTION_PREFIX + ACTION_ZOOM_OUT_FONT,
                tooltip_markup = Granite.markup_accel_tooltip (
                    application.get_accels_for_action (ACTION_PREFIX + ACTION_ZOOM_OUT_FONT), _("Zoom out")
                )
            };

            zoom_default_button = new Gtk.Button.with_label ("100%") {
                action_name = ACTION_PREFIX + ACTION_ZOOM_DEFAULT_FONT,
                tooltip_markup = Granite.markup_accel_tooltip (
                    application.get_accels_for_action (ACTION_PREFIX + ACTION_ZOOM_DEFAULT_FONT),
                    _("Default zoom level")
                )
            };

            var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU) {
                action_name = ACTION_PREFIX + ACTION_ZOOM_IN_FONT,
                tooltip_markup = Granite.markup_accel_tooltip (
                    application.get_accels_for_action (ACTION_PREFIX + ACTION_ZOOM_IN_FONT), _("Zoom in")
                )
            };

            var font_size_grid = new Gtk.Grid () {
                column_homogeneous = true,
                hexpand = true,
                margin_start = 12,
                margin_end = 12,
                margin_bottom = 6
            };
            font_size_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

            font_size_grid.add (zoom_out_button);
            font_size_grid.add (zoom_default_button);
            font_size_grid.add (zoom_in_button);

            var color_button_white = new Gtk.RadioButton (null) {
                halign = Gtk.Align.CENTER,
                tooltip_text = _("High Contrast")
            };

            var color_button_white_context = color_button_white.get_style_context ();
            color_button_white_context.add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
            color_button_white_context.add_class ("color-white");

            var color_button_light = new Gtk.RadioButton.from_widget (color_button_white) {
                halign = Gtk.Align.CENTER,
                tooltip_text = _("Solarized Light")
            };

            var color_button_light_context = color_button_light.get_style_context ();
            color_button_light_context.add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
            color_button_light_context.add_class ("color-light");

            var color_button_dark = new Gtk.RadioButton.from_widget (color_button_white) {
                halign = Gtk.Align.CENTER,
                tooltip_text = _("Dark")
            };

            var color_button_dark_context = color_button_dark.get_style_context ();
            color_button_dark_context.add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
            color_button_dark_context.add_class ("color-dark");

            var color_grid = new Gtk.Grid () {
                column_homogeneous = true,
                margin_start = 12,
                margin_end = 12,
                margin_bottom = 6
            };

            color_grid.add (color_button_white);
            color_grid.add (color_button_light);
            color_grid.add (color_button_dark);

            var natural_copy_paste_button = new Granite.SwitchModelButton (_("Natural Copy/Paste")) {
                description = _("Shortcuts don’t require Shift; may interfere with CLI apps")
            };

            var menu_popover_grid = new Gtk.Grid () {
                column_spacing = 6,
                margin_bottom = 6,
                margin_top = 12,
                orientation = Gtk.Orientation.VERTICAL,
                row_spacing = 6
            };

            menu_popover_grid.add (font_size_grid);
            menu_popover_grid.add (color_grid);
            menu_popover_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            menu_popover_grid.add (natural_copy_paste_button);

            menu_popover_grid.show_all ();

            var menu_popover = new Gtk.Popover (null);
            menu_popover.add (menu_popover_grid);

            var menu_button = new Gtk.MenuButton () {
                can_focus = false,
                image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                popover = menu_popover,
                tooltip_text = _("Settings"),
                valign = Gtk.Align.CENTER
            };

            var header = new Hdy.HeaderBar () {
                show_close_button = true,
                has_subtitle = false
            };
            header.pack_end (menu_button);
            header.pack_end (search_button);

            unowned Gtk.StyleContext header_context = header.get_style_context ();
            header_context.add_class ("default-decoration");

            search_toolbar = new Terminal.Widgets.SearchToolbar (this);

            search_revealer = new Gtk.Revealer ();
            search_revealer.set_transition_type (Gtk.RevealerTransitionType.SLIDE_DOWN);
            search_revealer.add (search_toolbar);

            get_simple_action (ACTION_COPY).set_enabled (false);
            get_simple_action (ACTION_COPY_LAST_OUTPUT).set_enabled (false);
            get_simple_action (ACTION_SCROLL_TO_LAST_COMMAND).set_enabled (false);


            notebook = new Granite.Widgets.DynamicNotebook.with_accellabels (
                new Granite.AccelLabel.from_action_name (_("New Tab"), ACTION_PREFIX + ACTION_NEW_TAB)
            ) {
                allow_new_window = true,
                allow_duplication = true,
                allow_restoring = Application.settings.get_boolean ("save-exited-tabs"),
                max_restorable_tabs = 5,
                group_name = "pantheon-terminal",
                can_focus = false,
                expand = true
            };
            notebook.tab_added.connect (on_tab_added);
            notebook.tab_removed.connect (on_tab_removed);
            notebook.tab_switched.connect (on_switch_page);
            notebook.tab_moved.connect (on_tab_moved);
            notebook.tab_reordered.connect (on_tab_reordered);
            notebook.tab_restored.connect (on_tab_restored);
            notebook.tab_duplicated.connect (on_tab_duplicated);
            notebook.close_tab_requested.connect (on_close_tab_requested);
            notebook.new_tab_requested.connect (on_new_tab_requested);
            var tab_bar_behavior = Application.settings.get_enum ("tab-bar-behavior");
            notebook.tab_bar_behavior = (Granite.Widgets.DynamicNotebook.TabBarBehavior)tab_bar_behavior;

            var grid = new Gtk.Grid ();
            grid.attach (header, 0, 0);
            grid.attach (search_revealer, 0, 1);
            grid.attach (notebook, 0, 2);

            get_style_context ().add_class ("terminal-window");
            add (grid);

            menu_popover.closed.connect (() => {
                var binding = menu_popover.get_data<Binding> ("zoom-binding");
                binding.unref ();
                current_terminal.grab_focus ();
            });

            menu_button.clicked.connect (() => {
                zoom_default_button.label = font_scale_to_zoom (current_terminal.font_scale);
                var binding = current_terminal.bind_property (
                    "font-scale",
                    zoom_default_button,
                    "label",
                    BindingFlags.DEFAULT,

                    (binding, from_val, ref to_val) => {
                        to_val.set_string (font_scale_to_zoom (from_val.get_double ()));
                        return true;
                    }
                );

                menu_popover.set_data<Binding> ("zoom-binding", binding);
            });

            switch (Application.settings.get_string ("background")) {
                case HIGH_CONTRAST_BG:
                    color_button_white.active = true;
                    break;
                case SOLARIZED_LIGHT_BG:
                    color_button_light.active = true;
                    break;
                case DARK_BG:
                    color_button_dark.active = true;
                    break;
            }

            color_button_dark.clicked.connect (() => {
                Application.settings.set_boolean ("prefer-dark-style", true);
                Application.settings.set_string ("background", DARK_BG);
                Application.settings.set_string ("foreground", DARK_FG);
            });

            color_button_light.clicked.connect (() => {
                Application.settings.set_boolean ("prefer-dark-style", false);
                Application.settings.set_string ("background", SOLARIZED_LIGHT_BG);
                Application.settings.set_string ("foreground", SOLARIZED_LIGHT_FG);
            });

            color_button_white.clicked.connect (() => {
                Application.settings.set_boolean ("prefer-dark-style", false);
                Application.settings.set_string ("background", HIGH_CONTRAST_BG);
                Application.settings.set_string ("foreground", HIGH_CONTRAST_FG);
            });

            Application.settings.bind (
                "natural-copy-paste",
                natural_copy_paste_button,
                "active",
                SettingsBindFlags.DEFAULT
            );

            bind_property ("title", header, "title", GLib.BindingFlags.SYNC_CREATE);

            key_press_event.connect ((event) => {
                if (event.is_modifier == 1) {
                    return false;
                }

                switch (event.keyval) {
                    case Gdk.Key.Escape:
                        if (search_toolbar.search_entry.has_focus) {
                            search_button.active = !search_button.active;
                            return true;
                        }
                        break;
                    case Gdk.Key.Return:
                        if (search_toolbar.search_entry.has_focus) {
                            if (Gdk.ModifierType.SHIFT_MASK in event.state) {
                                search_toolbar.previous_search ();
                            } else {
                                search_toolbar.next_search ();
                            }
                            return true;
                        } else {
                            current_terminal.remember_position ();
                            get_simple_action (ACTION_SCROLL_TO_LAST_COMMAND).set_enabled (true);
                            current_terminal.remember_command_end_position ();
                            get_simple_action (ACTION_COPY_LAST_OUTPUT).set_enabled (false);
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
                        if (Gdk.ModifierType.MOD1_MASK in event.state &&
                            Application.settings.get_boolean ("alt-changes-tab")) {
                            var i = event.keyval - 49;
                            if (i > notebook.n_tabs - 1)
                                return false;
                            notebook.current = notebook.get_tab_by_index ((int) i);
                            return true;
                        }
                        break;
                    case Gdk.Key.@9:
                        if (Gdk.ModifierType.MOD1_MASK in event.state &&
                            Application.settings.get_boolean ("alt-changes-tab")) {
                            notebook.current = notebook.get_tab_by_index (notebook.n_tabs - 1);
                            return true;
                        }
                        break;

                    case Gdk.Key.Up:
                    case Gdk.Key.Down:
                        current_terminal.remember_command_start_position ();
                        break;
                    case Gdk.Key.Menu:
                        /* Popup context menu below cursor position */
                        long col, row;
                        current_terminal.get_cursor_position (out col, out row);
                        var cell_width = current_terminal.get_char_width ();
                        var cell_height = current_terminal.get_char_height ();
                        var rect_window = current_terminal.get_window ();
                        var vadj_val = current_terminal.get_vadjustment ().get_value ();

                        Gdk.Rectangle rect = {(int)(col * cell_width),
                                              (int)((row - vadj_val) * cell_height),
                                              (int)cell_width,
                                              (int)cell_height};

                        menu.popup_at_rect (rect_window,
                                            rect,
                                            Gdk.Gravity.SOUTH_WEST,
                                            Gdk.Gravity.NORTH_WEST,
                                            event);
                        menu.select_first (false);
                        break;
                    default:
                        if (!(Gtk.accelerator_get_default_mod_mask () in event.state)) {
                            current_terminal.remember_command_start_position ();
                        }

                        break;
                }

                /* Use hardware keycodes so the key used
                 * is unaffected by internationalized layout */
                if (Gdk.ModifierType.CONTROL_MASK in event.state &&
                    Application.settings.get_boolean ("natural-copy-paste")) {
                    uint keycode = event.hardware_keycode;
                    if (match_keycode (Gdk.Key.c, keycode)) {
                        if (current_terminal.get_has_selection ()) {
                            current_terminal.copy_clipboard ();
                            if (!(Gdk.ModifierType.SHIFT_MASK in event.state)) { /* Shift not pressed */
                                current_terminal.unselect_all ();
                            }
                            return true;
                        } else { /* Ctrl-c: Command cancelled */
                            current_terminal.last_key_was_return = true;
                        }
                    } else if (match_keycode (Gdk.Key.v, keycode)) {
                        return handle_paste_event ();
                    }
                }

                if (Gdk.ModifierType.MOD1_MASK in event.state) {
                    uint keycode = event.hardware_keycode;

                    if (event.keyval == Gdk.Key.Up) {
                        return !get_simple_action (ACTION_SCROLL_TO_LAST_COMMAND).enabled;
                    }

                    if (match_keycode (Gdk.Key.c, keycode)) { /* Alt-c */
                        update_copy_output_sensitive ();
                    }
                }

                return false;
            });
        }

        private bool handle_paste_event () {
            if (search_toolbar.search_entry.has_focus) {
                return false;
            } else if (clipboard.wait_is_text_available ()) {
                action_paste ();
                return true;
            }

            return false;
        }

        private void restore_saved_state (bool restore_pos = true) {
            if (Granite.Services.System.history_is_enabled () &&
                Application.settings.get_boolean ("remember-tabs")) {

                saved_tabs = Terminal.Application.saved_state.get_strv ("tabs");
                saved_zooms = Terminal.Application.saved_state.get_strv ("tab-zooms");
            } else {
                saved_tabs = {};
                saved_zooms = {};
            }

            var rect = Gdk.Rectangle ();
            Terminal.Application.saved_state.get ("window-size", "(ii)", out rect.width, out rect.height);

            default_width = rect.width;
            default_height = rect.height;

            if (default_width == -1 || default_height == -1) {
                var geometry = get_display ().get_primary_monitor ().get_geometry ();

                default_width = geometry.width * 2 / 3;
                default_height = geometry.height * 3 / 4;
            }

            if (restore_pos) {
                Terminal.Application.saved_state.get ("window-position", "(ii)", out rect.x, out rect.y);

                if (rect.x != -1 || rect.y != -1) {
                    move (rect.x, rect.y);
                }
            }

            var window_state = Terminal.Application.saved_state.get_enum ("window-state");
            if (window_state == MainWindow.MAXIMIZED) {
                maximize ();
            } else if (window_state == MainWindow.FULLSCREEN) {
                fullscreen ();
                is_fullscreen = true;
            }
        }

        private void on_tab_added (Granite.Widgets.Tab tab) {
            var terminal_widget = get_term_widget (tab);
            terminals.append (terminal_widget);
            terminal_widget.window = this;
        }

        private void on_tab_removed (Granite.Widgets.Tab tab) {
            var terminal_widget = get_term_widget (tab);
            terminals.remove (terminal_widget);

            if (notebook.n_tabs == 0) {
                destroy ();
            }
        }

        private bool on_close_tab_requested (Granite.Widgets.Tab tab) {
            var terminal_widget = get_term_widget (tab);

            if (terminal_widget.has_foreground_process ()) {
                var dialog = new ForegroundProcessDialog (this);
                if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                    dialog.destroy ();
                    terminal_widget.kill_fg ();
                } else {
                    dialog.destroy ();

                    return false;
                }
            }

            if (!terminal_widget.child_has_exited) {
                if (notebook.n_tabs >= 2 && Application.settings.get_boolean ("save-exited-tabs")) {
                    make_restorable (tab);
                } else {
                    terminal_widget.term_ps ();
                }
            }

            current_terminal.grab_focus ();
            if (terminal_widget != current_terminal) { // Otherwise current_terminal will change triggering a name check
                check_for_tabs_with_same_name ();
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
            check_for_tabs_with_same_name ();
        }

        private void on_tab_moved (Granite.Widgets.Tab tab, int x, int y) {
            Idle.add (() => {
                var new_window = new MainWindow.with_coords (
                    app,
                    x,
                    y,
                    false,
                    false
                );

                var terminal_widget = get_term_widget (tab);
                var new_notebook = new_window.notebook;

                notebook.remove_tab (tab);
                new_notebook.insert_tab (tab, -1);
                new_window.current_terminal = terminal_widget;
                check_for_tabs_with_same_name (); // Update remaining tabs
                return false;
            });
        }

        private void on_tab_duplicated (Granite.Widgets.Tab tab) {
            var terminal_widget = get_term_widget (tab);
            new_tab (terminal_widget.get_shell_location ());
        }

        private void on_new_tab_requested () {
            if (Application.settings.get_boolean ("follow-last-tab")) {
                new_tab (current_terminal.get_shell_location ());
            } else {
                new_tab (Environment.get_home_dir ());
            }
        }

        public void update_context_menu () {
            /* Update the "Paste" menu option */
            clipboard.request_targets (update_context_menu_cb);

            /* Update the "Show in ..." menu option */
            get_current_selection_link_or_pwd ((clipboard, uri) => {
                update_menu_label (Utils.sanitize_path (uri, current_terminal.get_shell_location ()));
            });
        }

        private void update_menu_label (string? uri) {
            AppInfo? appinfo = get_default_app_for_uri (uri);

            get_simple_action (ACTION_OPEN_IN_BROWSER).set_enabled (appinfo != null);
            open_in_browser_menuitem_label.label = _("Show in %s").printf (
                appinfo != null ? appinfo.get_display_name () : _("Default application")
            );
        }

        private AppInfo? get_default_app_for_uri (string? uri) {
            if (uri == null) {
                return null;
            }

            AppInfo? appinfo = null;
            var scheme = Uri.parse_scheme (uri);
            if (scheme != null) {
                appinfo = AppInfo.get_default_for_uri_scheme (scheme);
            }

            if (appinfo == null) {
                bool uncertain;
                /* Guess content type from filename if possible */
                //TODO Get content type from actual file (if exists)
                var ctype = ContentType.guess (uri, null, out uncertain);
                if (!uncertain) {
                    appinfo = AppInfo.get_default_for_type (ctype, true);
                }

                if (appinfo == null) {
                    var file = File.new_for_uri (uri);
                    try {
                        var info = file.query_info (FileAttribute.STANDARD_CONTENT_TYPE,
                                                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);

                        if (info.has_attribute (FileAttribute.STANDARD_CONTENT_TYPE)) {
                            appinfo = AppInfo.get_default_for_type (
                                        info.get_attribute_string (FileAttribute.STANDARD_CONTENT_TYPE), true);
                        }
                    } catch (Error e) {
                        warning ("Could not get file info %s", e.message);
                    }
                }
            }

            return appinfo;
        }

        private void update_context_menu_cb (Gtk.Clipboard clipboard_, Gdk.Atom[]? atoms) {
            bool can_paste = false;

            if (atoms != null && atoms.length > 0) {
                can_paste = Gtk.targets_include_text (atoms) || Gtk.targets_include_uri (atoms);
            }

            get_simple_action (ACTION_PASTE).set_enabled (can_paste);
        }

        private void update_copy_output_sensitive () {
            get_simple_action (ACTION_COPY_LAST_OUTPUT).set_enabled (current_terminal.has_output ());
        }

        private uint timer_window_state_change = 0;
        private bool on_window_state_change (Gdk.EventConfigure event) {
            // triggered when the size, position or stacking of the window has changed
            // it is delayed 400ms to prevent spamming gsettings
            if (timer_window_state_change > 0)
                GLib.Source.remove (timer_window_state_change);

            timer_window_state_change = GLib.Timeout.add (400, () => {
                timer_window_state_change = 0;
                if (get_window () == null)
                    return false;

                /* Check for fullscreen first: https://github.com/elementary/terminal/issues/377 */
                if ((get_window ().get_state () & Gdk.WindowState.FULLSCREEN) != 0) {
                    Terminal.Application.saved_state.set_enum ("window-state", MainWindow.FULLSCREEN);
                } else if (is_maximized) {
                    Terminal.Application.saved_state.set_enum ("window-state", MainWindow.MAXIMIZED);
                } else {
                    Terminal.Application.saved_state.set_enum ("window-state", MainWindow.NORMAL);

                    var rect = Gdk.Rectangle ();
                    get_size (out rect.width, out rect.height);
                    Terminal.Application.saved_state.set ("window-size", "(ii)", rect.width, rect.height);

                    int root_x, root_y;
                    get_position (out root_x, out root_y);
                    Terminal.Application.saved_state.set ("window-position", "(ii)", root_x, root_y);
                }

                return false;
            });

            return base.configure_event (event);
        }

        private void on_switch_page (Granite.Widgets.Tab? old,
                                     Granite.Widgets.Tab new_tab) {

            current_terminal = get_term_widget (new_tab);
            /* The font-scales of all terminals are currently the synchronized through saved-state binding */
            new_tab.icon = null;
            Idle.add (() => {
                get_term_widget (new_tab).grab_focus ();
                update_copy_output_sensitive ();
                title = current_terminal.current_working_directory;
                if (Granite.Services.System.history_is_enabled () &&
                    Application.settings.get_boolean ("remember-tabs")) {

                    Terminal.Application.saved_state.set_int (
                        "focused-tab",
                        notebook.get_tab_position (new_tab)
                    );
                }

                return false;
            });
        }

        private void open_tabs () {
            string[] tabs = {};
            double[] zooms = {};
            int focus = 0;
            var default_zoom = Application.saved_state.get_double ("zoom"); //Range set in settings 0.25 - 4.0

            if (Granite.Services.System.history_is_enabled () &&
                Application.settings.get_boolean ("remember-tabs")) {

                tabs = saved_tabs;
                var n_tabs = tabs.length;

                foreach (string zoom_s in saved_zooms) {
                    var zoom = double.parse (zoom_s);

                    if (zooms.length < n_tabs) {
                        zooms += zoom;
                    } else {
                        break;
                    }
                }

                while (zooms.length < n_tabs) {
                    zooms += default_zoom;
                }

                if (tabs.length == 0) {
                    tabs += Environment.get_home_dir ();
                    zooms += default_zoom;
                }

                focus = Terminal.Application.saved_state.get_int ("focused-tab");
            } else {
                tabs += Terminal.Application.working_directory ?? Environment.get_current_dir ();
                zooms += default_zoom;
            }


            assert (zooms.length == tabs.length);

            int null_dirs = 0;
            for (int i = 0; i < tabs.length; i++) {
                File file = File.new_for_path (tabs[i]);

                if (file.query_exists () == false) {
                    null_dirs++;
                    tabs[i] = "";
                }

                if (null_dirs == tabs.length) {
                    tabs[0] = Terminal.Application.working_directory ?? Environment.get_current_dir ();
                }
            }

            Terminal.Application.saved_state.set_strv ("tabs", {});

            focus = focus.clamp (0, tabs.length - 1);

            /* This must not be in an Idle loop to avoid duplicate tabs being opened (issue #245) */
            focus += notebook.n_tabs;
            int index = 0;
            foreach (string loc in tabs) {
                if (loc == "") {
                    focus--;
                } else {
                    var term = new_tab (loc, null, false);
                    term.font_scale = zooms[index].clamp (
                        TerminalWidget.MIN_SCALE,
                        TerminalWidget.MAX_SCALE
                    );
                }

                index++;
            }

            if (focus_restored_tabs) {
                var tab = notebook.get_tab_by_index (focus.clamp (0, notebook.n_tabs - 1));
                notebook.current = tab;
                get_term_widget (tab).grab_focus ();
            }
        }

        private TerminalWidget new_tab (string location, string? program = null, bool focus = true) {
            /*
             * If the user choose to use a specific working directory.
             * Reassigning the directory variable a new value
             * leads to free'd memory being read.
             */

            /* Set up terminal */
            var terminal_widget = new TerminalWidget (this) {
                scrollback_lines = Application.settings.get_int ("scrollback-lines"),
                /* Make the terminal occupy the whole GUI */
                expand = true
            };



            var tab = create_tab (
                location != null ? Path.get_basename (location) : TerminalWidget.DEFAULT_LABEL,
                null, terminal_widget); //Set correct label now to avoid race when spawning shell

            terminal_widget.child_exited.connect (() => {
                if (!terminal_widget.killed) {
                    if (program != null) {
                        /* If a program was running, do not close the tab so that output of program
                         * remains visible */
                        terminal_widget.active_shell (location);
                        /* Allow closing tab with "exit" */
                        program = null;
                    } else {
                        terminal_widget.tab.close ();
                        return;
                    }
                }
            });

            terminal_widget.cwd_changed.connect (check_for_tabs_with_same_name);

            terminal_widget.set_font (term_font);

            if (current_terminal != null) {
                terminal_widget.font_scale = current_terminal.font_scale;
            } else {
                terminal_widget.font_scale = Terminal.Application.saved_state.get_double ("zoom");
            }

            int minimum_width = terminal_widget.calculate_width (80) / 2;
            int minimum_height = terminal_widget.calculate_height (24) / 2;
            set_size_request (minimum_width, minimum_height);
            app.minimum_width = minimum_width;
            app.minimum_height = minimum_height;

            Gdk.Geometry hints = Gdk.Geometry ();
            hints.width_inc = (int) terminal_widget.get_char_width ();
            hints.height_inc = (int) terminal_widget.get_char_height ();
            set_geometry_hints (this, hints, Gdk.WindowHints.RESIZE_INC);

            notebook.insert_tab (tab, -1);

            if (focus) {
                notebook.current = tab;
                terminal_widget.grab_focus ();
            }

            if (program == null) {
                /* Set up the virtual terminal */
                if (location == "") {
                    terminal_widget.active_shell ();
                } else {
                    terminal_widget.active_shell (location);
                }
            } else {
                terminal_widget.run_program (program, location);
            }

            return terminal_widget;
        }

        private Granite.Widgets.Tab create_tab (string label, GLib.Icon? icon, TerminalWidget term) {
            var sw = new Gtk.ScrolledWindow (null, term.get_vadjustment ());
            sw.add (term);
            var tab = new Granite.Widgets.Tab.with_accellabels (
                label,
                icon,
                sw,
                new Granite.AccelLabel.from_action_name (_("Close Tab"), ACTION_PREFIX + ACTION_CLOSE_TAB),
                new Granite.AccelLabel.from_action_name (_("Duplicate"), ACTION_PREFIX + ACTION_DUPLICATE_TAB)
            );
            term.tab = tab;
            /* We have to rewrite the tooltip everytime the label changes to override Granite annoying habit of
             * automatically changing the tooltip to be the same as the label. */
            term.tab.notify["label"].connect_after (() => {
                term.tab.tooltip = term.current_working_directory;
            });
            tab.ellipsize_mode = Pango.EllipsizeMode.MIDDLE;

            var reload_menu_item = new Gtk.MenuItem.with_label (_("Reload"));
            tab.menu.append (reload_menu_item);
            reload_menu_item.activate.connect (term.reload);
            tab.menu.show_all ();

            return tab;
        }

        private void make_restorable (Granite.Widgets.Tab tab) {
            var term = get_term_widget (tab);
            terminals.remove (term);
            restorable_terminals.insert (term.terminal_id, term);
            tab.restore_data = term.terminal_id;

            ((Gtk.Container)tab.page).remove (term);

            tab.dropped_callback = (() => {
                unowned TerminalWidget terminal_widget = restorable_terminals.get (tab.restore_data);
                terminal_widget.term_ps ();
                restorable_terminals.remove (tab.restore_data);
            });
        }

        private void update_font () {
            // We have to fetch both values at least once, otherwise
            // GLib.Settings won't notify on their changes
            var app_font_name = Application.settings.get_string ("font");
            var sys_font_name = Application.settings_sys.get_string ("monospace-font-name");

            if (app_font_name != "") {
                term_font = Pango.FontDescription.from_string (app_font_name);
            } else {
                term_font = Pango.FontDescription.from_string (sys_font_name);
            }

            foreach (var terminal in terminals) {
                terminal.set_font (term_font);
            }
        }

        protected override bool delete_event (Gdk.EventAny event) {
            save_opened_terminals ();
            var tabs_to_terminate = new GLib.List <TerminalWidget> ();

            foreach (var terminal_widget in terminals) {
                terminal_widget = (TerminalWidget) terminal_widget;
                if (terminal_widget.has_foreground_process ()) {
                    var dialog = new ForegroundProcessDialog.before_close (this);
                    if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                        terminal_widget.kill_fg ();
                        dialog.destroy ();
                    } else {
                        dialog.destroy ();
                        return true;
                    }
                }

                tabs_to_terminate.append (terminal_widget);
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

        private void on_get_text (Gtk.Clipboard board, string? intext) {
            if (Application.settings.get_boolean ("unsafe-paste-alert") && !unsafe_ignored ) {

                if (intext == null) {
                    return;
                }

                if (!intext.validate ()) {
                    warning ("Dropping invalid UTF-8 paste");
                    return;
                }

                var text = intext.strip ();

                string? unsafe_warning = null;

                if ((text.index_of ("sudo") > -1) && (text.index_of ("\n") != 0)) {
                    unsafe_warning = _("The pasted text may be trying to gain administrative access");
                } else if (text.index_of ("\n") != -1) {
                    unsafe_warning = _("The pasted text may contain multiple commands");
                }

                if (unsafe_warning != null) {
                    var unsafe_paste_dialog = new UnsafePasteDialog (
                        this,
                        unsafe_warning,
                        text
                    );

                    if (unsafe_paste_dialog.run () != Gtk.ResponseType.ACCEPT) {
                        unsafe_paste_dialog.destroy ();
                        return;
                    }

                    unsafe_paste_dialog.destroy ();
                }
            }

            current_terminal.remember_command_start_position ();

            if (board == primary_selection) {
                current_terminal.paste_primary ();
            } else {
                current_terminal.paste_clipboard ();
            }
        }

        private void action_copy () {
            if (current_terminal.link_uri != null && ! current_terminal.get_has_selection ())
                clipboard.set_text (current_terminal.link_uri,
                                    current_terminal.link_uri.length);
            else
                current_terminal.copy_clipboard ();
        }

        private void action_copy_last_output () {
            string output = current_terminal.get_last_output ();
            Gtk.Clipboard.get_default (Gdk.Display.get_default ()).set_text (output, output.length);
        }

        private void action_paste () {
            clipboard.request_text (on_get_text);
        }

        private void action_select_all () {
            current_terminal.select_all ();
        }

        private void action_open_in_browser () {
            get_current_selection_link_or_pwd ((clipboard, uri) => {
                string? to_open = Utils.sanitize_path (uri, current_terminal.get_shell_location ());
                if (to_open != null) {
                    try {
                        Gtk.show_uri_on_window (null, to_open, Gtk.get_current_event_time ());
                    } catch (GLib.Error error) {
                        warning ("Could not show %s - %s", to_open, error.message);
                    }
                }
            });
        }

        private void get_current_selection_link_or_pwd (Gtk.ClipboardTextReceivedFunc uri_handler) {
            var link_uri = current_terminal.link_uri;
            if (link_uri == null) {
                if (current_terminal.get_has_selection ()) {
                    current_terminal.copy_primary ();
                    primary_selection.request_text (uri_handler);
                } else {
                    uri_handler (primary_selection, current_terminal.get_shell_location ());
                }
            } else {
                if (!link_uri.contains ("://")) {
                    link_uri = "http://" + link_uri;
                }

                uri_handler (primary_selection, link_uri);
            }
        }

        private void action_scroll_to_last_command () {
            current_terminal.scroll_to_last_command ();
            /* Repeated presses are ignored */
            get_simple_action (ACTION_SCROLL_TO_LAST_COMMAND).set_enabled (false);
        }

        private void action_close_tab () {
            current_terminal.tab.close ();
            current_terminal.grab_focus ();
            // Closing a tab will switch to another, which will trigger check for same names
        }

        private void action_new_window () {
            app.new_window ();
        }

        private void action_new_tab () {
            if (Application.settings.get_boolean ("follow-last-tab")) {
                new_tab (current_terminal.get_shell_location ());
            } else {
                new_tab (Environment.get_home_dir ());
            }
        }

        private void action_duplicate_tab () {
            new_tab (current_terminal.get_shell_location ());
        }

        private void action_zoom_in_font () {
            current_terminal.increment_size ();
        }

        private void action_zoom_out_font () {
            current_terminal.decrement_size ();
        }

        private void action_zoom_default_font () {
            current_terminal.set_default_font_size ();
        }

        private void action_next_tab () {
            notebook.next_page ();
        }

        private void action_previous_tab () {
            notebook.previous_page ();
        }

        void action_move_tab_right () {
            notebook.set_tab_position (notebook.current, (notebook.get_tab_position (notebook.current) + 1) % notebook.n_tabs);
        }

        void action_move_tab_left () {
            notebook.set_tab_position (notebook.current, (notebook.get_tab_position (notebook.current) - 1) % notebook.n_tabs);
        }

        private void action_search () {
            var search_action = (SimpleAction) actions.lookup_action (ACTION_SEARCH);
            var search_state = search_action.get_state ().get_boolean ();

            search_action.set_state (!search_state);
            search_revealer.set_reveal_child (search_button.active);

            if (search_button.active) {
                action_accelerators[ACTION_SEARCH_NEXT] = "<Control>g";
                action_accelerators[ACTION_SEARCH_NEXT] = "<Control>Down";
                action_accelerators[ACTION_SEARCH_PREVIOUS] = "<Control><Shift>g";
                action_accelerators[ACTION_SEARCH_PREVIOUS] = "<Control>Up";
                search_button.tooltip_markup = Granite.markup_accel_tooltip (
                    {"Escape", "<Ctrl><Shift>f"},
                    _("Hide find bar")
                );
                search_toolbar.grab_focus ();
            } else {
                action_accelerators.remove_all (ACTION_SEARCH_NEXT);
                action_accelerators.remove_all (ACTION_SEARCH_PREVIOUS);
                search_button.tooltip_markup = Granite.markup_accel_tooltip (
                    {"<Ctrl><Shift>f"},
                    _("Find…")
                );
                search_toolbar.clear ();
                current_terminal.grab_focus ();
            }

            string [] next_accels = new string [] {};
            if (!action_accelerators[ACTION_SEARCH_NEXT].is_empty) {
                next_accels = action_accelerators[ACTION_SEARCH_NEXT].to_array ();
            }

            string [] prev_accels = new string [] {};
            if (!action_accelerators[ACTION_SEARCH_NEXT].is_empty) {
                prev_accels = action_accelerators[ACTION_SEARCH_PREVIOUS].to_array ();
            }

            app.set_accels_for_action (
                ACTION_PREFIX + ACTION_SEARCH_NEXT,
                next_accels
            );
            app.set_accels_for_action (
                ACTION_PREFIX + ACTION_SEARCH_PREVIOUS,
                prev_accels
            );
        }

        private void action_search_next () {
            if (search_button.active) {
                search_toolbar.next_search ();
            }
        }

        private void action_search_previous () {
            if (search_button.active) {
                search_toolbar.previous_search ();
            }
        }

        private void action_fullscreen () {
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

        /** Compare every tab label with every other and resolve ambiguities **/
        private void check_for_tabs_with_same_name () {
            /* Take list copies so foreach clauses can be nested safely*/
            var terms = terminals.copy ();
            var terms2 = terminals.copy ();

            foreach (TerminalWidget terminal in terms) {
                string term_path = terminal.current_working_directory;
                string term_label = Path.get_basename (term_path);

                if (term_label == "" ||
                    terminal.tab_label == TerminalWidget.DEFAULT_LABEL) {

                    continue;
                }

                /* Reset tab_name to basename so long name only used when required */
                terminal.tab_label = term_label;

                foreach (TerminalWidget terminal2 in terms2) {
                    string term2_path = terminal2.current_working_directory;
                    string term2_name = Path.get_basename (term2_path);

                    if (terminal2 != terminal && term2_name == term_label && term2_path != term_path) {
                        terminal2.tab_label = disambiguate_label (term2_path, term_path);
                        terminal.tab_label = disambiguate_label (term_path, term2_path);
                        // Overwrite tooltip_text set by changing tab_label
                        terminal2.tooltip_text = term2_path;
                        terminal.tooltip_text = term_path;

                    }
                }
            }

            title = current_terminal.current_working_directory;
            return;
        }

        private void save_opened_terminals () {
            string[] opened_tabs = {};
            string[] zooms = {};

            Application.saved_state.set_double ("zoom", current_terminal.font_scale);

            if (Granite.Services.System.history_is_enabled () &&
                Application.settings.get_boolean ("remember-tabs")) {

                notebook.tabs.foreach ((tab) => {
                    var term = get_term_widget (tab);
                    if (term != null) {
                        var location = term.get_shell_location ();
                        if (location != null && location != "") {
                            opened_tabs += location;
                            zooms += ("%.1f").printf (term.font_scale);
                        }
                    }
                });
            }

            Terminal.Application.saved_state.set_strv (
                "tabs",
                opened_tabs
            );

            Terminal.Application.saved_state.set_strv (
                "tab-zooms",
                zooms
            );

            Terminal.Application.saved_state.set_int (
                "focused-tab",
                notebook.get_tab_position (notebook.current)
            );
        }

        /** Return enough of @path to distinguish it from @conflict_path **/
        private string disambiguate_label (string path, string conflict_path) {
            string prefix = "";
            string conflict_prefix = "";
            string temp_path = path;
            string temp_conflict_path = conflict_path;
            string basename = Path.get_basename (path);

            if (basename != Path.get_basename (conflict_path)) {
                return basename;
            }

            /* Add parent directories until path and conflict path differ */
            while (prefix == conflict_prefix) {
                var parent_temp_path = Utils.get_parent_path_from_path (temp_path);
                var parent_temp_confict_path = Utils.get_parent_path_from_path (temp_conflict_path);
                prefix = Path.get_basename (parent_temp_path) + Path.DIR_SEPARATOR_S + prefix;
                conflict_prefix = Path.get_basename (parent_temp_confict_path) + Path.DIR_SEPARATOR_S + conflict_prefix;
                temp_path = parent_temp_path;
                temp_conflict_path = parent_temp_confict_path;
            }

            return (prefix + basename).replace ("//", "/");
        }

        public GLib.SimpleAction? get_simple_action (string action) {
            return actions.lookup_action (action) as GLib.SimpleAction;
        }

        private string font_scale_to_zoom (double font_scale) {
            return ("%.0f%%").printf (font_scale * 100);
        }
    }
}

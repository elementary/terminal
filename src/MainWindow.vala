/*
* Copyright (c) 2011-2022 elementary, Inc. (https://elementary.io)
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
        private Hdy.HeaderBar header;
        public TerminalView notebook { get; private set construct; }
        private Gtk.Clipboard clipboard;
        private Gtk.Clipboard primary_selection;
        private Terminal.Widgets.SearchToolbar search_toolbar;
        private Gtk.Label title_label;
        private Gtk.Stack title_stack;
        private Gtk.ToggleButton search_button;
        private Widgets.ZoomOverlay zoom_overlay;
        private Dialogs.ColorPreferences? color_preferences_dialog;
        private MenuItem open_in_browser_menuitem;

        private bool is_fullscreen {
            get {
                return header.decoration_layout_set;
            }

            set {
                if (value) {
                    fullscreen ();
                    header.decoration_layout_set = true;
                } else {
                    unfullscreen ();
                    header.decoration_layout_set = false;
                }
            }
        }

        private Gtk.EventControllerKey key_controller;
        private uint timer_window_state_change = 0;
        private uint focus_timeout = 0;

        private const int NORMAL = 0;
        private const int MAXIMIZED = 1;
        private const int FULLSCREEN = 2;

        public bool unsafe_ignored;
        public bool focus_restored_tabs { get; construct; default = true; }
        public bool recreate_tabs { get; construct; default = true; }
        public Menu context_menu_model { get; private set; }
        public Terminal.Application app { get; construct; }
        public SimpleActionGroup actions { get; construct; }

        public TerminalWidget? current_terminal { get; private set; default = null; }

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CLOSE_TAB = "action-close-tab";
        public const string ACTION_CLOSE_TABS_TO_RIGHT = "action_close_tabs_to_right";
        public const string ACTION_CLOSE_OTHER_TABS = "action_close_other_tabs";
        public const string ACTION_FULLSCREEN = "action-fullscreen";
        public const string ACTION_NEW_TAB = "action-term_widgetnew-tab";
        public const string ACTION_NEW_TAB_AT = "action-new-tab-at";
        public const string ACTION_TAB_ACTIVE_SHELL = "action-tab_active_shell";
        public const string ACTION_TAB_RELOAD = "action-tab_reload";
        public const string ACTION_RESTORE_CLOSED_TAB = "action-restore-closed-tab";
        public const string ACTION_DUPLICATE_TAB = "action-duplicate-tab";
        public const string ACTION_NEXT_TAB = "action-next-tab";
        public const string ACTION_PREVIOUS_TAB = "action-previous-tab";
        public const string ACTION_MOVE_TAB_RIGHT = "action-move-tab-right";
        public const string ACTION_MOVE_TAB_LEFT = "action-move-tab-left";
        public const string ACTION_MOVE_TAB_TO_NEW_WINDOW = "action-move-tab-to-new-window";
        public const string ACTION_SEARCH = "action-search";
        public const string ACTION_SEARCH_ACCEL = "<Control><Shift>f";
        public const string ACTION_SEARCH_NEXT = "action-search-next";
        public const string ACTION_SEARCH_PREVIOUS = "action-search-previous";
        public const string ACTION_OPEN_IN_BROWSER = "action-open-in-browser";
        public const string ACTION_OPEN_IN_BROWSER_ACCEL = "<Control><Shift>e";


        private static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        private const ActionEntry[] ACTION_ENTRIES = {
            { ACTION_CLOSE_TAB, action_close_tab },
            { ACTION_CLOSE_TABS_TO_RIGHT, action_close_tabs_to_right },
            { ACTION_CLOSE_OTHER_TABS, action_close_other_tabs },
            { ACTION_FULLSCREEN, action_fullscreen },
            { ACTION_NEW_TAB, action_new_tab },
            { ACTION_NEW_TAB_AT, action_new_tab_at, "s" },
            { ACTION_TAB_RELOAD, action_tab_reload},
            { ACTION_TAB_ACTIVE_SHELL, action_tab_active_shell, "s" },
            { ACTION_RESTORE_CLOSED_TAB, action_restore_closed_tab, "s" },
            { ACTION_DUPLICATE_TAB, action_duplicate_tab },
            { ACTION_NEXT_TAB, action_next_tab },
            { ACTION_PREVIOUS_TAB, action_previous_tab },
            { ACTION_MOVE_TAB_RIGHT, action_move_tab_right},
            { ACTION_MOVE_TAB_LEFT, action_move_tab_left},
            { ACTION_MOVE_TAB_TO_NEW_WINDOW, action_move_tab_to_new_window},
            { ACTION_SEARCH, action_search, null, "false" },
            { ACTION_SEARCH_NEXT, action_search_next },
            { ACTION_SEARCH_PREVIOUS, action_search_previous },
            { ACTION_OPEN_IN_BROWSER, action_open_in_browser }
        };

        public MainWindow (Terminal.Application app, bool recreate_tabs = true) {
            Object (
                app: app,
                recreate_tabs: recreate_tabs
            );
        }

        static construct {
            action_accelerators[ACTION_CLOSE_TAB] = "<Control><Shift>w";
            action_accelerators[ACTION_FULLSCREEN] = "F11";
            action_accelerators[ACTION_NEW_TAB] = "<Control><Shift>t";
            action_accelerators[ACTION_DUPLICATE_TAB] = "<Control><Shift>d";
            action_accelerators[ACTION_TAB_RELOAD] = "<Control><Shift>r";
            action_accelerators[ACTION_NEXT_TAB] = "<Control>Tab";
            action_accelerators[ACTION_NEXT_TAB] = "<Control>Page_Down";
            action_accelerators[ACTION_PREVIOUS_TAB] = "<Control><Shift>Tab";
            action_accelerators[ACTION_PREVIOUS_TAB] = "<Control>Page_Up";
            action_accelerators[ACTION_MOVE_TAB_RIGHT] = "<Control><Alt>Right";
            action_accelerators[ACTION_MOVE_TAB_LEFT] = "<Control><Alt>Left";
            action_accelerators[ACTION_SEARCH] = ACTION_SEARCH_ACCEL;
            action_accelerators[ACTION_OPEN_IN_BROWSER] = ACTION_OPEN_IN_BROWSER_ACCEL;
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

            clipboard = Gtk.Clipboard.get (Gdk.Atom.intern ("CLIPBOARD", false));
            primary_selection = Gtk.Clipboard.get (Gdk.Atom.intern ("PRIMARY", false));

            //Window actions
            open_in_browser_menuitem = new MenuItem (
               "", // Appropriate label attribute will be set in update_menu_label ()
               ACTION_PREFIX + ACTION_OPEN_IN_BROWSER
            );
            open_in_browser_menuitem.set_attribute_value ("accel", ACTION_OPEN_IN_BROWSER_ACCEL);

            var search_menuitem = new MenuItem (
                _("Show Search Bar"),
                ACTION_PREFIX + ACTION_SEARCH
            );
            search_menuitem.set_attribute_value ("accel", ACTION_SEARCH_ACCEL);

            //TerminalWidget actions
            var copy_menuitem = new MenuItem (
                _("Copy"),
                TerminalWidget.ACTION_COPY
            );
            copy_menuitem.set_attribute_value ("accel", new Variant ("s", TerminalWidget.ACCELS_COPY[0]));

            var copy_last_output_menuitem = new MenuItem (
                _("Copy Last Output"),
                TerminalWidget.ACTION_COPY_OUTPUT
            );
            copy_last_output_menuitem.set_attribute_value ("accel", new Variant ("s", TerminalWidget.ACCELS_COPY_OUTPUT[0]));

            var paste_menuitem = new MenuItem (
                _("Paste"),
                TerminalWidget.ACTION_PASTE
            );
            paste_menuitem.set_attribute_value ("accel", new Variant ("s", TerminalWidget.ACCELS_PASTE[0]));

            var select_all_menuitem = new MenuItem (
                _("Select All"),
                TerminalWidget.ACTION_SELECT_ALL
            );
            select_all_menuitem.set_attribute_value ("accel", new Variant ("s", TerminalWidget.ACCELS_SELECT_ALL[0]));

            var terminal_action_section = new Menu ();
            terminal_action_section.append_item (copy_menuitem);
            terminal_action_section.append_item (copy_last_output_menuitem);
            terminal_action_section.append_item (paste_menuitem);
            terminal_action_section.append_item (select_all_menuitem);

            var search_section = new Menu ();
            search_section.append_item (search_menuitem);

            context_menu_model = new Menu ();
            // "Open in" item must be in position 0 (see update_menu_label ())
            context_menu_model.append_item (open_in_browser_menuitem);
            context_menu_model.append_section (null, terminal_action_section);
            context_menu_model.append_section (null, search_section);

            setup_ui ();

            key_controller = new Gtk.EventControllerKey (this) {
                propagation_phase = TARGET
            };
            key_controller.key_pressed.connect (key_pressed);
            key_controller.focus_in.connect (() => {
                if (focus_timeout == 0) {
                    focus_timeout = Timeout.add (20, () => {
                        focus_timeout = 0;
                        save_opened_terminals (true, true);
                        return Source.REMOVE;
                    });
                }
            });

            update_font ();
            Application.settings_sys.changed["monospace-font-name"].connect (update_font);
            Application.settings.changed["font"].connect (update_font);

            set_size_request (app.minimum_width, app.minimum_height);

            restore_saved_state ();
            show_all ();

            if (recreate_tabs) {
                open_tabs ();
            }

            delete_event.connect (on_delete_event);
        }

        public void add_tab_with_working_directory (string? directory, string? command = null, bool create_new_tab = false) {
            /* This requires all restored tabs to be initialized first so that the shell location is available */
            /* Do not add a new tab if location is already open in existing tab */
            string? location = null;
            if (directory == null || directory == "") {
                if (notebook.n_pages == 0 || command != null || create_new_tab) { //Ensure at least one tab
                    new_tab ("", command);
                }

                return;
            } else {
                location = directory;
            }

            /* We can match existing tabs only if there is no command and create_new_tab == false */
            if (command == null && !create_new_tab) {
                var file = File.new_for_commandline_arg (location);
                for (int pos = 0; pos < notebook.n_pages; pos++) {
                    var tab = notebook.tab_view.get_nth_page (pos);
                    var terminal_widget = get_term_widget (tab);
                    var tab_path = terminal_widget.get_shell_location ();
                    /* Detect equialent paths */
                    if (file.equal (File.new_for_path (tab_path))) {
                        /* Just focus the duplicate tab instead */
                        notebook.selected_page = tab;
                        return; /* Duplicate found, abandon adding tab */
                    }
                }
            }

            new_tab (location, command);
        }

        private void setup_ui () {
            var unfullscreen_button = new Gtk.Button.from_icon_name ("view-restore-symbolic") {
                action_name = ACTION_PREFIX + ACTION_FULLSCREEN,
                can_focus = false,
                margin_start = 12,
                no_show_all = true,
                visible = false
            };
            unfullscreen_button.tooltip_markup = Granite.markup_accel_tooltip (
                action_accelerators[ACTION_FULLSCREEN].to_array (),
                _("Exit FullScreen")
            );
            unfullscreen_button.get_style_context ().remove_class ("image-button");
            unfullscreen_button.get_style_context ().add_class ("titlebutton");

            search_button = new Gtk.ToggleButton () {
                action_name = ACTION_PREFIX + ACTION_SEARCH,
                image = new Gtk.Image.from_icon_name ("edit-find-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                valign = Gtk.Align.CENTER,
                tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>f"}, _("Find…"))
            };

            var menu_button = new Gtk.MenuButton () {
                can_focus = false,
                image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
                popover = new SettingsPopover (),
                tooltip_text = _("Settings"),
                valign = Gtk.Align.CENTER
            };

            search_toolbar = new Terminal.Widgets.SearchToolbar (this);

            title_label = new Gtk.Label (title);
            title_label.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);

            title_stack = new Gtk.Stack () {
                transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN
            };
            title_stack.add (title_label);
            title_stack.add (search_toolbar);
            // Must show children before visible_child can be set
            title_stack.show_all ();
            // We set visible child here to avoid transition being visible on startup.
            title_stack.visible_child = title_label;

            header = new Hdy.HeaderBar () {
                show_close_button = true,
                has_subtitle = false,
                decoration_layout = "close:",
                decoration_layout_set = false
            };

            header.pack_end (unfullscreen_button);
            header.pack_end (menu_button);
            header.pack_end (search_button);
            header.set_custom_title (title_stack);

            unowned Gtk.StyleContext header_context = header.get_style_context ();
            header_context.add_class ("default-decoration");
            header.bind_property ("decoration-layout-set", unfullscreen_button, "visible", BindingFlags.DEFAULT);

            notebook = new TerminalView (this);
            notebook.tab_view.page_attached.connect (on_tab_added);
            notebook.tab_view.page_detached.connect (on_tab_removed);
            notebook.tab_view.page_reordered.connect (on_tab_reordered);
            notebook.tab_view.create_window.connect (on_create_window_request);
            notebook.tab_view.close_page.connect ((tab) => {
                var term = get_term_widget (tab);
                var confirmed = false;
                if (term == null) {
                    confirmed = true;
                } else {
                    confirmed = confirm_close_tab (term);
                }

                if (confirmed) {
                    if (!term.child_has_exited) {
                        term.term_ps ();
                    }

                    if (Application.settings.get_boolean ("save-exited-tabs")) {
                        make_restorable (term);
                    }

                    disconnect_terminal_signals (term);
                }

                notebook.tab_view.close_page_finish (tab, confirmed);

                return Gdk.EVENT_STOP;
            });

            notebook.tab_view.notify["selected-page"].connect (() => {
                var term = get_term_widget (notebook.tab_view.selected_page);
                current_terminal = term;
                zoom_overlay.hide_zoom_level ();

                if (term == null) {
                    // Happens on closing window - ignore
                    return;
                }


                title = term.window_title != "" ? term.window_title
                                                : term.current_working_directory;
                term.grab_focus ();
            });

            var overlay = new Gtk.Overlay () {
                child = notebook
            };

            zoom_overlay = new Widgets.ZoomOverlay (overlay);

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.add (header);
            box.add (overlay);

            add (box);
            get_style_context ().add_class ("terminal-window");

            bind_property ("title", title_label, "label");

            unowned var menu_popover = (SettingsPopover) menu_button.popover;

            menu_popover.show_theme_editor.connect (() => {
                if (color_preferences_dialog == null) {
                    color_preferences_dialog = new Dialogs.ColorPreferences (this);
                }

                color_preferences_dialog.destroy.connect (() => color_preferences_dialog = null);
                color_preferences_dialog.present ();
            });

            bind_property ("title", header, "title", GLib.BindingFlags.SYNC_CREATE);
            bind_property ("current-terminal", menu_popover, "terminal");
        }

        private bool key_pressed (uint keyval, uint keycode, Gdk.ModifierType modifiers) {
            switch (keyval) {
                case Gdk.Key.Escape:
                    if (search_toolbar.search_entry.has_focus) {
                        search_button.active = !search_button.active;
                        return true;
                    }
                    break;

                case Gdk.Key.Return:
                    if (search_toolbar.search_entry.has_focus) {
                        if (SHIFT_MASK in modifiers) {
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
                    if (MOD1_MASK in modifiers
                    && Application.settings.get_boolean ("alt-changes-tab")
                    && notebook.n_pages > 1) {
                        var tab_index = keyval - 49;
                        if (tab_index > notebook.n_pages - 1) {
                            return false;
                        }

                        notebook.selected_page = notebook.tab_view.get_nth_page ((int) tab_index);
                        return true;
                    }
                    break;

                case Gdk.Key.@9:
                    if (MOD1_MASK in modifiers
                    && Application.settings.get_boolean ("alt-changes-tab")
                    && notebook.n_pages > 1) {
                        notebook.selected_page = notebook.tab_view.get_nth_page ((int)notebook.n_pages - 1);
                        return true;
                    }
                    break;

                default:
                    break;
            }

            return false;
        }

        private void restore_saved_state () {
            var rect = Gdk.Rectangle ();
            Terminal.Application.saved_state.get ("window-size", "(ii)", out rect.width, out rect.height);

            default_width = rect.width;
            default_height = rect.height;

            if (default_width == -1 || default_height == -1) {
                var geometry = get_display ().get_primary_monitor ().get_geometry ();

                default_width = geometry.width * 2 / 3;
                default_height = geometry.height * 3 / 4;
            }

            var window_state = Terminal.Application.saved_state.get_enum ("window-state");
            if (window_state == MainWindow.MAXIMIZED) {
                maximize ();
            } else if (window_state == MainWindow.FULLSCREEN) {
                is_fullscreen = true;
            }
        }

        private void on_tab_added (Hdy.TabPage tab, int pos) {
            var term = get_term_widget (tab);
            term.main_window = this;
            save_opened_terminals (true, true);
        }

        private void on_tab_removed (Hdy.TabPage tab) {
            if (notebook.n_pages == 0) {
                // Close window when last tab removed (Note: cannot drag last tab out of window)
                save_opened_terminals (true, true);
                destroy ();
            } else {
                check_for_tabs_with_same_name ();
                save_opened_terminals (true, true);
            }
        }

        public bool confirm_close_tab (TerminalWidget terminal_widget) {
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

            //Names checked in page_detached handler

            return true;
        }

        private void on_tab_reordered (Hdy.TabPage tab, int new_pos) {
            save_opened_terminals (true, true);
        }

        private unowned Hdy.TabView? on_create_window_request () {
            var new_window = new MainWindow (
                app,
                false
            );

            return new_window.notebook.tab_view;
        }

        public void update_context_menu () requires (current_terminal != null) {
            /* Update the "Show in ..." menu option */
            get_current_selection_link_or_pwd ((clipboard, uri) => {
                update_menu_label (Utils.sanitize_path (uri, current_terminal.get_shell_location ()));
            });
        }

        private void update_menu_label (string? uri) {
            AppInfo? appinfo = get_default_app_for_uri (uri);

            //Changing atributes has no effect after adding item to menu so remove and re-add.
            context_menu_model.remove (0); // This item was added first
            get_simple_action (ACTION_OPEN_IN_BROWSER).set_enabled (appinfo != null);
            var new_name = _("Show in %s").printf (
                appinfo != null ?
                appinfo.get_display_name () : _("Default application")
            );

            open_in_browser_menuitem.set_attribute_value (
                "label",
                new Variant ("s", new_name)
            );

            context_menu_model.prepend_item (open_in_browser_menuitem);
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

        protected override bool configure_event (Gdk.EventConfigure event) {
            // triggered when the size, position or stacking of the window has changed
            // it is delayed 400ms to prevent spamming gsettings
            if (timer_window_state_change > 0) {
                GLib.Source.remove (timer_window_state_change);
            }

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
                }

                return false;
            });

            return base.configure_event (event);
        }

        private void open_tabs () {
            string[] tabs = {};
            double[] zooms = {};
            uint focus = 0;
            var default_zoom = Application.saved_state.get_double ("zoom"); //Range set in settings 0.25 - 4.0

            if (Granite.Services.System.history_is_enabled () &&
                Application.settings.get_boolean ("remember-tabs")) {

                tabs = Terminal.Application.saved_state.get_strv ("tabs");
                var n_tabs = tabs.length;

                if (n_tabs == 0) {
                    tabs += Environment.get_home_dir ();
                    zooms += default_zoom;
                } else {
                    foreach (unowned string zoom_s in Terminal.Application.saved_state.get_strv ("tab-zooms")) {
                        var zoom = double.parse (zoom_s); // Locale independent

                        if (zooms.length < n_tabs) {
                            zooms += zoom;
                        } else {
                            break;
                        }
                    }

                    while (zooms.length < n_tabs) {
                        zooms += default_zoom;
                    }
                }

                focus = Terminal.Application.saved_state.get_int ("focused-tab");
            } else {
                tabs += Environment.get_current_dir ();
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
                    tabs[0] = Environment.get_current_dir ();
                }
            }

            focus = focus.clamp (0, tabs.length - 1);

            /* This must not be in an Idle loop to avoid duplicate tabs being opened (issue #245) */
            focus += notebook.n_pages;
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
                var tab = notebook.tab_view.get_nth_page ((int)(focus.clamp (0, notebook.n_pages - 1)));
                notebook.selected_page = tab;
            }
        }

        private TerminalWidget new_tab (
            string location,
            string? program = null,
            bool focus = true,
            int pos = (int)notebook.n_pages
        ) {

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

            var tab = append_tab (
                location != null ? Path.get_basename (location) : TerminalWidget.DEFAULT_LABEL,
                null, terminal_widget, pos
            );

            //Set correct label now to avoid race when spawning shell

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

            if (focus) {
                notebook.selected_page = tab;
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

            check_for_tabs_with_same_name ();
            save_opened_terminals (true, true);

            connect_terminal_signals (terminal_widget);

            return terminal_widget;
        }

        private void connect_terminal_signals (TerminalWidget terminal_widget) {
            terminal_widget.child_exited.connect (on_terminal_child_exited);
            terminal_widget.notify["font-scale"].connect (on_terminal_font_scale_changed);
            terminal_widget.cwd_changed.connect (on_terminal_cwd_changed);
            terminal_widget.window_title_changed.connect (on_terminal_window_title_changed);
        }

        private void disconnect_terminal_signals (TerminalWidget terminal_widget) {
            terminal_widget.child_exited.disconnect (on_terminal_child_exited);
            terminal_widget.notify["font-scale"].disconnect (on_terminal_font_scale_changed);
            terminal_widget.cwd_changed.disconnect (on_terminal_cwd_changed);
            terminal_widget.window_title_changed.disconnect (on_terminal_window_title_changed);
        }

        private void on_terminal_child_exited (Vte.Terminal term, int status) {
            var tw = (TerminalWidget)term;
            if (tw.tab.child != tw.parent) {
                // TabView already removed tab - ignore signal
                return;
            }
             if (!tw.killed) {
                if (tw.program_string != null) {
                    /* If a program was running, do not close the tab so that output of program
                     * remains visible */
                    tw.program_string = null;
                    tw.active_shell (tw.current_working_directory);
                } else {
                    if (tw.tab != null) {
                        notebook.tab_view.close_page (tw.tab);
                    }

                    return;
                }
            }
        }

        private void on_terminal_font_scale_changed () {
            zoom_overlay.show_zoom_level (current_terminal.font_scale);
            save_opened_terminals (false, true);
        }

        private void on_terminal_window_title_changed () {
            title = current_terminal.window_title;
        }

        private Hdy.TabPage append_tab (
            string label,
            GLib.Icon? icon,
            TerminalWidget term,
            int pos
        ) {
            var sw = new Gtk.ScrolledWindow (null, term.get_vadjustment ());
            sw.add (term);
            var tab = notebook.tab_view.insert (sw, pos);
            tab.title = label;
            tab.tooltip = term.current_working_directory;
            tab.icon = icon;
            term.tab = tab;

            tab.child.show_all ();
            return tab;
        }

        private void make_restorable (TerminalWidget term) {
            //FIXME Terminal child always exits when tab is closed (unlike Granite.DynamicNotebook)
            if (Application.settings.get_boolean ("save-exited-tabs")) {
                notebook.make_restorable (term.current_working_directory);
            }

            if (!term.child_has_exited) {
                term.term_ps ();
            }

            return;
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

            for (int i = 0; i < notebook.n_pages; i++) {
                var term = get_term_widget (notebook.tab_view.get_nth_page (i));
                term.set_font (term_font);
            }
        }

        public bool on_delete_event () {
            //Avoid saved terminals being overwritten when tabs destroyed.
            notebook.tab_view.page_detached.disconnect (on_tab_removed);
            save_opened_terminals (true, true);
            var tabs_to_terminate = new GLib.List <TerminalWidget> ();

            for (int i = 0; i < notebook.n_pages; i++) {
                var term = get_term_widget (notebook.tab_view.get_nth_page (i));
                if (term.has_foreground_process ()) {
                    var dialog = new ForegroundProcessDialog.before_close (this);
                    if (dialog.run () == Gtk.ResponseType.ACCEPT) {
                        term.kill_fg ();
                        dialog.destroy ();
                    } else {
                        dialog.destroy ();
                        return true;
                    }
                }

                tabs_to_terminate.append (term);
            }

            foreach (var t in tabs_to_terminate) {
                t.term_ps ();
            }

            return false;
        }

        private void action_open_in_browser () requires (current_terminal != null) {
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

        private void get_current_selection_link_or_pwd (
            Gtk.ClipboardTextReceivedFunc uri_handler
        ) requires (current_terminal != null) {

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

        private void action_close_tab () {
            notebook.close_tab ();
        }

        private void action_close_tabs_to_right () {
            notebook.close_tabs_to_right ();
        }

        private void action_close_other_tabs () {
            notebook.close_other_tabs ();
        }

        private void action_restore_closed_tab (GLib.SimpleAction action, GLib.Variant? param) {
            new_tab (param.get_string (), null, true); //TODO Restore icon?
        }

        private void action_new_tab () requires (current_terminal != null) {
            if (Application.settings.get_boolean ("follow-last-tab")) {
                new_tab (current_terminal.get_shell_location ());
            } else {
                new_tab (Environment.get_home_dir ());
            }
        }

        private void action_new_tab_at (GLib.SimpleAction action, GLib.Variant? param) {
            var uri = param.get_string ();
            new_tab (uri);
        }

        private void action_tab_active_shell (GLib.SimpleAction action, GLib.Variant? param) {
            var path = param.get_string ();
            var term = current_terminal;
            // Ignore if foreground process running, for now.
            if (term.has_foreground_process ()) {
                return;
            }

            // Clear any partially entered command
            term.reload ();

            // Change to requested directory
            var command = "cd '" + path + "'\n";
            term.feed_child (command.data);

            // Clear screen
            term.feed_child ("clear\n".data);
        }

        private void action_tab_reload () {
            TerminalWidget? term;
            var target = notebook.tab_menu_target;
            if (target != null) {
                term = get_term_widget (target);
            } else {
                term = get_term_widget (notebook.tab_view.selected_page);
            }

            if (term != null) {
                term.reload ();
            }
        }

        private void action_duplicate_tab () requires (current_terminal != null) {
            var term = notebook.tab_menu_target != null ?
                       get_term_widget (notebook.tab_menu_target) :
                       current_terminal;

            var pos = notebook.tab_menu_target != null ?
                      notebook.tab_view.get_page_position (notebook.tab_menu_target) + 1 :
                      (int)notebook.n_pages;

            new_tab (term.get_shell_location (), null, true, pos);
        }

        private void action_next_tab () {
            notebook.tab_view.select_next_page ();
        }

        private void action_previous_tab () {
            notebook.tab_view.select_previous_page ();
        }

        void action_move_tab_right () {
            notebook.tab_view.reorder_forward (notebook.selected_page);
        }

        void action_move_tab_left () {
            notebook.tab_view.reorder_backward (notebook.selected_page);
        }

        void action_move_tab_to_new_window () {
            notebook.transfer_tab_to_new_window ();
        }

        private void action_search () requires (current_terminal != null) {
            var search_action = (SimpleAction) actions.lookup_action (ACTION_SEARCH);
            var search_state = search_action.get_state ().get_boolean ();

            search_action.set_state (!search_state);

            if (search_button.active) {
                title_stack.visible_child = search_toolbar;
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
                title_stack.visible_child = title_label;
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
            is_fullscreen = !is_fullscreen;
        }

        private unowned TerminalWidget? get_term_widget (Hdy.TabPage? tab) {
            if (tab == null) {
                return null;
            }
            var tab_child = (Gtk.Bin)(tab.child); // ScrolledWindow
            var term = tab_child.get_child (); // TerminalWidget
            return (TerminalWidget)term;
        }

        public unowned TerminalWidget? get_terminal (string id) {
            for (int i = 0; i < notebook.n_pages; i++) {
                unowned var term = get_term_widget (notebook.tab_view.get_nth_page (i));
                if (term.terminal_id == id) {
                    return term;
                }
            }

            return null;
        }

        /** Compare every tab label with every other and resolve ambiguities **/
        private void check_for_tabs_with_same_name () requires (current_terminal != null) {
            int i = 0;
            int j = 0;
            for (i = 0; i < notebook.n_pages; i++) {
                var term = get_term_widget (notebook.tab_view.get_nth_page (i));
                string term_path = term.current_working_directory;
                string term_label = Path.get_basename (term_path);
                if (term_label == "" ||
                    term.tab_label == TerminalWidget.DEFAULT_LABEL) {
                    continue;
                }

                /* Reset tab_name to basename so long name only used when required */
                term.tab_label = term_label;

                for (j = 0; j < notebook.n_pages; j++) {
                var term2 = get_term_widget (notebook.tab_view.get_nth_page (j));
                    string term2_path = term2.current_working_directory;
                    string term2_name = Path.get_basename (term2_path);

                    if (term2.terminal_id != term.terminal_id &&
                        term2_name == term_label &&
                        term2_path != term_path) {

                        term2.tab_label = disambiguate_label (term2_path, term_path);
                        term.tab_label = disambiguate_label (term_path, term2_path);
                    }
                }
            }

            return;
        }

        private void on_terminal_cwd_changed (TerminalWidget src, string cwd) {
            src.tab.tooltip = cwd;
            check_for_tabs_with_same_name (); // Also sets window title
            save_opened_terminals (true, false);
        }

        private void save_opened_terminals (bool save_tabs, bool save_zooms) {
            string[] zooms = {};
            string[] opened_tabs = {};
            int focused_tab = 0;

            // Continuous saving of opened terminals interferes with current unit tests
            if (app.is_testing) {
                return;
            }

            if (save_zooms && current_terminal != null) {
                Application.saved_state.set_double ("zoom", current_terminal.font_scale);
            }

            if (Granite.Services.System.history_is_enabled () &&
                Application.settings.get_boolean ("remember-tabs")) {

                for (int i = 0; i < notebook.n_pages; i++) {
                    var term = get_term_widget (notebook.tab_view.get_nth_page (i));
                    if (term != null) {
                        var location = term.get_shell_location ();
                        if (location != null && location != "") {
                            if (save_tabs) {
                                opened_tabs += location;
                            }
                            if (save_zooms) {
                                zooms += term.font_scale.to_string (); // Locale independent
                            }
                        }
                    }
                }

                if (save_tabs && notebook.selected_page != null) {
                    focused_tab = notebook.tab_view.get_page_position (notebook.selected_page);
                }
            }

            if (save_tabs) {
                Terminal.Application.saved_state.set_strv (
                    "tabs",
                    opened_tabs
                );

                Terminal.Application.saved_state.set_int (
                    "focused-tab",
                    focused_tab
                );
            }

            if (save_zooms) {
                Terminal.Application.saved_state.set_strv (
                    "tab-zooms",
                    zooms
                );
            }
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
    }
}

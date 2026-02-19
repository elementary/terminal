/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 */

namespace Terminal {
    public class MainWindow : Adw.Window {
        private Adw.HeaderBar header;
        public TerminalView notebook { get; private set construct; }
        private Terminal.Widgets.SearchToolbar search_toolbar;
        private Gtk.Button unfullscreen_button;
        private Gtk.Label title_label;
        private Gtk.Stack title_stack;
        private Gtk.ToggleButton search_button;
        private Dialogs.ColorPreferences? color_preferences_dialog;
        private uint focus_timeout = 0;

        public bool recreate_tabs { get; construct; }
        public Terminal.Application app { get; construct; }
        public SimpleActionGroup actions { get; construct; }

        public TerminalWidget? current_terminal { get; private set; default = null; }

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_CLOSE_TAB = "action-close-tab";
        public const string ACTION_CLOSE_TABS_TO_RIGHT = "action_close_tabs_to_right";
        public const string ACTION_CLOSE_OTHER_TABS = "action_close_other_tabs";
        private const string ACTION_FULLSCREEN = "action-fullscreen";
        public const string ACTION_NEW_TAB = "action-term_widgetnew-tab";
        public const string ACTION_NEW_TAB_AT = "action-new-tab-at";
        public const string ACTION_TAB_ACTIVE_SHELL = "action-tab_active_shell";
        public const string ACTION_TAB_RELOAD = "action-tab_reload";
        public const string ACTION_RESTORE_CLOSED_TAB = "action-restore-closed-tab";
        public const string ACTION_DUPLICATE_TAB = "action-duplicate-tab";
        private const string ACTION_NEXT_TAB = "action-next-tab";
        private const string ACTION_PREVIOUS_TAB = "action-previous-tab";
        private const string ACTION_MOVE_TAB_RIGHT = "action-move-tab-right";
        private const string ACTION_MOVE_TAB_LEFT = "action-move-tab-left";
        public const string ACTION_MOVE_TAB_TO_NEW_WINDOW = "action-move-tab-to-new-window";
        private const string ACTION_SEARCH = "action-search";
        public const string ACTION_SEARCH_NEXT = "action-search-next";
        public const string ACTION_SEARCH_PREVIOUS = "action-search-previous";

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
            { ACTION_SEARCH, action_search, null, "false", action_search_change_state },
            { ACTION_SEARCH_NEXT, action_search_next },
            { ACTION_SEARCH_PREVIOUS, action_search_previous }
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
            action_accelerators[ACTION_SEARCH] = "<Control><Shift>f";
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

            title = TerminalWidget.DEFAULT_LABEL;

            setup_ui ();

            var key_controller = new Gtk.EventControllerKey () {
                propagation_phase = CAPTURE
            };
            key_controller.key_pressed.connect (key_pressed);

            var focus_controller = new Gtk.EventControllerFocus ();
            focus_controller.enter.connect (() => {
                if (focus_timeout == 0) {
                    focus_timeout = Timeout.add (20, () => {
                        focus_timeout = 0;
                        save_opened_terminals (true, true);
                        current_terminal.grab_focus ();
                        return Source.REMOVE;
                    });
                }
            });

            // Need to disambiguate from ShortcutManager interface add_controller ()
            ((Gtk.Widget)this).add_controller (key_controller);
            ((Gtk.Widget)this).add_controller (focus_controller);

            set_size_request (Application.MINIMUM_WIDTH, Application.MINIMUM_HEIGHT);

            if (recreate_tabs) {
                open_tabs ();
            }

            close_request.connect (on_delete_event);
        }

        public void add_tab_with_working_directory (
            string directory = "",
            string command = "",
            bool create_new_tab = false
        ) {

            /* This requires all restored tabs to be initialized first so that
             * the shell location is available.
             * Do not add a new tab if location is already open in existing tab */
            string location = "";
            if (directory.length == 0) {
                if (notebook.n_pages == 0 || command != null || create_new_tab) { //Ensure at least one tab
                    notebook.add_new_tab ("", command);
                }

                return;
            } else {
                location = directory;
            }

            /* We can match existing tabs only if there is no command and create_new_tab == false */
            if (command.length == 0 && !create_new_tab) {
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

            notebook.add_new_tab (location, command);
        }

        private Adw.TabPage? tab_to_close = null;
        private TerminalWidget? term_to_close = null;
        private void setup_ui () {
            unfullscreen_button = new Gtk.Button.from_icon_name ("view-restore-symbolic") {
                action_name = ACTION_PREFIX + ACTION_FULLSCREEN,
                can_focus = false,
                margin_start = 12,
                visible = false
            };
            unfullscreen_button.tooltip_markup = Granite.markup_accel_tooltip (
                action_accelerators[ACTION_FULLSCREEN].to_array (),
                _("Exit FullScreen")
            );
            unfullscreen_button.remove_css_class ("image-button");
            unfullscreen_button.add_css_class ("titlebutton");

            search_button = new Gtk.ToggleButton () {
                action_name = ACTION_PREFIX + ACTION_SEARCH,
                icon_name = "edit-find-symbolic",
                valign = CENTER,
                tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>f"}, _("Find…"))
            };

            var new_tab_button = new Gtk.Button.from_icon_name ("list-add-symbolic") {
                valign = CENTER,
                action_name = ACTION_PREFIX + ACTION_NEW_TAB,
                tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>t"}, _("New Tab…"))
            };

            var new_tab_revealer = new Gtk.Revealer () {
                child = new_tab_button,
                transition_type = SLIDE_LEFT
            };

            var menu_button = new Gtk.MenuButton () {
                can_focus = false,
                icon_name = "open-menu-symbolic",
                popover = new SettingsPopover (),
                tooltip_text = _("Settings"),
                valign = CENTER
            };

            search_toolbar = new Terminal.Widgets.SearchToolbar (this);

            title_label = new Gtk.Label (title) {
                wrap = false,
                single_line_mode = true,
                ellipsize = Pango.EllipsizeMode.END
            };

            title_label.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

            title_stack = new Gtk.Stack () {
                transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN,
                hhomogeneous = false
            };
            title_stack.add_child (title_label);
            title_stack.add_child (search_toolbar);
            title_stack.visible_child = title_label;

            header = new Adw.HeaderBar () {
                title_widget = title_stack,
                centering_policy = STRICT
            };

            header.pack_end (unfullscreen_button);
            header.pack_end (menu_button);
            header.pack_end (search_button);
            header.pack_end (new_tab_revealer);

            header.add_css_class ("default-decoration");

            notebook = new TerminalView (this);
            notebook.tab_view.page_attached.connect (on_tab_added);
            notebook.tab_view.page_detached.connect (on_tab_removed);
            notebook.tab_view.page_reordered.connect (on_tab_reordered);
            notebook.tab_view.create_window.connect (on_create_window_request);

            notebook.tab_view.close_page.connect ((tab) => {
                term_to_close = get_term_widget (tab);
                if (term_to_close != null) {
                    tab_to_close = tab;
                    term_to_close.confirm_kill_fg_process (
                        _("Are you sure you want to close this tab?"),
                        _("Close tab"),
                        (confirmed) => {
                            if (confirmed) {
                                term_to_close.kill_fg ();
                                terminate_and_disconnect (term_to_close, true);
                            }

                            notebook.tab_view.close_page_finish (tab_to_close, confirmed);
                        }
                    );
                }

                return Gdk.EVENT_STOP;
            });

            notebook.tab_view.notify["selected-page"].connect (() => {
                var term = get_term_widget (notebook.tab_view.selected_page);
                current_terminal = term;

                if (term == null) {
                    // Happens on closing window - ignore
                    return;
                }

                title = term.window_title != "" ? term.window_title
                                                : term.current_working_directory;


                // Need to wait for default handler to run before focusing
                Idle.add (() => {
                    term.grab_focus ();
                    return Source.REMOVE;
                });

                if (term.tab == null) {
                    // Happens on opening window - ignore
                    return;
                }

                if (term.tab_state != WORKING) {
                    term.tab_state = NONE;
                }
            });

            notebook.tab_bar.bind_property ("tabs-revealed", new_tab_revealer, "reveal-child", SYNC_CREATE | INVERT_BOOLEAN);

            var box = new Adw.ToolbarView () {
                content = notebook,
                top_bar_style = RAISED_BORDER
            };
            box.add_top_bar (header);
            box.add_top_bar (notebook.tab_bar);

            content = box;
            add_css_class ("terminal-window");

            bind_property ("title", title_label, "label");

            unowned var menu_popover = (SettingsPopover) menu_button.popover;

            menu_popover.show_theme_editor.connect (() => {
                if (color_preferences_dialog == null) {
                    color_preferences_dialog = new Dialogs.ColorPreferences (this);
                }

                color_preferences_dialog.present ();
            });

            bind_property ("current-terminal", menu_popover, "terminal");
        }

        private bool key_pressed (uint keyval, uint keycode, Gdk.ModifierType modifiers) {
            switch (keyval) {
                case Gdk.Key.Escape:
                    if (focus_widget.is_ancestor (search_toolbar)) {
                        actions.lookup_action (ACTION_SEARCH).change_state (false);
                        return Gdk.EVENT_STOP;
                    }
                    break;

                case Gdk.Key.Return:
                    if (focus_widget.is_ancestor (search_toolbar)) {
                        if (SHIFT_MASK in modifiers) {
                            search_toolbar.previous_search ();
                        } else {
                            search_toolbar.next_search ();
                        }
                        return Gdk.EVENT_STOP;
                    }
                    break;
            }

            return Gdk.EVENT_PROPAGATE;
        }

        private void on_tab_added (Adw.TabPage tab, int pos) {
            var term = get_term_widget (tab);
            save_opened_terminals (true, true);
            connect_terminal_signals (term);
        }

        private void on_tab_removed (Adw.TabPage tab) {
            if (notebook.n_pages == 0) {
                // Close window when last tab removed (Note: cannot drag last tab out of window)
                save_opened_terminals (true, true);
                destroy ();
            } else {
                check_for_tabs_with_same_name ();
                save_opened_terminals (true, true);
            }
        }

        private void on_tab_reordered (Adw.TabPage tab, int new_pos) {
            save_opened_terminals (true, true);
        }

        private unowned Adw.TabView? on_create_window_request () {
            return present_new_empty_window ().notebook.tab_view;
        }

        private void open_tabs () {
            string[] tabs = {};
            double[] zooms = {};
            int focus = 0;
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
                        if (zooms.length < n_tabs) {
                            zooms += double.parse (zoom_s); // Locale independent
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

                if (!file.query_exists ()) {
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
                    var term = notebook.add_new_tab (loc, "");
                    term.font_scale = zooms[index].clamp (
                        TerminalWidget.MIN_SCALE,
                        TerminalWidget.MAX_SCALE
                    );
                }

                index++;
            }

            notebook.selected_page = notebook.tab_view.get_nth_page (focus.clamp (0, notebook.n_pages - 1));
        }

        private void connect_terminal_signals (TerminalWidget terminal_widget) {
            terminal_widget.child_exited.connect (on_terminal_child_exited);
            terminal_widget.cwd_changed.connect (on_terminal_cwd_changed);
            terminal_widget.foreground_process_changed.connect (on_terminal_program_changed);
            terminal_widget.window_title_changed.connect (on_terminal_window_title_changed);
        }

        private void on_terminal_child_exited (Vte.Terminal term, int status) {
            var tw = (TerminalWidget)term;
            if (tw.tab.child != tw.parent) {
                // TabView already removed tab - ignore signal
                return;
            }

            if (!tw.killed) {
                if (tw.program_string.length > 0) {
                    /* If a program was running, do not close the tab so that output of program
                     * remains visible */
                    tw.program_string = "";
                    tw.active_shell (tw.current_working_directory);
                    check_for_tabs_with_same_name ();
                } else {
                    if (tw.tab != null) {
                        notebook.tab_view.close_page (tw.tab);
                    }

                    return;
                }
            }
        }

        private void on_terminal_window_title_changed () {
            title = current_terminal.window_title;
        }

        private bool close_immediately = false;
        //TODO Make TerminalWidget.confirm_kill_fg_process asynchronous and terminate all in callback
        private bool on_delete_event () {
            if (close_immediately) {
                return Gdk.EVENT_PROPAGATE;
            }
            //Avoid saved terminals being overwritten when tabs destroyed.
            notebook.tab_view.page_detached.disconnect (on_tab_removed);
            save_opened_terminals (true, true);
            for (int i = 0; i < notebook.n_pages; i++) {
                var term = get_term_widget (notebook.tab_view.get_nth_page (i));
                if (term.has_foreground_process ()) {
                    term.confirm_kill_fg_process (
                        _("Are you sure you want to close all foreground processes before closing the window?"),
                        _("Close window"),
                        ((confirmed) => {
                            if (confirmed) {
                                terminate_all ();
                                close_immediately = true;
                                this.close ();
                            }
                        })
                    );

                    return Gdk.EVENT_STOP;
                }
            }

            terminate_all ();

            return Gdk.EVENT_PROPAGATE;
        }

        private void terminate_all () {
            for (int i = 0; i < notebook.n_pages; i++) {
                var term = get_term_widget (notebook.tab_view.get_nth_page (i));
                terminate_and_disconnect (term, false);
            }
        }

        private void terminate_and_disconnect (TerminalWidget term, bool make_restorable_required) {
            term.term_ps ();
            if (make_restorable_required && Application.settings.get_boolean ("save-exited-tabs")) {
               notebook.make_restorable (term.current_working_directory);
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
            notebook.add_new_tab (param.get_string ()); // TODO Restore icon?
            notebook.after_tab_restored (param.get_string ());
        }

        private void action_new_tab () requires (current_terminal != null) {
            if (Application.settings.get_boolean ("follow-last-tab")) {
                notebook.add_new_tab (current_terminal.get_shell_location ());
            } else {
                notebook.add_new_tab (Environment.get_home_dir ());
            }
        }

        private void action_new_tab_at (GLib.SimpleAction action, GLib.Variant? param)
        requires (param != null)
        requires (param.is_of_type (VariantType.STRING)) {
            notebook.add_new_tab (param.get_string ());
        }

        private void action_tab_active_shell (GLib.SimpleAction action, GLib.Variant? param) {
            var path = param.get_string ();
            current_terminal.change_directory (path);
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
                      notebook.n_pages;

            notebook.add_new_tab (term.get_shell_location (), "", pos);
        }

        private void action_next_tab () {
            notebook.cycle_tabs (FORWARD);
        }

        private void action_previous_tab () {
            notebook.cycle_tabs (BACK);
        }

        private void action_move_tab_right () {
            notebook.tab_view.reorder_forward (notebook.selected_page);
        }

        private void action_move_tab_left () {
            notebook.tab_view.reorder_backward (notebook.selected_page);
        }

        private void action_move_tab_to_new_window () {
            // Do not use app action because we do not want default tab added
            notebook.transfer_tab_to_window (present_new_empty_window ());
        }

        private void action_search_change_state (SimpleAction search_action, GLib.Variant value)
        requires (value.is_of_type (VariantType.BOOLEAN))
        requires (current_terminal != null) {
            search_action.set_state (value);

            if (search_action.state.get_boolean ()) {
                search_button.active = true;
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
                search_button.active = false;
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

            string[] next_accels = {};
            if (!action_accelerators[ACTION_SEARCH_NEXT].is_empty) {
                next_accels = action_accelerators[ACTION_SEARCH_NEXT].to_array ();
            }

            string[] prev_accels = {};
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

        private void action_search () {
            unowned var search_action = (SimpleAction) actions.lookup_action (ACTION_SEARCH);
            search_action.change_state (!search_action.state.get_boolean ());
        }

        private void action_search_next () {
            if (actions.lookup_action (ACTION_SEARCH).state.get_boolean ()) {
                search_toolbar.next_search ();
            }
        }

        private void action_search_previous () {
            if (actions.lookup_action (ACTION_SEARCH).state.get_boolean ()) {
                search_toolbar.previous_search ();
            }
        }

        private void action_fullscreen () {
            if (is_fullscreen ()) {
                header.decoration_layout = null;
                unfullscreen_button.visible = false;
                unfullscreen ();
            } else {
                header.decoration_layout = "close:";
                unfullscreen_button.visible = true;
                fullscreen ();
            }
        }

        private static unowned TerminalWidget? get_term_widget (Adw.TabPage? tab) {
            if (tab == null) {
                return null;
            }

            var tab_child = (Gtk.ScrolledWindow) tab.child;
            unowned var term = (TerminalWidget) tab_child.child;
            return term;
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

        public void set_active_terminal_tab (Adw.TabPage tab) {
            notebook.tab_view.selected_page = tab;
        }

        /** Compare every tab label with every other and resolve ambiguities **/
        private void check_for_tabs_with_same_name () requires (current_terminal != null) {
            int i = 0;
            int j = 0;
            for (i = 0; i < notebook.n_pages; i++) {
                var term = get_term_widget (notebook.tab_view.get_nth_page (i));
                string term_path, term_label;
                if (term.program_string != "") {
                    term.tab.title = term.program_string;
                    continue;
                } else {
                    term_path = term.current_working_directory;
                    term_label = Path.get_basename (term_path);
                    if (term_label == "" || term_label == "/") {
                        term.tab.title = TerminalWidget.DEFAULT_LABEL;
                        continue;
                    } else {
                        term.tab.title = term_label;
                    }
                }

                for (j = 0; j < notebook.n_pages; j++) {
                var term2 = get_term_widget (notebook.tab_view.get_nth_page (j));
                    string term2_path = term2.current_working_directory;
                    string term2_name = Path.get_basename (term2_path);

                    if (term2.terminal_id != term.terminal_id &&
                        term2_name == term_label &&
                        term2_path != term_path) {

                        term2.tab.title = disambiguate_label (term2_path, term_path);
                        term.tab.title = disambiguate_label (term_path, term2_path);
                    }
                }
            }

            return;
        }

        private void on_terminal_cwd_changed () {
            check_for_tabs_with_same_name (); // Also sets window title
            save_opened_terminals (true, false);
        }

        private void on_terminal_program_changed (TerminalWidget src, string cmdline) {
            src.program_string = cmdline;
            check_for_tabs_with_same_name (); // Also sets window title
        }

        public void save_opened_terminals (bool save_tabs, bool save_zooms) {
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
        private static string disambiguate_label (string path, string conflict_path) {
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

        private MainWindow present_new_empty_window () {
            var new_window = new MainWindow (app, false);
            new_window.set_size_request (
                app.active_window.width_request,
                app.active_window.height_request
            );

            new_window.present ();
            return new_window;
        }

        public GLib.SimpleAction? get_simple_action (string action) {
            return actions.lookup_action (action) as GLib.SimpleAction;
        }
    }
}

/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024-2025 elementary, Inc. (https://elementary.io)
 */

public class Terminal.TerminalView : Granite.Bin {
    const int TAB_HISTORY_MAX_ITEMS = 20;

    public signal void new_tab_requested ();
    public signal void tab_duplicated (Adw.TabPage page);

    public int n_pages {
        get {
            return tab_view.n_pages;
        }
    }

    public Adw.TabPage selected_page {
        get {
            return tab_view.selected_page;
        }

        set {
            tab_view.selected_page = value;
        }
    }

    public unowned MainWindow main_window { private get; construct; }
    public Adw.TabBar tab_bar { get; private set; }
    public Adw.TabView tab_view { get; private set; }
    public Adw.TabPage? tab_menu_target { get; private set; default = null; }

    private static GLib.Settings gnome_interface_settings;
    private Widgets.ZoomOverlay zoom_overlay;
    private Gtk.MenuButton tab_history_button;
    private Pango.FontDescription term_font;

    static construct {
        gnome_interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
    }

    public TerminalView (MainWindow window) {
        Object (main_window: window);
    }

    construct {
        var app_instance = (Gtk.Application) GLib.Application.get_default ();

        tab_view = new Adw.TabView () {
            hexpand = true,
            vexpand = true
        };
        tab_view.menu_model = create_menu_model ();
        tab_view.setup_menu.connect (tab_view_setup_menu);

        var new_tab_button = new Gtk.Button.from_icon_name ("list-add-symbolic") {
            has_frame = false,
            tooltip_markup = Granite.markup_accel_tooltip (
                app_instance.get_accels_for_action (MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW_TAB),
                _("New Tab")
            ),
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW_TAB
        };

        tab_history_button = new Gtk.MenuButton () {
            icon_name = "document-open-recent-symbolic",
            tooltip_text = _("Closed Tabs")
        };

        tab_bar = new Adw.TabBar () {
            autohide = Application.settings.get_enum ("tab-bar-behavior") == 1,
            expand_tabs = false,
            inverted = true,
            start_action_widget = new_tab_button,
            end_action_widget = tab_history_button,
            view = tab_view,
        };

        var overlay = new Gtk.Overlay () {
            child = tab_view
        };

        zoom_overlay = new Widgets.ZoomOverlay (overlay);

        // We don't add tab_bar because it's in the main window header
        child = overlay;

        Application.settings.changed["tab-bar-behavior"].connect (() => {
            tab_bar.autohide = Application.settings.get_enum ("tab-bar-behavior") == 1;
        });

        var button_target = new Gtk.DropTarget (Type.STRING, Gdk.DragAction.COPY) {
            preload = true // So we can predetermine whether string is suitable for dropping here
        };

        button_target.notify["value"].connect (on_add_button_target_value_changed);
        button_target.drop.connect (on_add_button_drop);
        new_tab_button.add_controller (button_target);

        tab_view.notify["selected-page"].connect (zoom_overlay.hide_zoom_level);

        tab_bar.setup_extra_drop_target (Gdk.DragAction.COPY, { Type.STRING });
        tab_bar.extra_drag_drop.connect (on_tab_bar_extra_drag_drop);

        var key_controller = new Gtk.EventControllerKey () {
            propagation_phase = CAPTURE
        };
        key_controller.key_pressed.connect (key_pressed);
        add_controller (key_controller);

        update_font ();
        gnome_interface_settings.changed["monospace-font-name"].connect (update_font);
        Application.settings.changed["font"].connect (update_font);
    }

    public void make_restorable (string path) {
        if (tab_history_button.menu_model == null) {
            tab_history_button.menu_model = new Menu ();
            tab_history_button.popover.has_arrow = false;
        }

        var menu = (Menu) tab_history_button.menu_model;
        int position_in_menu = -1;
        var path_in_menu = false;
        int i;
        for (i = 0; i < menu.get_n_items (); i++) {
            if (path == menu.get_item_attribute_value (
                i, Menu.ATTRIBUTE_TARGET, VariantType.STRING).get_string ()
            ) {
                path_in_menu = true;
                position_in_menu = i;
                break;
            }
        }

        if (path_in_menu) {
            menu.remove (position_in_menu);
        }

        if (menu.get_n_items () >= TAB_HISTORY_MAX_ITEMS) {
            menu.remove (TAB_HISTORY_MAX_ITEMS - 1);
        }

        menu.prepend (
            path,
            "%s::%s".printf (MainWindow.ACTION_PREFIX + MainWindow.ACTION_RESTORE_CLOSED_TAB, path)
        );
    }

    public TerminalWidget add_new_tab (string? location, string program = "", int pos = -1) {
        if (pos == -1) {
            pos = n_pages;
        }

        var terminal_widget = new TerminalWidget () {
            scrollback_lines = Application.settings.get_int ("scrollback-lines"),
            /* Make the terminal occupy the whole GUI */
            hexpand = true,
            vexpand = true
        };

        terminal_widget.notify["font-scale"].connect ((obj, pspec) => {
            zoom_overlay.show_zoom_level (((TerminalWidget) obj).font_scale);
            main_window.save_opened_terminals (false, true);
        });

        var scrolled = new Gtk.ScrolledWindow () {
            vadjustment = terminal_widget.vadjustment,
            child = terminal_widget
        };

        unowned var tab = tab_view.insert (scrolled, pos);
        tab.title = location != null ? Path.get_basename (location) : TerminalWidget.DEFAULT_LABEL;
        terminal_widget.bind_property ("current-working-directory", tab, "tooltip");
        terminal_widget.tab = tab;

        terminal_widget.notify["tab-state"].connect (() => {
            tab.icon = terminal_widget.tab_state.to_icon ();
            tab.loading = terminal_widget.tab_state == WORKING;
        });

        // Set correct label now to avoid race when spawning shell

        terminal_widget.set_font (term_font);

        var current_terminal = get_term_widget (tab_view.selected_page);
        if (current_terminal != null) {
            terminal_widget.font_scale = current_terminal.font_scale;
        } else {
            terminal_widget.font_scale = Terminal.Application.saved_state.get_double ("zoom");
        }

        selected_page = tab;

        if (program.length == 0) {
            /* Set up the virtual terminal */
            if (location == "") {
                terminal_widget.active_shell ();
            } else {
                terminal_widget.active_shell (location);
            }
        } else {
            terminal_widget.run_program (program, location);
        }

        main_window.save_opened_terminals (true, true);

        return terminal_widget;
    }

    public void close_tab () {
        var target = tab_menu_target ?? tab_view.selected_page;

        if (target == null) {
            return;
        }

        tab_view.close_page (target);
    }

    public void close_tabs_to_right () {
        var target = tab_menu_target ?? tab_view.selected_page;

        if (target == null) {
            return;
        }

        tab_view.close_pages_after (target);
        tab_view.selected_page = target;
    }

    public void close_other_tabs () {
        var target = tab_menu_target ?? tab_view.selected_page;

        if (target == null) {
            return;
        }

        tab_view.close_other_pages (target);
        tab_view.selected_page = target;
    }

    public void cycle_tabs (Adw.NavigationDirection direction) {
        var pos = tab_view.get_page_position (selected_page);
        pos = direction == FORWARD ? pos + 1 : pos - 1;
        pos = (pos + n_pages) % n_pages;

        selected_page = tab_view.get_nth_page (pos);
    }

    public void transfer_tab_to_window (MainWindow window) {
        var target = tab_menu_target ?? tab_view.selected_page;

        if (target == null) {
            return;
        }

        tab_view.transfer_page (target, window.notebook.tab_view, 0);
    }

    // This is called when tab context menu is opened or closed
    private void tab_view_setup_menu (Adw.TabPage? page) {
        tab_menu_target = page;
        var actions = main_window.actions;
        var close_other_tabs_action = Utils.action_from_group (MainWindow.ACTION_CLOSE_OTHER_TABS, actions);
        var close_tabs_to_right_action = Utils.action_from_group (MainWindow.ACTION_CLOSE_TABS_TO_RIGHT, actions);
        var open_in_new_window_action = Utils.action_from_group (MainWindow.ACTION_MOVE_TAB_TO_NEW_WINDOW, actions);

        int page_position = page != null ? tab_view.get_page_position (page) : -1;

        close_other_tabs_action.set_enabled (page != null && tab_view.n_pages > 1);
        close_tabs_to_right_action.set_enabled (page != null && page_position != tab_view.n_pages - 1);
        open_in_new_window_action.set_enabled (page != null && tab_view.n_pages > 1);
    }

    private bool key_pressed (uint keyval, uint keycode, Gdk.ModifierType modifiers) {
        switch (keyval) {
            case Gdk.Key.@1: //alt+[1-8]
            case Gdk.Key.@2:
            case Gdk.Key.@3:
            case Gdk.Key.@4:
            case Gdk.Key.@5:
            case Gdk.Key.@6:
            case Gdk.Key.@7:
            case Gdk.Key.@8:
                if (ALT_MASK in modifiers && Application.settings.get_boolean ("alt-changes-tab")) {
                    var tab_index = (int) (keyval - Gdk.Key.@1);
                    if (tab_index < n_pages) {
                        selected_page = tab_view.get_nth_page (tab_index);
                    }

                    return Gdk.EVENT_STOP;
                }
                break;

            case Gdk.Key.@9:
                if (ALT_MASK in modifiers && Application.settings.get_boolean ("alt-changes-tab") && n_pages > 0) {
                    selected_page = tab_view.get_nth_page (n_pages - 1);
                    return Gdk.EVENT_STOP;
                }
                break;
        }

        return Gdk.EVENT_PROPAGATE;
    }

    private void update_font () {
        // We have to fetch both values at least once, otherwise
        // GLib.Settings won't notify on their changes
        var app_font_name = Application.settings.get_string ("font");
        var sys_font_name = gnome_interface_settings.get_string ("monospace-font-name");

        if (app_font_name != "") {
            term_font = Pango.FontDescription.from_string (app_font_name);
        } else {
            term_font = Pango.FontDescription.from_string (sys_font_name);
        }

        for (int i = 0; i < n_pages; i++) {
            var term = get_term_widget (tab_view.get_nth_page (i));
            term.set_font (term_font);
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

    public void after_tab_restored (TerminalWidget term) {
        var menu = (Menu) tab_history_button.menu_model;
        for (var i = 0; i < menu.get_n_items (); i++) {
            if (term.terminal_id == menu.get_item_attribute_value (i, Menu.ATTRIBUTE_TARGET, VariantType.STRING).get_string ()) {
                menu.remove (i);
                break;
            }
        }

        if (menu.get_n_items () == 0) {
            tab_history_button.menu_model = null;
        }
    }

    private static Menu create_menu_model () {
        var close_tab_section = new Menu ();
        close_tab_section.append (_("Close Tabs to the Right"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_TABS_TO_RIGHT);
        close_tab_section.append (_("Close Other Tabs"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_OTHER_TABS);
        close_tab_section.append (_("Close Tab"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_TAB);

        var open_tab_section = new Menu ();
        open_tab_section.append (_("Open in New Window"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_MOVE_TAB_TO_NEW_WINDOW);
        open_tab_section.append (_("Duplicate Tab"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_DUPLICATE_TAB);

        var reload_section = new Menu ();
        reload_section.append (_("Reload"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_TAB_RELOAD);

        var menu = new Menu ();
        menu.append_section (null, open_tab_section);
        menu.append_section (null, close_tab_section);
        menu.append_section (null, reload_section);

        return menu;
    }

    private static void on_add_button_target_value_changed (Object obj, ParamSpec pspec)
    requires (obj is Gtk.DropTarget) {
        var button_target = (Gtk.DropTarget) obj;

        unowned var value = button_target.get_value ();
        if (!value.holds (typeof (string))) {
            button_target.reject ();
            return;
        }

        var uris = Uri.list_extract_uris (value.get_string ());
        foreach (unowned var uri in uris) {
            if (!Utils.valid_local_uri (uri, null)) {
                button_target.reject ();
                break;
            }
        }
    }

    private bool on_add_button_drop (Value val, double x, double y) {
        var uris = Uri.list_extract_uris (val.get_string ());
        var new_tab_action = Utils.action_from_group (MainWindow.ACTION_NEW_TAB_AT, main_window.actions);
        // ACTION_NEW_TAB_AT only works with local paths to folders
        foreach (var uri in uris) {
            string path;
            if (!Utils.valid_local_uri (uri, out path)) {
                continue;
            }

            new_tab_action.activate (path);
        }

        return true;
    }

    private bool on_tab_bar_extra_drag_drop (Adw.TabPage tab, Value val) {
        //TODO Gtk4 Port:Check val contains uri_list
        var uris = Uri.list_extract_uris (val.dup_string ());
        var active_shell_action = Utils.action_from_group (MainWindow.ACTION_TAB_ACTIVE_SHELL, main_window.actions);
        // ACTION_TAB_ACTIVE_SHELL only works with local paths to folders
        foreach (var uri in uris) {
            var file = GLib.File.new_for_uri (uri);
            var scheme = file.get_uri_scheme ();
            if (scheme != "file" && scheme != "") {
                return false;
            }

            var type = file.query_file_type (NONE);
            string path;
            if (type == DIRECTORY) {
                path = file.get_path ();
            } else if (type == REGULAR) {
                path = file.get_parent ().get_path ();
            } else {
                continue;
            }

            active_shell_action.activate (path);
        }

        return true;
    }
}

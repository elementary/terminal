/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024-2025 elementary, Inc. (https://elementary.io)
 */

public class Terminal.TerminalView : Gtk.Box {
    const int TAB_HISTORY_MAX_ITEMS = 20;

    public enum TargetType {
        URI_LIST
    }

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

    public unowned MainWindow main_window { get; construct; }
    private Adw.TabBar tab_bar;
    public Adw.TabView tab_view { get; private set; }
    public Adw.TabPage? tab_menu_target { get; private set; default = null; }
    private Gtk.CssProvider style_provider;
    private Gtk.MenuButton tab_history_button;

    public TerminalView (MainWindow window) {
        Object (
            main_window: window
        );
    }

    construct {
        orientation = VERTICAL;
        hexpand = true;
        vexpand = true;

        var app_instance = (Terminal.Application) GLib.Application.get_default ();
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
            autohide = false,
            expand_tabs = false,
            inverted = true,
            start_action_widget = new_tab_button,
            end_action_widget = tab_history_button,
            view = tab_view,
        };

        style_provider = new Gtk.CssProvider ();
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        var button_target = new Gtk.DropTarget (Type.STRING, Gdk.DragAction.COPY) {
            preload = true //So we can predetermine whether string is suitable for dropping here
        };

        button_target.notify["value"].connect (() => {
            var val = button_target.get_value ();
            var uris = Uri.list_extract_uris (val.dup_string ());
            foreach (string s in uris) {
                if (!Utils.valid_local_uri (s, null)) {
                    button_target.reject ();
                    break;
                }
            }
        });

        button_target.drop.connect (on_add_button_drop);
        new_tab_button.add_controller (button_target);

        Type[] types = { Type.STRING };
        tab_bar.setup_extra_drop_target (Gdk.DragAction.COPY, types);
        tab_bar.extra_drag_drop.connect (on_tab_bar_extra_drag_drop);

        append (tab_bar);
        append (tab_view);
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

    private Menu create_menu_model () {
        var menu = new Menu ();

        var close_tab_section = new Menu ();
        close_tab_section.append (_("Close Tabs to the Right"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_TABS_TO_RIGHT);
        close_tab_section.append (_("Close Other Tabs"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_OTHER_TABS);
        close_tab_section.append (_("Close Tab"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_TAB);

        var open_tab_section = new Menu ();
        open_tab_section.append (_("Open in New Window"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_MOVE_TAB_TO_NEW_WINDOW);
        open_tab_section.append (_("Duplicate Tab"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_DUPLICATE_TAB);

        var reload_section = new Menu ();
        reload_section.append (_("Reload"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_TAB_RELOAD);

        menu.append_section (null, open_tab_section);
        menu.append_section (null, close_tab_section);
        menu.append_section (null, reload_section);
        return menu;
    }

    private bool on_add_button_drop (Value val, double x, double y) {
        var uris = Uri.list_extract_uris (val.dup_string ());
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

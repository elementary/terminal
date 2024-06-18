// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2013 Mario Guerriero <mario@elementaryos.org>
                2024 Colin Kiama <colinkiama@gmail.com>
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

public class Terminal.TerminalView : Gtk.Box {
    const int TAB_HISTORY_MAX_ITEMS = 20;

    public enum TargetType {
        URI_LIST
    }

    public signal void new_tab_requested ();
    public signal void tab_duplicated (Hdy.TabPage page);
    public signal void restorable_terminal_dropped (string id);
    
    public uint n_pages {
        get {
            return tab_view.n_pages;
        }
    }

    public Hdy.TabPage selected_page {
        get {
            return tab_view.selected_page;
        }
        
        set {
            tab_view.selected_page = value;
        }
    }

    public unowned MainWindow main_window { get; construct; }
    public Hdy.TabView tab_view { get; construct; }
    private Hdy.TabBar tab_bar;
    private weak Hdy.TabPage? tab_menu_target = null;
    private Gtk.CssProvider style_provider;
    private Gtk.MenuButton tab_history_button;

    public TerminalView (MainWindow window) {
        Object (
            main_window: window,
            orientation: Gtk.Orientation.VERTICAL,
            hexpand: true,
            vexpand: true
        );
    }

    construct {
        var app_instance = (Gtk.Application) GLib.Application.get_default ();
        tab_view = new Hdy.TabView () {
            hexpand = true,
            vexpand = true
        };

        tab_view.menu_model = create_menu_model ();
        tab_view.setup_menu.connect (tab_view_setup_menu);

        var new_tab_button = new Gtk.Button.from_icon_name ("list-add-symbolic") {
            relief = Gtk.ReliefStyle.NONE,
            tooltip_markup = Granite.markup_accel_tooltip (
                app_instance.get_accels_for_action (MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW_TAB),
                _("New Tab")
            ),
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_NEW_TAB
        };

        tab_history_button = new Gtk.MenuButton () {
            image = new Gtk.Image.from_icon_name ("document-open-recent-symbolic", Gtk.IconSize.MENU),
            tooltip_text = _("Closed Tabs"),
            use_popover = false,
        };

        tab_bar = new Hdy.TabBar () {
            autohide = false,
            expand_tabs = false,
            inverted = true,
            start_action_widget = new_tab_button,
            end_action_widget = tab_history_button,
            view = tab_view,
        };

        style_provider = new Gtk.CssProvider ();
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (),
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        // update_inline_tab_colors ();
        
        // Application.settings.changed["style-scheme"].connect (update_inline_tab_colors);
        // Application.settings.changed["follow-system-style"].connect (update_inline_tab_colors);
        // var granite_settings = Granite.Settings.get_default ();
        // granite_settings.notify["prefers-color-scheme"].connect (update_inline_tab_colors);

        // Handle Drag-and-drop of files onto add-tab button to create document
        // Gtk.TargetEntry uris = {"text/uri-list", 0, TargetType.URI_LIST};
        // Gtk.drag_dest_set (tab_bar, Gtk.DestDefaults.ALL, {uris}, Gdk.DragAction.COPY);
        // tab_bar.drag_data_received.connect (drag_received);

        add (tab_bar);
        add (tab_view);
    }

    // private void update_inline_tab_colors () {
        // var style_scheme = "";
        // if (Application.settings.get_boolean ("follow-system-style")) {
        //     var system_prefers_dark = Granite.Settings.get_default ().prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
        //     if (system_prefers_dark) {
        //         style_scheme = "elementary-dark";
        //     } else {
        //         style_scheme = "elementary-light";
        //     }
        // } else {
        //     style_scheme = Application.settings.get_string ("style-scheme");
        // }

        // var sssm = Gtk.SourceStyleSchemeManager.get_default ();
        // if (style_scheme in sssm.scheme_ids) {
        //     var theme = sssm.get_scheme (style_scheme);
        //     var text_color_data = theme.get_style ("text");

        //     // Default gtksourceview background color is white
        //     var color = "#FFFFFF";
        //     if (text_color_data != null) {
        //         // If the current style has a background color, use that
        //         color = text_color_data.background;
        //     }

        //     var define = "@define-color tab_base_color %s;".printf (color);
        //     try {
        //         style_provider.load_from_data (define);
        //     } catch (Error e) {
        //         critical ("Unable to set inline tab styling, going back to classic notebook tabs");
        //     }
        // }
    // }

    public void make_restorable (TerminalWidget terminal) {
warning ("TV make restorable %s, %s", terminal.current_working_directory, terminal.terminal_id);
        if (tab_history_button.menu_model == null) {
            tab_history_button.menu_model = new Menu ();
        }

        var path = terminal.current_working_directory;
        var id = terminal.terminal_id;


        var menu = (Menu) tab_history_button.menu_model;
        int position_in_menu = -1;
        var path_in_menu = false;
        int i;
        for (i = 0; i < menu.get_n_items (); i++) {
            if (path == menu.get_item_attribute_value (
                i, Menu.ATTRIBUTE_LABEL, VariantType.STRING).get_string ()
            ) {
                path_in_menu = true;
                position_in_menu = i;
                break;
            }
        }

        if (path_in_menu) {
warning ("path in menu true %s ", path);
            var dropped_id = menu.get_item_attribute_value (
                i, Menu.ATTRIBUTE_TARGET, VariantType.STRING
            ).get_string ();
            
            restorable_terminal_dropped (dropped_id);
            menu.remove (position_in_menu);
        }

        if (menu.get_n_items () >= TAB_HISTORY_MAX_ITEMS) {
warning ("too many");
            var dropped_id = menu.get_item_attribute_value (
                TAB_HISTORY_MAX_ITEMS - 1, Menu.ATTRIBUTE_TARGET, VariantType.STRING
            ).get_string ();
            
            restorable_terminal_dropped (dropped_id);
            menu.remove (TAB_HISTORY_MAX_ITEMS - 1);
        }

        menu.prepend (
            path,
            "%s::%s".printf (MainWindow.ACTION_PREFIX + MainWindow.ACTION_RESTORE_CLOSED_TAB, id)
        );
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

    public void duplicate_tab () {

    }

    public void transfer_tab_to_new_window () {
        var target = tab_menu_target ?? tab_view.selected_page;

        if (target == null) {
            return;
        }

        var new_window = new MainWindow (main_window.app, false);
        tab_view.transfer_page (target, new_window.notebook.tab_view, 0);
    }

    // This is called when tab context menu is opened or closed
    private void tab_view_setup_menu (Hdy.TabPage? page) {
        tab_menu_target = page;

        var close_other_tabs_action = Utils.action_from_group (MainWindow.ACTION_CLOSE_OTHER_TABS, main_window.actions);
        var close_tabs_to_right_action = Utils.action_from_group (MainWindow.ACTION_CLOSE_TABS_TO_RIGHT, main_window.actions);

        int page_position = page != null ? tab_view.get_page_position (page) : -1;

        close_other_tabs_action.set_enabled (page != null && tab_view.n_pages > 1);
        close_tabs_to_right_action.set_enabled (page != null && page_position != tab_view.n_pages - 1);
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

    private GLib.Menu create_menu_model () {
        var menu = new GLib.Menu ();

        var close_tab_section = new Menu ();
        close_tab_section.append (_("Close Tabs to the Right"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_TABS_TO_RIGHT);
        close_tab_section.append (_("Close Other Tabs"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_OTHER_TABS);
        close_tab_section.append (_("Close Tab"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_CLOSE_TAB);

        var open_tab_section = new Menu ();
        open_tab_section.append (_("Open in New Window"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_MOVE_TAB_TO_NEW_WINDOW);
        open_tab_section.append (_("Duplicate Tab"), MainWindow.ACTION_PREFIX + MainWindow.ACTION_DUPLICATE_TAB);

        menu.append_section (null, open_tab_section);
        menu.append_section (null, close_tab_section);
        return menu;
    }
}

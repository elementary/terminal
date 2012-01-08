// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011 David Gomes <davidrafagomes@gmail.com>
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

using Gtk;
using Granite.Widgets;

namespace PantheonTerminal {

    public class PantheonTerminalToolbar : Gtk.Toolbar {

        private PantheonTerminalWindow window;
        private string old_searched_text;

        public ToolButton new_button;
        public ToolButton copy_button;
        public ToolButton paste_button;
        public ToolButton stop_button;
        public ToolButton pause_button;
        public SearchBar search_entry;
        public AppMenu app_menu;

        UIManager ui;

        public PantheonTerminalToolbar (PantheonTerminalWindow parent, UIManager ui, Gtk.ActionGroup action_group) {

            this.window = parent;
            this.ui = ui;

            get_style_context ().add_class ("primary-toolbar");

            new_button = action_group.get_action ("New window").create_tool_item () as Gtk.ToolButton;
            copy_button = action_group.get_action ("Copy").create_tool_item () as Gtk.ToolButton;
            paste_button = action_group.get_action ("Paste").create_tool_item () as Gtk.ToolButton;

            add (new_button);
            add (new SeparatorToolItem ());
            add (copy_button);
            add (paste_button);
            add (new SeparatorToolItem ());

            search_entry = new Granite.Widgets.SearchBar (_("Search..."));
            search_entry.width_request = 200;
            search_entry.changed.connect (on_search_entry_text_changed);
            search_entry.key_press_event.connect (on_search_entry_key_press);

            var search_tool = new ToolItem ();
            search_tool.add (search_entry);

            add (add_spacer ());
            add (search_tool);

            var menu = window.ui.get_widget ("ui/AppMenu") as Gtk.Menu;

            app_menu = (window.get_application() as Granite.Application).create_appmenu(menu);

            add (new SeparatorToolItem ());
            add (app_menu);

            restore_settings ();
            settings.changed.connect (restore_settings);
        }

        public void restore_settings () {

            if (settings.show_toolbar) {
                visible = true;
                show ();
                show_all ();
            } else {
                hide ();
            }
        }

        private ToolItem add_spacer () {

            var spacer = new ToolItem ();
            spacer.set_expand (true);

            return spacer;
        }

        public bool on_search_entry_key_press (Gdk.EventKey event) {

          string key = Gdk.keyval_name (event.keyval);

          if (key == "Escape")
            window.current_terminal.grab_focus ();
          if (key == "Return") //FIXME Not working
            window.current_terminal.search_find_next ();

          return false;
        }

        public void on_search_entry_text_changed () {

            var searched_text = search_entry.get_text ();
            var compile_flags = RegexCompileFlags.OPTIMIZE | RegexCompileFlags.MULTILINE;

            /* Test for previous searches */
            if (searched_text != old_searched_text) {
                /* Reset the search position */
                window.current_terminal.search_set_gregex (new Regex (".", compile_flags));
                while (window.current_terminal.search_find_previous ());
                old_searched_text = searched_text;
            }

            var search_regex = new Regex (searched_text, compile_flags);
            window.current_terminal.search_set_gregex (search_regex);
            window.current_terminal.search_find_next ();
        }
    }
} // Namespace

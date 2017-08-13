// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
* Copyright (c) 2011-2017 elementary LLC. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3 as published by the Free Software Foundation.
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

namespace PantheonTerminal.Widgets {

    public class SearchToolbar : Gtk.Toolbar {
        public weak PantheonTerminalWindow window { get; construct; }
        public Gtk.SearchEntry search_entry;

        public SearchToolbar (PantheonTerminalWindow window) {
            Object (
                icon_size: Gtk.IconSize.SMALL_TOOLBAR,
                window: window
            );
        }

        construct {
            search_entry = new Gtk.SearchEntry ();
            search_entry.placeholder_text = _("Find");
            search_entry.width_request = 250;
            search_entry.margin_left = 6;

            var tool_search_entry = new Gtk.ToolItem ();
            tool_search_entry.add (search_entry);

            var previous_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
            previous_button.tooltip_text = _("Previous result");

            var next_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
            next_button.tooltip_text = _("Next result");

            add (tool_search_entry);
            add (previous_button);
            add (next_button);

            get_style_context ().add_class ("search-bar");
            show_all ();

            grab_focus.connect (() => {
                search_entry.grab_focus ();
            });

            search_entry.search_changed.connect (() => {
                try {
                    // FIXME Have a configuration menu or something.
                    var regex = new Regex (Regex.escape_string (search_entry.text), RegexCompileFlags.CASELESS);
                    window.current_terminal.search_set_gregex (regex, 0);
                    window.current_terminal.search_set_wrap_around (true);
                } catch (RegexError er) {
                    warning ("There was an error to compile the regex: %s", er.message);
                }
            });

            previous_button.clicked.connect (previous_search);
            next_button.clicked.connect (next_search);
        }

        public void clear () {
            search_entry.text = "";
        }

        public void previous_search () {
            window.current_terminal.search_find_previous ();
        }

        public void next_search () {
            window.current_terminal.search_find_next ();
        }
    }
}

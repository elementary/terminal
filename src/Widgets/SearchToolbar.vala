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

    public class SearchToolbar : Gtk.Grid {
        private Gtk.ToggleButton cycle_button;
        public weak PantheonTerminalWindow window { get; construct; }
        public Gtk.SearchEntry search_entry;

        public SearchToolbar (PantheonTerminalWindow window) {
            Object (window: window);
        }

        construct {
            search_entry = new Gtk.SearchEntry ();
            search_entry.hexpand = true;
            search_entry.placeholder_text = _("Find");

            var previous_button = new Gtk.Button.from_icon_name ("go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            previous_button.sensitive = false;
            previous_button.tooltip_text = _("Previous result");

            var next_button = new Gtk.Button.from_icon_name ("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            next_button.sensitive = false;
            next_button.tooltip_text = _("Next result");

            cycle_button = new Gtk.ToggleButton ();
            cycle_button.image =  new Gtk.Image.from_icon_name ("media-playlist-repeat-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            cycle_button.sensitive = false;
            cycle_button.tooltip_text = _("Cyclic search");

            var search_grid = new Gtk.Grid ();
            search_grid.margin = 3;
            search_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
            search_grid.add (search_entry);
            search_grid.add (next_button);
            search_grid.add (previous_button);
            search_grid.add (cycle_button);

            add (search_grid);
            get_style_context ().add_class ("search-bar");
            show_all ();

            grab_focus.connect (() => {
                search_entry.grab_focus ();
            });

            search_entry.search_changed.connect (() => {
                if (search_entry.text != "") {
                    previous_button.sensitive = true;
                    next_button.sensitive = true;
                    cycle_button.sensitive = true;
                } else {
                    previous_button.sensitive = false;
                    next_button.sensitive = false;
                    cycle_button.sensitive = false;
                }

                try {
                    // FIXME Have a configuration menu or something.
                    var regex = new Regex (Regex.escape_string (search_entry.text), RegexCompileFlags.CASELESS);
                    window.current_terminal.search_set_gregex (regex, 0);
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
            window.current_terminal.search_set_wrap_around (cycle_button.active);
            window.current_terminal.search_find_previous ();
        }

        public void next_search () {
            window.current_terminal.search_set_wrap_around (cycle_button.active);
            window.current_terminal.search_find_next ();
        }
    }
}

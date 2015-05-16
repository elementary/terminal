// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2015 Pantheon Terminal Developers
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

namespace PantheonTerminal.Widgets {

    public class SearchToolbar : Gtk.Toolbar {
        // Parent window
        private weak PantheonTerminalWindow window;

        private Gtk.ToolItem tool_search_entry;

        public Gtk.SearchEntry search_entry;

        public signal void clear ();

        public SearchToolbar (PantheonTerminalWindow window) {
            this.window = window;

            this.search_entry = new Gtk.SearchEntry ();
            this.search_entry.placeholder_text = _("Find");
            this.search_entry.width_request = 250;
            this.search_entry.margin_left = 6;

            // Items
            this.tool_search_entry = new Gtk.ToolItem ();
            this.tool_search_entry.add (search_entry);

            var i = new Gtk.Image.from_icon_name ("go-up-symbolic",
                                                  Gtk.IconSize.SMALL_TOOLBAR);
            i.pixel_size = 16;
            var previous_button = new Gtk.ToolButton (i, null);
            previous_button.set_tooltip_text (_("Previous result"));

            i = new Gtk.Image.from_icon_name ("go-down-symbolic",
                                              Gtk.IconSize.SMALL_TOOLBAR);
            i.pixel_size = 16;
            var next_button = new Gtk.ToolButton (i, null);
            next_button.set_tooltip_text (_("Next result"));

            this.add (tool_search_entry);
            this.add (previous_button);
            this.add (next_button);

            this.show_all ();
            this.set_style (Gtk.ToolbarStyle.ICONS);
            this.get_style_context ().add_class ("search-bar");

            // Signals and callbacks
            this.clear.connect (clear_cb);
            this.grab_focus.connect (grab_focus_cb);
            this.search_entry.search_changed.connect (search_changed_cb);
            previous_button.clicked.connect (previous_search);
            next_button.clicked.connect (next_search);
        }

        void clear_cb () {
            this.search_entry.text = "";
        }

        void grab_focus_cb () {
            this.search_entry.grab_focus ();
        }

        void search_changed_cb () {
            try {
                // FIXME Have a configuration menu or something.
                var regex = new Regex (Regex.escape_string (search_entry.text),
                                       RegexCompileFlags.CASELESS);
                this.window.current_terminal.search_set_gregex (regex);
                this.window.current_terminal.search_set_wrap_around (true);
            } catch (RegexError er) {
                warning ("There was an error to compile the regex: %s", er.message);
            }
        }

        public void previous_search () {
            this.window.current_terminal.search_find_previous ();
        }

        public void next_search () {
            this.window.current_terminal.search_find_next ();
        }
    }
}

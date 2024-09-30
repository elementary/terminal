/*
 * Copyright (c) 2011-2024 elementary LLC. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

namespace Terminal.Widgets {

    public class SearchToolbar : Gtk.Box {
        private Gtk.ToggleButton cycle_button;
        private uint last_search_term_length = 0;

        public weak MainWindow window { get; construct; }
        public Gtk.SearchEntry search_entry;

        public SearchToolbar (MainWindow window) {
            Object (window: window);
        }

        construct {
            search_entry = new Gtk.SearchEntry ();
            search_entry.hexpand = true;
            search_entry.placeholder_text = _("Find");

            var previous_button = new Gtk.Button.from_icon_name ("go-up-symbolic");
            previous_button.set_action_name (MainWindow.ACTION_PREFIX + MainWindow.ACTION_SEARCH_PREVIOUS);
            previous_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Control>Up", "<Control><Shift>g"},
                _("Previous result")
            );

            var next_button = new Gtk.Button.from_icon_name ("go-down-symbolic");
            next_button.set_action_name (MainWindow.ACTION_PREFIX + MainWindow.ACTION_SEARCH_NEXT);
            next_button.tooltip_markup = Granite.markup_accel_tooltip (
                {"<Control>Down", "<Control>g"},
                _("Next result")
            );

            cycle_button = new Gtk.ToggleButton ();
            cycle_button.icon_name = "media-playlist-repeat-symbolic";
            cycle_button.sensitive = false;
            cycle_button.set_can_focus (false);
            cycle_button.tooltip_text = _("Cyclic search");

            add_css_class (Granite.STYLE_CLASS_LINKED);
            append (search_entry);
            append (next_button);
            append (previous_button);
            append (cycle_button);

            next_button.clicked.connect_after (() => {
                grab_focus ();
            });

            previous_button.clicked.connect_after (() => {
                grab_focus ();
            });

            cycle_button.clicked.connect_after (() => {
                grab_focus ();
            });

            search_entry.search_changed.connect (() => {
                if (search_entry.text != "") {
                    window.get_simple_action (MainWindow.ACTION_SEARCH_NEXT).set_enabled (true);
                    window.get_simple_action (MainWindow.ACTION_SEARCH_PREVIOUS).set_enabled (true);
                    cycle_button.sensitive = true;
                } else {
                    window.get_simple_action (MainWindow.ACTION_SEARCH_NEXT).set_enabled (false);
                    window.get_simple_action (MainWindow.ACTION_SEARCH_PREVIOUS).set_enabled (false);
                    cycle_button.sensitive = false;
                }

                var term = (Vte.Terminal)(window.current_terminal);
                var search_term = search_entry.text;
                previous_search ();  /* Ensure that we still at the highlighted occurrence */

                if (last_search_term_length > search_term.length) {
                    term.match_remove_all ();
                    term.unselect_all ();  /* Ensure revised search finds first occurrence first*/
                }

                last_search_term_length = search_term.length;

                try {
                    // FIXME Have a configuration menu or something.
                    /* NOTE Using a Vte.Regex leads and Vte.Terminal.search_set_regex leads to
                     * a "PCRE2 not supported" error.
                     */
                    var regex = new Vte.Regex.for_search (GLib.Regex.escape_string (search_term), -1, PCRE2.Flags.CASELESS | PCRE2.Flags.MULTILINE);
                    term.search_set_regex (regex, 0);
                    next_search (); /* Search immediately - not after ENTER pressed */
                } catch (Error er) {
                    warning ("There was an error to compile the regex: %s", er.message);
                }
            });
        }

        public new bool grab_focus () {
            return search_entry.grab_focus ();
            //TODO Deselect selection if necessary
        }

        public void clear () {
            search_entry.text = "";
            last_search_term_length = 0;
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

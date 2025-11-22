/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2011-2025 elementary, Inc. (https://elementary.io)
 */

public class Terminal.Widgets.SearchToolbar : Granite.Box {
    public weak MainWindow window { private get; construct; }

    private Gtk.ToggleButton cycle_button;
    private uint last_search_term_length = 0;
    private Gtk.SearchEntry search_entry;

    public SearchToolbar (MainWindow window) {
        Object (window: window);
    }

    construct {
        search_entry = new Gtk.SearchEntry () {
            hexpand = true,
            placeholder_text = _("Find")
        };

        var previous_button = new Gtk.Button.from_icon_name ("go-up-symbolic") {
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_SEARCH_PREVIOUS,
            tooltip_markup = Granite.markup_accel_tooltip (
                {"<Control>Up", "<Control><Shift>g"},
                _("Previous result")
            )
        };

        var next_button = new Gtk.Button.from_icon_name ("go-down-symbolic") {
            action_name = MainWindow.ACTION_PREFIX + MainWindow.ACTION_SEARCH_NEXT,
            tooltip_markup = Granite.markup_accel_tooltip (
                {"<Control>Down", "<Control>g"},
                _("Next result")
            )
        };

        cycle_button = new Gtk.ToggleButton () {
            active = false,
            sensitive = false
        };
        cycle_button.toggled.connect (() => {
            if (cycle_button.active) {
                cycle_button.tooltip_text = _("Disable cyclic search");
                cycle_button.icon_name = "media-playlist-repeat-symbolic";
            } else {
                cycle_button.tooltip_text = _("Enable cyclic search");
                cycle_button.icon_name = "media-playlist-repeat-disabled-symbolic";
            }
        });
        // Toggle to update
        // TODO Restore state from settings
        cycle_button.toggled ();

        child_spacing = LINKED;
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
            var search_entry_is_empty = search_entry.text == "";
            window.action_set_enabled (MainWindow.ACTION_PREFIX + MainWindow.ACTION_SEARCH_NEXT, !search_entry_is_empty);
            window.action_set_enabled (MainWindow.ACTION_PREFIX + MainWindow.ACTION_SEARCH_PREVIOUS, !search_entry_is_empty);
            cycle_button.sensitive = !search_entry_is_empty;

            var term = (Vte.Terminal) (window.current_terminal);
            var search_term = search_entry.text;
            previous_search ();  /* Ensure that we still at the highlighted occurrence */

            if (last_search_term_length > search_term.length) {
                term.match_remove_all ();
                term.unselect_all ();  /* Ensure revised search finds first occurrence first*/
            }

            last_search_term_length = search_term.length;

            try {
                // FIXME Have a configuration menu or something.
                /* NOTE Using a Vte.Regex and Vte.Terminal.search_set_regex leads to
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

    public override bool grab_focus () {
        return search_entry.grab_focus ();
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

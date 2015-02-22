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

            var i = new Gtk.Image.from_icon_name ("go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            i.pixel_size = 16;
            var previous_button = new Gtk.ToolButton (i, null);

            i = new Gtk.Image.from_icon_name ("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            i.pixel_size = 16;
            var next_button = new Gtk.ToolButton (i, null);

            this.add (tool_search_entry);
            this.add (previous_button);
            this.add (next_button);

            this.show_all ();
            this.set_style (Gtk.ToolbarStyle.ICONS);
            this.get_style_context () .add_class ("search-bar");

            // Signals and callbacks
            this.clear.connect (clear_cb);
            this.grab_focus.connect (grab_focus_cb);
            this.search_entry.search_changed.connect (search_changed_cb);
            previous_button.clicked.connect (previous_search);
            next_button.clicked.connect (next_search);

            // Events
            this.search_entry.key_press_event.connect (on_key_press);
        }

        void clear_cb () {
            this.search_entry.text = "";
        }

        void grab_focus_cb () {
            this.search_entry.grab_focus ();
        }
        
        void search_changed_cb () {
            try {
                var regex = new Regex (search_entry.text);
                this.window.current_terminal.search_set_gregex (regex);
                this.window.current_terminal.search_set_wrap_around (true);
            } catch ( RegexError er) {
                error ("There was an error to compile the regex: %s", er.message);
            }
        }

        void previous_search () {
            this.window.current_terminal.search_find_previous ();
        }

        void next_search () {
            this.window.current_terminal.search_find_next ();
        }

        bool on_key_press (Gdk.EventKey event) {
            var key = Gdk.keyval_name (event.keyval).replace ("KP_", "");

            switch (key) {

                case "Escape":
                    this.window.search_button.active = !this.window.search_button.active;
                    return true;

                case "Return":
                    if ((event.state & Gdk.ModifierType.SHIFT_MASK) != 0){
                        previous_search ();
                    } else {
                        next_search ();
                    }
                    return true;

                default:
                    return false;
            }
        }
    }
}

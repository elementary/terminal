namespace PantheonTerminal.Widgets {

    public class SearchToolbar : Gtk.Toolbar {
        // Parent window
        private weak PantheonTerminalWindow window;

        private Gtk.ToolItem tool_search_entry;

        public Gtk.SearchEntry search_entry;

	public signal void clear ();

        public SearchToolbar (PantheonTerminalWindow window) {
            this.window = window;

            search_entry = new Gtk.SearchEntry ();
            search_entry.placeholder_text = _("Find");
            search_entry.width_request = 250;

            // Items
            tool_search_entry = new Gtk.ToolItem ();
            tool_search_entry.add (search_entry);

            var previous_button = new Gtk.ToolButton (new Gtk.Button.from_icon_name ("go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
            
            var next_button = new Gtk.ToolButton (new Gtk.Button.from_icon_name ("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);

            this.add (tool_search_entry);
            this.add (previous_button);
            this.add (next_button);

            this.show_all();
            this.set_style (Gtk.ToolbarStyle.ICONS);
            
            //Signals and callbacks
            this.clear.connect(clear_cb);
            this.grab_focus.connect(grab_focus_cb);
            search_entry.search_changed.connect (search_changed_cb);
            previous_button.clicked.connect (previous_search);
            next_button.clicked.connect (next_search);
            //Events
            this.search_entry.key_press_event.connect (on_key_press);
        }

        void clear_cb () {
            this.search_entry.text = "";
        }

        void grab_focus_cb () {
            this.search_entry.grab_focus ();
        }
        
        void search_changed_cb () {
            debug ("Searching for %s\n".printf (search_entry.text));
            try {
                var regex = new Regex (search_entry.text);
                this.window.current_terminal.search_set_gregex (regex);
                this.window.current_terminal.search_set_wrap_around (true);
                this.window.current_terminal.search_find_next ();
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
                    if ((event.state & Gdk.ModifierType.SHIFT_MASK) !=0){
                        previous_search ();
                    }else{
                        next_search ();
                    }
                    return true;
                default:
                    return false;
            }
        }
    }
}

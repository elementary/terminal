// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
    BEGIN LICENSE

    Copyright (C) 2011-2014 Pantheon Terminal Developers
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

namespace PantheonTerminal {

    public class PantheonTerminalWindow : Gtk.Window {

        public PantheonTerminalApp app {
            get {
                return application as PantheonTerminalApp;
            }
        }

        public Granite.Widgets.DynamicNotebook notebook;
        Pango.FontDescription term_font;
        private Gtk.Clipboard clipboard;

        private GLib.List <TerminalWidget> terminals = new GLib.List <TerminalWidget> ();
        private HashTable<string, TerminalWidget> restorable_terminals;
        private int restorable_counter = 0;

        public TerminalWidget current_terminal = null;
        private bool is_fullscreen = false;
        private string saved_tabs;

        const string ui_string = """
            <ui>
            <popup name="MenuItemTool">
                <menuitem name="New window" action="New window"/>
                <menuitem name="New tab" action="New tab"/>
                <menuitem name="CloseTab" action="CloseTab"/>
                <menuitem name="Copy" action="Copy"/>
                <menuitem name="Paste" action="Paste"/>
                <menuitem name="Select All" action="Select All"/>
                <menuitem name="About" action="About"/>

                <menuitem name="NextTab" action="NextTab"/>
                <menuitem name="PreviousTab" action="PreviousTab"/>

                <menuitem name="ZoomIn" action="ZoomIn"/>
                <menuitem name="ZoomOut" action="ZoomOut"/>

                <menuitem name="Fullscreen" action="Fullscreen"/>
            </popup>

            <popup name="AppMenu">
                <menuitem name="Copy" action="Copy"/>
                <menuitem name="Paste" action="Paste"/>
                <menuitem name="Select All" action="Select All"/>
                <separator />
                <menuitem name="About" action="About"/>
            </popup>
            </ui>
        """;

        public Gtk.ActionGroup main_actions;
        public Gtk.UIManager ui;

        public PantheonTerminalWindow (PantheonTerminalApp app, bool should_recreate_tabs=true) {
            init (app, should_recreate_tabs);
        }

        public PantheonTerminalWindow.with_coords (PantheonTerminalApp app, int x, int y,
                                                   bool should_recreate_tabs = true) {
            move (x, y);
            init (app, should_recreate_tabs, false);
        }

        public PantheonTerminalWindow.with_working_directory (PantheonTerminalApp app, string location,
                                                              bool should_recreate_tabs = true) {
            init (app, should_recreate_tabs);
            new_tab (location);
        }

        public void add_tab_with_command (string command) {
            new_tab ("", command);
        }

        public void add_tab_with_working_directory (string location) {
            new_tab (location);
        }

        private void init (PantheonTerminalApp app, bool recreate_tabs = true, bool restore_pos = true) {
            icon_name = "utilities-terminal";
            set_application (app);

            Notify.init (app.program_name);
            set_visual (Gdk.Screen.get_default ().get_rgba_visual ());

            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            title = _("Terminal");
            restore_saved_state (restore_pos);

            /* Actions and UIManager */
            main_actions = new Gtk.ActionGroup ("MainActionGroup");
            main_actions.set_translation_domain ("pantheon-terminal");
            main_actions.add_actions (main_entries, this);

            clipboard = Gtk.Clipboard.get (Gdk.Atom.intern ("CLIPBOARD", false));
            update_context_menu ();
            clipboard.owner_change.connect (update_context_menu);

            ui = new Gtk.UIManager ();

            try {
                ui.add_ui_from_string (ui_string, -1);
            } catch (Error e) {
                error ("Couldn't load the UI: %s", e.message);
            }

            Notify.init ("pantheon-terminal");
            //new Notify.Notification ("Bye Process", "p finished","utilities-terminal").show ();

            Gtk.AccelGroup accel_group = ui.get_accel_group ();
            add_accel_group (accel_group);

            ui.insert_action_group (main_actions, 0);
            ui.ensure_update ();

            setup_ui ();
            show_all ();

            term_font = Pango.FontDescription.from_string (get_term_font ());

            if (recreate_tabs)
                open_tabs ();

            set_size_request (app.minimum_width, app.minimum_height);

            destroy.connect (on_destroy);
            restorable_terminals = new HashTable<string, TerminalWidget> (str_hash, str_equal);
        }

        private void setup_ui () {
            /* Use CSD */
            var header = new Gtk.HeaderBar ();
            header.set_show_close_button (true);
            header.get_style_context ().remove_class ("header-bar");

            this.set_titlebar (header);

            /* Set up the Notebook */
            notebook = new Granite.Widgets.DynamicNotebook ();
            notebook.show_icons = false;

            main_actions.get_action ("Copy").set_sensitive (false);

            notebook.tab_added.connect (on_tab_added);
            notebook.tab_removed.connect (on_tab_removed);
            notebook.tab_switched.connect (on_switch_page);
            notebook.tab_moved.connect (on_tab_moved);
            notebook.tab_reordered.connect (on_tab_reordered);
            notebook.tab_restored.connect (on_tab_restored);
            notebook.tab_duplicated.connect (on_tab_duplicated);
            notebook.close_tab_requested.connect (on_close_tab_requested);
            notebook.new_tab_requested.connect (on_new_tab_requested);
            notebook.allow_new_window = true;
            notebook.allow_duplication = true;
            notebook.allow_restoring = settings.save_exited_tabs;
            notebook.max_restorable_tabs = 5;
            notebook.group_name = "pantheon-terminal";
            notebook.can_focus = false;
            notebook.tab_bar_behavior = settings.tab_bar_behavior;
            add (notebook);

            key_press_event.connect ((e) => {
                switch (e.keyval) {
                    case Gdk.Key.@0:
                        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                            action_zoom_default_font ();
                            return true;
                        }

                        break;
                    case Gdk.Key.KP_Add:
                        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                            action_zoom_in_font ();
                            return true;
                        }

                        break;
                    case Gdk.Key.KP_Subtract:
                        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                            action_zoom_out_font ();
                            return true;
                        }

                        break;
                    case Gdk.Key.@1: //alt+[1-8]
                    case Gdk.Key.@2:
                    case Gdk.Key.@3:
                    case Gdk.Key.@4:
                    case Gdk.Key.@5:
                    case Gdk.Key.@6:
                    case Gdk.Key.@7:
                    case Gdk.Key.@8:
                        if (((e.state & Gdk.ModifierType.MOD1_MASK) != 0) && settings.alt_changes_tab) {
                            var i = e.keyval - 49;
                            if (i > notebook.n_tabs - 1)
                                return false;

                            notebook.current = notebook.get_tab_by_index ((int) i);
                            return true;
                        }

                        break;
                    case Gdk.Key.@9:
                        if (((e.state & Gdk.ModifierType.MOD1_MASK) != 0) && settings.alt_changes_tab) {
                            notebook.current = notebook.get_tab_by_index (notebook.n_tabs - 1);
                            return true;
                        }

                        break;
                    case Gdk.Key.@D:
                    case Gdk.Key.@d:
                        if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                            if (!current_terminal.has_foreground_process () && settings.save_exited_tabs) {
                                action_close_tab ();

                                return true;
                            }
                        }

                        break;
                }

                return false;
            });
        }

        private void restore_saved_state (bool restore_pos = true) {
            saved_tabs = saved_state.tabs;
            default_width = PantheonTerminal.saved_state.window_width;
            default_height = PantheonTerminal.saved_state.window_height;

            if (restore_pos) {
                int x = saved_state.opening_x;
                int y = saved_state.opening_y;

                if (x != -1 && y != -1) {
                    move (x, y);
                } else {
                    x = (Gdk.Screen.width ()  - default_width)  / 2;
                    y = (Gdk.Screen.height () - default_height) / 2;
                    move (x, y);
                }
            }

            if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.MAXIMIZED) {
                maximize ();
                notebook.margin_top = 3;
            } else if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.FULLSCREEN) {
                fullscreen ();
                notebook.margin_top = 0;
            }

            /* Reset saved state to avoid restoring it again */
            saved_state.window_state = PantheonTerminalWindowState.NORMAL;
            saved_state.window_height = settings.window_height;
            saved_state.window_width = settings.window_width;
            saved_state.opening_x = -1;
            saved_state.opening_y = -1;
            saved_state.tabs = "";
        }

        private void on_tab_added (Granite.Widgets.Tab tab) {
            var t = (tab.page as Gtk.Grid).get_child_at (0, 0) as TerminalWidget;
            terminals.append (t);
            t.window = this;
        }

        private void on_tab_removed (Granite.Widgets.Tab tab) {
            var t = (tab.page as Gtk.Grid).get_child_at (0, 0) as TerminalWidget;
            terminals.remove (t);

            if (notebook.n_tabs == 0)
                destroy ();
        }

        private bool on_close_tab_requested (Granite.Widgets.Tab tab) {
            var t = (tab.page as Gtk.Grid).get_child_at (0, 0) as TerminalWidget;

            if (t.has_foreground_process ()) {
                var d = new ForegroundProcessDialog ();
                if (d.run () == 1) {
                    d.destroy ();
                    t.kill_fg ();
                } else {
                    d.destroy ();

                    return false;
                }
            }

            if (!t.child_has_exited) {
                if (notebook.n_tabs >= 2 && settings.save_exited_tabs) {
                    make_restorable (tab);
                } else {
                    t.term_ps ();
                }
            }

            if (notebook.n_tabs - 1 == 0) {
                update_saved_window_state ();
                reset_saved_tabs ();
            }

            return true;
        }

        private void on_tab_reordered (Granite.Widgets.Tab tab, int new_pos) {
            current_terminal.grab_focus ();
        }

        private void on_tab_restored (string label, string restore_key, GLib.Icon? icon) {
            TerminalWidget term = restorable_terminals.get (restore_key);
            var tab = create_tab (label, icon, term);

            restorable_terminals.remove (restore_key);
            notebook.insert_tab (tab, -1);
            notebook.current = tab;
            term.grab_focus ();
        }

        private void on_tab_moved (Granite.Widgets.Tab tab, int x, int y) {
            var new_window = app.new_window_with_coords (x, y, false);
            var terminal = (tab.page as Gtk.Grid).get_child_at (0, 0) as TerminalWidget;
            var new_notebook = new_window.notebook;

            notebook.remove_tab (tab);
            new_notebook.insert_tab (tab, -1);
            new_window.current_terminal = terminal;
        }

        private void on_tab_duplicated (Granite.Widgets.Tab tab) {
            var t = (tab.page as Gtk.Grid).get_child_at (0, 0) as TerminalWidget;
            new_tab (t.get_shell_location ());
        }

        private void on_new_tab_requested () {
            if (settings.follow_last_tab)
                new_tab (current_terminal.get_shell_location ());
            else
                new_tab ();
        }

        private void update_context_menu () {
            clipboard.request_targets (update_context_menu_cb);
        }

        private void update_context_menu_cb (Gtk.Clipboard clipboard_,
                                             Gdk.Atom[] atoms) {
            bool can_paste = false;

            if (atoms != null && atoms.length > 0)
                can_paste = Gtk.targets_include_text (atoms) || Gtk.targets_include_uri (atoms);
            main_actions.get_action ("Paste").set_sensitive (can_paste);
        }

        private void update_saved_window_state () {
            /* Save window state */
            if ((get_window ().get_state () & Gdk.WindowState.MAXIMIZED) != 0) {
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.MAXIMIZED;
            } else if ((get_window ().get_state () & Gdk.WindowState.FULLSCREEN) != 0) {
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.FULLSCREEN;
            } else {
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.NORMAL;
            }

            /* Save window size */
            if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.NORMAL) {
                int width, height;
                get_size (out width, out height);
                PantheonTerminal.saved_state.window_width = width;
                PantheonTerminal.saved_state.window_height = height;
            }

            /* Save window position */
            int root_x, root_y;
            get_position (out root_x, out root_y);
            saved_state.opening_x = root_x;
            saved_state.opening_y = root_y;
        }

        private void reset_saved_tabs () {
            saved_state.tabs = "";
        }

        private void on_switch_page (Granite.Widgets.Tab? old,
                             Granite.Widgets.Tab new_tab) {
            current_terminal = ((Gtk.Grid) new_tab.page).get_child_at (0, 0) as TerminalWidget;
            title = current_terminal.window_title ?? "";
            new_tab.page.grab_focus ();
        }

        private void open_tabs () {
            string tabs = saved_tabs;
            if (tabs == "" || !settings.remember_tabs ||
                tabs.replace (",", " ").strip () == "") {
                new_tab ();
            } else {
                foreach (string loc in tabs.split (",")) {
                    if (loc != "")
                        new_tab (loc);
                }
            }
        }

        private void new_tab (string directory="", string? program=null) {
            /*
             * If the user choose to use a specific working directory.
             * Reassigning the directory variable a new value
             * leads to free'd memory being read.
             */
            string location;
            if (directory == "") {
                location = PantheonTerminalApp.working_directory ?? "";
            } else {
                location = directory;
            }

            /* Set up terminal */
            var t = new TerminalWidget (this);
            t.scrollback_lines = settings.scrollback_lines;

            /* Make the terminal occupy the whole GUI */
            t.vexpand = true;
            t.hexpand = true;

            if (program == null) {
                /* Set up the virtual terminal */
                if (location == "")
                    t.active_shell ();
                else
                    t.active_shell (location);
            } else {
                t.run_program (program);
            }

            var tab = create_tab (_("Terminal"), null, t);

            t.child_exited.connect (() => {
                if (!t.killed) {
                    t.tab.close ();
                }
            });

            t.set_font (term_font);

            int minimum_width = t.calculate_width (80) / 2;
            int minimum_height = t.calculate_height (24) / 2;
            set_size_request (minimum_width, minimum_height);
            app.minimum_width = minimum_width;
            app.minimum_height = minimum_height;

            notebook.insert_tab (tab, -1);
            notebook.current = tab;
            t.grab_focus ();
        }

        private Granite.Widgets.Tab create_tab (string label, GLib.Icon? icon, TerminalWidget term) {
            var g = new Gtk.Grid ();
            var sb = new Gtk.Scrollbar (Gtk.Orientation.VERTICAL, term.vadjustment);
            g.attach (term, 0, 0, 1, 1);
            g.attach (sb, 1, 0, 1, 1);
            var tab = new Granite.Widgets.Tab (label, icon, g);
            term.tab = tab;
            tab.ellipsize_mode = Pango.EllipsizeMode.START;

            return tab;
        }

        private void make_restorable (Granite.Widgets.Tab tab) {
            var restore_key = "%d".printf (restorable_counter++);
            var page = tab.page as Gtk.Grid;
            var term = page.get_child_at (0, 0) as TerminalWidget;

            terminals.remove (term);
            page.remove (term);
            restorable_terminals.insert (restore_key, term);
            tab.restore_data = restore_key;

            tab.dropped_callback = (() => {
                unowned TerminalWidget t = restorable_terminals.get (tab.restore_data);
                t.term_ps ();
                restorable_terminals.remove (tab.restore_data);
            });
        }

        public void run_program_term (string program) {
            new_tab ("", program);
        }

        static string get_term_font () {
            string font_name;

            if (settings.font == "") {
                var settings_sys = new GLib.Settings ("org.gnome.desktop.interface");
                font_name = settings_sys.get_string ("monospace-font-name");
            } else {
                font_name = settings.font;
            }

            return font_name;
        }

        protected override bool delete_event (Gdk.EventAny event) {
            update_saved_window_state ();
            action_quit ();
            string tabs = "";

            foreach (var t in terminals) {
                t = (TerminalWidget) t;
                tabs += t.get_shell_location () + ",";
                if (t.has_foreground_process ()) {
                    var d = new ForegroundProcessDialog.before_close ();
                    if (d.run () == 1) {
                        t.kill_fg_and_term_ps ();
                        d.destroy ();
                    } else {
                        d.destroy ();
                        return true;
                    }

                } else {
                    t.term_ps ();
                }
            }

            saved_state.tabs = tabs;
            return false;
        }

        private void on_destroy () {
            foreach (unowned TerminalWidget t in restorable_terminals.get_values ()) {
                t.term_ps ();
            }
        }

        void action_quit () {

        }

        void action_copy () {
            if (current_terminal.uri != null)
                clipboard.set_text (current_terminal.uri,
                                    current_terminal.uri.length);
            else
                current_terminal.copy_clipboard ();
        }

        void action_paste () {
            current_terminal.paste_clipboard ();
        }

        void action_select_all () {
            current_terminal.select_all ();
        }

        void action_close_tab () {
            current_terminal.tab.close ();
            current_terminal.grab_focus ();
        }

        void action_new_window () {
            app.new_window ();
        }

        void action_new_tab () {
            if (settings.follow_last_tab)
                new_tab (current_terminal.get_shell_location ());
            else
                new_tab ();
        }

        void action_about () {
            app.show_about (this);
        }

        void action_zoom_in_font () {
            current_terminal.increment_size ();
        }

        void action_zoom_out_font () {
            current_terminal.decrement_size ();
        }

        void action_zoom_default_font () {
            current_terminal.set_default_font_size ();
        }

        void action_next_tab () {
            notebook.next_page ();
        }

        void action_previous_tab () {
            notebook.previous_page ();
        }

        void action_fullscreen () {
            if (is_fullscreen) {
                notebook.margin_top = 3;
                unfullscreen ();
                is_fullscreen = false;
            } else {
                notebook.margin_top = 0;
                fullscreen ();
                is_fullscreen = true;
            }
        }

        static const Gtk.ActionEntry[] main_entries = {
            { "CloseTab", "gtk-close", N_("Close"),
              "<Control><Shift>w", N_("Close"),
              action_close_tab },

            { "New window", "window-new",
              N_("New Window"), "<Control><Shift>n", N_("Open a new window"),
              action_new_window },

            { "New tab", "gtk-new",
              N_("New Tab"), "<Control><Shift>t", N_("Create a new tab"),
              action_new_tab },

            { "Copy", "gtk-copy",
              N_("Copy"), "<Control><Shift>c", N_("Copy the selected text"),
              action_copy },

            { "Paste", "gtk-paste",
              N_("Paste"), "<Control><Shift>v", N_("Paste some text"),
              action_paste },

            { "Select All", "gtk-select-all",
              N_("Select All"), "<Control><Shift>a",
              N_("Select all the text in the terminal"), action_select_all },

            { "About", "gtk-about", N_("About"),
              null, N_("Show about window"), action_about },

            { "NextTab", null, N_("Next Tab"),
              "<Control><Shift>Right", N_("Go to next tab"),
              action_next_tab },

            { "PreviousTab", null, N_("Previous Tab"),
              "<Control><Shift>Left", N_("Go to previous tab"),
              action_previous_tab },

            { "ZoomIn", "gtk-zoom-in", N_("Zoom in"),
              "<Control>plus", N_("Zoom in"),
              action_zoom_in_font },

            { "ZoomOut", "gtk-zoom-out",
              N_("Zoom out"), "<Control>minus", N_("Zoom out"),
              action_zoom_out_font },

            { "Fullscreen", "gtk-fullscreen",
              N_("Fullscreen"), "F11", N_("Toggle/Untoggle fullscreen"),
              action_fullscreen }
        };
    }
}
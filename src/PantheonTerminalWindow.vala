// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN ICENSE

  Copyright (C) 2011-2012 David Gomes <davidrafagomes@gmail.com>
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
using Gdk;
using Vte;
using Granite;
using Pango;

namespace PantheonTerminal {

    public class PantheonTerminalWindow : Gtk.Window {

        public PantheonTerminalApp app;

        public Granite.Widgets.DynamicNotebook notebook;
        FontDescription term_font;
        private Button add_button;
        private Gtk.Clipboard clipboard;

        private GLib.List <TerminalWidget> terminals = new GLib.List <TerminalWidget> ();

        public TerminalWidget current_terminal = null;
        public Granite.Widgets.Tab current_tab;
        private bool is_fullscreen = false;

        const string ui_string = """
            <ui>
            <popup name="MenuItemTool">
                <menuitem name="Quit" action="Quit"/>
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

		//variable indicating that a tab might has been closed by exit command
		bool closed_by_exit;

        public PantheonTerminalWindow (Granite.Application app) {
            this.app = app as PantheonTerminalApp;
            set_application (app);
            init ();
        }

        public PantheonTerminalWindow.with_coords (Granite.Application app, int x, int y,
                                                   bool should_recreate_tabs = true) {

            this.app = app as PantheonTerminalApp;
            set_application (app);
            this.move (x, y);
            init (should_recreate_tabs, false);
        }

        private void init (bool recreate_tabs=true, bool restore_pos = true) {
            this.icon_name = "utilities-terminal";

            Notify.init (app.program_name);
            set_visual (Gdk.Screen.get_default ().get_rgba_visual ());

            closed_by_exit = true;

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

            term_font = FontDescription.from_string (get_term_font ());

            if (recreate_tabs)
                open_tabs ();
        }
        private void setup_ui () {
            /* Set up the Notebook */
            notebook = new Granite.Widgets.DynamicNotebook ();
            notebook.show_icons = false;
            notebook.tab_switched.connect (on_switch_page);
            notebook.tab_moved.connect (on_tab_moved);
            notebook.allow_new_window = true;
            notebook.allow_duplication = false;
            notebook.margin_top = 3;

            notebook.tab_added.connect ((tab) => {
            	new_tab ("", tab);
            });

            notebook.tab_removed.connect ((tab) => {
                var t = ((tab.page as Gtk.Grid).get_child_at (0, 0) as TerminalWidget);

                if (t.has_foreground_process ()) {
                    var d = new ForegroundProcessDialog ();
                    if (d.run () == 1) {
                        closed_by_exit = false;
                        t.kill_ps_and_fg ();

                        if (notebook.n_tabs - 1 == 0) {
                        	update_saved_state ();
                        	destroy ();
                    	}
                    	d.destroy ();

                    	return true;
                    }
                    d.destroy ();

                    return false;
                } else {
                	if (notebook.n_tabs - 1 == 0) {
                		update_saved_state ();
                		tab.parent.parent.parent.destroy ();
            		}
            	}
            	closed_by_exit = false;
            	t.kill_ps ();

            	return true;
            });

            var right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            right_box.show ();
            notebook.can_focus = false;
            add (notebook);

            this.key_press_event.connect ((e) => {
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
                        if ((e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                            var i = e.keyval - 49;
                            if (i > this.notebook.n_tabs - 1)
                                return false;
                            this.notebook.current = this.notebook.get_tab_by_index ((int) i);
                            return true;
                        }

                        break;
                    case Gdk.Key.@9:
                        if ((e.state & Gdk.ModifierType.MOD1_MASK) != 0) {
                            notebook.current = notebook.get_tab_by_index (notebook.n_tabs - 1);
                            return true;
                        }

                        break;
                }

                return false;
            });

            /* Set up the "Add new tab" button */
            add_button = new Button ();
            Image add_image = null;
            add_image = new Image.from_icon_name ("list-add-symbolic", IconSize.MENU);
            add_button.set_image (add_image);
            add_button.show ();
            add_button.set_relief (ReliefStyle.NONE);
            add_button.set_tooltip_text (_("Open a new tab"));
            right_box.pack_start (add_button, false, false, 0);
        }

        private void restore_saved_state (bool restore_pos = true) {
            default_width = PantheonTerminal.saved_state.window_width;
            default_height = PantheonTerminal.saved_state.window_height;

            if (restore_pos) {
                int x = saved_state.opening_x;
                int y = saved_state.opening_y;
                if (x != -1 && y != -1)
                    this.move (x, y);
                else {
                    x = (Gdk.Screen.width ()  - default_width)  / 2;
                    y = (Gdk.Screen.height () - default_height) / 2;
                    this.move (x, y);
                }
            }

            if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.MAXIMIZED)
                maximize ();
            else if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.FULLSCREEN)
                fullscreen ();
        }

		private void on_tab_moved (Granite.Widgets.Tab tab, int new_pos, bool new_window, int x, int y) {
			if (new_window) {
				app.new_window_with_coords (x, y, false);
				var win = app.windows.last ().data;
				//win.move (x, y);

				var n = win.notebook;
				//remove the one automatically created after inserting
                n.insert_tab (tab, -1);
				n.remove_tab (n.tabs.nth_data (1));


				//notebook.remove_tab (tab);
				if (notebook.n_tabs == 0)
					destroy ();
			}
		}

        private void update_context_menu () {
            clipboard.request_targets (update_context_menu_cb);
        }

        private void update_context_menu_cb (Gtk.Clipboard clipboard_, Gdk.Atom[] atoms) {
            bool can_paste;
            can_paste = Gtk.targets_include_text (atoms) || Gtk.targets_include_uri (atoms);
            main_actions.get_action ("Paste").set_sensitive (can_paste);
        }

        private void update_saved_state () {
            /* Save window state */
            if ((get_window ().get_state () & WindowState.MAXIMIZED) != 0)
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.MAXIMIZED;
            else if ((get_window ().get_state () & WindowState.FULLSCREEN) != 0)
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.FULLSCREEN;
            else
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.NORMAL;

            /* Save window size */
            if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.NORMAL) {
                int width, height;
                get_size (out width, out height);
                PantheonTerminal.saved_state.window_width = width;
                PantheonTerminal.saved_state.window_height = height;
            }

            saved_state.tabs  = "";
            string tab_loc;
            foreach (var t in terminals) {
                t = (TerminalWidget) t;
                tab_loc = t.get_shell_location ();
                if (tab_loc != "")
                    saved_state.tabs += tab_loc + ",";
            }
            int root_x, root_y;
            this.get_position (out root_x, out root_y);
            saved_state.opening_x = root_x;
            saved_state.opening_y = root_y;
        }

        void on_switch_page (Granite.Widgets.Tab? old, Granite.Widgets.Tab new_tab) {
            current_tab = new_tab;
            current_terminal = ((Grid) new_tab.page).get_child_at (0, 0) as TerminalWidget;
            title = current_terminal.window_title;
            new_tab.page.grab_focus ();
        }

        private void open_tabs () {
            string tabs = saved_state.tabs;
            if (tabs == "" || !settings.remember_tabs || tabs.replace (",", " ").strip () == "")
                new_tab ();
            else {
                foreach (string loc in tabs.split (",")) {
                    if (loc != "")
                        new_tab (loc);
                }
            }
        }

        private void new_tab (string location="", owned Granite.Widgets.Tab? tab=null) {
            /* Set up terminal */
            var t = new TerminalWidget (main_actions, ui, this);
            t.scrollback_lines = settings.scrollback_lines;
            current_terminal = t;
            var g = new Grid ();
            var sb = new Scrollbar (Orientation.VERTICAL, t.vadjustment);
            g.attach (t, 0, 0, 1, 1);
            g.attach (sb, 1, 0, 1, 1);

            /* Make the terminal occupy the whole GUI */
            t.vexpand = true;
            t.hexpand = true;

            /* Set up the virtual terminal */
            if (location == "")
                t.active_shell ();
            else
                t.active_shell (location);

            /* Set up actions releated to the terminal */
            main_actions.get_action ("Copy").set_sensitive (t.get_has_selection ());

            /* Create a new tab if it hasnt already been created by the plus button press */
            bool to_be_inserted = false;
            if (tab == null) {
            	tab = new Granite.Widgets.Tab (_("Terminal"), null, g);
            	to_be_inserted = true;
        	} else {
        		tab.page = g;
        		tab.label = _("Terminal");
        		tab.page.show_all ();
        	}

            t.tab = tab;
            tab.ellipsize_mode = Pango.EllipsizeMode.START;

            t.window_title_changed.connect (() => {
                string new_text = t.get_window_title ();

                /* Strips the location */
                /*for (int i = 0; i < new_text.length; i++) {
                    if (new_text[i] == ':') {
                        new_text = new_text[i + 2:new_text.length];
                        break;
                    }
                }

                if (new_text.length > 50) {
                    new_text = new_text[new_text.length - 50:new_text.length];
                }
                */

                tab.label = new_text;
            });

            t.selection_changed.connect (() => {
                main_actions.get_action("Copy").set_sensitive (t.get_has_selection ());
            });

            t.child_exited.connect (() => {
            	if (closed_by_exit)
            		notebook.remove_tab (tab);
        		closed_by_exit = true;
            });

            t.set_font (term_font);
            set_size_request (t.calculate_width (80), t.calculate_height (24));
            terminals.append (t);

            if (to_be_inserted)
            	notebook.insert_tab (tab, -1);

        	notebook.current = tab;
        	t.grab_focus ();
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
            update_saved_state ();
            action_quit ();
            string tabs = "";

            foreach (var t in terminals) {
                t = (TerminalWidget) t;
                tabs += t.get_shell_location () + ",";
                if (t.has_foreground_process ()) {
                    var d = new ForegroundProcessDialog.before_close ();
                    if (d.run () == 1) {
                        t.kill_ps_and_fg ();
                        d.destroy ();
                    } else {
                        d.destroy ();
                        return true;
                    }
                }
            }

            saved_state.tabs = tabs;
            return false;
        }

        void action_quit () {

        }

        void action_copy () {
            if (current_terminal.uri != null)
                clipboard.set_text (current_terminal.uri, current_terminal.uri.length);
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
            notebook.remove_tab (notebook.current);
            terminals.remove (current_terminal);
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
            unfullscreen();
            is_fullscreen = false;
          } else {
            fullscreen();
            is_fullscreen = true;
          }
        }

        static const Gtk.ActionEntry[] main_entries = {
           { "Quit", Gtk.Stock.QUIT, N_("Quit"), "<Control>q", N_("Quit"), action_quit },

           { "CloseTab", Gtk.Stock.CLOSE, N_("Close"), "<Control><Shift>w", N_("Close"),
             action_close_tab },

           { "New window", "window-new", N_("New Window"), "<Control><Shift>n", N_("Open a new window"),
             action_new_window },

           { "New tab", Gtk.Stock.NEW, N_("New Tab"), "<Control><Shift>t", N_("Create a new tab"),
             action_new_tab },

           { "Copy", "gtk-copy", N_("Copy"), "<Control><Shift>c", N_("Copy the selected text"),
             action_copy },

           { "Paste", "gtk-paste", N_("Paste"), "<Control><Shift>v", N_("Paste some text"),
             action_paste },

           { "Select All", Gtk.Stock.SELECT_ALL, N_("Select All"), "<Control><Shift>a",
             N_("Select all the text in the terminal"), action_select_all },

           { "About", Gtk.Stock.ABOUT, N_("About"), null, N_("Show about window"), action_about },

           { "NextTab", null, N_("Next Tab"), "<Control><Shift>Right", N_("Go to next tab"),
             action_next_tab },

           { "PreviousTab", null, N_("Previous Tab"), "<Control><Shift>Left", N_("Go to previous tab"),
             action_previous_tab },

           { "ZoomIn", Gtk.Stock.ZOOM_IN, N_("Zoom in"), "<Control>plus", N_("Zoom in"),
             action_zoom_in_font },

           { "ZoomOut", Gtk.Stock.ZOOM_OUT, N_("Zoom out"), "<Control>minus", N_("Zoom out"),
             action_zoom_out_font },

           { "Fullscreen", Gtk.Stock.FULLSCREEN, N_("Fullscreen"), "F11", N_("Toggle/Untoggle fullscreen"),
             action_fullscreen }
        };

    }

} // Namespace

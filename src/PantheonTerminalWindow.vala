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
        FontDescription system_font;
        private Button add_button;

        private GLib.List <TerminalWidget> terminals = new GLib.List <TerminalWidget> ();

        public TerminalWidget current_terminal = null;
        Widget current_tab;
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

        public PantheonTerminalWindow (Granite.Application app) {
            this.app = app as PantheonTerminalApp;
            set_application (app);
            Notify.init (app.program_name);

            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            title = _("Terminal");
            restore_saved_state ();

            /* Actions and UIManager */
            main_actions = new Gtk.ActionGroup ("MainActionGroup");
            main_actions.set_translation_domain ("pantheon-terminal");
            main_actions.add_actions (main_entries, this);

            ui = new Gtk.UIManager ();

            try {
                ui.add_ui_from_string (ui_string, -1);
            } catch (Error e) {
                error ("Couldn't load the UI: %s", e.message);
            }

            Gtk.AccelGroup accel_group = ui.get_accel_group();
            add_accel_group (accel_group);

            ui.insert_action_group (main_actions, 0);
            ui.ensure_update ();

            setup_ui ();
            show_all ();

            system_font = FontDescription.from_string (get_system_font ());

            new_tab ();
        }

        private void setup_ui () {
            /* Set up the Notebook */
            notebook = new Granite.Widgets.DynamicNotebook ();
            notebook.show_icons = false;
            notebook.tab_switched.connect (on_switch_page);
            notebook.tab_moved.connect (on_tab_moved);
            
            notebook.allow_new_window = true;
            
            notebook.tab_added.connect ((tab) => {
            	new_tab (tab);
            });
            notebook.tab_removed.connect ((tab) => {
                var t = ((tab.page as Gtk.Grid).get_child_at (0, 0) as TerminalWidget);
                if (t.has_foreground_process ()) {
                    var d = new ForegroundProcessDialog ();
                    if (d.run () == 1) {
                        t.kill_ps_and_fg ();
                        notebook.remove_tab (tab);
                        if (notebook.n_tabs == 0)
                        	destroy ();
                    }
                    d.destroy ();
                } else {
                	t.kill_ps ();
                	if (notebook.n_tabs - 1 == 0)
                		destroy ();
            	}
            	
            	return false;
            });
            
            var right_box = new HBox (false, 0);
            right_box.show ();
            notebook.can_focus = false;
            add (notebook);

            /* Set up the Add button */
            add_button = new Button ();
            Image add_image = null;
            add_image = new Image.from_icon_name ("list-add-symbolic", IconSize.MENU);
            add_button.set_image (add_image);
            add_button.show ();
            add_button.set_relief (ReliefStyle.NONE);
            add_button.set_tooltip_text (_("Open a new tab"));
            right_box.pack_start (add_button, false, false, 0);
        }

        private void restore_saved_state () {
            default_width = PantheonTerminal.saved_state.window_width;
            default_height = PantheonTerminal.saved_state.window_height;

            if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.MAXIMIZED)
                maximize ();
            else if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.FULLSCREEN)
                fullscreen ();
        }

		private void on_tab_moved (Granite.Widgets.Tab tab, int new_pos, bool new_window, int x, int y)
		{
			if (new_window) {
				
				app.new_window ();
				var win = app.windows.last ().data;
				win.move (x, y);
				
				var n = win.get_children ().nth_data (0) as Granite.Widgets.DynamicNotebook;
				//remove the one automatically created
				n.remove_tab (n.tabs.nth_data (0));
				
				notebook.remove_tab (tab);
				if (notebook.n_tabs == 0)
					destroy ();
				n.insert_tab (tab, -1);
				
			}
		}

        private void update_saved_state () {
            // Save window state
            if ((get_window ().get_state () & WindowState.MAXIMIZED) != 0)
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.MAXIMIZED;
            else if ((get_window ().get_state () & WindowState.FULLSCREEN) != 0)
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.FULLSCREEN;
            else
                PantheonTerminal.saved_state.window_state = PantheonTerminalWindowState.NORMAL;

            // Save window size
            if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.NORMAL) {
                int width, height;
                get_size (out width, out height);
                PantheonTerminal.saved_state.window_width = width;
                PantheonTerminal.saved_state.window_height = height;
            }
        }

        void on_switch_page (Granite.Widgets.Tab? old, Granite.Widgets.Tab new_tab) {
            current_tab = new_tab;
            current_terminal = ((Grid) new_tab.page).get_child_at (0, 0) as TerminalWidget;
            title = current_terminal.window_title;
            new_tab.page.grab_focus ();
        }

        public void remove_page (int page) {
        }

        private void new_tab (owned Granite.Widgets.Tab? tab=null) {
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
            t.active_shell ();

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
                /*
                for (int i = 0; i < new_text.length; i++) {
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
			
            t.child_exited.connect (() => {
                notebook.remove_tab (tab);
                if (notebook.n_tabs == 0)
                	destroy ();
            	
                terminals.remove (t);
            });

            t.selection_changed.connect (() => {
                main_actions.get_action("Copy").set_sensitive (t.get_has_selection ());
            });

            t.drag_data_received.connect ((ctx, x, y, selection_data, target_type, _time) => {
                var uris = selection_data.get_uris();
                for (var i=0; i < uris.length; i++) {
                    uris[i] = "'"+ uris[i].splice (0, "file://".length) +"'";
                }
                string uris_s = string.joinv(" ", uris);
                t.feed_child (uris_s, uris_s.length);
            });

            t.set_font (system_font);
            set_size_request (t.calculate_width (81), t.calculate_height (25));
            terminals.append (t);
            
            if (to_be_inserted)
            	notebook.insert_tab (tab, -1);
        	
        	notebook.current = tab;
        	t.grab_focus ();
        }

        static string get_system_font () {
            string font_name;

            var settings = new GLib.Settings ("org.gnome.desktop.interface");
            font_name = settings.get_string ("monospace-font-name");

            return font_name;
        }

        protected override bool delete_event (Gdk.EventAny event) {
            update_saved_state ();
            action_quit ();

            foreach (var t in terminals) {
                if (((TerminalWidget)t).has_foreground_process ()) {
                    var d = new ForegroundProcessDialog.before_close ();
                    if (d.run () == 1) {
                        return false;
                    } else {
                        d.destroy ();
                        return true;
                    }
                }
            }

            return false;
        }

        void action_quit () {

        }

        void action_copy () {
            current_terminal.copy_clipboard ();
        }

        void action_paste () {
            current_terminal.paste_clipboard ();
        }

        void action_select_all () {
            current_terminal.select_all ();
        }

        void action_close_tab () {
            notebook.tab_removed (notebook.current);
        }

        void action_new_window () {
            app.new_window ();
        }

        void action_new_tab () {
            new_tab ();
        }

        void action_about () {
            app.show_about (this);
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
           { "CloseTab", Gtk.Stock.CLOSE, N_("Close"), "<Control><Shift>w", N_("Close"), action_close_tab },
           { "New window", "window-new", N_("New Window"), "<Control><Shift>n", N_("Open a new window"),
             action_new_window },
           { "New tab", Gtk.Stock.NEW, N_("New Tab"), "<Control><Shift>t", N_("Create a new tab"), action_new_tab },
           { "Copy", "gtk-copy", N_("Copy"), "<Control><Shift>c", N_("Copy the selected text"), action_copy },
           { "Paste", "gtk-paste", N_("Paste"), "<Control><Shift>v", N_("Paste some text"), action_paste },
           { "Select All", Gtk.Stock.SELECT_ALL, N_("Select All"), "<Control><Shift>a",
             N_("Select all the text in the terminal"), action_select_all },
           { "About", Gtk.Stock.ABOUT, N_("About"), null, N_("Show about window"), action_about },

           { "Fullscreen", Gtk.Stock.FULLSCREEN, N_("Fullscreen"), "F11", N_("Toggle/Untoggle fullscreen"), action_fullscreen}
        };

    }

} // Namespace

// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011-2012 Adrien Plazas <kekun.plazas@laposte.net>
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

/* TODO
 * For 0.2
 * Use stepped window resize ? (useful if using another terminal background color than the one from the window)
 * Start the port to the terminal background service
 */

using Gtk;
using Gdk;
using Vte;
using Pango;
using Granite;
using Notify;

namespace PantheonTerminal {

    public class PantheonTerminalWindow : Gtk.Window {

        public signal void theme_changed ();

        public PantheonTerminalApp app;
        Notebook notebook;
        FontDescription font;
        Gdk.Color bgcolor;
        Gdk.Color fgcolor;
        private Button add_button;

        TabWithCloseButton current_tab_label = null;
        public TerminalWidget current_terminal = null;
        Widget current_tab;

        const string ui_string = """
            <ui>
            <popup name="MenuItemTool">
                <menuitem name="Quit" action="Quit"/>
                <menuitem name="New tab" action="New tab"/>
                <menuitem name="CloseTab" action="CloseTab"/>
                <menuitem name="Copy" action="Copy"/>
                <menuitem name="Paste" action="Paste"/>
                <menuitem name="Select All" action="Select All"/>
                <menuitem name="About" action="About"/>
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

            //Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;
            title = _("Terminal");
            restore_saved_state ();
            set_size_request (40, 40);
            //icon_name = "utilities-terminal";

            //Actions and UIManager
            main_actions = new Gtk.ActionGroup ("MainActionGroup"); /* Actions and UIManager */
            main_actions.set_translation_domain ("pantheon-terminal");
            main_actions.add_actions (main_entries, this);
            //main_actions.add_toggle_actions (toggle_entries, this);

            ui = new Gtk.UIManager ();

            try {
                ui.add_ui_from_string (ui_string, -1);
            } catch(Error e) {
                error ("Couldn't load the UI: %s", e.message);
            }

            Gtk.AccelGroup accel_group = ui.get_accel_group();
            add_accel_group (accel_group);

            ui.insert_action_group (main_actions, 0);
            ui.ensure_update ();

            setup_ui ();
            set_theme ();
            show_all ();
            connect_signals ();

            new_tab (true);
        }

        private void setup_ui () {

            /* Set up the Notebook */
            notebook = new Notebook ();
            var right_box = new HBox (false, 0);
            right_box.show ();
            notebook.set_action_widget (right_box, PackType.END);
            notebook.set_scrollable (true);
            notebook.can_focus = false;
            notebook.set_group_name ("pantheon-terminal");

            //container.pack_start (notebook, true, true, 0);

            add (notebook);

            /* Set up the Add button */
            add_button = new Button ();
            Image add_image = null;
            add_image = new Image.from_icon_name ("list-add-symbolic", IconSize.MENU);
            add_button.set_image (add_image);
            add_button.show ();
            add_button.set_relief (ReliefStyle.NONE);
            add_button.set_tooltip_text ("Open a new tab");
            right_box.pack_start (add_button, false, false, 0);

            update_saved_state ();
        }

        private void connect_signals () {
            
            add_button.clicked.connect (() => { new_tab (false); } );

            notebook.switch_page.connect (on_switch_page);
            notebook.page_removed.connect (() => { if (notebook.get_n_pages () == 0) this.destroy (); });
        }
        
        void on_switch_page (Widget page, uint n) {
            current_tab_label = notebook.get_tab_label (page) as TabWithCloseButton;
            current_tab = notebook.get_nth_page ((int) n);
            current_terminal = ((Grid) page).get_child_at (0, 0) as TerminalWidget;
            page.grab_focus ();
        }

        public void remove_page (int page) {
            notebook.remove_page (page);
        
            if (notebook.get_n_pages () == 0)
                destroy ();
        }

        public override bool scroll_event (EventScroll event) {
            switch (event.direction) {
                case ScrollDirection.UP:
                case ScrollDirection.RIGHT:
                    notebook.page++;
                    break;
                case ScrollDirection.DOWN:
                case ScrollDirection.LEFT:
                    notebook.page--;
                    break;
            }
            return false;
        }

        private void new_tab (bool first) {
            /* Set up terminal */
            var t = new TerminalWidget (main_actions, ui);
            var g = new Grid ();
            var sb = new Scrollbar (Orientation.VERTICAL, t.vadjustment);
            g.attach (t, 0, 0, 1, 1);
            g.attach (sb, 1, 0, 1, 1);
            
            current_terminal = t;

            /* Add the terminal to the GUI */
            t.vexpand = true;
            t.hexpand = true;

            /* Set up the virtual terminal */
            t.active_shell ();
            
            /* Create a new tab with the terminal */
            var tab = new TabWithCloseButton (_("Terminal"));
            tab.terminal = current_terminal;
            tab.width_request = 64;
            int new_page = notebook.get_current_page () + 1;
            notebook.insert_page (g, tab, new_page);
            notebook.set_tab_reorderable (notebook.get_nth_page (new_page), true);
            notebook.set_tab_detachable (notebook.get_nth_page (new_page), true);
            
            /* Bind signals to the new tab */
            tab.clicked.connect (() => { 
                /* It was doing something */
                if (t.has_foreground_process ()) {
                    var d = new ForegroundProcessDialog ();
                    if (d.run () == 1)
                        notebook.remove (g); 
                    d.destroy ();
                }

                tab.terminal.child_exited ();
            });

            notebook.switch_page.connect ((page, page_num) => { if (notebook.page_num (t) == (int) page_num) tab.set_notification (false); });
            focus_in_event.connect (() => { if (notebook.page_num (t) == notebook.get_current_page ()) tab.set_notification (false); return false; });
            theme_changed.connect (() => { set_terminal_theme (t); });
            t.child_exited.connect (() => { remove_page (notebook.page); });

            t.window_title_changed.connect (() => {

                string new_text = t.get_window_title ();
                int i;

                for (i = 0; i < new_text.length; i++) {
                    if (new_text[i] == ':') {
                        new_text = new_text[i + 2:new_text.length];
                        break;
                    }
                }

                if (new_text.length > 50) {
                    new_text = new_text[new_text.length - 50: new_text.length];
                }

                tab.set_text (new_text);
            });

            t.task_over.connect (() => {
                try {
                    var notification = new Notification (t.get_window_title (), "Task finished.", "utilities-terminal");
                    notification.show ();
                } catch (Error err) {
                    stderr.printf ("Unable to send notification: %s", err.message);
                }
            });

            tab.grab_focus ();
            //t.grab_focus ();
            set_terminal_theme (t);
            g.show_all ();
            notebook.page = new_page;
        }

        public void set_terminal_theme (TerminalWidget t) {

            t.set_font (font);
            t.set_color_background (bgcolor);
            t.set_color_foreground (fgcolor);
        }

        public void set_theme () {

            string theme = "dark";

            if (theme == "normal") {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = false;

                /* Get the system's style */
                realize ();
                font = FontDescription.from_string (get_system_font ());
                bgcolor = get_style ().bg[StateType.NORMAL];
                fgcolor = get_style ().fg[StateType.NORMAL];
            } else {
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = true;

                /* Get the system's style */
                realize ();
                font = FontDescription.from_string (get_system_font ());
                bgcolor = get_style ().bg[StateType.NORMAL];
                fgcolor = get_style ().fg[StateType.NORMAL];
            }

            theme_changed ();
        }

        static string get_system_font () {

            string font_name = null;

            var settings = new GLib.Settings("org.gnome.desktop.interface");
            font_name = settings.get_string("monospace-font-name");

            return font_name;
        }

        /*public void preferences () {

            var dialog = new Preferences ("Preferences", this);
            dialog.show_all ();
            dialog.run ();
            dialog.destroy ();
        }*/


        private void restore_saved_state () {
            
            debug ("%d, %d", PantheonTerminal.saved_state.window_width, PantheonTerminal.saved_state.window_height);            
            
            default_width = PantheonTerminal.saved_state.window_width;
            default_height = PantheonTerminal.saved_state.window_height;

            if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.MAXIMIZED)
                maximize ();
            else if (PantheonTerminal.saved_state.window_state == PantheonTerminalWindowState.FULLSCREEN)
                fullscreen ();
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

        protected override bool delete_event (Gdk.EventAny event) {
            update_saved_state ();
            action_quit ();
            return false;
        }
        
        void action_quit () {
 
            if (app.get_windows ().length () >= 1)
                destroy ();

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
            current_tab_label.clicked ();
        }

        void action_new_window () {
            app.new_window ();
            //var window = new PantheonTerminalWindow (app);
            //window.show ();            
        }

        void action_new_tab () {
            new_tab (false);
        }
        
        void action_about () {
            app.show_about (this);
        }
        
        static const Gtk.ActionEntry[] main_entries = {

           { "Quit", Gtk.Stock.QUIT, N_("Quit"), "<Control>q", N_("Quit"), action_quit },
           { "CloseTab", Gtk.Stock.CLOSE, N_("Close"), "<Control><Shift>w", N_("Close"), action_close_tab },
           { "New window", "window-new", N_("New Window"), "<Control><Shift>n", N_("Open a new window"), action_new_window }, 
           { "New tab", Gtk.Stock.NEW, N_("New Tab"), "<Control><Shift>t", N_("Create a new tab"), action_new_tab },
           { "Copy", "gtk-copy", N_("Copy"), "<Control><Shift>c", N_("Copy the selected text"), action_copy },
           { "Paste", "gtk-paste", N_("Paste"), "<Control><Shift>v", N_("Paste some text"), action_paste },
           { "Select All", Gtk.Stock.SELECT_ALL, N_("Select All"), "<Control><Shift>a", N_("Select all the text in the terminal"), action_select_all },
           { "About", Gtk.Stock.ABOUT, N_("About"), null, N_("Show about window"), action_about }
        };

    }

} // Namespace

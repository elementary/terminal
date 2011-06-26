//  
//  Copyright (C) 2011 Adrien Plazas
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
// 
// 
//  Authors:
//      Adrien Plazas <kekun.plazas@laposte.net>
//  Artists:
//      Daniel Foré <daniel@elementaryos.org>
// 

/* Notify with system bubbles if the window is not focused (tag FIXME)
 * Keep focus on terminal if terminal focused
 * 
 * For 0.2
 * Set text colors
 * Set preferences via GSettings ? (legacy theme)
 * Use stepped window resize ? (usefull if using another terminal background color than the one from the window)
 * Do not focus on buttons (is it useful ?) (guess not)
 */

using Gtk;
using Gdk;
using Vte;
using Pango;
//~ using Notify;

using Resources;

namespace PantheonTerminal
{
    private class PantheonTerminal : Gtk.Window
    {
		public signal void theme_changed();
		
        Notebook notebook;
        FontDescription font;
        Gdk.Color bgcolor;
        Gdk.Color fgcolor;
        
        bool window_focus = false;
        
        string[] args;
        
    //~     Notify.Notification notification;
        
        private PantheonTerminal(string[] args)
        {
            this.args = args;
            foreach (string arg in args)
				stdout.printf("%s\n", arg);
            
//~             Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;
            set_title("Terminal");
            default_width = 640;
            default_height = 400;
            destroy.connect(close);
            
            // Check if the window have the focus
            focus_in_event.connect(() => { window_focus = true; return false; });
            focus_out_event.connect(() => { window_focus = false; return false; });
                    
            notebook = new Notebook();
//~             var left_box = new HBox(false, 0);
            var right_box = new HBox(false, 0);
//~             left_box.show();
            right_box.show();
//~             notebook.set_action_widget(left_box, PackType.START);
            notebook.set_action_widget(right_box, PackType.END);
            notebook.set_scrollable(true);
            add(notebook);
            
//~             left_box.set_size_request(10, 0);
            
            // Set "New tab" button
            var add_button = new Button();
            add_button.set_image(new Image.from_stock(Stock.ADD, IconSize.MENU));
            add_button.show();
            add_button.set_relief(ReliefStyle.NONE);
            add_button.set_tooltip_text("Open a new tab");
            add_button.clicked.connect(() => { new_tab(false); } );
            right_box.pack_start(add_button, false, false, 0);
                    
            // Try to set the icon FIXME
            Pixbuf icon = new Pixbuf(Colorspace.RGB, true, 8, 1, 1);
            try { IconTheme.get_default().load_icon("terminal", 16, IconLookupFlags.FORCE_SVG); } catch (Error er) {}
            set_icon(icon);
            
            // Set the theme
            set_theme();
            
            show_all();
            new_tab(true);
        }
        
        private void new_tab(bool first)
        {
            // Set up terminal
            var t = new TerminalWithNotification();
            if (first)
				t.fork_command(args[0], args, null, null, true, true, true);
			else
				t.fork_command(null, null, null, null, true, true, true);
			
                
            t.show();
            
            // Create a new tab with the terminal
            var tab = new TabWithCloseButton("Terminal");
            notebook.insert_page(t, tab, notebook.get_current_page() + 1);
            notebook.next_page();
            notebook.set_tab_reorderable(t, true);
            
            // Set connections
            tab.clicked.connect(() => { notebook.remove(t); });
            t.window_title_changed.connect(() => { tab.set_text(t.get_window_title()); });
            notebook.switch_page.connect((page, page_num) => { if (notebook.page_num(t) == (int) page_num) tab.set_notification(false); });
            focus_in_event.connect(() => { if (notebook.page_num(t) == notebook.get_current_page()) tab.set_notification(false); return false; });
            t.preferences.connect(preferences);
            t.about.connect(about);
            t.child_exited.connect(() => { t.fork_command(null, null, null, null, true, true, true); });
            theme_changed.connect(() => { set_terminal_theme(t); });
//~             t.contents_changed.connect(() => { stdout.printf("pty %i\n", t.get_pty()); });
            
            // If a task is over
            t.task_over.connect(() => {
                if (notebook.page_num(t) != notebook.get_current_page() || !window_focus)
                    tab.set_notification(true);
                if (!window_focus)
                {
                    try
                    { GLib.Process.spawn_command_line_async("notify-send \"" + t.get_window_title() + "\" \"Task over\""); }
                    catch
                    {  }
                }
    //~                 notification = (Notify.Notification)GLib.Object.new (
    //~                     typeof (Notify.Notification),
    //~                     "summary", "sum",
    //~                     "body", "message",
    //~                     "icon-name", "");
                        // Notify OSD
    //~                 notification = new Notification("test", "test", "test");
    //~                 try { notification.show(); }
    //~                 catch {}
                });
            
            // Set up style
            set_terminal_theme(t);
//~             t.set_font(font);
//~             t.set_color_background(bgcolor);
//~             t.set_color_foreground(fgcolor);
//~             t.set_background_transparent(true);
//~ 			t.set_opacity(32000);
        }
        
        public void set_terminal_theme(TerminalWithNotification t)
		{
			// Dark theme
			Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;
			t.set_font(font);
			t.set_color_background(bgcolor);
            t.set_color_foreground(fgcolor);
		}
		
		public void set_theme()
		{
			Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;
			
			// Get the system's style
            realize();
            font = FontDescription.from_string(system_font());
            bgcolor = get_style().bg[StateType.NORMAL];
            fgcolor = get_style().fg[StateType.NORMAL];
            			
			theme_changed();
		}
		
		static string system_font()
        {
            string font_name = null;
            /* Wait for GNOME 3 FIXME
             * var settings = new GLib.Settings("org.gnome.desktop.interface");
             * font_name = settings.get_string("monospace-font-name");
             */
            font_name = "Droid Sans Mono 10";
            return font_name;
        }
        
        public void about()
        {
            show_about_dialog(this,
                "program-name", Resources.APP_TITLE,
                "version", Resources.VERSION,
                "comments", Resources.COMMENTS,
                "copyright", Resources.COPYRIGHT,
                "license", Resources.LICENSE,
                "website", Resources.WEBSITE_URL,
                "website-label",  Resources.WEBSITE_LABEL,
                "authors", Resources.AUTHORS,
                "artists", Resources.ARTISTS,
//~     				"logo", new Pixbuf.from_file(Resources.ICON_ABOUT_LOGO),
//~      				"translator-credits", _("translator-credits"), // FIXME
                null);
        }
        
        public void preferences()
        {
            stdout.printf("Preferences not yet available.\n");
        }
        
        
        private void close()
        {
            Gtk.main_quit();
        }
        
        private static void main(string[] args)
        {
            Gtk.init(ref args);
            new PantheonTerminal(args[1:args.length]);
            Gtk.main();
        }
    }
    
    public class TabWithCloseButton : HBox
    {
        public signal void clicked();
        
        private Button button;
        private Label label;
        private string text;
        bool notification = false;
        
        public TabWithCloseButton(string text)
        {
            this.text = text;
            
            // Button
            button = new Button();
            button.set_image(new Image.from_stock(Stock.CLOSE, IconSize.MENU));
            button.show();
            button.set_relief(ReliefStyle.NONE);
            button.clicked.connect(() => { clicked(); });
            
            // Label
            label = new Label(text);
            label.show();
            
            // Pack the elements
            pack_start(button, false, true, 0);
            pack_end(label, true, true, 0);
            
            show();
        }
        
        public void set_notification(bool notification)
        {
            this.notification = notification;
            if (notification)
            { label.set_markup("<span color=\"#18a0c0\">"+text+"</span>"); }
            else
            { label.set_markup(text); }
        }
        
        public void set_text(string text)
        {
            this.text = text;
            set_notification(notification);
        }
    }
}

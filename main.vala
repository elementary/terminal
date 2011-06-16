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
//      Daniel Fore <???@gmail.com>
// 

/* Set system font
 * Set preferences via GSettings ?
 * Set notifications with tab color change and OSD bubble
 * Do not focus on button
 * Improve window resize
 * Add drag and drop
 * Add menu, copy, past, about, etc
 * Do not notify on resize event
 */

using Gtk;
using Vte;
using Notify;

private class PantheonTerminal : Window
{
    Notebook notebook;
    Gdk.Color bgcolor;
    Gdk.Color fgcolor;
    
    Notify.Notification notification;
    
	private PantheonTerminal()
	{
        Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;
        set_title("Terminal");
                
        notebook = new Notebook();
		var left_box = new HBox(false, 0);
        var right_box = new HBox(false, 0);
        left_box.show();
        right_box.show();
        notebook.set_action_widget(left_box, PackType.START);
        notebook.set_action_widget(right_box, PackType.END);
        
        left_box.set_size_request(10, 0);
        
        // Set "Add" button
        var add_button = new Button();
        add_button.set_image(new Image.from_stock(Stock.ADD, IconSize.MENU));
        add_button.show();
        add_button.set_relief(ReliefStyle.NONE);
        add_button.set_tooltip_text("Open a new tab");
        
        right_box.pack_start(add_button);
        
        add_button.clicked.connect(add_clicked);
        

        
        // Get the system's style
        realize();
        bgcolor = get_style().bg[StateType.NORMAL];
        fgcolor = get_style().fg[StateType.NORMAL];
        
		//connect exiting on the terminal with quiting the app
		destroy.connect ( (t)=> { Gtk.main_quit(); } );
		add(notebook);
		//try to set the icon
//~ 		try{
//~ 			set_icon_from_file("/usr/share/pixmaps/gnome-term.png");
//~ 		}catch(Error er)
//~ 		{
//~ 			//we don't really need to print this error
//~ 			stdout.printf(er.message);
//~ 		}
		show_all();
        add_clicked();
	}
    
    private void add_clicked()
    {
        // Set up terminal
        var t = new Terminal();
        t.fork_command(null,null,null,null, true, true,true);
        t.set_size_request(600, 400);
        t.show();
        
        // Create a new tab with the terminal
        notebook.append_page(t, new Label("Terminal"));
        notebook.set_tab_reorderable(t, true);
        
        // Unnotify a page when switching to it
        notebook.switch_page.connect((page) => { notebook.set_tab_label(page, new Label(notebook.get_tab_label_text(page))); });
        
        // Set up style
        t.set_color_background(bgcolor);
        t.set_color_foreground(fgcolor);
        t.window_title_changed.connect(() => { notify(t); });
    }
    
    private void notify(Terminal t)
    {
        var title = new Label(t.get_window_title());
        var color = new Gdk.Color();
        color.red = (uint16) ((double) 65535 * 0.1);
        color.green = (uint16) ((double) 65535 * 0.65);
        color.blue = (uint16) ((double) 65535 * 0.85);
//~         title.modify_fg(StateType.PRELIGHT, color);
        if (notebook.page_num(t) != notebook.get_current_page())
            title.modify_fg(StateType.PRELIGHT, color);
            title.set_state(StateType.PRELIGHT);
        notebook.set_tab_label(t, title); // Add color, bold, somthing, to the label
//~         else
//~             notebook.set_tab_label(t, new Label(t.get_window_title()));
//~             notification = (Notify.Notification)GLib.Object.new (
//~                             typeof (Notify.Notification),
//~                             "summary", "Title",
//~                             "body", "Artist\nAlbum");
//~         notification = new Notify.Notification(t.get_window_title(), "Task over\n", "");
//~         stdout.printf("%s, task over\n", t.get_window_title());
    }
    
	private static void main(string[] args)
	{
		Gtk.init(ref args);
		new PantheonTerminal();
		Gtk.main();
	}
}

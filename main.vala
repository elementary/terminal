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

/* Use system font
 * Set preferences via GSettings ?
 * Do not focus on buttons
 * Improve window resize
 * Add menu, copy, past, about, etc
 * Notify with system bubbles if the window is not focused
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
        destroy.connect(close);
                
        notebook = new Notebook();
		var left_box = new HBox(false, 0);
        var right_box = new HBox(false, 0);
        left_box.show();
        right_box.show();
        notebook.set_action_widget(left_box, PackType.START);
        notebook.set_action_widget(right_box, PackType.END);
        notebook.set_scrollable(true);
        add(notebook);
        
        left_box.set_size_request(10, 0);
        
        // Set "New tab" button
        var add_button = new Button();
        add_button.set_image(new Image.from_stock(Stock.ADD, IconSize.MENU));
        add_button.show();
        add_button.set_relief(ReliefStyle.NONE);
        add_button.set_tooltip_text("Open a new tab");
        add_button.clicked.connect(new_tab);
        right_box.pack_start(add_button, false, false, 0);
                
        // Get the system's style
        realize();
        bgcolor = get_style().bg[StateType.NORMAL];
        fgcolor = get_style().fg[StateType.NORMAL];
		        
		// Try to set the icon FIXME
        Gdk.Pixbuf icon = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 1, 1);
        try { IconTheme.get_default().load_icon("terminal", 16, IconLookupFlags.FORCE_SVG); } catch (Error er) {}
		try { set_icon(icon); } catch(Error er) {}
        
		show_all();
        new_tab();
	}
    
    private void new_tab()
    {
        // Set up terminal
        var t = new TerminalWithNotification();
        t.fork_command(null,null,null,null, true, true,true);
        t.set_size_request(600, 400);
        
        // Test the "task_over" signal
        t.task_over.connect(() => {stdout.printf("task_over\n");});

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
        t.task_over.connect(() => { if (notebook.page_num(t) != notebook.get_current_page()) tab.set_notification(true); });
        
        // Set up style
        t.set_color_background(bgcolor);
        t.set_color_foreground(fgcolor);
    }
    
    private void close()
    {
        Gtk.main_quit();
    }
    
	private static void main(string[] args)
	{
		Gtk.init(ref args);
		new PantheonTerminal();
		Gtk.main();
	}
}

public class TerminalWithNotification : Terminal
{
    public signal void task_over();
    
    long last_row_count = 0;
    long last_column_count = 0;
    
    public TerminalWithNotification()
    {
        window_title_changed.connect(check_for_notification);
    }
    
    private void check_for_notification()
    {
        /* Curently I use this trick to know if a task is over, the drawnback is
         * that when the window is resized and a notification should be received,
         * the user will not be notified.
         */
        if (get_row_count() == last_row_count && get_column_count() == last_column_count)
            task_over();
        last_row_count = get_row_count();
        last_column_count = get_column_count();
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

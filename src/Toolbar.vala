// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011 David Gomes <davidrafagomes@gmail.com>
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
using Granite.Widgets;

namespace PantheonTerminal {
    
    public class Toolbar : Gtk.Toolbar {

        private PantheonTerminalWindow window;

        public ToolButton new_button;
        public ToolButton copy_button;
        public ToolButton paste_button;
        public ToolButton zoom_in_button;
        public ToolButton zoom_out_button;
        public ToolButton stop_button;
        public ToolButton pause_button;
        public ToolButton app_menu_button;

        public enum ToolButton {
            NEW_BUTTON,
            COPY_BUTTON,
            PASTE_BUTTON,
            ZOOM_IN_BUTTON,
            ZOOM_OUT_BUTTON,
            STOP_BUTTON,
            PAUSE_BUTTON,
            APPMENU_BUTTON,
        }

        public enum ToolEntry {
            SEARCH_ENTRY,
        }

        public Toolbar (PantheonTerminalWindow parent, Gtk.ActionGroup action_group) {

            this.window = parent;

            get_style_context ().add_class ("primary-toolbar");

            /*
            FIXME Doesn't seem to be working on compiling
            new_button = action_group.get_action ("New").create_tool_item () as Gtk.ToolButton;
            copy_button = action_group.get_action ("Copy").create_tool_item () as Gtk.ToolButton;
            paste_button = action_group.get_action ("Paste").create_tool_item () as Gtk.ToolButton;

            add (new_button);
            add (copy_button);
            add (paste_button);*/
        }
    }
}

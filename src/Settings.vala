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

    public SavedState saved_state;
    public Settings settings;

    public enum PantheonTerminalWindowState {
        NORMAL = 0,
        MAXIMIZED = 1,
        FULLSCREEN = 2
    }

    public enum cursor_shape {
        BLOCK = 0,
        IBEAM = 1,
        UNDERLINE = 2
    }

    public class SavedState : Granite.Services.Settings {

        public int window_width { get; set; }
        public int window_height { get; set; }
        public PantheonTerminalWindowState window_state { get; set; }
        public string[] tabs { get; set; }
        public int opening_x { get; set; }
        public int opening_y { get; set; }
        public double zoom { get; set; }

        public SavedState () {
            base ("io.elementary.terminal.saved-state");
        }
    }

    public class Settings : Granite.Services.Settings {

        public int scrollback_lines { get; set; }
        public bool follow_last_tab { get; set; }
        public bool remember_tabs { get; set; }
        public bool alt_changes_tab { get; set; }
        public bool audible_bell { get; set; }
        public bool natural_copy_paste { get; set; }
        public bool unsafe_paste_alert { get; set; }

        public string foreground { get; set; }
        public string background { get; set; }
        public string cursor_color { get; set; }
        public Vte.CursorShape cursor_shape { get; set; }
        public string palette { get; set; }

        public string shell { get; set; }
        public string encoding { get; set; }
        public string font { get; set; }
        public bool allow_bold { get; set; }
        public bool save_exited_tabs { get; set; }
        public Granite.Widgets.DynamicNotebook.TabBarBehavior tab_bar_behavior { get; set; }

        public Settings () {
            base ("io.elementary.terminal.settings");
        }
    }
}

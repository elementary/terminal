/*
* Copyright (c) 2011-2019 elementary, Inc. (https://elementary.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License version 3, as published by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

namespace Terminal {
    public Settings settings;

    public class Settings : Granite.Services.Settings {
        public int scrollback_lines { get; set; }
        public bool follow_last_tab { get; set; }
        public bool remember_tabs { get; set; }
        public bool alt_changes_tab { get; set; }
        public bool audible_bell { get; set; }
        public bool natural_copy_paste { get; set; }
        public bool prefer_dark_style { get; set; }
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

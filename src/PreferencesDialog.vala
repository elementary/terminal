// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

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
using Granite.Widgets;

namespace PantheonTerminal {

    public class Preferences : Dialog {

        private PantheonTerminalWindow parent_window;

        public StaticNotebook main_static_notebook;

        public Preferences (string? title, PantheonTerminalWindow window) {

            this.parent_window = window;
            this.title = title;
            this.type_hint = Gdk.WindowTypeHint.DIALOG;
            this.set_transient_for (parent_window);
            this.resizable = false;
            set_default_size (550, 250);

            main_static_notebook = new StaticNotebook ();

            create_layout ();
        }

        private void create_layout () {

            var general = new Label (_("General"));
            main_static_notebook.append_page (get_general_box (), general);

            var second = new Label (_("Appearance"));
            main_static_notebook.append_page (get_appearance_box (), second);

            ((Gtk.Box) get_content_area()).add (main_static_notebook);

            add_button (Stock.CLOSE, ResponseType.ACCEPT);
        }

        Gtk.Widget get_general_box () {

            var general_grid = new Gtk.Grid ();
            general_grid.row_spacing = 5;
            general_grid.column_spacing = 5;
            general_grid.margin_left = 12;
            general_grid.margin_right = 12;
            general_grid.margin_top = 12;
            general_grid.margin_bottom = 12;

            var scrollback_counter = new SpinButton.with_range (1, 2147483647, 1);
            settings.schema.bind ("scrollback-lines", scrollback_counter, "value", SettingsBindFlags.DEFAULT);

            int row = 0;

            var scrolling_label = new Label (_("Scrolling"));
            scrolling_label.set_markup ("<b>%s</b>".printf (_("Scrolling")));
            general_grid.attach (scrolling_label, 0, row, 2, 1);
            scrolling_label.hexpand = scrolling_label.vexpand = true;
            scrolling_label.halign = Gtk.Align.START;
            row++;

            var scrollback_label = new Label (_("Scrollback lines:"));
            add_option (general_grid, scrollback_label, scrollback_counter, ref row);

            return general_grid;
        }

        Gtk.Widget get_appearance_box () {

            var show_toolbar = new Switch ();
            settings.schema.bind ("show-toolbar", show_toolbar, "active", SettingsBindFlags.DEFAULT);

            var transparency_switch = new Switch ();
            settings.schema.bind ("background-transparent", transparency_switch, "active", SettingsBindFlags.DEFAULT);

            //var opacity_scale = new HScale.with_range (0, 100, 1);
            //settings.schema.bind ("opacity", opacity_scale, "digits", SettingsBindFlags.DEFAULT);
            var opacity_scale = new SpinButton.with_range (0.0, 1.0, 0.1);
            settings.schema.bind ("opacity", opacity_scale, "value", SettingsBindFlags.DEFAULT);            
            settings.schema.bind ("background-transparent", opacity_scale, "sensitive", SettingsBindFlags.DEFAULT);

            var general_grid = new Gtk.Grid ();
            general_grid.row_spacing = 5;
            general_grid.column_spacing = 5;
            general_grid.margin_left = 12;
            general_grid.margin_right = 12;
            general_grid.margin_top = 12;
            general_grid.margin_bottom = 12;

            int row = 0;
            var label = new Label (_("Show toolbar:"));
            add_option (general_grid, label, show_toolbar, ref row);

            var transparency_label  = new Label (_("Background transparent:"));
            add_option (general_grid, transparency_label, transparency_switch, ref row);

            var opacity_label = new Label (_("Background opacity:"));
            opacity_label.margin_left = 20;
            add_option (general_grid, opacity_label, opacity_scale, ref row);

            return general_grid;
        }

        void add_option (Gtk.Grid grid, Gtk.Widget label, Gtk.Widget switcher, ref int row) {

            label.hexpand = true;
            label.halign = Gtk.Align.START;
            switcher.halign = Gtk.Align.END;
            grid.attach (label, 0, row, 1, 1);
            grid.attach_next_to (switcher, label, Gtk.PositionType.RIGHT, 1, 1);
            row ++;
        }

    }

} // Namespace

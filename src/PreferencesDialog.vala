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

    public class Preferences : Dialog {

        private PantheonTerminalWindow parent_window;

        public StaticNotebook main_static_notebook;

        private CheckButton view_tabs;

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

            // TODO Finish Preferences Dialog
            var general = new Label (_("General"));
            main_static_notebook.append_page (get_general_box (), general);
        }

        Gtk.Widget get_general_box () {
            
            view_tabs = new CheckButton ();

            var general_grid = new Gtk.Grid ();
            general_grid.row_spacing = 5;
            general_grid.column_spacing = 5;
            general_grid.margin_left = 12;
            general_grid.margin_right = 12;
            general_grid.margin_top = 12;
            general_grid.margin_bottom = 12;

            return general_grid;
        }

    }

} // Namespace


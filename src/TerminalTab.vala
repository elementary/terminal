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

namespace PantheonTerminal {

    public class TerminalTab : Gtk.Box {

        public signal void clicked ();

        private Button button;
        public Label label;
        public string text;

        public bool reorderable = true;
        public bool detachable = true;

        public TerminalWidget terminal;
        
        public int index;

        public TerminalTab (string text) {
            /* Set up the GUI */
            this.text = text;
            var hbox = new HBox (false, 0);

            /* Add the button */
            button = new Button ();
            button.set_image (new Image.from_stock (Stock.CLOSE, IconSize.MENU));
            button.show ();
            button.set_relief (ReliefStyle.NONE);
            button.clicked.connect (() => { clicked (); });
            button.tooltip_text = "Close the tab";

            /* Add the label */
            label = new Label (text);
            label.show ();

            /* Pack all the elements */
            hbox.pack_start (button, false, true, 0);
            hbox.pack_end (label, true, true, 0);

            add (hbox);
            button_press_event.connect (on_button_press_event);

            show_all ();
        }

        public void set_text (string text) {
            this.text = text;
            label.set_text (text);
        }

        bool on_button_press_event (Gdk.EventButton event) {
            if (event.button == 2) { 
                clicked ();
                return true;
            }
            return false;
        }
    }
} // Namespace

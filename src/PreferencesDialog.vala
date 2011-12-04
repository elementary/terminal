// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011 David gomes <davidrafagomes@gmail.com>
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
using Resources;

namespace PantheonTerminal {

    public class Preferences : Dialog {

        public Preferences (string? title, Window main_window) {

            this.title = title;
            this.type_hint = Gdk.WindowTypeHint.DIALOG;
            this.set_transient_for (main_window);
            this.resizable = false;

            set_default_size (550, 250);

            create_layout ();

        }

        private void create_layout () {

            // TODO Finish Preferences Dialog
        }

    }

} // Namespace


// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011-2012 Mario Guerriero <mefrio.g@gmail.com>
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

using Vte;

namespace PantheonTerminal {

    public class ForegroundProcessDialog : Gtk.MessageDialog {

        public ForegroundProcessDialog () {
            use_markup = true;
            set_markup ("<b>" + _("There is an active process on this shell!") + "</b>\n\n" +
                      _("Do you want to stay on the shell?"));
            
            var button = new Gtk.Button.with_label (_("Stay on this terminal"));
            button.show ();
            add_action_widget (button, 0);
            
            button = new Gtk.Button.with_label (_("Kill terminal"));
            button.show ();
            add_action_widget (button, 1);
        }
        
        public ForegroundProcessDialog.before_close () {
            use_markup = true;
            set_markup ("<b>" + _("There is an active process on this terminal!") + "</b>\n\n" +
                      _("Do you want to close this terminal?"));
            
            var button = new Gtk.Button.with_label (_("Stay"));
            button.show ();
            add_action_widget (button, 0);
            
            button = new Gtk.Button.with_label (_("Close terminal"));
            button.show ();
            add_action_widget (button, 1);
        }

    }

}

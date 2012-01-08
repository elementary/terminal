// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011 Mario Guerriero <mefrio.g@gmail.com>
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

using Granite;
using Granite.Services;

using PantheonTerminal;

namespace PantheonTerminal {

    public class PantheonTerminal : Granite.Application {

            public GLib.List <PantheonTerminalWindow> windows;
            public int nwindows = 0;
            
            static string app_cmd_name;

            construct {
            /*
                build_data_dir = Constants.DATADIR;
                build_pkg_data_dir = Constants.PKGDATADIR;
                build_release_name = Constants.RELEASE_NAME;
                build_version = Constants.VERSION;
                build_version_info = Constants.VERSION_INFO;
            */
                program_name = app_cmd_name;
                exec_name = app_cmd_name.down();
                app_years = "2011";
                app_icon = "utilities-terminal";
                app_launcher = "pantheon-terminal.desktop";
                application_id = "net.launchpad.pantheon-terminal";
                main_url = "https://launchpad.net/pantheon-terminal";
                bug_url = "https://bugs.launchpad.net/pantheon-terminal";
                help_url = "https://answers.launchpad.net/pantheon-terminal";
                translate_url = "https://translations.launchpad.net/pantheon-terminal";
                about_authors = { "Adrien Plazas <kekun.plazas@lapsote.com>" };
                //about_documenters = {"",""};
                about_artists = { "Daniel Foré <daniel@elementaryos.org>" };
                about_translators = "Launchpad Translators";
                about_license_type = License.GPL_3_0;

            }

        public PantheonTerminal () {

            Logger.initialize ("PantheonTerminal");
            Logger.DisplayLevel = LogLevel.DEBUG;
            
            windows = new GLib.List <PantheonTerminalWindow> ();
            
            saved_state = new SavedState ();
            settings = new Settings ();
        }

        protected override void activate () {

            var window = new PantheonTerminalWindow (this);
            window.show ();
            windows.append (window);
            nwindows++;
        }

        public static int main(string[] args) {

                app_cmd_name = "Pantheon Terminal";

                var app = new PantheonTerminal ();
                return app.run (args);
        }
    }
} // Namespace

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
    [DBus (name="io.elementary.terminal")]
    public class DBus {
        [DBus (visible = false)]
        public signal void finished_process (string terminal_id, string process, int exit_status);

        public DBus () {
        }

        public void process_finished (string terminal_id, string process, int exit_status) {
            finished_process (terminal_id, process, exit_status);
        }
    }
}

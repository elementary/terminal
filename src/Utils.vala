/*
* Copyright (c) 2011-2020 elementary, Inc. (https://elementary.io)
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


namespace Terminal.Utils {
    public string? sanitize_path (string _path, string shell_location, bool add_file_scheme = true) {
        /* Remove trailing whitespace, ensure scheme, substitute leading "~" and "..", remove extraneous "/" */
        string scheme = "", path = "";
        var parts_scheme = _path.split ("://", 2);
        if (parts_scheme.length == 2) {
            scheme = parts_scheme[0] + "://";
            path = parts_scheme[1];
        } else if (parts_scheme.length == 1 ) {
            if (add_file_scheme) {
                scheme = "file://";
            }

            path = _path;
        } else {
            critical ("Invalid path");
            return null;
        }

        path = Uri.unescape_string (path);
        if (path == null) {
            return null;
        }

        path = strip_uri (path);

        do {
            path = path.replace ("//", "/");

        } while (path.contains ("//"));

        // If just basename of file then assume in current shell location
        if (!path.contains (Path.DIR_SEPARATOR_S)) {
            path = string.join (Path.DIR_SEPARATOR_S, ".", path);
        }

        var parts_sep = path.split (Path.DIR_SEPARATOR_S, 3);
        var index = 0;
        while (parts_sep[index] == null && index < parts_sep.length - 1) {
            index++;
        }

        if (parts_sep[index] == "~") {
            parts_sep[index] = Environment.get_home_dir ();
        } else if (parts_sep[index] == ".") {
            parts_sep[index] = shell_location;
        } else if (parts_sep[index] == "..") {
            parts_sep[index] = construct_parent_path (shell_location);
        }

        var result = scheme + string.joinv (Path.DIR_SEPARATOR_S, parts_sep).replace ("//", "/");
        return result;
    }

    /*** Simplified version of PF.FileUtils function, with fewer checks ***/
    public string get_parent_path_from_path (string path) {
        if (path.length < 2) {
            return Path.DIR_SEPARATOR_S;
        }

        StringBuilder string_builder = new StringBuilder (path);
        if (path.has_suffix (Path.DIR_SEPARATOR_S)) {
            string_builder.erase (string_builder.str.length - 1, -1);
        }

        int last_separator = string_builder.str.last_index_of (Path.DIR_SEPARATOR_S);
        if (last_separator < 0) {
            last_separator = 0;
        }

        string_builder.erase (last_separator, -1);
        return string_builder.str + Path.DIR_SEPARATOR_S;
    }

    private string construct_parent_path (string path) {
        if (path.length < 2) {
            return Path.DIR_SEPARATOR_S;
        }

        var sb = new StringBuilder (path);

        if (path.has_suffix (Path.DIR_SEPARATOR_S)) {
            sb.erase (sb.str.length - 1, -1);
        }

        int last_separator = sb.str.last_index_of (Path.DIR_SEPARATOR_S);
        if (last_separator < 0) {
            last_separator = 0;
        }
        sb.erase (last_separator, -1);

        string parent_path = sb.str + Path.DIR_SEPARATOR_S;

        return parent_path;
    }

    private string? strip_uri (string? _uri) {
        string uri = _uri;
        /* Strip off any trailing spaces, newlines or carriage returns */
        if (_uri != null) {
            uri = uri.strip ();
            uri = uri.replace ("\n", "");
            uri = uri.replace ("\r", "");
        }

        return uri;
    }

    /**
     * Checks a string for possible unsafe contents before pasting
     *
     * @param clipboard contents containing terminal commands
     *
     * @param return localized explanation of risk
     *
     * @return true if safe, false if unsafe.
     */
    public bool is_safe_paste (string text, out string[]? msg_array) {
        string[] msgs = {};
        var newline_index = text.index_of ("\n"); // First occurrence of new line
        bool embedded_newline = newline_index >= 0 && newline_index < text.length - 1;
        if (embedded_newline || "&" in text || "|" in text || ";" in text ) {
            msgs += _("The pasted text may contain multiple commands");
        }

        if ("sudo " in text || "doas " in text || "run0 " in text || "pkexec " in text || "su " in text) {
            msgs += _("The pasted text may be trying to gain administrative access");
        }

        string[] skip_commands = {
            "--assume-yes",
            "-f",
            "--force",
            "--interactive=never",
            "-y",
            "--yes"
        };

        var words = text.split (" ");
        foreach (unowned var skip_command in skip_commands) {
            if (skip_command in words) {
                msgs += _("The pasted text includes a command to skip warnings and confirmations");
                break;
            }
        }

        if (msgs.length > 0) {
            msg_array = msgs;
            return false;
        } else {
            msg_array = null;
            return true;
        }
    }

    public string? escape_uri (string uri, bool allow_utf8 = true, bool allow_single_quote = true) {
        // We only want to allow '#' in appropriate position for fragment identifier, i.e. after the last directory separator.
        var placeholder = "::::::";
        var parts = uri.split (Path.DIR_SEPARATOR_S);
        parts[parts.length - 1] = parts[parts.length - 1].replace ("#", placeholder);
        var uri_to_escape = string.joinv (Path.DIR_SEPARATOR_S, parts);
        string rc = ((Uri.RESERVED_CHARS_GENERIC_DELIMITERS + Uri.RESERVED_CHARS_SUBCOMPONENT_DELIMITERS))
                    .replace ("#", "")
                    .replace ("*", "")
                    .replace ("~", "");

        if (!allow_single_quote) {
            rc = rc.replace ("'", "");
        }

        //Escape and then replace fragment identifier
        return Uri.escape_string (
            (Uri.unescape_string (uri_to_escape) ?? uri_to_escape),
            rc ,
            allow_utf8
        ).replace (placeholder, "#");
    }

    public bool valid_local_uri (string s, out string path) {
        var scheme = Uri.peek_scheme (s);
        path = "";
        string absolute_uri;
        if (scheme == null || scheme == "") {
            absolute_uri = "file:///" + s;
        } else if (scheme != "file") {
            return false;
        } else {
            absolute_uri = s;
        }

        try {
            if (!Uri.is_valid (absolute_uri, PARSE_RELAXED)) {
                return false;
            }

            var file = GLib.File.new_for_uri (absolute_uri);
            var type = file.query_file_type (NONE);
            if (type == DIRECTORY) {
                path = file.get_path ();
            } else if (type == REGULAR) {
                path = file.get_parent ().get_path ();
            } else {
                return false;
            }

            return true;
        } catch (Error e) {
            warning ("Error parsing uri - %s", e.message);
        }

        return false;
    }
}

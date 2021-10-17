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
    public string? sanitize_path (string _path, string shell_location) {
        /* Remove trailing whitespace, ensure scheme, substitute leading "~" and "..", remove extraneous "/" */
        string scheme, path;

        var parts_scheme = _path.split ("://", 2);
        if (parts_scheme.length == 2) {
            scheme = parts_scheme[0] + "://";
            path = parts_scheme[1];
        } else {
            scheme = "file://";
            path = _path;
        }

        path = Uri.unescape_string (path);
        if (path == null) {
            return null;
        }

        path = strip_uri (path);

        do {
            path = path.replace ("//", "/");

        } while (path.contains ("//"));

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

        var result = escape_uri (scheme + string.joinv (Path.DIR_SEPARATOR_S, parts_sep).replace ("//", "/"));
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

    private string? escape_uri (string uri, bool allow_utf8 = true, bool allow_single_quote = true) {
        // We only want to allow '#' in appropriate position for fragment identifier so replace '/#' with a reserved character sequence
        // not used in valid uris before escaping.
        var placeholder = "::::::";
        var uri_to_escape = uri.replace ("/#", placeholder);
        string rc = ((Uri.RESERVED_CHARS_GENERIC_DELIMITERS + Uri.RESERVED_CHARS_SUBCOMPONENT_DELIMITERS))
                    .replace ("#", "")
                    .replace ("*", "")
                    .replace ("~", "");

        if (!allow_single_quote) {
            rc = rc.replace ("'", "");
        }

        //Escape and then replace fragment identifier
        return Uri.escape_string ((Uri.unescape_string (uri_to_escape) ?? uri_to_escape), rc , allow_utf8).replace (placeholder, "/#");
    }

}

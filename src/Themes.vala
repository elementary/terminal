/*
* Copyright (c) 2020 elementary, Inc. (https://elementary.io)
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

public struct Terminal.Theme {
    string name;
    string palette;
}

public class Terminal.Themes {
    public const int PALETTE_SIZE = 19;
    public const string CUSTOM = "custom";
    public const string DARK = "dark";
    public const string HIGH_CONTRAST = "high-contrast";
    public const string LIGHT = "solarized-light";

    private static Gee.ArrayList<Theme?> themes = new Gee.ArrayList<Theme?> ();
    public static string active_name {
        get {
            var palette = get_active_palette ();

            foreach (Terminal.Theme theme in themes) {
                if (theme.palette == palette) {
                    return theme.name;
                }
            }

            return "Custom";
        }
        set {
            foreach (var theme in themes) {
                if (theme.name == value) {
                    set_active_palette (theme.palette);
                }
            }
        }
    }

    // format is color01:color02:...:color16:background:foreground:cursor
    static construct {
        themes.add ({CUSTOM, ""});
        themes.add ({HIGH_CONTRAST, "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:#fff:#333:#839496"});
        themes.add ({LIGHT, "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:rgba(253, 246, 227, 0.95):#586e75:#839496"});
        themes.add ({DARK, "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:rgba(46, 46, 46, 0.95):#a5a5a5:#839496"});
    }

    public static string get_active_palette () {
        var palette = Application.settings.get_string ("palette");
        var background = Application.settings.get_string ("background");
        var foreground = Application.settings.get_string ("foreground");
        var cursor = Application.settings.get_string ("cursor-color");

        return @"$palette:$background:$foreground:$cursor";
    }

    public static void set_active_palette (string input) {
        var input_palette = input.split (":");
        if (input_palette.length != Terminal.Themes.PALETTE_SIZE) {
            warning ("Length of palette setting does not match palette size");
            return;
        }

        var background = input_palette[Terminal.Themes.PALETTE_SIZE - 3];
        var foreground = input_palette[Terminal.Themes.PALETTE_SIZE - 2];
        var cursor = input_palette[Terminal.Themes.PALETTE_SIZE - 1];
        var palette_length = input.length - background.length - foreground.length - cursor.length - 3;
        var palette = input.substring (0, palette_length);

        Application.settings.set_string ("palette", palette);
        Application.settings.set_string ("background", background);
        Application.settings.set_string ("foreground", foreground);
        Application.settings.set_string ("cursor-color", cursor);
    }
}

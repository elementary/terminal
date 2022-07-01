/*
* Copyright 2020 elementary, Inc. (https://elementary.io)
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

public class Terminal.Themes {
    public const int PALETTE_SIZE = 19;
    public const string DARK = "dark";
    public const string HIGH_CONTRAST = "high-contrast";
    public const string LIGHT = "solarized-light";

    // format is color01:color02:...:color16:background:foreground:cursor
    static construct {
        Application.settings.changed["theme"].connect (() => {
            switch (Application.settings.get_string ("theme")) {
                case (HIGH_CONTRAST):
                    Application.settings.set_boolean ("prefer-dark-style", false);
                    break;
                case (LIGHT):
                    Application.settings.set_boolean ("prefer-dark-style", false);
                    break;
                case (DARK):
                    Application.settings.set_boolean ("prefer-dark-style", true);
                    break;
            }
        });
    }

    public static Gdk.RGBA[] get_rgba_palette (string theme) {
        string settings_pallette_string;
        switch (theme) {
            case (HIGH_CONTRAST):
                settings_pallette_string = "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:#fff:#333:#839496";
                break;
            case (LIGHT):
                settings_pallette_string = "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:rgba(253, 246, 227, 0.95):#586e75:#839496";
                break;
            case (DARK):
                settings_pallette_string = "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:rgba(46, 46, 46, 0.95):#a5a5a5:#839496";
                break;
            default:
                settings_pallette_string = Application.settings.get_string ("palette");
                settings_pallette_string += ":" + Application.settings.get_string ("background");
                settings_pallette_string += ":" + Application.settings.get_string ("foreground");
                settings_pallette_string += ":" + Application.settings.get_string ("cursor-color");
                break;
        }

        var setting_palette_array = new string[PALETTE_SIZE];
        setting_palette_array = settings_pallette_string.split (":");
        bool settings_valid = setting_palette_array.length == PALETTE_SIZE;

        const string[] DEFAULT_PALETTE = {
            "#073642", "#dc322f", "#859900", "#b58900",
            "#268bd2", "#ec0048", "#2aa198", "#94a3a5",
            "#586e75", "#cb4b16", "#859900", "#b58900",
            "#268bd2", "#d33682", "#2aa198", "#6c71c4",
            "rgba(46, 46, 46, 0.95)", "#a5a5a5", "#839496"
        };

        var palette = new Gdk.RGBA[PALETTE_SIZE];
        for (int i = 0; i < PALETTE_SIZE; i++) {
            var new_color = Gdk.RGBA ();
            if (!new_color.parse (setting_palette_array[i])) {
                critical ("Color %i '%s' is not valid - replacing with default", i, setting_palette_array[i]);
                // Replace invalid color with corresponding one from default palette
                setting_palette_array[i] = DEFAULT_PALETTE[i];

                new_color.parse (DEFAULT_PALETTE[i]);
                settings_valid = false;
            }

            palette[i] = new_color;
        }

        if (!settings_valid) {
            /* Remove invalid colors from setting */
            Application.settings.set_string ("palette", string.joinv (":", setting_palette_array));
        }

        return palette;
    }
}

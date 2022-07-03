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
    public const string DARK = "dark";
    public const string HIGH_CONTRAST = "high-contrast";
    public const string LIGHT = "solarized-light";
    public const string CUSTOM = "custom";

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

    // format is color01:color02:...:color16:background:foreground:cursor
    public static Gdk.RGBA[] get_rgba_palette (string theme) {
        var string_palette = get_string_palette (theme);
        bool settings_valid = string_palette.length == PALETTE_SIZE;

        var rgba_palette = new Gdk.RGBA[PALETTE_SIZE];
        for (int i = 0; i < PALETTE_SIZE; i++) {
            var new_color = Gdk.RGBA ();
            // Replace invalid color with corresponding one from default palette
            if (!new_color.parse (string_palette[i])) {
                critical ("Color %i '%s' is not valid - replacing with default", i, string_palette[i]);
                string_palette[i] = DARK_PALETTE[i];
                new_color.parse (DARK_PALETTE[i]);
                settings_valid = false;
            }

            rgba_palette[i] = new_color;
        }

        return rgba_palette;
    }

    // DARK_PALETTE is used as a fallback when custom palette colors are invalid
    public const string[] DARK_PALETTE = {
        "#073642", "#dc322f", "#859900", "#b58900", "#268bd2", "#ec0048", "#2aa198", "#94a3a5",
        "#586e75", "#cb4b16", "#859900", "#b58900", "#268bd2", "#d33682", "#2aa198", "#6c71c4",
        "rgba(46, 46, 46, 0.95)", "#a5a5a5", "#839496"
    };
    public const int PALETTE_SIZE = 19;
    public static string[] get_string_palette (string theme) {
        var string_palette = new string[PALETTE_SIZE];
        switch (theme) {
            case (HIGH_CONTRAST):
                string_palette = {
                    "#073642", "#dc322f", "#859900", "#b58900", "#268bd2", "#ec0048", "#2aa198", "#94a3a5",
                    "#586e75", "#cb4b16", "#859900", "#b58900", "#268bd2", "#d33682", "#2aa198", "#6c71c4",
                    "#ffffff", "#333333", "#839496"
                };
                break;
            case (LIGHT):
                string_palette = {
                    "#073642", "#dc322f", "#859900", "#b58900", "#268bd2", "#ec0048", "#2aa198", "#94a3a5",
                    "#586e75", "#cb4b16", "#859900", "#b58900", "#268bd2", "#d33682", "#2aa198", "#6c71c4",
                    "rgba(253, 246, 227, 0.95)", "#586e75", "#839496"
                };
                break;
            case (DARK):
                string_palette = DARK_PALETTE;
                break;
            case (CUSTOM):
                string_palette = Application.settings.get_string ("palette").split (":");
                string_palette += Application.settings.get_string ("background");
                string_palette += Application.settings.get_string ("foreground");
                string_palette += Application.settings.get_string ("cursor-color");
                break;
        }

        return string_palette;
    }

    public static void set_default_palette_for_style () {
        var prefer_dark = Application.settings.get_boolean ("prefer-dark-style");
        var string_palette = get_string_palette (prefer_dark ? DARK : LIGHT);
        Application.settings.set_string ("palette", string.joinv (":", string_palette[0:PALETTE_SIZE - 3]));
        Application.settings.set_string ("background", string_palette[PALETTE_SIZE - 3]);
        Application.settings.set_string ("foreground", string_palette[PALETTE_SIZE - 2]);
        Application.settings.set_string ("cursor-color", string_palette[PALETTE_SIZE - 1]);
    }
}

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

namespace Terminal {

    public class Themes {
        public const int PALETTE_SIZE = 19;
        public static Gee.ArrayList<Theme?> themes = new Gee.ArrayList<Theme?> ();

        // format is color01:color02:...:color16:background:foreground:cursor
        static construct {
            themes.add ({"Custom", ""});
            themes.add ({"Default (High Contrast)", "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:#fff:#333:#839496"});
            themes.add ({"Default (Light)", "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:rgba(253, 246, 227, 0.95):#586e75:#839496"});
            themes.add ({"Default (Dark)", "#073642:#dc322f:#859900:#b58900:#268bd2:#ec0048:#2aa198:#94a3a5:#586e75:#cb4b16:#859900:#b58900:#268bd2:#d33682:#2aa198:#6c71c4:rgba(46, 46, 46, 0.95):#a5a5a5:#839496"});
            themes.add ({"3024 Day", "#090300:#db2d20:#01a252:#fded02:#01a0e4:#a16a94:#b5e4f4:#a5a2a2:#5c5855:#e8bbd0:#3a3432:#4a4543:#807d7c:#d6d5d4:#cdab53:#f7f7f7:#f7f7f7:#4a4543:#4a4543"});
            themes.add ({"3024 Night", "#090300:#db2d20:#01a252:#fded02:#01a0e4:#a16a94:#b5e4f4:#a5a2a2:#5c5855:#e8bbd0:#3a3432:#4a4543:#807d7c:#d6d5d4:#cdab53:#f7f7f7:#090300:#a5a2a2:#a5a2a2"});
            themes.add ({"Dracula", "#282a36:#ff5555:#50fa7b:#ffb86c:#8be9fd:#bd93f9:#ff79c6:#94a3a5:#44475a:#ff5555:#50fa7b:#ffb86c:#8be9fd:#bd93f9:#ff79c6:#ffffff:#282a36:#94a3a5:#94a3a5"});
            themes.add ({"Gruvbox Light", "#fbf1c7:#cc241d:#98971a:#d79921:#458588:#b16286:#689d6a:#7c6f64:#928374:#9d0006:#79740e:#b57614:#076678:#8f3f71:#427b58:#3c3836:#fbf1c7:#3c3836:#3c3836"});
            themes.add ({"Gruvbox Dark", "#282828:#cc241d:#98971a:#d79921:#458588:#b16286:#689d6a:#a89984:#928374:#fb4934:#b8bb26:#fabd2f:#83a598:#d3869b:#8ec07c:#ebdbb2:#282828:#ebdbb2:#ebdbb2"});
            themes.add ({"Monokai", "#272822:#f92672:#a6e22e:#f4bf75:#66d9ef:#ae81ff:#2aa198:#f8f8f2:#75715e:#f92672:#a6e22e:#f4bf75:#66d9ef:#ae81ff:#2aa198:#f9f8f5:#272822:#f8f8f2:#f8f8f2"});
            themes.add ({"Nord Light", "#3b4252:#bf616a:#a3be8c:#ebcb8b:#81a1c1:#b48ead:#88c0d0:#e5e9f0:#4c566a:#bf616a:#a3be8c:#ebcb8b:#81a1c1:#b48ead:#88c0d0:#eceff4:#eceff4:#2e3440:#2e3440"});
            themes.add ({"Nord Dark", "#3b4252:#bf616a:#a3be8c:#ebcb8b:#81a1c1:#b48ead:#88c0d0:#e5e9f0:#4c566a:#bf616a:#a3be8c:#ebcb8b:#81a1c1:#b48ead:#88c0d0:#eceff4:#2e3440:#eceff4:#eceff4"});
            themes.add ({"Solarized Light", "#073642:#dc322f:#859900:#b58900:#268bd2:#d33682:#2aa198:#eee8d5:#586e75:#cb4b16:#586e75:#657b83:#839496:#6c71c4:#93a1a1:#fdf6e3:#fdf6e3:#586e75:#586e75"});
            themes.add ({"Solarized Dark", "#073642:#dc322f:#859900:#b58900:#268bd2:#d33682:#2aa198:#eee8d5:#586e75:#cb4b16:#586e75:#657b83:#839496:#6c71c4:#93a1a1:#fdf6e3:#002b36:#839496:#839496"});
            themes.add ({"Spacegray", "#1c1f26:#b04b57:#87b379:#e5c179:#7d8fa4:#a47996:#85a7a5:#b3b8c3:#65737f:#b04b57:#87b379:#e5c179:#7d8fa4:#a47996:#85a7a5:#ffffff:#2b303b:#dfe1e8:#dfe1e8"});
            themes.add ({"Spacegray Eighties", "#15171c:#ec5f67:#81a764:#fec254:#5486c0:#bf83c1:#57c2c1:#efece7:#555555:#ff6973:#93d493:#ffd256:#4d84d1:#ff55ff:#83e9e4:#ffffff:#222222:#bdbaae:#bdbaae"});
            themes.add ({"Spacegray Light", "#1c1f26:#b04b57:#87b379:#e5c179:#7d8fa4:#a47996:#85a7a5:#b3b8c3:#65737f:#b04b57:#87b379:#e5c179:#7d8fa4:#a47996:#85a7a5:#ffffff:#eff1f5:#4f5b67:#4f5b67"});
            themes.add ({"Summerfruit Light", "#151515:#fd008a:#1acb00:#fc8b00:#3873ef:#ac00a8:#27aaab:#d0d0d0:#303030:#fd008a:#1acb00:#fc8b00:#3873ef:#ac00a8:#27aaab:#ffffff:#ffffff:#151515:#151515"});
            themes.add ({"Summerfruit Dark", "#151515:#fd008a:#1acb00:#fc8b00:#3873ef:#ac00a8:#27aaab:#d0d0d0:#303030:#fd008a:#1acb00:#fc8b00:#3873ef:#ac00a8:#27aaab:#ffffff:#151515:#d0d0d0:#d0d0d0"});
            themes.add ({"Tomorrow", "#4d4d4c:#c82828:#718c00:#eab700:#4171ae:#8959a8:#3e999f:#fffefe:#8e908c:#c82828:#708b00:#e9b600:#4170ae:#8958a7:#3d999f:#fffefe:#ffffff:#4d4d4c:#4d4d4c"});
            themes.add ({"Tomorrow Night", "#1d1f21:#cc6666:#b5bd68:#f0c674:#81a2be:#b293bb:#8abeb7:#fffefe:#373b41:#cc6666:#b5bd68:#f0c574:#80a1bd:#b294ba:#8abdb6:#fffefe:#1d1f21:#c5c8c6:#c5c8c6"});
            themes.add ({"Tomorrow Night Blue", "#002451:#ff9da3:#d1f1a9:#ffeead:#bbdaff:#ebbbff:#99ffff:#fffefe:#003f8e:#ff9ca3:#d0f0a8:#ffedac:#badaff:#ebbaff:#99ffff:#fffefe:#002451:#fffefe:#fffefe"});
            themes.add ({"Tomorrow Night Bright", "#000000:#d54e53:#b9ca49:#e7c547:#79a6da:#c397d8:#70c0b1:#fffefe:#424242:#d44d53:#b9c949:#e6c446:#79a6da:#c396d7:#70c0b1:#fffefe:#000000:#eaeaea:#eaeaea"});
            themes.add ({"Tomorrow Night Eighties", "#2d2d2d:#f27779:#99cc99:#ffcc66:#6699cc:#cc99cc:#66cccc:#fffefe:#515151:#f17779:#99cc99:#ffcc66:#6699cc:#cc99cc:#66cccc:#fffefe:#2d2d2d:#cccccc:#cccccc"});
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

        public static string get_active_name () {
            var palette = get_active_palette ();

            foreach (Terminal.Theme theme in themes) {
                if (theme.palette == palette) {
                    return theme.name;
                }
            }

            return "Custom";
        }

        public static void set_active_name (string name) {
            foreach (Terminal.Theme theme in themes) {
                if (theme.name == name) {
                    set_active_palette (theme.palette);
                }
            }
        }
    }

    public struct Theme {
        string name;
        string palette;
    }
}

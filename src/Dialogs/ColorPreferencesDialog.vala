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

public class Terminal.Dialogs.ColorPreferences : Gtk.Dialog {
    private Gtk.ListStore console_theme_store;
    private Gtk.ComboBox console_theme_combobox;
    private Gtk.Image contrast_image;

    private Gtk.ColorButton color01_button; // Black
    private Gtk.ColorButton color02_button; // Red
    private Gtk.ColorButton color03_button; // Green
    private Gtk.ColorButton color04_button; // Yellow
    private Gtk.ColorButton color05_button; // Blue
    private Gtk.ColorButton color06_button; // Magenta
    private Gtk.ColorButton color07_button; // Cyan
    private Gtk.ColorButton color08_button; // Light gray
    private Gtk.ColorButton color09_button; // Dark gray
    private Gtk.ColorButton color10_button; // Light Red
    private Gtk.ColorButton color11_button; // Light Green
    private Gtk.ColorButton color12_button; // Light Yellow
    private Gtk.ColorButton color13_button; // Light Blue
    private Gtk.ColorButton color14_button; // Light Magenta
    private Gtk.ColorButton color15_button; // Light Cyan
    private Gtk.ColorButton color16_button; // White
    private Gtk.ColorButton background_button;
    private Gtk.ColorButton foreground_button;
    private Gtk.ColorButton cursor_button;

    public signal void theme_changed ();

    public ColorPreferences (Gtk.Window? parent) {
        Object (
            deletable: false,
            resizable: false,
            title: _("Color Preferences"),
            transient_for: parent
        );
    }

    construct {
        var window_theme_label = new SettingsLabel (_("Window style:"));

        var window_theme_switch = new Granite.ModeSwitch.from_icon_name (
            "display-brightness-symbolic",
            "weather-clear-night-symbolic"
        ) {
            primary_icon_tooltip_text = _("Light window style"),
            secondary_icon_tooltip_text = _("Dark window style")
        };
        Application.settings.bind ("prefer-dark-style", window_theme_switch, "active", SettingsBindFlags.DEFAULT);

        console_theme_store = new Gtk.ListStore (2, typeof (string), typeof (string));

        foreach (Terminal.Theme theme in Terminal.Themes.themes) {
            Gtk.TreeIter iter;
            console_theme_store.insert_with_values (out iter, -1, 0, theme.name, 1, theme.palette, -1);
        };

        var console_theme_label = new SettingsLabel (_("Console style:"));

        var console_theme_cell = new Gtk.CellRendererText ();

        console_theme_combobox = new Gtk.ComboBox.with_model (console_theme_store);
        console_theme_combobox.pack_start (console_theme_cell, false);
        console_theme_combobox.set_attributes (console_theme_cell, "text", 0);
        console_theme_combobox.active = 0;
        console_theme_combobox.changed.connect (combobox_selection_changed);

        var black_color_label = new SettingsLabel (_("Black:"));
        var red_color_label = new SettingsLabel (_("Red:"));
        var green_color_label = new SettingsLabel (_("Green:"));
        var yellow_color_label = new SettingsLabel (_("Yellow:"));
        var blue_color_label = new SettingsLabel (_("Blue:"));
        var magenta_color_label = new SettingsLabel (_("Magenta:"));
        var cyan_color_label = new SettingsLabel (_("Cyan:"));
        var grey_color_label = new SettingsLabel (_("Gray:"));
        var background_label = new SettingsLabel (_("Background:"));
        var foreground_label = new SettingsLabel (_("Foreground:"));
        var cursor_label = new SettingsLabel (_("Cursor:"));

        color01_button = new Gtk.ColorButton ();
        color02_button = new Gtk.ColorButton ();
        color03_button = new Gtk.ColorButton ();
        color04_button = new Gtk.ColorButton ();
        color05_button = new Gtk.ColorButton ();
        color06_button = new Gtk.ColorButton ();
        color07_button = new Gtk.ColorButton ();
        color08_button = new Gtk.ColorButton ();
        color09_button = new Gtk.ColorButton ();
        color10_button = new Gtk.ColorButton ();
        color11_button = new Gtk.ColorButton ();
        color12_button = new Gtk.ColorButton ();
        color13_button = new Gtk.ColorButton ();
        color14_button = new Gtk.ColorButton ();
        color15_button = new Gtk.ColorButton ();
        color16_button = new Gtk.ColorButton ();
        background_button = new Gtk.ColorButton ();
        background_button.use_alpha = true;
        foreground_button = new Gtk.ColorButton ();
        cursor_button = new Gtk.ColorButton ();
        cursor_button.use_alpha = true;

        color01_button.color_set.connect (update_settings_from_buttons);
        color02_button.color_set.connect (update_settings_from_buttons);
        color03_button.color_set.connect (update_settings_from_buttons);
        color04_button.color_set.connect (update_settings_from_buttons);
        color05_button.color_set.connect (update_settings_from_buttons);
        color06_button.color_set.connect (update_settings_from_buttons);
        color07_button.color_set.connect (update_settings_from_buttons);
        color08_button.color_set.connect (update_settings_from_buttons);
        color09_button.color_set.connect (update_settings_from_buttons);
        color10_button.color_set.connect (update_settings_from_buttons);
        color11_button.color_set.connect (update_settings_from_buttons);
        color12_button.color_set.connect (update_settings_from_buttons);
        color13_button.color_set.connect (update_settings_from_buttons);
        color14_button.color_set.connect (update_settings_from_buttons);
        color15_button.color_set.connect (update_settings_from_buttons);
        color16_button.color_set.connect (update_settings_from_buttons);
        background_button.color_set.connect (update_settings_from_buttons);
        foreground_button.color_set.connect (update_settings_from_buttons);
        cursor_button.color_set.connect (update_settings_from_buttons);

        var contrast_top_label = new Gtk.Label ("┐");

        contrast_image = new Gtk.Image.from_icon_name ("process-completed", Gtk.IconSize.LARGE_TOOLBAR);

        var contrast_bottom_label = new Gtk.Label ("┘");

        var contrast_grid = new Gtk.Grid () {
            row_spacing = 3
        };
        contrast_grid.attach (contrast_top_label, 0, 0);
        contrast_grid.attach (contrast_image, 0, 1);
        contrast_grid.attach (contrast_bottom_label, 0, 2);

        var colors_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6,
            margin_start = 12,
            margin_end = 12,
            halign = Gtk.Align.CENTER
        };
        colors_grid.attach (new Granite.HeaderLabel (_("Styles")), 0, 0, 3);
        colors_grid.attach (window_theme_label, 0, 1, 1);
        colors_grid.attach (window_theme_switch, 1, 1, 2);
        colors_grid.attach (console_theme_label, 0, 2, 1);
        colors_grid.attach (console_theme_combobox, 1, 2, 2);
        colors_grid.attach (new Granite.HeaderLabel (_("Custom Colors")), 0, 3, 3);
        colors_grid.attach (background_label, 0, 4, 1);
        colors_grid.attach (background_button, 1, 4, 1);
        colors_grid.attach (foreground_label, 0, 5, 1);
        colors_grid.attach (foreground_button, 1, 5, 1);
        colors_grid.attach (cursor_label, 0, 6, 1);
        colors_grid.attach (cursor_button, 1, 6, 1);
        colors_grid.attach (black_color_label, 0, 7, 1);
        colors_grid.attach (color01_button, 1, 7, 1);
        colors_grid.attach (color09_button, 2, 7, 1);
        colors_grid.attach (red_color_label, 0, 8, 1);
        colors_grid.attach (color02_button, 1, 8, 1);
        colors_grid.attach (color10_button, 2, 8, 1);
        colors_grid.attach (green_color_label, 0, 9, 1);
        colors_grid.attach (color03_button, 1, 9, 1);
        colors_grid.attach (color11_button, 2, 9, 1);
        colors_grid.attach (yellow_color_label, 0, 10, 1);
        colors_grid.attach (color04_button, 1, 10, 1);
        colors_grid.attach (color12_button, 2, 10, 1);
        colors_grid.attach (blue_color_label, 0, 11, 1);
        colors_grid.attach (color05_button, 1, 11, 1);
        colors_grid.attach (color13_button, 2, 11, 1);
        colors_grid.attach (magenta_color_label, 0, 12, 1);
        colors_grid.attach (color06_button, 1, 12, 1);
        colors_grid.attach (color14_button, 2, 12, 1);
        colors_grid.attach (cyan_color_label, 0, 13, 1);
        colors_grid.attach (color07_button, 1, 13, 1);
        colors_grid.attach (color15_button, 2, 13, 1);
        colors_grid.attach (grey_color_label, 0, 14, 1);
        colors_grid.attach (color08_button, 1, 14, 1);
        colors_grid.attach (color16_button, 2, 14, 1);
        colors_grid.attach (contrast_grid, 2, 4, 1, 2);

        update_widgets_from_settings ();

        get_content_area ().add (colors_grid);

        var close_button = (Gtk.Button) add_button (_("Close"), Gtk.ResponseType.CLOSE);
        close_button.clicked.connect (destroy);
    }

    public void update_widgets_from_settings () {
        update_buttons_from_settings ();
        update_contrast_from_settings ();
        update_combobox_from_settings ();
    }

    private void update_settings_from_buttons () {
        string[] colors = {
            color01_button.rgba.to_string (),
            color02_button.rgba.to_string (),
            color03_button.rgba.to_string (),
            color04_button.rgba.to_string (),
            color05_button.rgba.to_string (),
            color06_button.rgba.to_string (),
            color07_button.rgba.to_string (),
            color08_button.rgba.to_string (),
            color09_button.rgba.to_string (),
            color10_button.rgba.to_string (),
            color11_button.rgba.to_string (),
            color12_button.rgba.to_string (),
            color13_button.rgba.to_string (),
            color14_button.rgba.to_string (),
            color15_button.rgba.to_string (),
            color16_button.rgba.to_string (),
            background_button.rgba.to_string (),
            foreground_button.rgba.to_string (),
            cursor_button.rgba.to_string ()
        };

        Terminal.Themes.set_active_palette (string.joinv (":", colors));
        update_combobox_from_settings ();
        update_contrast_from_settings ();
        theme_changed ();
    }

    private Gdk.RGBA[]? get_palette_from_settings () {
        var color_palette = new Gdk.RGBA[Terminal.Themes.PALETTE_SIZE];
        var input_palette = Terminal.Themes.get_active_palette ().split (":");

        if (input_palette.length != Terminal.Themes.PALETTE_SIZE) {
            warning ("Length of palette setting does not match palette size");
            return null;
        }

        var error = false;

        for (int i = 0; i < Terminal.Themes.PALETTE_SIZE; i++) {
            if (!color_palette[i].parse (input_palette[i])) {
                error = true;
            }
        }

        if (error) {
            warning ("Found invalid color in one of the color palette settings");
            return null;
        }

        return color_palette;
    }

    private void update_buttons_from_settings () {
        var color_palette = get_palette_from_settings ();
        if (color_palette == null) {
            return;
        }

        color01_button.rgba = color_palette[0];
        color02_button.rgba = color_palette[1];
        color03_button.rgba = color_palette[2];
        color04_button.rgba = color_palette[3];
        color05_button.rgba = color_palette[4];
        color06_button.rgba = color_palette[5];
        color07_button.rgba = color_palette[6];
        color08_button.rgba = color_palette[7];
        color09_button.rgba = color_palette[8];
        color10_button.rgba = color_palette[9];
        color11_button.rgba = color_palette[10];
        color12_button.rgba = color_palette[11];
        color13_button.rgba = color_palette[12];
        color14_button.rgba = color_palette[13];
        color15_button.rgba = color_palette[14];
        color16_button.rgba = color_palette[15];
        background_button.rgba = color_palette[16];
        foreground_button.rgba = color_palette[17];
        cursor_button.rgba = color_palette[18];
    }

    private void update_contrast_from_settings () {
        var color_palette = get_palette_from_settings ();
        if (color_palette == null) {
            return;
        }

        var contrast_ratio = get_contrast_ratio (color_palette[17], color_palette[16]);
        if (contrast_ratio < 3) {
            contrast_image.icon_name = "dialog-warning";
            contrast_image.tooltip_text = _("Contrast is very low");
        } else if (contrast_ratio < 4.5) {
            contrast_image.icon_name = "dialog-warning";
            contrast_image.tooltip_text = _("Contrast is low");
        } else if (contrast_ratio < 7) {
            contrast_image.icon_name = "process-completed";
            contrast_image.tooltip_text = _("Contrast is good");
        } else {
            contrast_image.icon_name = "process-completed";
            contrast_image.tooltip_text = _("Contrast is high");
        }
    }

    private void update_combobox_from_settings () {
        var current_name = Terminal.Themes.get_active_name ();

        Gtk.TreeIter iter;
        console_theme_store.get_iter_first (out iter);

        while (console_theme_store.iter_next (ref iter)) {
            GLib.Value name;
            console_theme_store.get_value (iter, 0, out name);

            if (current_name == (string)name) {
                console_theme_combobox.set_active_iter (iter);
                return;
            }
        }

        console_theme_combobox.set_active (0);
    }

    private void combobox_selection_changed (Gtk.ComboBox combobox) {
        Gtk.TreeIter iter;
        if (combobox.get_active_iter (out iter)) {
            GLib.Value name;
            GLib.Value palette;
            console_theme_store.get_value (iter, 0, out name);
            console_theme_store.get_value (iter, 1, out palette);

            Terminal.Themes.set_active_palette ((string)palette);
            update_buttons_from_settings ();
            update_contrast_from_settings ();
            theme_changed ();
        }
    }

    // contrast ratio code is taken from https://github.com/danrabbit/harvey/
    private double get_contrast_ratio (Gdk.RGBA foreground, Gdk.RGBA background) {
        var foreground_luminance = get_luminance (foreground);
        var background_luminance = get_luminance (background);

        if (background_luminance > foreground_luminance) {
            return (background_luminance + 0.05) / (foreground_luminance + 0.05);
        } else {
            return (foreground_luminance + 0.05) / (background_luminance + 0.05);
        }
    }

    private double get_luminance (Gdk.RGBA color) {
        var red = sanitize_color (color.red) * 0.2126;
        var green = sanitize_color (color.green) * 0.7152;
        var blue = sanitize_color (color.blue) * 0.0722;

        return (red + green + blue);
    }

    private double sanitize_color (double color) {
        if (color <= 0.03928) {
            color = color / 12.92;
        } else {
            color = Math.pow ((color + 0.055) / 1.055, 2.4);
        }
        return color;
    }

    private class SettingsLabel : Gtk.Label {
        public SettingsLabel (string text) {
            label = text;
            halign = Gtk.Align.END;
            margin_start = 12;
        }
    }
}

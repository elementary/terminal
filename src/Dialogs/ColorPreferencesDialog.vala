/*
 * Copyright 2022-2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

public class Terminal.Dialogs.ColorPreferences : Granite.Dialog {
    private Gtk.ColorDialogButton black_button;
    private Gtk.ColorDialogButton red_button;
    private Gtk.ColorDialogButton green_button;
    private Gtk.ColorDialogButton yellow_button;
    private Gtk.ColorDialogButton blue_button;
    private Gtk.ColorDialogButton magenta_button;
    private Gtk.ColorDialogButton cyan_button;
    private Gtk.ColorDialogButton light_gray_button;
    private Gtk.ColorDialogButton dark_gray_button;
    private Gtk.ColorDialogButton light_red_button;
    private Gtk.ColorDialogButton light_green_button;
    private Gtk.ColorDialogButton light_yellow_button;
    private Gtk.ColorDialogButton light_blue_button;
    private Gtk.ColorDialogButton light_magenta_button;
    private Gtk.ColorDialogButton light_cyan_button;
    private Gtk.ColorDialogButton white_button;
    private Gtk.ColorDialogButton background_button;
    private Gtk.ColorDialogButton foreground_button;
    private Gtk.ColorDialogButton cursor_button;
    private Gtk.ColorDialog color_dialog;

    public ColorPreferences (Gtk.Window? parent) {
        Object (
            resizable: false,
            title: _("Color Preferences"),
            transient_for: parent
        );
    }

    construct {
        var window_theme_label = settings_label (_("Window style:"));
        window_theme_label.margin_bottom = 12;

        var window_theme_switch = new Granite.ModeSwitch.from_icon_name (
            "display-brightness-symbolic",
            "weather-clear-night-symbolic"
        ) {
            primary_icon_tooltip_text = _("Light"),
            secondary_icon_tooltip_text = _("Dark")
        };
        Application.settings.bind ("prefer-dark-style", window_theme_switch, "active", SettingsBindFlags.DEFAULT);

        var palette_header = new Gtk.Label (_("Color Palette")) {
            margin_top = 12,
            margin_bottom = 12
        };
        palette_header.add_css_class (Granite.STYLE_CLASS_TITLE_LABEL);

        var default_button = new Gtk.Button.from_icon_name ("edit-clear-all-symbolic") {
            halign = Gtk.Align.END,
            margin_top = 12,
            margin_bottom = 6,
            tooltip_text = _("Reset to default")
        };

        var black_color_label = settings_label (_("Black:"));
        var red_color_label = settings_label (_("Red:"));
        var green_color_label = settings_label (_("Green:"));
        var yellow_color_label = settings_label (_("Yellow:"));
        var blue_color_label = settings_label (_("Blue:"));
        var magenta_color_label = settings_label (_("Magenta:"));
        var cyan_color_label = settings_label (_("Cyan:"));
        var dark_gray_color_label = settings_label (_("Gray:"));
        var white_color_label = settings_label (_("White:"));
        var light_red_color_label = settings_label (_("Light Red:"));
        var light_green_color_label = settings_label (_("Light Green:"));
        var light_yellow_color_label = settings_label (_("Light Yellow:"));
        var light_blue_color_label = settings_label (_("Light Blue:"));
        var light_magenta_color_label = settings_label (_("Light Magenta:"));
        var light_cyan_color_label = settings_label (_("Light Cyan:"));
        var light_gray_color_label = settings_label (_("Light Gray:"));
        var background_label = settings_label (_("Background:"));
        var foreground_label = settings_label (_("Foreground:"));
        var cursor_label = settings_label (_("Cursor:"));

        color_dialog = new Gtk.ColorDialog ();
        black_button = new Gtk.ColorDialogButton (color_dialog);
        red_button = new Gtk.ColorDialogButton (color_dialog);
        green_button = new Gtk.ColorDialogButton (color_dialog);
        yellow_button = new Gtk.ColorDialogButton (color_dialog);
        blue_button = new Gtk.ColorDialogButton (color_dialog);
        magenta_button = new Gtk.ColorDialogButton (color_dialog);
        cyan_button = new Gtk.ColorDialogButton (color_dialog);
        light_gray_button = new Gtk.ColorDialogButton (color_dialog);
        dark_gray_button = new Gtk.ColorDialogButton (color_dialog);
        light_red_button = new Gtk.ColorDialogButton (color_dialog);
        light_green_button = new Gtk.ColorDialogButton (color_dialog);
        light_yellow_button = new Gtk.ColorDialogButton (color_dialog);
        light_blue_button = new Gtk.ColorDialogButton (color_dialog);
        light_magenta_button = new Gtk.ColorDialogButton (color_dialog);
        light_cyan_button = new Gtk.ColorDialogButton (color_dialog);
        white_button = new Gtk.ColorDialogButton (color_dialog);
        background_button = new Gtk.ColorDialogButton (color_dialog);
        foreground_button = new Gtk.ColorDialogButton (color_dialog);
        cursor_button = new Gtk.ColorDialogButton (color_dialog);

        var contrast_top_label = new Gtk.Label (""); // Text will be set on showing
        var contrast_bottom_label = new Gtk.Label (""); // Text will be set on showing
        var contrast_image = new Gtk.Image.from_icon_name ("process-completed");

        var contrast_grid = new Gtk.Grid () {
            row_spacing = 3
        };
        contrast_grid.attach (contrast_top_label, 0, 0);
        contrast_grid.attach (contrast_image, 0, 1);
        contrast_grid.attach (contrast_bottom_label, 0, 2);

        var colors_grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6,
            margin_top = 12,
            margin_bottom = 12,
            margin_start = 12,
            margin_end = 12,
            halign = Gtk.Align.CENTER
        };

        colors_grid.attach (window_theme_label, 0, 1);
        colors_grid.attach (window_theme_switch, 1, 1, 2);
        colors_grid.attach (palette_header, 0, 2, 1);
        colors_grid.attach (default_button, 3, 2, 1);
        colors_grid.attach (background_label, 0, 4, 1);
        colors_grid.attach (background_button, 1, 4, 1);
        colors_grid.attach (foreground_label, 0, 5, 1);
        colors_grid.attach (foreground_button, 1, 5, 1);
        colors_grid.attach (contrast_grid, 2, 4, 1, 2);
        colors_grid.attach (cursor_label, 0, 6, 1);
        colors_grid.attach (cursor_button, 1, 6, 1);

        colors_grid.attach (black_color_label, 0, 8, 1);
        colors_grid.attach (black_button, 1, 8, 1);
        colors_grid.attach (dark_gray_color_label, 2, 8, 1);
        colors_grid.attach (dark_gray_button, 3, 8, 1);
        colors_grid.attach (red_color_label, 0, 9, 1);
        colors_grid.attach (red_button, 1, 9, 1);
        colors_grid.attach (light_red_color_label, 2, 9, 1);
        colors_grid.attach (light_red_button, 3, 9, 1);
        colors_grid.attach (green_color_label, 0, 10, 1);
        colors_grid.attach (green_button, 1, 10, 1);
        colors_grid.attach (light_green_color_label, 2, 10, 1);
        colors_grid.attach (light_green_button, 3, 10, 1);
        colors_grid.attach (yellow_color_label, 0, 11, 1);
        colors_grid.attach (yellow_button, 1, 11, 1);
        colors_grid.attach (light_yellow_color_label, 2, 11, 1);
        colors_grid.attach (light_yellow_button, 3, 11, 1);
        colors_grid.attach (blue_color_label, 0, 12, 1);
        colors_grid.attach (blue_button, 1, 12, 1);
        colors_grid.attach (light_blue_color_label, 2, 12, 1);
        colors_grid.attach (light_blue_button, 3, 12, 1);
        colors_grid.attach (magenta_color_label, 0, 13, 1);
        colors_grid.attach (magenta_button, 1, 13, 1);
        colors_grid.attach (light_magenta_color_label, 2, 13, 1);
        colors_grid.attach (light_magenta_button, 3, 13, 1);
        colors_grid.attach (cyan_color_label, 0, 14, 1);
        colors_grid.attach (cyan_button, 1, 14, 1);
        colors_grid.attach (light_cyan_color_label, 2, 14, 1);
        colors_grid.attach (light_cyan_button, 3, 14, 1);
        colors_grid.attach (light_gray_color_label, 0, 15, 1);
        colors_grid.attach (light_gray_button, 1, 15, 1);
        colors_grid.attach (white_color_label, 2, 15, 1);
        colors_grid.attach (white_button, 3, 15, 1);

        update_buttons_from_settings ();
        update_contrast (contrast_image);

        get_content_area ().append (colors_grid);

        var close_button = (Gtk.Button) add_button (_("Close"), Gtk.ResponseType.CLOSE);
        close_button.clicked.connect (destroy);

        Application.settings.set_string ("theme", Themes.CUSTOM);

        black_button.notify["rgba"].connect (update_palette_settings);
        red_button.notify["rgba"].connect (update_palette_settings);
        green_button.notify["rgba"].connect (update_palette_settings);
        yellow_button.notify["rgba"].connect (update_palette_settings);
        blue_button.notify["rgba"].connect (update_palette_settings);
        magenta_button.notify["rgba"].connect (update_palette_settings);
        cyan_button.notify["rgba"].connect (update_palette_settings);
        light_gray_button.notify["rgba"].connect (update_palette_settings);
        dark_gray_button.notify["rgba"].connect (update_palette_settings);
        light_red_button.notify["rgba"].connect (update_palette_settings);
        light_green_button.notify["rgba"].connect (update_palette_settings);
        light_yellow_button.notify["rgba"].connect (update_palette_settings);
        light_blue_button.notify["rgba"].connect (update_palette_settings);
        light_magenta_button.notify["rgba"].connect (update_palette_settings);
        light_cyan_button.notify["rgba"].connect (update_palette_settings);
        white_button.notify["rgba"].connect (update_palette_settings);

        default_button.clicked.connect (() => {
            Application.settings.reset ("palette");
            Application.settings.reset ("background");
            Application.settings.reset ("foreground");
            Application.settings.reset ("cursor-color");

            update_buttons_from_settings ();
        });

        background_button.notify["rgba"].connect (() => {
            Application.settings.set_string ("background", background_button.get_rgba ().to_string ());
            update_contrast (contrast_image);
        });

        foreground_button.notify["rgba"].connect (() => {
            Application.settings.set_string ("foreground", foreground_button.get_rgba ().to_string ());
            update_contrast (contrast_image);
        });

        cursor_button.notify["rgba"].connect (() => {
            Application.settings.set_string ("cursor-color", cursor_button.get_rgba ().to_string ());
        });

        contrast_top_label.state_flags_changed.connect ((previous_flags) => {
            var state_flags = get_state_flags ();
            contrast_top_label.label = Gtk.StateFlags.DIR_LTR in state_flags ? "┐" : "┌";
            contrast_bottom_label.label = Gtk.StateFlags.DIR_LTR in state_flags ? "┘" : "└";
        });

        // show.connect (get_child ().show_all);
    }

    private void update_palette_settings (ParamSpec param) {
        string[] colors = {
            black_button.get_rgba ().to_string (),
            red_button.get_rgba ().to_string (),
            green_button.get_rgba ().to_string (),
            yellow_button.get_rgba ().to_string (),
            blue_button.get_rgba ().to_string (),
            magenta_button.get_rgba ().to_string (),
            cyan_button.get_rgba ().to_string (),
            light_gray_button.get_rgba ().to_string (),
            dark_gray_button.get_rgba ().to_string (),
            light_red_button.get_rgba ().to_string (),
            light_green_button.get_rgba ().to_string (),
            light_yellow_button.get_rgba ().to_string (),
            light_blue_button.get_rgba ().to_string (),
            light_magenta_button.get_rgba ().to_string (),
            light_cyan_button.get_rgba ().to_string (),
            white_button.get_rgba ().to_string ()
        };

        Application.settings.set_string ("palette", string.joinv (":", colors));
    }

    private void update_buttons_from_settings () {
        var color_palette = new Gdk.RGBA[Terminal.Themes.PALETTE_SIZE];

        var palette = Application.settings.get_string ("palette");
        var background = Application.settings.get_string ("background");
        var foreground = Application.settings.get_string ("foreground");
        var cursor = Application.settings.get_string ("cursor-color");

        var input_palette = @"$palette:$background:$foreground:$cursor".split (":");

        for (int i = 0; i < input_palette.length; i++) {
            if (!color_palette[i].parse (input_palette[i])) {
                warning ("Found invalid color in one of the color palette settings");
                return;
            }
        }

        black_button.rgba = color_palette[0];
        red_button.rgba = color_palette[1];
        green_button.rgba = color_palette[2];
        yellow_button.rgba = color_palette[3];
        blue_button.rgba = color_palette[4];
        magenta_button.rgba = color_palette[5];
        cyan_button.rgba = color_palette[6];
        light_gray_button.rgba = color_palette[7];
        dark_gray_button.rgba = color_palette[8];
        light_red_button.rgba = color_palette[9];
        light_green_button.rgba = color_palette[10];
        light_yellow_button.rgba = color_palette[11];
        light_blue_button.rgba = color_palette[12];
        light_magenta_button.rgba = color_palette[13];
        light_cyan_button.rgba = color_palette[14];
        white_button.rgba = color_palette[15];

        background_button.rgba = color_palette[16];
        foreground_button.rgba = color_palette[17];
        cursor_button.rgba = color_palette[18];
    }

    private void update_contrast (Gtk.Image contrast_image) {
        var contrast_ratio = get_contrast_ratio (foreground_button.get_rgba (), background_button.get_rgba ());
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

    private Gtk.Label settings_label (string text) {
        return new Gtk.Label (text) {
            halign = END,
            margin_start = 12
        };
    }
}

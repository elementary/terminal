/*
 * Copyright 2023 elementary, Inc (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-only
 */

public sealed class Terminal.SettingsPopover : Gtk.Popover {
    public signal void show_theme_editor ();

    public Vte.Terminal? terminal {
        owned get {
            return terminal_binding.source as Vte.Terminal;
        }

        set {
            terminal_binding.source = value;
            if (value != null) {
                insert_action_group ("term", value.get_action_group ("term"));
            }
        }
    }

    private const string STYLE_CSS = """
        .color-button radio {
            background-color: %s;
            color: %s;
            padding: 10px;
            -gtk-icon-shadow: none;
        }
    """;

    private BindingGroup terminal_binding;
    private Gtk.Box theme_buttons;

    public SettingsPopover () {
        Object ();
    }

    construct {
        var zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", MENU) {
            tooltip_markup = Granite.markup_accel_tooltip (
                TerminalWidget.ACCELS_ZOOM_OUT,
                _("Zoom out")
            )
        };
        zoom_out_button.set_detailed_action_name (TerminalWidget.ACTION_ZOOM_OUT);

        var zoom_default_button = new Gtk.Button () {
            tooltip_markup = Granite.markup_accel_tooltip (
                TerminalWidget.ACCELS_ZOOM_DEFAULT,
                _("Default zoom level")
            )
        };
        zoom_default_button.set_detailed_action_name (TerminalWidget.ACTION_ZOOM_DEFAULT);

        var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", MENU) {
            tooltip_markup = Granite.markup_accel_tooltip (
                TerminalWidget.ACCELS_ZOOM_IN,
                _("Zoom in")
            )
        };
        zoom_in_button.set_detailed_action_name (TerminalWidget.ACTION_ZOOM_IN);

        var font_size_box = new Gtk.Box (HORIZONTAL, 0) {
            homogeneous = true,
            hexpand = true,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6
        };
        font_size_box.add (zoom_out_button);
        font_size_box.add (zoom_default_button);
        font_size_box.add (zoom_in_button);

        font_size_box.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

        theme_buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
            homogeneous = true,
            margin_bottom = 6,
            margin_top = 6
        };

        var theme_revealer = new Gtk.Revealer () {
            child = theme_buttons
        };

        var follow_system_button = new Granite.SwitchModelButton (_("Follow System Style")) {
            active = Application.settings.get_boolean ("follow-system-style"),
        };

        var theme_box = new Gtk.Box (VERTICAL, 0);
        theme_box.add (follow_system_button);
        theme_box.add (theme_revealer);

        var hc_button = add_theme_button (Themes.HIGH_CONTRAST);
        hc_button.tooltip_text = _("High Contrast");

        var light_button = add_theme_button (Themes.LIGHT);
        light_button.tooltip_text = _("Solarized Light");
        light_button.group = hc_button;

        var dark_button = add_theme_button (Themes.DARK);
        dark_button.tooltip_text = _("Dark");
        dark_button.group = hc_button;

        Gtk.CssProvider custom_button_provider;

        var custom_button = add_theme_button (Themes.CUSTOM, out custom_button_provider);
        custom_button.tooltip_text = _("Custom");
        custom_button.group = hc_button;
        custom_button.get_style_context ().add_class ("color-custom");

        update_active_colorbutton (dark_button, Application.settings.get_string ("theme"));

        var natural_copy_paste_button = new Granite.SwitchModelButton (_("Natural Copy/Paste")) {
            description = _("Shortcuts don’t require Shift; may interfere with CLI apps"),
            active = Application.settings.get_boolean ("natural-copy-paste")
        };

        var audible_bell_button = new Granite.SwitchModelButton (_("Event Alerts")) {
            description = _("Notify for invalid input or multiple possible completions (subject to System Settings → Sound)"),
            active = Application.settings.get_boolean ("audible-bell")
        };

        var box = new Gtk.Box (VERTICAL, 6) {
            margin_bottom = 6,
            margin_top = 12,
        };

        box.add (font_size_box);
        box.add (new Gtk.Separator (HORIZONTAL));
        box.add (theme_box);
        box.add (new Gtk.Separator (HORIZONTAL));
        box.add (natural_copy_paste_button);
        box.add (audible_bell_button);
        child = box;

        custom_button.clicked.connect (() => {
            if (custom_button.active) {
                show_theme_editor ();
                popdown ();
            }
        });

        terminal_binding = new BindingGroup ();
        terminal_binding.bind_property ("font-scale", zoom_default_button, "label", SYNC_CREATE, font_scale_to_zoom);

        follow_system_button.bind_property ("active", theme_revealer, "reveal-child", SYNC_CREATE | INVERT_BOOLEAN);

        Application.settings.bind ("follow-system-style", follow_system_button, "active", DEFAULT);
        Application.settings.bind ("natural-copy-paste", natural_copy_paste_button, "active", DEFAULT);
        Application.settings.bind ("audible-bell", audible_bell_button, "active", DEFAULT);

        Application.settings.changed.connect ((s, n) => {
            if (n == "background" || n == "foreground") {
                update_theme_provider (custom_button_provider, Themes.CUSTOM);
            } else if (n == "theme") {
                update_active_colorbutton (dark_button, s.get_string (n));
            }
        });

        show.connect (get_child ().show_all);
    }

    private Gtk.RadioButton add_theme_button (string theme, out Gtk.CssProvider css_provider = null) {
        var button = new Gtk.RadioButton (null) {
            action_target = new Variant.string (theme),
            halign = Gtk.Align.CENTER
        };

        css_provider = new Gtk.CssProvider ();

        unowned var style_context = button.get_style_context ();
        style_context.add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
        style_context.add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        update_theme_provider (css_provider, theme);

        button.toggled.connect ((b) => {
            if (((Gtk.RadioButton) b).active) {
                Application.settings.set_value ("theme", b.action_target);
            }
        });

        theme_buttons.add (button);
        return button;
    }

    private static void update_active_colorbutton (Gtk.RadioButton default_button, string theme) {
        SearchFunc<Gtk.RadioButton,string> find_colorbutton = (b, t) => strcmp (b.action_target.get_string (), t);
        unowned var node = default_button.get_group ().search (theme, find_colorbutton);

        if (node != null) {
            node.data.active = true;
        } else {
            default_button.active = true;
        }
    }

    private static void update_theme_provider (Gtk.CssProvider css_provider, string theme) {
        var theme_palette = Themes.get_rgba_palette (theme);
        var background = theme_palette[Themes.PALETTE_SIZE - 3].to_string ();
        var foreground = theme_palette[Themes.PALETTE_SIZE - 2].to_string ();

        try {
            css_provider.load_from_data (STYLE_CSS.printf (background, foreground));
        } catch (Error e) {
            critical ("Unable to style color button: %s", e.message);
        }
    }

    private static bool font_scale_to_zoom (Binding binding, Value font_scale, ref Value label) {
        label.set_string ("%.0f%%".printf (font_scale.get_double () * 100));
        return true;
    }
}

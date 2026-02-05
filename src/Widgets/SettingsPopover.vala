/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2023-2025 elementary, Inc. (https://elementary.io)
 */

public sealed class Terminal.SettingsPopover : Gtk.Popover {
    public signal void show_theme_editor ();

    public TerminalWidget? terminal {
        owned get {
            return terminal_binding.source as TerminalWidget;
        }

        set {
            terminal_binding.source = value;
        }
    }

    private const string ACTION_GROUP_NAME = "settings";
    private const string ACTION_GROUP_PREFIX = ACTION_GROUP_NAME + ".";

    private BindingGroup terminal_binding;

    construct {
        var zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic") {
            tooltip_markup = Granite.markup_accel_tooltip (
                TerminalWidget.ACCELS_ZOOM_OUT,
                _("Zoom out")
            )
        };
        zoom_out_button.clicked.connect (() => terminal.decrease_font_size ());

        var zoom_default_button = new Gtk.Button () {
            tooltip_markup = Granite.markup_accel_tooltip (
                TerminalWidget.ACCELS_ZOOM_DEFAULT,
                _("Default zoom level")
            )
        };
        zoom_default_button.clicked.connect (() => terminal.default_font_size ());

        var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic") {
            tooltip_markup = Granite.markup_accel_tooltip (
                TerminalWidget.ACCELS_ZOOM_IN,
                _("Zoom in")
            )
        };
        zoom_in_button.clicked.connect (() => terminal.increase_font_size ());

        var font_size_box = new Granite.Box (HORIZONTAL, LINKED) {
            homogeneous = true,
            hexpand = true,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 6
        };
        font_size_box.append (zoom_out_button);
        font_size_box.append (zoom_default_button);
        font_size_box.append (zoom_in_button);

        var follow_system_button = new Granite.SwitchModelButton (_("Follow System Style")) {
            action_name = ACTION_GROUP_PREFIX + "follow-system-style"
        };

        var hc_button = new ThemeCheckButton (Themes.HIGH_CONTRAST) {
            tooltip_text = _("High Contrast")
        };

        var light_button = new ThemeCheckButton (Themes.LIGHT) {
            tooltip_text = _("Solarized Light")
        };

        var dark_button = new ThemeCheckButton (Themes.DARK) {
            tooltip_text = _("Dark")
        };

        var custom_button = new ThemeCheckButton (Themes.CUSTOM) {
            tooltip_text = _("Custom")
        };

        var custom_button_controller = new Gtk.GestureClick () {
            propagation_phase = CAPTURE
        };

        custom_button_controller.released.connect ((n, x, y) => {
            if (custom_button.active) {
                show_theme_editor ();
                popdown ();
            }
        });
        custom_button.add_controller (custom_button_controller);

        var theme_buttons = new Gtk.Box (HORIZONTAL, 0) {
            homogeneous = true,
            margin_bottom = 6,
            margin_top = 6
        };
        theme_buttons.append (hc_button);
        theme_buttons.append (light_button);
        theme_buttons.append (dark_button);
        theme_buttons.append (custom_button);

        var theme_revealer = new Gtk.Revealer () {
            child = theme_buttons
        };

        var theme_box = new Gtk.Box (VERTICAL, 0);
        theme_box.append (follow_system_button);
        theme_box.append (theme_revealer);

        var natural_copy_paste_button = new Granite.SwitchModelButton (_("Natural Copy/Paste")) {
            description = _("Shortcuts don’t require Shift; may interfere with CLI apps"),
            action_name = ACTION_GROUP_PREFIX + "natural-copy-paste"
        };

        var unsafe_paste_alert_button = new Granite.SwitchModelButton (_("Unsafe Paste Alert")) {
            description = _("Warn when pasted text contains multiple or administrative commands"),
            action_name = ACTION_GROUP_PREFIX + "unsafe-paste-alert"
        };

        var audible_bell_button = new Granite.SwitchModelButton (_("Event Alerts")) {
            description = _("Notify for invalid input or multiple possible completions (subject to System Settings → Sound)"),
            action_name = ACTION_GROUP_PREFIX + "audible-bell"
        };

        var auto_hide_button = new Granite.SwitchModelButton (_("Auto-hide Tab Bar")) {
            description = _("Hide the tab bar when there is only one tab"),
            active = Application.settings.get_enum ("tab-bar-behavior") == 1
        };

        auto_hide_button.toggled.connect (() => {
          Application.settings.set_enum ("tab-bar-behavior", auto_hide_button.active ? 1 : 0);
        });

        var box = new Gtk.Box (VERTICAL, 6) {
            margin_bottom = 6,
            margin_top = 12,
        };

        box.append (font_size_box);
        box.append (new Gtk.Separator (HORIZONTAL));
        box.append (theme_box);
        box.append (new Gtk.Separator (HORIZONTAL));
        box.append (natural_copy_paste_button);
        box.append (unsafe_paste_alert_button);
        box.append (audible_bell_button);
        box.append (auto_hide_button);
        child = box;

        var theme_action = Application.settings.create_action ("theme");
        var natural_copy_paste_action = Application.settings.create_action ("natural-copy-paste");
        var unsafe_paste_alert_action = Application.settings.create_action ("unsafe-paste-alert");
        var audible_bell_action = Application.settings.create_action ("audible-bell");
        var follow_system_style_action = Application.settings.create_action ("follow-system-style");

        var action_group = new SimpleActionGroup ();
        action_group.add_action (theme_action);
        action_group.add_action (natural_copy_paste_action);
        action_group.add_action (unsafe_paste_alert_action);
        action_group.add_action (audible_bell_action);
        action_group.add_action (follow_system_style_action);
        insert_action_group (ACTION_GROUP_NAME, action_group);

        custom_button.toggled.connect (() => {
            if (custom_button.active) {
                show_theme_editor ();
                popdown ();
            }
        });

        terminal_binding = new BindingGroup ();
        terminal_binding.bind_property ("font-scale", zoom_default_button, "label", SYNC_CREATE, font_scale_to_zoom);

        follow_system_button.bind_property ("active", theme_revealer, "reveal-child", SYNC_CREATE | INVERT_BOOLEAN);

        Application.settings.changed.connect ((s, n) => {
            if (n == "background" || n == "foreground") {
                custom_button.update_theme_provider ();
            } else if (n == "tab-bar-behavior") {
                auto_hide_button.active = Application.settings.get_enum ("tab-bar-behavior") == 1;
            }
        });
    }

    private static bool font_scale_to_zoom (Binding binding, Value font_scale, ref Value label) {
        label.set_string ("%.0f%%".printf (font_scale.get_double () * 100));
        return true;
    }

    private class ThemeCheckButton : Gtk.CheckButton {
        public string theme { get; construct; }

        private const string STYLE_CSS = """
            .color-button.%s radio {
                background-color: %s;
                color: %s;
                padding: 0.8rem; /* FIXME: Remove during GTK4 port */
            }
        """;

        private Gtk.CssProvider css_provider;

        public ThemeCheckButton (string theme) {
            Object (theme: theme);
        }

        construct {
            action_name = ACTION_GROUP_PREFIX + "theme";
            action_target = new Variant.string (theme);
            halign = CENTER;

            add_css_class (Granite.STYLE_CLASS_COLOR_BUTTON);
            add_css_class (theme);

            css_provider = new Gtk.CssProvider ();

            Gtk.StyleContext.add_provider_for_display (
                Gdk.Display.get_default (),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            update_theme_provider ();
        }

        public void update_theme_provider () {
            var theme_palette = Themes.get_rgba_palette (theme);
            var background = theme_palette[Themes.PALETTE_SIZE - 3].to_string ();
            var foreground = theme_palette[Themes.PALETTE_SIZE - 2].to_string ();

            css_provider.load_from_string (STYLE_CSS.printf (theme, background, foreground));
        }
    }
}

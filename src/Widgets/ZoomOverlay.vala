/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class Terminal.Widgets.ZoomOverlay : Gtk.Box {
    private Gtk.Revealer revealer;
    private Gtk.Label zoom_label;
    private int visible_duration;
    private uint timer_id;
    private bool will_hide;

    construct {
        revealer = new Gtk.Revealer () {
            hexpand = true,
            halign = CENTER,
            valign = CENTER,
            transition_type = CROSSFADE
        };

        zoom_label = new Gtk.Label ("") {
            use_markup = true
        };
        zoom_label.get_style_context ().add_class ("zoom");
        zoom_label.get_style_context ().add_class ("overlay-bar");

        revealer.add (zoom_label);

        visible_duration = 1500;
        will_hide = false;

        add (revealer);

        show_all ();
    }

    public void show_zoom_level (double zoom_level) {
        revealer.reveal_child = true;
        zoom_label.label = "<span font-features='tnum'>%.0f%%</span>".printf (zoom_level * 100);

        if (will_hide) {
            GLib.Source.remove (timer_id);
        }

        will_hide = true;
        timer_id = GLib.Timeout.add (visible_duration, () => {
            revealer.reveal_child = false;
            will_hide = false;
            return false;
        });
    }

    public void hide_zoom_level () {
        revealer.reveal_child = false;
        if (will_hide) {
            will_hide = false;
            GLib.Source.remove (timer_id);
        }
    }

}

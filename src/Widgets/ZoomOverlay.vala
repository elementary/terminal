/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class Terminal.Widgets.ZoomOverlay : Granite.Widgets.OverlayBar {
    private int visible_duration;
    private uint timer_id;
    private bool will_hide;

    public ZoomOverlay (Gtk.Overlay overlay) {
        base (overlay);
    }

    construct {
        visible_duration = 1500;
        will_hide = false;
    }

    public void show_zoom_level (double zoom_level) {
        label = _("Zoom: %.0f%%").printf (zoom_level * 100);
        show ();

        if (will_hide) {
            GLib.Source.remove (timer_id);
        }

        will_hide = true;
        timer_id = GLib.Timeout.add (visible_duration, () => {
            hide ();
            will_hide = false;
            return false;
        });
    }

    public void hide_zoom_level () {
        hide ();
        if (will_hide) {
            will_hide = false;
            GLib.Source.remove (timer_id);
        }
    }

}

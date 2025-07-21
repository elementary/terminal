/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 */

public class Terminal.Widgets.ZoomOverlay : Granite.OverlayBar {
    const uint VISIBLE_DURATION = 1500;
    private uint timer_id;

    public ZoomOverlay (Gtk.Overlay overlay) {
        base (overlay);
    }

    public void show_zoom_level (double zoom_level) {
        label = _("Zoom: %.0f%%").printf (zoom_level * 100);
        show ();

        cancel_timer ();
        timer_id = GLib.Timeout.add (VISIBLE_DURATION, () => {
            hide_zoom_level ();
            return Source.REMOVE;
        });
    }

    public void hide_zoom_level () {
        hide ();
        cancel_timer ();
    }

    private void cancel_timer () {
        if (timer_id > 0) {
            GLib.Source.remove (timer_id);
            timer_id = 0;
        }
    }

}

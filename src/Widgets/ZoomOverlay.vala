
namespace Terminal.Widgets {

    public class ZoomOverlay : Gtk.Overlay {
        private Gtk.Revealer revealer;
        private Gtk.Label zoom_label;
        private int visible_duration;
        private uint timer_id;
        private bool will_hide;

        static construct {
            set_css_name ("tooltip");
        }

        construct {
            revealer = new Gtk.Revealer () {
                hexpand = false,
                vexpand = false,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                transition_type = Gtk.RevealerTransitionType.CROSSFADE
            };

            zoom_label = new Gtk.Label ("");

            revealer.add (zoom_label);

            add_overlay (revealer);
            set_overlay_pass_through (revealer, true);

            visible_duration = 1500;
            will_hide = false;
        }

        public void show_zoom_level (double zoom_level) {
            revealer.reveal_child = true;
            zoom_label.label = "%.0f%%".printf (zoom_level * 100);

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
}

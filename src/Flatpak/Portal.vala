/*
 * Copyright (c) 2021 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

public class Terminal.PortalHelper : Object {
    private static PortalHelper? instance = null;
    public static PortalHelper get_instance () {
        if (instance == null) {
            instance = new PortalHelper ();
        }

        return instance;
    }

    private Xdp.Portal xdp_portal;
    private PortalHelper () {}

    public bool is_running_in_flatpak {
        get { return xdp_portal.running_under_flatpak (); }
    }

    public signal void action_invoked (string id, string? action, Variant? target);

    construct {
        xdp_portal = new Xdp.Portal ();
        xdp_portal.notification_action_invoked.connect ((id, action, target) => {
            action_invoked (id, action, target);
        });
    }

    public void send_notification (
        string notification_id,
        string title,
        string process,
        string process_icon_name,
        string action_name,
        Variant target
    ) {
        var process_icon = new ThemedIcon (process_icon_name);

        var builder = new GLib.VariantBuilder (VariantType.VARDICT);
        builder.add ("{sv}", "title", new GLib.Variant.string (title));
        builder.add ("{sv}", "body", new GLib.Variant.string (process));
        builder.add ("{sv}", "icon", process_icon.serialize ());
        builder.add ("{sv}", "default-action", new GLib.Variant.string (action_name));
        builder.add ("{sv}", "target", target);


        xdp_portal.add_notification.begin (
            notification_id,
            builder.end (),
            NONE,
            null,
            (obj, res) => {
                try {
                    var success = xdp_portal.add_notification.end (res);
                } catch (Error e) {
                    warning ("Notification failed. %s", e.message);
                }
            }
        );
    }

    public void withdraw_notification (string notification_id) {
        xdp_portal.remove_notification (notification_id);
    }
}

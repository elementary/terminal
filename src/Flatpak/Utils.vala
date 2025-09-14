/*
 * Copyright 2023 Paulo Queiroz <pvaqueiroz@gmail.com>
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
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

 /* All these functions must be called only when running in a Flatpak */
namespace Terminal.FlatpakUtils {
  internal string? flatpak_root = null;

  public string get_flatpak_root ()
  throws GLib.Error {
    if (flatpak_root == null) {
      KeyFile kf = new KeyFile ();

      kf.load_from_file ("/.flatpak-info", KeyFileFlags.NONE);
      flatpak_root = kf.get_string ("Instance", "app-path");
    }
    return flatpak_root;
  }

  public string? flatpak_spawn_on_host (
    string[] argv,
    out int status = null
  ) throws GLib.Error {
    GLib.Subprocess sp;
    GLib.SubprocessLauncher launcher;
    string[] real_argv = {};
    string? buf = null;

    status = -1;

    assert (Terminal.Application.is_running_in_flatpak);
// #if TERMINAL_IS_FLATPAK
    real_argv += "flatpak-spawn";
    real_argv += "--host";
// #endif

    foreach (unowned string arg in argv) {
      real_argv += arg;
    }

    launcher = new GLib.SubprocessLauncher (
      SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
    );

    launcher.unsetenv ("G_MESSAGES_DEBUG");
    sp = launcher.spawnv (real_argv);

    if (sp == null) return null;

    if (!sp.communicate_utf8 (null, null, out buf, null)) return null;

    int exit_status = sp.get_exit_status ();
    status = exit_status;

    return buf;
  }

  /* fp_guess_shell
   *
   * Copyright 2019 Christian Hergert <chergert@redhat.com>
   *
   * The following function is a derivative work of the code from
   * https://gitlab.gnome.org/chergert/flatterm which is licensed under the
   * Apache License, Version 2.0 <LICENSE-APACHE or
   * https://opensource.org/licenses/MIT>, at your option. This file may not
   * be copied, modified, or distributed except according to those terms.
   *
   * SPDX-License-Identifier: (MIT OR Apache-2.0)
   */
  public string? fp_guess_shell (Cancellable? cancellable = null) {
    assert (Terminal.Application.is_running_in_flatpak);
    try {
        string[] argv = { "flatpak-spawn", "--host", "getent", "passwd",
          Environment.get_user_name () };

        var launcher = new GLib.SubprocessLauncher (
          SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
        );

        launcher.unsetenv ("G_MESSAGES_DEBUG");
        var sp = launcher.spawnv (argv);

        if (sp == null)
          return null;

        string? buf = null;
        if (!sp.communicate_utf8 (null, cancellable, out buf, null))
          return null;

        var parts = buf.split (":");

        if (parts.length < 7) {
          return null;
        }

        return parts[6].strip ();
    } catch (Error e) {
        warning ("Failed to guess Flatpak shell");
        return null;
    }
  }

  public string[]? fp_get_env (Cancellable? cancellable = null) throws Error {
    string[] argv = { "flatpak-spawn", "--host", "env" };

    var launcher = new GLib.SubprocessLauncher (
      SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_SILENCE
    );

    launcher.setenv ("G_MESSAGES_DEBUG", "false", true);

    var sp = launcher.spawnv (argv);

    if (sp == null) {
      return null;
    }

    string? buf = null;
    if (!sp.communicate_utf8 (null, cancellable, out buf, null)) {
      return null;
    }

    string[] arr = buf.strip ().split ("\n");

    return arr;
  }

  public async int get_foreground_process (
    int terminal_fd,
    Cancellable? cancellable = null
  ) {

    try {
      KeyFile kf = new KeyFile ();

      kf.load_from_file ("/.flatpak-info", KeyFileFlags.NONE);
      string host_root = kf.get_string ("Instance", "app-path");

      var argv = new Array<string> ();

      argv.append_val ("%s/bin/terminal-toolbox".printf (host_root));
      argv.append_val ("tcgetpgrp");
      argv.append_val (terminal_fd.to_string ());

      int[] fds = new int[2];

      // This creates two fds, where we can write to one and read from the
      // other. We'll pass one fd to the HostCommand as stdout, which means
      // we'll be able to read what is HostCommand prints out from the other
      // fd we just opened.
      Unix.open_pipe (fds, Posix.FD_CLOEXEC);

      var read_fs = GLib.FileStream.fdopen (fds [0], "r");
      var write_fs = GLib.FileStream.fdopen (fds [1], "w");
      int[] pass_fds = {
        0,
        write_fs.fileno (), // stdout for toolbox, we can read from read_fs
        2,
        terminal_fd // we pass the terminal fd as (3) for toolbox
      };

      debug ("Send command");
      yield send_host_command (null, argv, new Array<string> (), pass_fds, null, null, null);

      string text = read_fs.read_line ();
      int response;

      if (int.try_parse (text, out response, null, 10)) {
        return response;
      }
    }
    catch (GLib.Error e) {
      warning ("%s", e.message);
    }

    return -1;
  }

  public delegate void HostCommandExitedCallback (uint pid, uint status);

  /**
   * The following function is derivative work of
   * https://github.com/gnunn1/tilix/blob/ddf5e5c069ab7d40f973cb2554eae5b13b23a87f/source/gx/tilix/terminal/terminal.d#L2967
   * which is licensed under the Mozilla Public License 2.0. If a copy of the
   * MPL was not distributed with this file, You can obtain one at
   * http://mozilla.org/MPL/2.0/.
   */
  public static async bool send_host_command (
    string? cwd,
    Array<string> argv,
    Array<string> envv,
    int[] fds,
    HostCommandExitedCallback? callback,
    GLib.Cancellable? cancellable,
    out int pid
  ) throws GLib.Error {
    pid = -1;

    uint[] handles = {};

    GLib.UnixFDList out_fd_list;
    GLib.UnixFDList in_fd_list = new GLib.UnixFDList ();

    foreach (var fd in fds) {
      handles += in_fd_list.append (fd);
    }

    var connection = yield new DBusConnection.for_address (
      GLib.Environment.get_variable ("DBUS_SESSION_BUS_ADDRESS"),
      GLib.DBusConnectionFlags.AUTHENTICATION_CLIENT
        | GLib.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
      null,
      null
    );

    connection.exit_on_close = true;

    uint signal_id = 0;

    signal_id = connection.signal_subscribe (
      "org.freedesktop.Flatpak",
      "org.freedesktop.Flatpak.Development",
      "HostCommandExited",
      "/org/freedesktop/Flatpak/Development",
      null,
      DBusSignalFlags.NONE,
      // This callback is only called if the command is properly spawned. It is
      // not called if spawning the command fails.
      (_connection, sender_name, object_path, interface_name, signal_name, parameters) => {
        connection.signal_unsubscribe (signal_id);

        // I'm not sure which pid this is (it might be from the process that
        // just exited or from the dbus command call).
        uint ppid = 0;
        // This is the return status of the command that just exited. Any
        // non-zero value means the shell/command exited with an error.
        uint status = 0;

        parameters.get ("(uu)", &ppid, &status);

        debug ("Command exited %s %s %s %s pid: %u status %u", signal_name, sender_name, object_path, interface_name, ppid, status);

        if (callback != null) {
          if (cancellable?.is_cancelled ()) {
            //  callback = null;
          }
          else {
            callback (ppid, status);
          }
        }
      }
    );

    var parameters = build_host_command_variant (cwd, argv, envv, handles);

    Variant? reply = null;

    try {
      reply = yield connection.call_with_unix_fd_list (
        "org.freedesktop.Flatpak",
        "/org/freedesktop/Flatpak/Development",
        "org.freedesktop.Flatpak.Development",
        "HostCommand",
        parameters,
        new VariantType ("(u)"),
        GLib.DBusCallFlags.NONE,
        -1,
        in_fd_list,
        null,
        out out_fd_list
      );
    }
    catch (GLib.Error e) {
      // If we reach this catch block the command we tried to spawn very likely
      // failed. In the context of opening new terminals, this means we failed
      // to spawn the user's shell or the specific command given to a tab. Most
      // users would expect to see an error banner/alert at this point.
      connection.signal_unsubscribe (signal_id);
      throw e;
    }

    if (reply == null) {
      warning ("No reply from flatpak dbus service");
      connection.signal_unsubscribe (signal_id);
      return false;
    }
    else {
      // Pid from the host command we just spawned
      uint p = 0;
      reply.get ("(u)", &p);
      pid = (int) p;
    }

    return true;
  }

  // This function builds a Variant to be passed to Flatpak's HostCommand DBus
  // call. See the following link for more details:
  // https://github.com/flatpak/flatpak/blob/01910ad12fd840a8667879f9a479a66e441cccdd/data/org.freedesktop.Flatpak.xml#L110
  public static Variant build_host_command_variant (
    string? cwd,
    Array<string> argv,
    Array<string> envv,
    uint[] handles
  ) {
    if (cwd == null) {
      cwd = GLib.Environment.get_home_dir ();
    }

    var handles_vb = new VariantBuilder (new VariantType ("a{uh}"));
    for (uint i = 0; i < handles.length; i++) {
      handles_vb.add_value (new Variant ("{uh}", i, (int32) handles [i]));
    }

    var envv_vb = new VariantBuilder (new VariantType ("a{ss}"));
    foreach (unowned string env in envv.data) {
      if (env == null) break;

      string[] parts = env.split ("=");
      if (parts.length == 2) {
        envv_vb.add_value (new Variant ("{ss}", parts [0], parts [1]));
      }
    }

    var he = handles_vb.end ();
    var ee = envv_vb.end ();

    return new Variant (
      "(^ay^aay@a{uh}@a{ss}u)",
      cwd,
      argv.data,
      he,
      ee,
      2
    );
  }

  public string? get_process_cmdline (int pid) {
    try {
      //  ps -p PID -o args --no-headers
      string? response = flatpak_spawn_on_host ({
        "ps",
        "-p",
        pid.to_string (),
        "-o",
        "args",
        "--no-headers"
      });

      return response.strip ();
    }
    catch (GLib.Error e) {
      warning ("%s", e.message);
    }
    return null;
  }

    public int get_euid_from_pid (
        int pid,
        GLib.Cancellable? cancellable
    ) throws GLib.Error {

    string proc_file = @"/proc/$pid";
    string[] argv = {
      "%s/bin/terminal-toolbox".printf (get_flatpak_root ()),
      "stat",
      proc_file
    };

    int status;
    var response = flatpak_spawn_on_host (argv, out status);
    int euid = -1;

    if (status == 0 && int.try_parse (response.strip (), out euid, null, 10)) {
      return euid;
    }
    else {
      return -1;
    }
  }
}

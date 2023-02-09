terminal_deps = [
    glib_dep,
    gobject_dep,
    gio_dep,
    gtk_dep,
    granite_dep,
    handy_dep,
    pcre2_dep,
    vte_dep,
    posix_dep,
    linux_dep,
    m_dep
]

terminal_sources = [
    'Dialogs/ColorPreferencesDialog.vala',
    'Dialogs/ForegroundProcessDialog.vala',
    'Dialogs/UnsafePasteDialog.vala',
    'Widgets/SearchToolbar.vala',
    'Widgets/TerminalWidget.vala',
    'Application.vala',
    'DBus.vala',
    'MainWindow.vala',
    'Themes.vala',
    'Utils.vala',
    configure_file(
        input: 'config.vala.in',
        output: '@BASENAME@',
        configuration: conf_data
    ),
    terminal_gresource
]

executable(
    meson.project_name(),
    terminal_sources,
    dependencies: terminal_deps,
    install : true
)

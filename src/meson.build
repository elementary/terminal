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
    'Widgets/SettingsPopover.vala',
    'Widgets/TerminalView.vala',
    'Widgets/TerminalWidget.vala',
    'Widgets/ZoomOverlay.vala',
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

# tests

test_env = [
    'G_TEST_SRCDIR=' + meson.current_source_dir(),
    'G_TEST_BUILDDIR=' + meson.current_build_dir(),
    'GSETTINGS_SCHEMA_DIR=' + meson.project_build_root() / 'data',
    'GSETTINGS_BACKEND=memory',
    'GIO_USE_VFS=local'
]

add_test_setup(
  'headless',
  exe_wrapper: [ find_program('xvfb-run'), '-a', '-s', '-screen 0 1024x768x24 -noreset' ],
  is_default: true
)

app_test = executable(
    meson.project_name() + '.tests.application',
    terminal_sources + 'tests/Application.vala',
    dependencies: terminal_deps,
    vala_args: [ '--define', 'TESTS']
)

test(
    'Application',
    app_test,
    env: test_env,
    protocol: 'tap',
    depends: test_schemas
)

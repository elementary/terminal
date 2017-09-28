project('io.elementary.terminal', 'vala', 'c')

i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"', language:'c')

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/Constants.vala',
    'src/DBus.vala',
    'src/Settings.vala',
    'src/PantheonTerminalWindow.vala',
    'src/Dialogs/ForegroundProcessDialog.vala',
    'src/Dialogs/UnsafePasteDialog.vala',
    'src/Widgets/SearchToolbar.vala',
    'src/Widgets/TerminalWidget.vala',
    dependencies: [
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('vte-2.91'),
        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')

project(
    'io.elementary.terminal',
    'vala', 'c',
    version: '5.5.1'
)

if meson.get_compiler('vala').version().version_compare('<0.40')
    error('Missing required dependency: valac >= 0.40')
endif

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')

vte_dep = dependency('vte-2.91')

if vte_dep.version().version_compare('>=0.59')
    add_project_arguments(['--define', 'VTE_0_60'], language : 'vala')
elif get_option('ubuntu-bionic-patched-vte')
    add_project_arguments(['--define', 'UBUNTU_BIONIC_PATCHED_VTE'], language : 'vala')
endif

terminal_resources = gnome.compile_resources(
    'terminal-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data'
)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/DBus.vala',
    'src/MainWindow.vala',
    'src/Dialogs/ForegroundProcessDialog.vala',
    'src/Dialogs/UnsafePasteDialog.vala',
    'src/Widgets/SearchToolbar.vala',
    'src/Widgets/TerminalWidget.vala',
    terminal_resources,
    dependencies: [
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('granite', version: '>=5.3.0'),
        vte_dep,
        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')

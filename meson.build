project(
    'io.elementary.terminal',
    'vala', 'c',
    version: '5.5.2'
)

if meson.get_compiler('vala').version().version_compare('<0.40')
    error('Missing required dependency: valac >= 0.40')
endif

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
        '-DHANDY_USE_UNSTABLE_API'
    ],
    language:'c'
)

vte_dep = dependency('vte-2.91')

libpcre2_dep = []
if vte_dep.version().version_compare('>=0.59')
    add_project_arguments(['--define', 'VTE_0_60'], language : 'vala')
    vapi_dir = meson.current_source_dir() / 'vapi'
    add_project_arguments('--vapidir=' + vapi_dir, language: 'vala')
    add_project_arguments('-DPCRE2_CODE_UNIT_WIDTH=0', language: 'c')
    libpcre2_dep = dependency('libpcre2-8')
elif get_option('ubuntu-bionic-patched-vte')
    add_project_arguments(['--define', 'UBUNTU_BIONIC_PATCHED_VTE'], language : 'vala')
endif

terminal_resources = gnome.compile_resources(
    'terminal-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data'
)

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
config_header = configure_file(
    input : 'config.vala.in',
    output : 'config.vala',
    configuration : conf_data
)

executable(
    meson.project_name(),
    config_header,
    'src/Application.vala',
    'src/DBus.vala',
    'src/MainWindow.vala',
    'src/Themes.vala',
    'src/Dialogs/ForegroundProcessDialog.vala',
    'src/Dialogs/ColorPreferencesDialog.vala',
    'src/Dialogs/UnsafePasteDialog.vala',
    'src/Widgets/SearchToolbar.vala',
    'src/Widgets/TerminalWidget.vala',
    terminal_resources,
    dependencies: [
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gtk+-3.0'),
        dependency('granite', version: '>=5.5.0'),
        dependency('libhandy-1', version: '>=0.83.0'),
        vte_dep,
        libpcre2_dep,
        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install : true
)

meson.add_install_script('meson/post_install.py')

subdir('data')
subdir('po')

project(
    'io.elementary.terminal',
    'vala', 'c',
    version: '6.1.2',
    meson_version: '>=0.60'
)

valac = meson.get_compiler('vala')
cc = meson.get_compiler('c')

if valac.version().version_compare('<0.40')
    error('Missing required dependency: valac >= 0.40')
endif

gnome = import('gnome')
i18n = import('i18n')

glib_version = '>=2.40'

glib_dep = dependency('glib-2.0', version: glib_version)
gobject_dep = dependency('gobject-2.0', version: glib_version)
gio_dep = dependency('gio-2.0', version: glib_version)
gee_dep = dependency('gee-0.8')
gtk_dep = dependency('gtk+-3.0', version: '>=3.24')
granite_dep = dependency('granite', version: '>=6.1')
handy_dep = dependency('libhandy-1', version: '>=0.83')
vte_dep = dependency('vte-2.91', version: '>=0.59')
pcre2_dep = dependency('libpcre2-8')

posix_dep = valac.find_library('posix')
linux_dep = valac.find_library('linux', required: false)
m_dep = cc.find_library('m', required : false)

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))

add_project_arguments('--vapidir', meson.current_source_dir() / 'vapi', language: 'vala')

if glib_dep.version().version_compare('>=2.73.2')
    add_project_arguments('--define', 'HAS_GLIB_2_74', language: 'vala')
endif

if linux_dep.found()
    add_project_arguments('--define', 'HAS_LINUX', language: 'vala')
endif

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DPCRE2_CODE_UNIT_WIDTH=0',
    '-DHANDY_USE_UNSTABLE_API',
    language:'c'
)

subdir('po')
subdir('po/extra')
subdir('data')
subdir('src')

gnome.post_install(glib_compile_schemas: true)

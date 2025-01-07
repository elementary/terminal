project(
    'io.elementary.terminal',
    'vala', 'c',
    version: '7.0.0',
    meson_version: '>=0.60'
)

valac = meson.get_compiler('vala')
cc = meson.get_compiler('c')

if valac.version().version_compare('<0.56')
    error('Missing required dependency: valac >= 0.56')
endif

gnome = import('gnome')
i18n = import('i18n')

granite_dep = dependency('granite-7', version: '>=7.5')
adwaita_dep = dependency('libadwaita-1', version: '>=1.5')
vte_dep = dependency('vte-2.91-gtk4', version: '>=0.76')
pcre2_dep = dependency('libpcre2-8', version: '>=10.4') # Perl Regular Expression library
posix_dep = valac.find_library('posix')
linux_dep = valac.find_library('linux', required: false)
m_dep = cc.find_library('m', required : false)

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))

add_project_arguments(
    '--vapidir', meson.current_source_dir() / 'vapi',
    '--enable-experimental',
    language: 'vala'
)

# if glib_dep.version().version_compare('>=2.73.2')
    add_project_arguments('--define', 'HAS_GLIB_2_74', language: 'vala')
# endif

if linux_dep.found()
    add_project_arguments('--define', 'HAS_LINUX', language: 'vala')
endif

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DPCRE2_CODE_UNIT_WIDTH=0',
    # '-DHANDY_USE_UNSTABLE_API',
    language:'c'
)

subdir('po')
subdir('po/extra')
subdir('data')
subdir('src')

gnome.post_install(glib_compile_schemas: true)

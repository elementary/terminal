datadir = get_option('prefix') / get_option('datadir')
podir = meson.project_source_root() / 'po'

i18n.merge_file(
    type: 'desktop',
    input: meson.project_name() + '.desktop.in',
    output: '@BASENAME@',
    po_dir: podir / 'extra',
    install: true,
    install_dir: datadir / 'applications'
)

i18n.merge_file(
    type: 'desktop',
    input: 'open-pantheon-terminal-here.desktop.in',
    output: '@BASENAME@',
    po_dir: podir / 'extra',
    install: true,
    install_dir: datadir / 'applications'
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: '@BASENAME@',
    po_dir: podir / 'extra',
    install: true,
    install_dir: datadir / 'metainfo'
)

install_data(meson.project_name() + '.gschema.xml', install_dir: datadir / 'glib-2.0' / 'schemas')
install_data('pantheon_terminal_process_completion_notifications.fish', install_dir: datadir / 'fish' / 'vendor_conf.d')
install_data('enable-zsh-completion-notifications', install_dir: datadir / meson.project_name())

terminal_gresource = gnome.compile_resources('gresource', meson.project_name() + '.gresource.xml')

desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
    test(
        'Validate desktop file', desktop_file_validate,
        args: meson.current_build_dir() / meson.project_name() + '.desktop'
    )

    test(
        'Validate open here desktop file', desktop_file_validate,
        args: meson.current_build_dir() / 'open-pantheon-terminal-here.desktop'
    )
endif

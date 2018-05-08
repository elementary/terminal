install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n.merge_file (
    'desktop',
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    type: 'desktop'
)

i18n.merge_file (
    'desktop',
    input: 'open-pantheon-terminal-here.desktop.in',
    output: 'open-pantheon-terminal-here.desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications'),
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    type: 'desktop'
)

i18n.merge_file (
    'appdata',
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    po_dir: join_paths(meson.source_root (), 'po', 'extra')
)

test (
    'Validate desktop file',
    find_program('desktop-file-validate'),
    args: join_paths(meson.current_build_dir (), meson.project_name() + '.desktop')
)

test (
    'Validate open here desktop file',
    find_program('desktop-file-validate'),
    args: join_paths(meson.current_build_dir (), 'open-pantheon-terminal-here.desktop')
)

test (
    'Validate appdata file',
    find_program('appstreamcli'),
    args: ['validate', join_paths(meson.current_build_dir (), meson.project_name() + '.appdata.xml')]
)

install_data(
    'enable-fish-completion-notifications',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)

install_data(
    'enable-zsh-completion-notifications',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)

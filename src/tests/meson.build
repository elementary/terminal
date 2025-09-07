unsafe_paste_test = executable(
    'UnsafePasteTest',
    'UnsafePasteTest.vala',
    meson.project_source_root() / 'src' / 'Utils.vala',
    dependencies: [
        glib_dep,
        gtk_dep
    ],
    install: false
)

test(
    'UnsafePasteTest',
    unsafe_paste_test
    # env: test_env
)

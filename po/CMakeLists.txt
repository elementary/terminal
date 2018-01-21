include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    DESKTOP_FILES
        ${CMAKE_SOURCE_DIR}/data/open-pantheon-terminal-here.desktop.in.in
        ${CMAKE_SOURCE_DIR}/data/io.elementary.terminal.desktop.in.in
    APPDATA_FILES
        ${CMAKE_SOURCE_DIR}/data/io.elementary.terminal.appdata.xml.in
)

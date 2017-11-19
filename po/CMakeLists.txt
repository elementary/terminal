include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    DESKTOP_FILES
        ${CMAKE_SOURCE_DIR}/data/open-pantheon-terminal-here.desktop.in
        ${CMAKE_SOURCE_DIR}/data/org.pantheon.terminal.desktop.in
    APPDATA_FILES
        ${CMAKE_SOURCE_DIR}/data/io.elementary.terminal.appdata.xml.in
)

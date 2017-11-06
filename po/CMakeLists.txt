include (Translations)
add_translations_directory ("io.elementary.terminal")
add_translations_catalog ("io.elementary.terminal"
    ../src
    DESKTOP_FILES
        ${CMAKE_SOURCE_DIR}/data/open-pantheon-terminal-here.desktop.in
        ${CMAKE_SOURCE_DIR}/data/io.elementary.terminal.desktop.in
    APPDATA_FILES
        ${CMAKE_SOURCE_DIR}/data/io.elementary.terminal.appdata.xml.in
)

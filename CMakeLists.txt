# Check http://elementaryos.org/docs/code/the-build-system for documentation

project (io.elementary.terminal C)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

#
# Base bits
#

enable_testing ()

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/${CMAKE_PROJECT_NAME}")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME ${CMAKE_PROJECT_NAME})
set (RELEASE_NAME "Fast and connected.")
set (VERSION "0.4.3")
set (VERSION_INFO "Release")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Add 'make uninstall' command to remove installed files
configure_file(
    "${CMAKE_SOURCE_DIR}/cmake/Uninstall.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake)

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED
  gthread-2.0
  gtk+-3.0>=3.9.10
  granite>=0.3.0
  glib-2.0>=2.39
  vte-2.91
  gdk-3.0)

add_definitions (${DEPS_CFLAGS})

# Work around http://www.cmake.org/Bug/view.php?id=12928:
# CMake ignores CPPFLAGS where Debian and Ubuntu pass their hardening options.
# See the bug linked above and https://wiki.debian.org/Hardening for more info.
add_definitions (${CPPFLAGS})

link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)

include (ValaPrecompile)
vala_precompile (VALA_C
    src/Application.vala
    src/Constants.vala
    src/DBus.vala
    src/Settings.vala
    src/PantheonTerminalWindow.vala
    src/Dialogs/ForegroundProcessDialog.vala
    src/Dialogs/UnsafePasteDialog.vala
    src/Widgets/SearchToolbar.vala
    src/Widgets/TerminalWidget.vala
PACKAGES
    vte-2.91
    granite
    gtk+-3.0
    gdk-3.0
    posix
CUSTOM_VAPIS
    vapi/config.vapi
OPTIONS
    --thread
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
)

include (GSettings)
add_schema ("data/io.elementary.terminal.gschema.xml")

#link_libraries (m)
add_subdirectory (po)


include (GResource)
glib_compile_resources (GLIB_RESOURCES_CSS SOURCE data/io.elementary.terminal.gresource.xml)

add_executable (${EXEC_NAME} ${VALA_C} ${GLIB_RESOURCES_CSS})
find_library (M_LIB m)
target_link_libraries (${EXEC_NAME} ${M_LIB})

include (Translations)
configure_file_translation(${CMAKE_SOURCE_DIR}/data/open-pantheon-terminal-here.desktop.in ${CMAKE_BINARY_DIR}/data/open-pantheon-terminal-here.desktop ${CMAKE_SOURCE_DIR}/po/)
configure_file_translation(${CMAKE_SOURCE_DIR}/data/org.pantheon.terminal.desktop.in ${CMAKE_BINARY_DIR}/data/org.pantheon.terminal.desktop ${CMAKE_SOURCE_DIR}/po/)
configure_file_translation(${CMAKE_SOURCE_DIR}/data/io.elementary.terminal.appdata.xml.in ${CMAKE_BINARY_DIR}/data/io.elementary.terminal.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
install (FILES ${CMAKE_BINARY_DIR}/data/org.pantheon.terminal.desktop DESTINATION share/applications)
install (FILES ${CMAKE_BINARY_DIR}/data/io.elementary.terminal.appdata.xml DESTINATION share/metainfo)
install (FILES ${CMAKE_BINARY_DIR}/data/open-pantheon-terminal-here.desktop DESTINATION share/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/enable-zsh-completion-notifications DESTINATION share/io.elementary.terminal)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/enable-fish-completion-notifications DESTINATION share/io.elementary.terminal)

# Check http://elementaryos.org/docs/code/the-build-system for documentation

project (pantheon-terminal C)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

#
# Base bits
#

enable_testing ()

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/pantheon-terminal")
set (GETTEXT_PACKAGE "pantheon-terminal")
set (RELEASE_NAME "Fast and connected.")
set (VERSION "0.3.0.1")
set (VERSION_INFO "Release")
set (CMAKE_C_FLAGS "-ggdb")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

# Comment this out to enable C compiler warnings
add_definitions (-w)

# Add 'make dist' command for creating release tarball
set (CPACK_PACKAGE_VERSION ${VERSION})
set (CPACK_SOURCE_GENERATOR "TGZ")
set (CPACK_SOURCE_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
set (CPACK_SOURCE_IGNORE_FILES "/build/;/.bzr/;/.bzrignore;~$;${CPACK_SOURCE_IGNORE_FILES}")

include (CPack)
add_custom_target (dist COMMAND ${CMAKE_MAKE_PROGRAM} package_source)

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED
  gthread-2.0
  gtk+-3.0>=3.9.10
  granite>=0.3.0
  vte-2.90
  libnotify
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
    src/DBus.vala
    src/Settings.vala
    src/PantheonTerminal.vala
    src/PantheonTerminalWindow.vala
    src/TerminalWidget.vala
    src/ForegroundProcessDialog.vala
    src/Constants.vala
PACKAGES
    vte-2.90
    granite
    gtk+-3.0
    libnotify
    gdk-3.0
    posix
CUSTOM_VAPIS
    vapi/config.vapi
OPTIONS
    --thread
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
)

include (GSettings)
add_schema ("org.pantheon.terminal.gschema.xml")

#link_libraries (m)
add_subdirectory (po)

add_executable (pantheon-terminal ${VALA_C})
find_library (M_LIB m)
target_link_libraries (pantheon-terminal ${M_LIB})

install (TARGETS pantheon-terminal RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/pantheon-terminal.desktop DESTINATION share/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/open-pantheon-terminal-here.desktop DESTINATION share/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/enable-zsh-completion-notifications DESTINATION share/pantheon-terminal)

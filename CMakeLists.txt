# Check http://webdev.elementaryos.org/docs/developer-guide/cmake for documentation

project (pantheon-terminal)
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base bits
#

enable_testing ()

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/pantheon-terminal")
set (GETTEXT_PACKAGE "pantheon-terminal")
set (RELEASE_NAME "Fast and connected.")
set (VERSION "0.1")
set (VERSION_INFO "Release")
set (CMAKE_C_FLAGS "-ggdb")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED gthread-2.0 gtk+-3.0 granite vte-2.90 libnotify gdk-3.0)

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.10.0" MINIMUM)

include(ValaPrecompile)
vala_precompile(VALA_C
    src/Settings.vala
    src/PantheonTerminal.vala
    src/PantheonTerminalWindow.vala
    src/TerminalWidget.vala
    src/ForegroundProcessDialog.vala
    src/config.vala
PACKAGES
    vte-2.90
    granite
    gtk+-3.0
    libnotify
    gdk-3.0
    posix
OPTIONS
    --thread
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
)

include(GSettings)
add_schema ("org.elementary.pantheon-terminal.gschema.xml")

add_subdirectory (po)

add_executable(pantheon-terminal ${VALA_C})

install(TARGETS pantheon-terminal RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/pantheon-terminal.desktop DESTINATION share/applications)

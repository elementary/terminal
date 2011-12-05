# Check http://webdev.elementaryos.org/docs/developer-guide/cmake for documentation

project (pantheon-terminal)
cmake_minimum_required (VERSION 2.8)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base bits
#
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/pantheon-terminal")
set (GETTEXT_PACKAGE "pantheon-terminal")
set (RELEASE_NAME "Fast and connected.")
set (VERSION "0.1")
set (VERSION_INFO "Release")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

#
# Niceties
#
set (ARCHIVE_NAME pantheon-terminal-${VERSION})
add_custom_target (dist
    COMMAND bzr export --root=${ARCHIVE_NAME} ${CMAKE_BINARY_DIR}/${ARCHIVE_NAME}.tar.bz2
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

add_custom_target (distcheck
    COMMAND cd ${CMAKE_BINARY_DIR}
    && rm -rf ${ARCHIVE_NAME}
    && tar xf ${ARCHIVE_NAME}.tar.bz2
    && mkdir ${ARCHIVE_NAME}/build
    && cd ${ARCHIVE_NAME}/build
    && cmake -DCMAKE_INSTALL_PREFIX=../install -DGSETTINGS_LOCALINSTALL=ON .. -DCMAKE_MODULE_PATH=/usr/share/cmake
    && make -j8
    && make -j8 install
    && make check
    )
add_dependencies(distcheck dist)

add_custom_target (uninstall "${CMAKE_COMMAND}" -P
  "${CMAKE_SOURCE_DIR}/cmake/uninstall.cmake")

#
# config.h
#
configure_file (${CMAKE_SOURCE_DIR}/src/config.vala.cmake ${CMAKE_SOURCE_DIR}/src/config.vala)
add_definitions(-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED gtk+-3.0 granite vte-2.90)

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.10.0" MINIMUM)

include(ValaPrecompile)
vala_precompile(VALA_C
    src/main.vala
    src/PreferencesDialog.vala
    src/TerminalWithNotification.vala
    src/Resources.vala
PACKAGES
    vte-2.90
    granite
    gtk+-3.0
OPTIONS
    --thread
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
    )

add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes )
add_executable(pantheon-terminal ${VALA_C})

install(TARGETS pantheon-terminal RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/pantheon-terminal.desktop DESTINATION share/applications)
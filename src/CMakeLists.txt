# Vala stuff

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.11.3" MINIMUM)
include(ValaPrecompile)


# pkgconfig, real C code
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED gtk+-3.0 vte-2.90)
set(CFLAGS
	${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER}
)
set(LIB_PATHS
	${DEPS_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})


add_definitions(${CFLAGS})
vala_precompile(VALA_C main.vala
PACKAGES
    gtk+-3.0
    vte-2.90
OPTIONS
    --thread)

add_executable(pantheon-terminal
    ${VALA_C} )

target_link_libraries(pantheon-terminal ${DEPS_LIBRARIES})

install(TARGETS pantheon-terminal RUNTIME DESTINATION bin)

# OpenRAC on the Nintendo Switch 2 (OunceDevKit, libounce). Included from CMakeLists.txt when the Switch 2 toolchain file is in use
# (NINTENDO_SWITCH2). Everything Switch 2 specific that is not code lives here; the code is in platform_switch2/.
if(NOT NINTENDO_SWITCH2)
  return()
endif()
set(OPENRAC_SWITCH2 ON)
set(OPENRAC_SWITCH2_DIR "${CMAKE_CURRENT_LIST_DIR}/../platform_switch2")
set(OPENRAC_SWITCH2_HOME "openrac" CACHE STRING "The folder of switch/ on the SD card the program keeps its data, settings and logs in")
add_compile_definitions("OPENRAC_S2_HOME=\"sdmc:/switch/${OPENRAC_SWITCH2_HOME}\"")
# Diagnostics for a program that stops answering: every generated function writes its address into a ring (platform_switch2/compat.c) and,
# with debug.txt on the card, the last ones are logged to boot.txt every 10 s. Slows the game down; off unless asked for.
option(OPENRAC_SWITCH2_CALL_RING "Log the last functions the game ran (for finding a freeze)" OFF)
if(OPENRAC_SWITCH2_CALL_RING)
  add_compile_definitions(OPENRAC_SWITCH2_CALL_RING=1)
endif()
add_compile_definitions(OPENRAC_SWITCH2=1 _GNU_SOURCE=1 CLOCK_THREAD_CPUTIME_ID=CLOCK_MONOTONIC)
# Horizon's libc lacks a few POSIX headers (dlfcn.h, execinfo.h, sys/sysinfo.h): stand-ins first on the path.
include_directories(BEFORE SYSTEM "${OPENRAC_SWITCH2_DIR}/compat")
# The decompilation's own copy of the retail libc (generated C: struct _reent, _Bigint, ...) meets this toolchain's newlib, which
# declares the same names through <math.h> -> <sys/reent.h>. The generated C needs none of newlib's: its guard is set for those files
# (OPENRAC_SWITCH2_GENERATED_C_OPTIONS, used where Games.cmake lists the generated sources).
set(OPENRAC_SWITCH2_GENERATED_C_OPTIONS "-D_SYS_REENT_H_" "-D__ULong_defined")
# Luau (and others) use <climits> names without including it; newlib's libstdc++ does not pull it in.
add_compile_options("SHELL:$<$<COMPILE_LANGUAGE:CXX>:-include climits>")
# There is no libdl on Horizon (dlopen and friends are the stand-ins in platform_switch2/compat.c).
set(CMAKE_DL_LIBS "")
# The console's file system will not rename a file over an existing one (every "write a temporary, rename it onto the file" in the port,
# the settings, the saves and the mods' files, failed with "File exists"): rename() is wrapped in platform_switch2/compat.c.
add_link_options("LINKER:--wrap=rename")

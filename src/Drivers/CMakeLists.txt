#//////////////////////////////////////////////////////////////////////////////////////
#// This file is distributed under the University of Illinois/NCSA Open Source License.
#// See LICENSE file in top directory for details.
#//
#// Copyright (c) 2019 QMCPACK developers.
#//
#// File developed by: Ye Luo, yeluo@anl.gov, Argonne National Laboratory
#//
#// File created by: Ye Luo, yeluo@anl.gov, Argonne National Laboratory
#//////////////////////////////////////////////////////////////////////////////////////

SET(DRIVERS check_spo check_wfc miniqmc miniqmc_sync_move)

# Setup StarPU
FIND_PACKAGE(PkgConfig)
PKG_CHECK_MODULES(STARPU REQUIRED starpu-1.3)
if (STARPU_FOUND)
  # CFLAGS other than -I
  foreach(CFLAG ${STARPU_CFLAGS_OTHER})
    SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CFLAG}")
  endforeach()
  # Static LDFLAGS other than -L
  foreach(LDFLAG ${STARPU_STATIC_LDFLAGS_OTHER})
    SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LDFLAG}")
  endforeach()
  # -L directories
  LINK_DIRECTORIES(${STARPU_STATIC_LIBRARY_DIRS})
else (STARPU_FOUND)
  MESSAGE(FATAL_ERROR "StarPU not found")
endif()

FOREACH(p ${DRIVERS})
  ADD_EXECUTABLE( ${p}  ${p}.cpp)
  if (STARPU_FOUND)
    TARGET_INCLUDE_DIRECTORIES(${p} PRIVATE ${STARPU_INCLUDE_DIRS})
    TARGET_LINK_LIBRARIES(${p} qmcwfs qmcbase qmcutil ${QMC_UTIL_LIBS} ${MPI_LIBRARY} ${STARPU_STATIC_LIBRARIES})
  else (STARPU_FOUND)
    TARGET_LINK_LIBRARIES(${p} qmcwfs qmcbase qmcutil ${QMC_UTIL_LIBS} ${MPI_LIBRARY})
  endif()
ENDFOREACH(p ${ESTEST})

SUBDIRS(tests)


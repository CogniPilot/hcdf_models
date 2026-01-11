# Copyright (c) 2025 CogniPilot Foundation
# SPDX-License-Identifier: Apache-2.0
#
# CMake module for HCDF SHA computation at build time
#
# This module provides functions to compute the SHA256 of an HCDF file
# and configure MCUmgr Kconfig options automatically.
#
# Usage:
#   include(${ZEPHYR_HCDF_MODELS_MODULE_DIR}/cmake/hcdf.cmake)
#   hcdf_configure(
#     BOARD mr_mcxn_t1
#     DEVICE optical-flow
#     BASE_URL "https://hcdf.cognipilot.org"
#   )
#

# Find the hcdf_models module directory
if(NOT DEFINED ZEPHYR_HCDF_MODELS_MODULE_DIR)
  # Try to find it via west
  execute_process(
    COMMAND west list -f {posixpath} hcdf_models
    OUTPUT_VARIABLE ZEPHYR_HCDF_MODELS_MODULE_DIR
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
endif()

# Function to compute short SHA (first 8 chars of SHA256) of a file
function(hcdf_compute_short_sha FILE_PATH OUT_VAR)
  if(NOT EXISTS "${FILE_PATH}")
    message(FATAL_ERROR "HCDF file not found: ${FILE_PATH}")
  endif()

  # Use cmake's built-in file hash if available (CMake 3.14+)
  file(SHA256 "${FILE_PATH}" FULL_SHA)
  string(SUBSTRING "${FULL_SHA}" 0 8 SHORT_SHA)
  set(${OUT_VAR} "${SHORT_SHA}" PARENT_SCOPE)
endfunction()

# Function to configure HCDF MCUmgr options
# This sets the URL and SHA Kconfig options for the HCDF MCUmgr group
function(hcdf_configure)
  cmake_parse_arguments(HCDF "" "BOARD;DEVICE;BASE_URL;SHA" "" ${ARGN})

  if(NOT HCDF_BOARD)
    message(FATAL_ERROR "hcdf_configure: BOARD is required")
  endif()
  if(NOT HCDF_DEVICE)
    message(FATAL_ERROR "hcdf_configure: DEVICE is required")
  endif()
  if(NOT HCDF_BASE_URL)
    set(HCDF_BASE_URL "https://hcdf.cognipilot.org")
  endif()

  # Construct the HCDF file path
  # Format: {base}/${board}/${device}/${device}.hcdf
  set(HCDF_URL "${HCDF_BASE_URL}/${HCDF_BOARD}/${HCDF_DEVICE}/${HCDF_DEVICE}.hcdf")

  # If SHA is not provided, try to compute it from local file
  if(NOT HCDF_SHA)
    # Look for the local HCDF file (follows symlink to SHA-versioned file)
    set(LOCAL_HCDF "${ZEPHYR_HCDF_MODELS_MODULE_DIR}/${HCDF_BOARD}/${HCDF_DEVICE}/${HCDF_DEVICE}.hcdf")

    if(EXISTS "${LOCAL_HCDF}")
      # Resolve symlink to get the actual file
      get_filename_component(REAL_HCDF "${LOCAL_HCDF}" REALPATH)
      get_filename_component(REAL_NAME "${REAL_HCDF}" NAME)

      # Extract SHA from filename (format: {sha}-{name}.hcdf)
      string(REGEX MATCH "^([a-f0-9]+)-" SHA_MATCH "${REAL_NAME}")
      if(SHA_MATCH)
        string(REGEX REPLACE "^([a-f0-9]+)-.*" "\\1" HCDF_SHA "${REAL_NAME}")
        message(STATUS "HCDF: Using SHA ${HCDF_SHA} from ${REAL_NAME}")
      else()
        # Fall back to computing SHA from file content
        hcdf_compute_short_sha("${REAL_HCDF}" HCDF_SHA)
        message(STATUS "HCDF: Computed SHA ${HCDF_SHA} from ${REAL_HCDF}")
      endif()
    else()
      message(WARNING "HCDF: Local file not found at ${LOCAL_HCDF}, SHA will be empty")
      set(HCDF_SHA "")
    endif()
  endif()

  # Set Kconfig options
  # Note: These need to be set before KConfig processing, so use cache variables
  set(CONFIG_MCUMGR_GRP_HCDF_URL "${HCDF_URL}" CACHE STRING "HCDF URL" FORCE)
  set(CONFIG_MCUMGR_GRP_HCDF_SHA "${HCDF_SHA}" CACHE STRING "HCDF SHA" FORCE)

  message(STATUS "HCDF Configuration:")
  message(STATUS "  Board:  ${HCDF_BOARD}")
  message(STATUS "  Device: ${HCDF_DEVICE}")
  message(STATUS "  URL:    ${HCDF_URL}")
  message(STATUS "  SHA:    ${HCDF_SHA}")
endfunction()

# Function to get HCDF URL for a board/device combination
function(hcdf_get_url BOARD DEVICE OUT_VAR)
  set(${OUT_VAR} "https://hcdf.cognipilot.org/${BOARD}/${DEVICE}/${DEVICE}.hcdf" PARENT_SCOPE)
endfunction()

# Function to get local HCDF file path
function(hcdf_get_local_path BOARD DEVICE OUT_VAR)
  set(${OUT_VAR} "${ZEPHYR_HCDF_MODELS_MODULE_DIR}/${BOARD}/${DEVICE}/${DEVICE}.hcdf" PARENT_SCOPE)
endfunction()

# Function to validate HCDF SHA from Kconfig against the actual HCDF file
# Call this after Kconfig has been processed (i.e., after find_package(Zephyr))
# Usage:
#   hcdf_validate_sha(BOARD mr_mcxn_t1 DEVICE optical-flow)
function(hcdf_validate_sha)
  cmake_parse_arguments(HCDF "" "BOARD;DEVICE" "" ${ARGN})

  if(NOT HCDF_BOARD)
    message(FATAL_ERROR "hcdf_validate_sha: BOARD is required")
  endif()
  if(NOT HCDF_DEVICE)
    message(FATAL_ERROR "hcdf_validate_sha: DEVICE is required")
  endif()

  # Get the SHA from Kconfig (set in prj.conf)
  if(NOT DEFINED CONFIG_MCUMGR_GRP_HCDF_SHA)
    message(STATUS "HCDF: CONFIG_MCUMGR_GRP_HCDF_SHA not defined, skipping validation")
    return()
  endif()
  set(KCONFIG_SHA "${CONFIG_MCUMGR_GRP_HCDF_SHA}")

  # Get the actual SHA from the local HCDF file
  set(LOCAL_HCDF "${ZEPHYR_HCDF_MODELS_MODULE_DIR}/${HCDF_BOARD}/${HCDF_DEVICE}/${HCDF_DEVICE}.hcdf")

  if(NOT EXISTS "${LOCAL_HCDF}")
    message(WARNING "HCDF: Local file not found at ${LOCAL_HCDF}, cannot validate SHA")
    return()
  endif()

  # Resolve symlink to get the actual file
  get_filename_component(REAL_HCDF "${LOCAL_HCDF}" REALPATH)
  get_filename_component(REAL_NAME "${REAL_HCDF}" NAME)

  # Extract SHA from filename (format: {sha}-{name}.hcdf)
  string(REGEX MATCH "^([a-f0-9]+)-" SHA_MATCH "${REAL_NAME}")
  if(SHA_MATCH)
    string(REGEX REPLACE "^([a-f0-9]+)-.*" "\\1" FILE_SHA "${REAL_NAME}")
  else()
    # Fall back to computing SHA from file content
    hcdf_compute_short_sha("${REAL_HCDF}" FILE_SHA)
  endif()

  # Compare SHAs
  if(NOT "${KCONFIG_SHA}" STREQUAL "${FILE_SHA}")
    # Get the app path relative to the workspace root (e.g., spinali/)
    # APPLICATION_SOURCE_DIR is the full path, we need it relative to where west runs from
    get_filename_component(WORKSPACE_DIR "${APPLICATION_SOURCE_DIR}/../.." REALPATH)
    file(RELATIVE_PATH APP_REL_PATH "${WORKSPACE_DIR}" "${APPLICATION_SOURCE_DIR}")
    message(WARNING
      "\n"
      "========================================\n"
      "HCDF SHA MISMATCH DETECTED!\n"
      "========================================\n"
      "  Board:       ${HCDF_BOARD}\n"
      "  Device:      ${HCDF_DEVICE}\n"
      "  prj.conf:    ${KCONFIG_SHA}\n"
      "  hcdf_models: ${FILE_SHA}\n"
      "\n"
      "To fix, run:\n"
      "  sed -i 's/CONFIG_MCUMGR_GRP_HCDF_SHA=\"${KCONFIG_SHA}\"/CONFIG_MCUMGR_GRP_HCDF_SHA=\"${FILE_SHA}\"/' ${APP_REL_PATH}/prj.conf\n"
      "========================================\n"
    )
  else()
    message(STATUS "HCDF: SHA validation passed (${KCONFIG_SHA})")
  endif()
endfunction()

# Copyright (c) 2025 CogniPilot Foundation
# SPDX-License-Identifier: Apache-2.0
#
# HCDF Models Zephyr Module
#
# This module provides HCDF files and a CMake helper for computing
# HCDF SHA values at build time.
#
# Usage in your application's CMakeLists.txt:
#   include(${ZEPHYR_HCDF_MODELS_MODULE_DIR}/cmake/hcdf.cmake)
#   hcdf_configure(BOARD mr_mcxn_t1 DEVICE optical-flow)
#

# Make the module directory available
set(ZEPHYR_HCDF_MODELS_MODULE_DIR ${CMAKE_CURRENT_LIST_DIR}/.. CACHE PATH "HCDF Models module directory")

############################################################################
# ADOBE CONFIDENTIAL
# ___________________
#  Copyright 2021 Adobe
#  All Rights Reserved.
# * NOTICE:  All information contained herein is, and remains
# the property of Adobe and its suppliers, if any. The intellectual
# and technical concepts contained herein are proprietary to Adobe
# and its suppliers and are protected by all applicable intellectual
# property laws, including trade secret and copyright laws.
# Dissemination of this information or reproduction of this material
# is strictly forbidden unless prior written permission is obtained
# from Adobe.
############################################################################

if(TARGET lemon::lemon)
    return()
endif()

message(STATUS "creating target 'lemon::lemon'")

SET(LEMON_ENABLE_GLPK OFF)
SET(LEMON_ENABLE_ILOG OFF)
SET(LEMON_ENABLE_COIN OFF)
SET(LEMON_ENABLE_SOPLEX OFF)

include(FetchContent)
FetchContent_Declare(lemon
  URL http://lemon.cs.elte.hu/pub/sources/lemon-1.3.1.zip
  URL_HASH SHA256=2222c2b2e58f556d6d53117dfbd9c5b4fc1fceb41a6eaca3c9a3e58b66f9e46f)
FetchContent_Populate(lemon)

configure_file(
  ${lemon_SOURCE_DIR}/lemon/config.h.in
  ${lemon_BINARY_DIR}/lemon/config.h
)

add_library(lemon INTERFACE)
target_compile_definitions(lemon INTERFACE
  -DLEMON_ONLY_TEMPLATES)
target_include_directories(lemon
  INTERFACE
  ${lemon_SOURCE_DIR}
  ${lemon_BINARY_DIR}
)

add_library(lemon::lemon ALIAS lemon)

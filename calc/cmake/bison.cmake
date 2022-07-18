
message(STATUS "Getting bison release")

FetchContent_Declare(winbison
  URL https://github.com/lexxmark/winflexbison/releases/download/v2.5.25/win_flex_bison-2.5.25.zip
  URL_HASH SHA256=8d324b62be33604b2c45ad1dd34ab93d722534448f55a16ca7292de32b6ac135)
FetchContent_Populate(winbison)

set(BISON_EXECUTABLE "${winbison_SOURCE_DIR}/win_bison.exe" CACHE FILEPATH "" FORCE)

find_package(BISON 3.2)

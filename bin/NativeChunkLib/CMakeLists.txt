cmake_minimum_required(VERSION 3.17)
project(CmakeLibraryTest)

set(CMAKE_CXX_STANDARD 14)
set(DEST "C:\\Users\\Freek\\Documents\\My Games\\InfiniteTerrain\\bin\\binaries")

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(STATUS Building for 64 bits)
else()
    message(STATUS Building for 32 bits)
endif(CMAKE_SIZEOF_VOID_P EQUAL 8)

add_subdirectory(godot-cpp)

add_library(
        ChunkLib SHARED
        src/GodotLibrary.cpp
        src/TestClass.cpp
        src/NativeChunk.cpp include/NativeChunk.hpp src/MeshData.cpp include/MeshData.hpp src/ChunkMeshInstance.cpp include/ChunkMeshInstance.hpp)

target_link_libraries(ChunkLib PUBLIC godot-cpp)
target_include_directories(
        ChunkLib
        PUBLIC
        $<INSTALL_INTERFACE:include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

install(TARGETS ChunkLib DESTINATION ${DEST})

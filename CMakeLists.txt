cmake_minimum_required(VERSION 3.1...3.18)

project(
        libRT2D 
        VERSION 0.1.0 
        LANGUAGES CXX    
        )


set(libRT2D_INCLUDE_DIR "${PROJECT_SOURCE_DIR}/include")
set(libRT2D_SRC_DIR "q${PROJECT_SOURCE_DIR}/src")

set(libRT2D_INCLUDE_FILES
        "${libRT2D_INCLUDE_DIR}/")

set(libRT2D_SRC_FILES
        "${libRT2D_SRC_DIR}/libRT2D.cpp")

#### Include Lib ####
add_subdirectory("lib")


add_library(libRT2D SHARED "${libRT2D_INCLUDE_FILES}" "${libRT2D_SRC_FILES}")
target_include_directories(libRT2D "${libRT2D_INCLUDE_DIR}")

target_link_libraries(libRT2D libHQZ libRapidJSON)

target_compile_features(libRT2D cxx_std_17)


if(BUILD_EXAMPLE)
    set(libRT2D_Build_Example ON)
endif()

option(libRT2D_Build_Example "Build libRT2D Examples" OFF)
if(libRT2D_Build_Example)
    set(libRT2D_EXAMPLE_DIR "${PROJECT_SOURCE_DIR}/example")
    add_subdirectory(example)    
endif()





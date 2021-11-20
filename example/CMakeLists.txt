
set(EXAMPLES
    1Tx1Rx
)

foreach (example ${EXAMPLES})
    add_executable(${example} ${example}/${example}.cpp)
    target_link_libraries((${example} libRT2D)
endforeach()

if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
endif()

add_custom_target(examples ALL DEPENDS ${EXAMPLES})

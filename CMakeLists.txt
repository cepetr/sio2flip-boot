cmake_minimum_required(VERSION 3.10)

project(xex_boot ASM)

set(app_name ${CMAKE_PROJECT_NAME})

add_executable(${app_name} boot.s)

set_target_properties(${app_name} PROPERTIES SUFFIX ".sys")

target_link_options(${app_name} PRIVATE -C atari-cassette.cfg)
target_link_options(${app_name} PRIVATE --start-addr 0x0700)
target_link_options(${app_name} PRIVATE -m ${app_name}.map)

set_property(TARGET ${app_name} APPEND PROPERTY ADDITIONAL_CLEAN_FILES ${app_name}.map)

# Post-build step: convert .sys file to .c array using xxd -i
add_custom_command(
    TARGET ${app_name}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "// Automatically generated file" > ${app_name}.c
    COMMAND ${CMAKE_COMMAND} -E echo "// clang-format off" >> ${app_name}.c
    COMMAND ${CMAKE_COMMAND} -E echo "" >> ${app_name}.c
    COMMAND xxd -i ${app_name}.sys >> ${app_name}.c
    COMMENT "Generating C array from ${app_name}.sys"
)

# Post-build step: copy generated .c file to the parent directory

add_custom_command(
    TARGET ${app_name}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy ${app_name}.c ../../${app_name}.c
    COMMENT "Copying generated C array to parent directory"
)

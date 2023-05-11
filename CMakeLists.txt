cmake_minimum_required(VERSION 3.20)

project(RayTracingOpenGL)

add_executable(${PROJECT_NAME}
    src/Main.cpp

    deps/glad3.3/src/glad.c

    deps/imgui/imgui.cpp
    deps/imgui/imgui_demo.cpp
    deps/imgui/imgui_draw.cpp
    deps/imgui/imgui_tables.cpp
    deps/imgui/imgui_widgets.cpp
    deps/imgui/backends/imgui_impl_glfw.cpp
    deps/imgui/backends/imgui_impl_opengl3.cpp
)

add_subdirectory(deps/glfw)

target_include_directories(${PROJECT_NAME} PRIVATE
    deps/glad3.3/include/
    deps/glfw/include/
    deps/imgui/
)

target_link_libraries(${PROJECT_NAME}
    glfw
)

set_target_properties(${PROJECT_NAME} PROPERTIES CXX_STANDARD 17)

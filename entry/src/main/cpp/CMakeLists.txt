cmake_minimum_required(VERSION 3.13)
project(native_renderer)

set(CMAKE_CXX_STANDARD 17)

# 源文件
file(GLOB_RECURSE RENDERER_SOURCES "renderer/*.cpp")
file(GLOB_RECURSE PLATFORM_SOURCES "platform/*.cpp")

# stb_image 实现单元（单独编译）
set(STB_IMPL "platform/stb_image_impl.c")

add_library(native_renderer SHARED
    ${RENDERER_SOURCES}
    ${PLATFORM_SOURCES}
    ${STB_IMPL}
)

target_include_directories(native_renderer PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/third_party/stb
    ${CMAKE_CURRENT_SOURCE_DIR}/renderer
    ${CMAKE_CURRENT_SOURCE_DIR}/platform
)

# HarmonyOS NDK 库
find_library(EGL_LIB EGL)
find_library(GLES_LIB GLESv2)
find_library(NAPI_LIB ace_napi.z)
find_library(HILOG_LIB hilog_ndk.z)
find_library(RAWFILE_LIB rawfile)
find_library(ANDROID_LIB android)
find_library(LOG_LIB log)

target_link_libraries(native_renderer
    ${EGL_LIB}
    ${GLES_LIB}
    ${NAPI_LIB}
    ${HILOG_LIB}
    ${RAWFILE_LIB}
    ${ANDROID_LIB}
    ${LOG_LIB}
)

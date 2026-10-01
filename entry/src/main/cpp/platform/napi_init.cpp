// entry/src/main/cpp/platform/napi_init.cpp
#include "napi_bridge.h"
#include "Renderer.h"
#include <hilog_ndk.h>
#include <string>

static const char* MODULE_NAME = "native_renderer";
static const char* TAG = "NapiInit";

// XComponent surface 绑定
static napi_value OnSurfaceCreated(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    // 获取 native window from XComponent
    napi_valuetype type;
    napi_typeof(env, argv[0], &type);

    OH_LOG_INFO(LOG_APP, "OnSurfaceCreated called");

    // 通过 napi_unwrap 获取 OHNativeWindow
    void* nativeWindow = nullptr;
    napi_unwrap(env, argv[0], &nativeWindow);

    if (nativeWindow != nullptr) {
        // 获取窗口尺寸
        int32_t width = 1280;
        int32_t height = 720;
        // 实际应从 window 获取

        Renderer::instance().init((EGLNativeWindowType)nativeWindow, width, height);
    }

    return nullptr;
}

static napi_value OnSurfaceChanged(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t width, height;
    napi_get_value_int32(env, argv[0], &width);
    napi_get_value_int32(env, argv[1], &height);

    Renderer::instance().resize(width, height);
    return nullptr;
}

static napi_value OnSurfaceDestroyed(napi_env env, napi_callback_info info) {
    Renderer::instance().destroy();
    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    OH_LOG_INFO(LOG_APP, "native_renderer module init");

    napi_property_descriptor desc[] = {
        {"nativeInit", nullptr, NativeInit, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeDestroy", nullptr, NativeDestroy, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeResize", nullptr, NativeResize, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeBeginFrame", nullptr, NativeBeginFrame, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeSubmitCommands", nullptr, NativeSubmitCommands, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeEndFrame", nullptr, NativeEndFrame, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeLoadTexture", nullptr, NativeLoadTexture, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeUnloadTexture", nullptr, NativeUnloadTexture, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeSetCamera", nullptr, NativeSetCamera, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"nativeTouchInput", nullptr, NativeTouchInput, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onSurfaceCreated", nullptr, OnSurfaceCreated, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onSurfaceChanged", nullptr, OnSurfaceChanged, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"onSurfaceDestroyed", nullptr, OnSurfaceDestroyed, nullptr, nullptr, nullptr, napi_default, nullptr},
    };

    napi_define_properties(env, exports,
                           sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module nativeRendererModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "native_renderer",
    .nm_priv = ((void*)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterNativeRendererModule(void) {
    napi_module_register(&nativeRendererModule);
}

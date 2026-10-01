// entry/src/main/cpp/platform/napi_bridge.h
#pragma once

#include <napi/napi_native_api.h>

// NAPI 函数声明
napi_value NativeInit(napi_env env, napi_callback_info info);
napi_value NativeDestroy(napi_env env, napi_callback_info info);
napi_value NativeResize(napi_env env, napi_callback_info info);
napi_value NativeBeginFrame(napi_env env, napi_callback_info info);
napi_value NativeSubmitCommands(napi_env env, napi_callback_info info);
napi_value NativeEndFrame(napi_env env, napi_callback_info info);
napi_value NativeLoadTexture(napi_env env, napi_callback_info info);
napi_value NativeLoadTextureRaw(napi_env env, napi_callback_info info);
napi_value NativeUnloadTexture(napi_env env, napi_callback_info info);
napi_value NativeSetCamera(napi_env env, napi_callback_info info);
napi_value NativeGetCircleTextureId(napi_env env, napi_callback_info info);
napi_value NativeGetWhiteTextureId(napi_env env, napi_callback_info info);
napi_value NativeTouchInput(napi_env env, napi_callback_info info);

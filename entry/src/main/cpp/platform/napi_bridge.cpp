// entry/src/main/cpp/platform/napi_bridge.cpp
#include "napi_bridge.h"
#include "Renderer.h"
#include "stb_image.h"
#include <hilog_ndk.h>
#include <string>
#include <vector>
#include <cstring>

static const char* TAG = "NapiBridge";

napi_value NativeInit(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value argv[3];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    // 参数 0: surfaceId (string) — 需要通过 PlatformUtil 获取 window
    // 参数 1: width (number)
    // 参数 2: height (number)
    int32_t width, height;
    napi_get_value_int32(env, argv[1], &width);
    napi_get_value_int32(env, argv[2], &height);

    // 获取 surface — 通过 XComponent 的 native window
    // 实际实现中，surfaceId 需要通过 OH_NativeWindow 获取
    // 这里先记录参数，实际 surface 绑定在 napi_init.cpp 中处理

    OH_LOG_INFO(LOG_APP, "NativeInit: %{public}dx%{public}d", width, height);
    return nullptr;
}

napi_value NativeDestroy(napi_env env, napi_callback_info info) {
    Renderer::instance().destroy();
    return nullptr;
}

napi_value NativeResize(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t width, height;
    napi_get_value_int32(env, argv[0], &width);
    napi_get_value_int32(env, argv[1], &height);

    Renderer::instance().resize(width, height);
    return nullptr;
}

napi_value NativeBeginFrame(napi_env env, napi_callback_info info) {
    Renderer::instance().beginFrame();
    return nullptr;
}

napi_value NativeSubmitCommands(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    // argv[0] 是 DrawCmd[] 数组
    napi_value cmdArray = argv[0];
    uint32_t length;
    napi_get_array_length(env, cmdArray, &length);

    std::vector<DrawCmdData> cmds(length);
    double tmpD;

    for (uint32_t i = 0; i < length; i++) {
        napi_value elem;
        napi_get_element(env, cmdArray, i, &elem);

        napi_value val;

        napi_get_named_property(env, elem, "type", &val);
        napi_get_value_int32(env, val, &cmds[i].type);

        napi_get_named_property(env, elem, "textureId", &val);
        napi_get_value_int32(env, val, &cmds[i].textureId);

        napi_get_named_property(env, elem, "x", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].x = (float)tmpD;

        napi_get_named_property(env, elem, "y", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].y = (float)tmpD;

        napi_get_named_property(env, elem, "width", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].width = (float)tmpD;

        napi_get_named_property(env, elem, "height", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].height = (float)tmpD;

        napi_get_named_property(env, elem, "rotation", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].rotation = (float)tmpD;

        napi_get_named_property(env, elem, "srcX", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].srcX = (float)tmpD;

        napi_get_named_property(env, elem, "srcY", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].srcY = (float)tmpD;

        napi_get_named_property(env, elem, "srcW", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].srcW = (float)tmpD;

        napi_get_named_property(env, elem, "srcH", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].srcH = (float)tmpD;

        napi_get_named_property(env, elem, "r", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].r = (float)tmpD;

        napi_get_named_property(env, elem, "g", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].g = (float)tmpD;

        napi_get_named_property(env, elem, "b", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].b = (float)tmpD;

        napi_get_named_property(env, elem, "a", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].a = (float)tmpD;

        napi_get_named_property(env, elem, "flipX", &val);
        napi_get_value_int32(env, val, &cmds[i].flipX);

        napi_get_named_property(env, elem, "flipY", &val);
        napi_get_value_int32(env, val, &cmds[i].flipY);

        napi_get_named_property(env, elem, "layer", &val);
        napi_get_value_int32(env, val, &cmds[i].layer);

        napi_get_named_property(env, elem, "texW", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].texW = (float)tmpD;

        napi_get_named_property(env, elem, "texH", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].texH = (float)tmpD;

        napi_get_named_property(env, elem, "x2", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].x2 = (float)tmpD;

        napi_get_named_property(env, elem, "y2", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].y2 = (float)tmpD;

        napi_get_named_property(env, elem, "x3", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].x3 = (float)tmpD;

        napi_get_named_property(env, elem, "y3", &val);
        napi_get_value_double(env, val, &tmpD);
        cmds[i].y3 = (float)tmpD;
    }

    Renderer::instance().submitCommands(cmds.data(), (int)length);
    return nullptr;
}

napi_value NativeEndFrame(napi_env env, napi_callback_info info) {
    Renderer::instance().endFrame();
    return nullptr;
}

napi_value NativeLoadTexture(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value argv[2];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t textureId;
    napi_get_value_int32(env, argv[0], &textureId);

    // argv[1] = ArrayBuffer (raw PNG bytes)
    void* data;
    size_t byteLength;
    napi_get_arraybuffer_info(env, argv[1], &data, &byteLength);

    int w, h, channels;
    unsigned char* rgba = stbi_load_from_memory(
        (const unsigned char*)data, (int)byteLength, &w, &h, &channels, 4);

    if (rgba == nullptr) {
        OH_LOG_ERROR(LOG_APP, "stb_image decode failed: %{public}s", stbi_failure_reason());
        return nullptr;
    }

    Renderer::instance().loadTexture(textureId, rgba, w, h);
    stbi_image_free(rgba);
    return nullptr;
}

napi_value NativeLoadTextureRaw(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value argv[4];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t textureId;
    napi_get_value_int32(env, argv[0], &textureId);

    int32_t width, height;
    napi_get_value_int32(env, argv[1], &width);
    napi_get_value_int32(env, argv[2], &height);

    // argv[3] = ArrayBuffer (raw RGBA pixels, width * height * 4 bytes)
    void* data;
    size_t byteLength;
    napi_get_arraybuffer_info(env, argv[3], &data, &byteLength);

    size_t expected = (size_t)width * height * 4;
    if (byteLength < expected) {
        OH_LOG_ERROR(LOG_APP, "NativeLoadTextureRaw: buffer too small %{public}zu < %{public}zu",
                     byteLength, expected);
        return nullptr;
    }

    // Copy pixels since loadTexture may upload asynchronously
    unsigned char* pixels = new unsigned char[expected];
    memcpy(pixels, data, expected);
    Renderer::instance().loadTexture(textureId, pixels, width, height);
    delete[] pixels;
    return nullptr;
}

napi_value NativeUnloadTexture(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value argv[1];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t textureId;
    napi_get_value_int32(env, argv[0], &textureId);
    Renderer::instance().unloadTexture(textureId);
    return nullptr;
}

napi_value NativeSetCamera(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value argv[3];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    double x, y, zoom;
    napi_get_value_double(env, argv[0], &x);
    napi_get_value_double(env, argv[1], &y);
    napi_get_value_double(env, argv[2], &zoom);

    Renderer::instance().setCamera((float)x, (float)y, (float)zoom);
    return nullptr;
}

napi_value NativeGetCircleTextureId(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_int32(env, Renderer::instance().circleTextureId(), &result);
    return result;
}

napi_value NativeGetWhiteTextureId(napi_env env, napi_callback_info info) {
    napi_value result;
    napi_create_int32(env, Renderer::instance().whiteTextureId(), &result);
    return result;
}

napi_value NativeTouchInput(napi_env env, napi_callback_info info) {
    size_t argc = 4;
    napi_value argv[4];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

    int32_t touchId, action;
    double x, y;
    napi_get_value_int32(env, argv[0], &touchId);
    napi_get_value_int32(env, argv[1], &action);
    napi_get_value_double(env, argv[2], &x);
    napi_get_value_double(env, argv[3], &y);

    // TODO: 转发到输入处理系统
    return nullptr;
}

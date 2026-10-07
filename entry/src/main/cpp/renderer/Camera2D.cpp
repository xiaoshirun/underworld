// entry/src/main/cpp/renderer/Camera2D.cpp
#include "Camera2D.h"
#include <cstring>

Camera2D::Camera2D() {
    memset(projection_, 0, sizeof(projection_));
    projection_[15] = 1.0f;
}

void Camera2D::setScreenSize(float width, float height) {
    screenW_ = width;
    screenH_ = height;
}

void Camera2D::setPosition(float x, float y) {
    posX_ = x;
    posY_ = y;
}

void Camera2D::setZoom(float zoom) {
    zoom_ = zoom;
}

void Camera2D::ortho(float* out, float left, float right,
                     float bottom, float top, float near, float far) {
    memset(out, 0, 16 * sizeof(float));
    out[0]  =  2.0f / (right - left);
    out[5]  =  2.0f / (top - bottom);
    out[10] = -2.0f / (far - near);
    out[12] = -(right + left) / (right - left);
    out[13] = -(top + bottom) / (top - bottom);
    out[14] = -(far + near) / (far - near);
    out[15] =  1.0f;
}

void Camera2D::update() {
    float halfW = (screenW_ * 0.5f) / zoom_;
    float halfH = (screenH_ * 0.5f) / zoom_;
    float left   = posX_ - halfW;
    float right  = posX_ + halfW;
    float bottom = posY_ - halfH;
    float top    = posY_ + halfH;
    ortho(projection_, left, right, bottom, top, -1.0f, 1.0f);
}

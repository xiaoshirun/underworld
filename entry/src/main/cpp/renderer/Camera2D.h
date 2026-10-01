// entry/src/main/cpp/renderer/Camera2D.h
#pragma once

class Camera2D {
public:
    Camera2D();

    void setScreenSize(float width, float height);
    void setPosition(float x, float y);
    void setZoom(float zoom);

    void update();
    const float* projectionMatrix() const { return projection_; }

private:
    float projection_[16];
    float screenW_ = 1280.0f;
    float screenH_ = 720.0f;
    float posX_ = 0.0f;
    float posY_ = 0.0f;
    float zoom_ = 1.0f;

    static void ortho(float* out, float left, float right,
                      float bottom, float top, float near, float far);
};

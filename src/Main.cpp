#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <imgui.h>
#include <backends/imgui_impl_glfw.h>
#include <backends/imgui_impl_opengl3.h>
#include "Vec3.h"
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <string>
#include <assert.h>

int g_winWidth = 1600;
int g_winHeight = 900;
uint32_t g_avgImage;
int g_imageFrames = 0;

void ResetImageFrames()
{
    g_imageFrames = 0;
}

uint32_t CreateAvgImage(int width, int height)
{
    uint32_t texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, width, height, 0, GL_RGBA, GL_FLOAT, nullptr);

    glBindImageTexture(0, texture, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA32F);

    return texture;
}

void OnResize(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
    g_winWidth = width;
    g_winHeight = height;

    ResetImageFrames();
    glDeleteTextures(1, &g_avgImage);
    g_avgImage = CreateAvgImage(g_winWidth, g_winHeight);
}

uint32_t CreateBuffers()
{
    uint32_t vertexArray;
    glGenVertexArrays(1, &vertexArray);
    glBindVertexArray(vertexArray);

    float vertices[] = {
        -1.0f, -1.0f,
         1.0f, -1.0f,
         1.0f,  1.0f,

         1.0f,  1.0f,
        -1.0f,  1.0f,
        -1.0f, -1.0f,
    };

    uint32_t vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*)0);

    return vertexArray;
}

char* ReadFile(const char* filename)
{
    FILE* file = fopen(filename, "rb");
    if (!file) file = fopen((std::string("../") + filename).c_str(), "rb");
    if (!file) file = fopen((std::string("../../") + filename).c_str(), "rb");
    assert(file != nullptr && "Failed to open file");

    fseek(file, 0, SEEK_END);
    int fileLen = ftell(file);
    fseek(file, 0, SEEK_SET);

    char* buf = (char*)malloc(fileLen + 1);
    fread(buf, 1, fileLen, file);
    fclose(file);

    buf[fileLen] = '\0';

    return buf;
}

uint32_t CreateShaders(const char* vertFile, const char* fragFile)
{
    auto createShader = [](const char* filename, GLenum type) -> uint32_t
    {
        char* source = ReadFile(filename);

        uint32_t shader = glCreateShader(type);
        glShaderSource(shader, 1, &source, 0);
        glCompileShader(shader);

        free(source);

        int success;
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if (!success)
        {
            int logLength;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
            char* log = new char[logLength];
            glGetShaderInfoLog(shader, logLength, 0, log);
            printf("Failed to compile shader %s\n%s\n", filename, log);
            delete[] log;
        }

        return shader;
    };

    static uint32_t vertexShader = createShader(vertFile, GL_VERTEX_SHADER);
    uint32_t fragmentShader = createShader(fragFile, GL_FRAGMENT_SHADER);

    uint32_t program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    glLinkProgram(program);

    int success;
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if (!success)
    {
        int logLength;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
        char* log = new char[logLength];
        glGetProgramInfoLog(program, logLength, 0, log);
        printf("Failed to link shader program\n%s\n", log);
        delete[] log;
    }

    return program;
}

int main()
{
    printf("pozdravljen svet\n");

    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(g_winWidth, g_winHeight, "RayTracingOpenGL", 0, 0);
    glfwMakeContextCurrent(window);
    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    printf("OpenGL Version: %s\n", glGetString(GL_VERSION));

    glViewport(0, 0, g_winWidth, g_winHeight);
    glfwSetFramebufferSizeCallback(window, OnResize);

    glfwSwapInterval(0);
    bool vsync = false;

    uint32_t vertexArray = CreateBuffers();
    g_avgImage = CreateAvgImage(g_winWidth, g_winHeight);

    uint32_t shaderProgram1 = CreateShaders("src/vert.glsl", "src/frag1.glsl");
    uint32_t shaderProgram2 = CreateShaders("src/vert.glsl", "src/frag2.glsl");
    uint32_t shaderProgram3 = CreateShaders("src/vert.glsl", "src/frag3.glsl");

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& imguiIo = ImGui::GetIO();
    imguiIo.ConfigFlags |= ImGuiConfigFlags_DockingEnable;

    ImGui::StyleColorsDark();

    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 430");

    bool imguiWinOpen = true;

    Vec3 camPos = { 0.f, 0.f, 1.f };
    Vec3 prevCamPos = camPos;
    float rotationUp = 0.0f;
    float rotationRight = 0.0f;

    float moveSpeed = 2.0f;
    float rotationSpeed = 1.0f;

    double prevMouseX, prevMouseY;
    glfwGetCursorPos(window, &prevMouseX, &prevMouseY);

    int sceneIndex = 1;
    uint32_t currentShaderProgram = -1;

    float tmin = 0.001f;
    int maxRayDepth = 8;

    while (!glfwWindowShouldClose(window))
    {
        static float fovy = 60.0f;

        float viewportHeight = tan(fovy * 3.14159f / 180.0f / 2.0f) * 2.0f;
        float viewportWidth = viewportHeight * g_winWidth / g_winHeight;

        Vec3 forwardDir = Vec3(0, 0, -1);
        forwardDir = Vec3::RotateX(forwardDir, rotationUp);
        forwardDir = Vec3::RotateY(forwardDir, rotationRight);

        Vec3 rightDir = Vec3::Cross(forwardDir, Vec3(0, 1, 0)).Normalized();
        Vec3 upDir = Vec3::Cross(rightDir, forwardDir);

        Vec3 camRight = viewportWidth * rightDir;
        Vec3 camUp = viewportHeight * upDir;

        Vec3 botLeftRayDir = forwardDir - camRight / 2.f - camUp / 2.f;

        glfwPollEvents();

        if (glfwGetKey(window, GLFW_KEY_W))
            camPos += forwardDir * moveSpeed * imguiIo.DeltaTime;
        if (glfwGetKey(window, GLFW_KEY_S))
            camPos -= forwardDir * moveSpeed * imguiIo.DeltaTime;
        if (glfwGetKey(window, GLFW_KEY_A))
            camPos -= rightDir * moveSpeed * imguiIo.DeltaTime;
        if (glfwGetKey(window, GLFW_KEY_D))
            camPos += rightDir * moveSpeed * imguiIo.DeltaTime;

        if (glfwGetKey(window, GLFW_KEY_E))
            camPos += Vec3(0, 1, 0) * moveSpeed * imguiIo.DeltaTime;
        if (glfwGetKey(window, GLFW_KEY_Q))
            camPos -= Vec3(0, 1, 0) * moveSpeed * imguiIo.DeltaTime;

        if (prevCamPos != camPos)
        {
            prevCamPos = camPos;
            ResetImageFrames();
        }

        if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT))
        {
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

            ResetImageFrames();

            double mouseX, mouseY;
            glfwGetCursorPos(window, &mouseX, &mouseY);
            double deltaMouseX = mouseX - prevMouseX;
            double deltaMouseY = mouseY - prevMouseY;

            rotationRight -= deltaMouseX / 1000.0f * rotationSpeed;
            rotationUp -= deltaMouseY / 1000.0f * rotationSpeed;

            rotationUp = std::max(rotationUp, -3.14159f / 2.001f);
            rotationUp = std::min(rotationUp, 3.14159f / 2.001f);
        }
        else
        {
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
        }

        glfwGetCursorPos(window, &prevMouseX, &prevMouseY);

        if (ImGui::IsKeyPressed(ImGuiKey_G))
            imguiWinOpen = !imguiWinOpen;

        glClear(GL_COLOR_BUFFER_BIT);

        switch (sceneIndex)
        {
        case 1: currentShaderProgram = shaderProgram1; break;
        case 2: currentShaderProgram = shaderProgram2; break;
        case 3: currentShaderProgram = shaderProgram3; break;
        }

        glUseProgram(currentShaderProgram);

        int uWinWidthLoc = glGetUniformLocation(currentShaderProgram, "uWinWidth");
        int uWinHeightLoc = glGetUniformLocation(currentShaderProgram, "uWinHeight");
        int uBotLeftRayDirLoc = glGetUniformLocation(currentShaderProgram, "uBotLeftRayDir");
        int uCamRightLoc = glGetUniformLocation(currentShaderProgram, "uCamRight");
        int uCamUpLoc = glGetUniformLocation(currentShaderProgram, "uCamUp");
        int uRayOriginLoc = glGetUniformLocation(currentShaderProgram, "uRayOrigin");
        int uTMinLoc = glGetUniformLocation(currentShaderProgram, "uTMin");
        int uMaxRayDepthLoc = glGetUniformLocation(currentShaderProgram, "uMaxRayDepth");
        int uImageFramesLoc = glGetUniformLocation(currentShaderProgram, "uImageFrames");

        glUniform1f(uWinWidthLoc, g_winWidth);
        glUniform1f(uWinHeightLoc, g_winHeight);
        glUniform3fv(uBotLeftRayDirLoc, 1, &botLeftRayDir.x);
        glUniform3fv(uCamRightLoc, 1, &camRight.x);
        glUniform3fv(uCamUpLoc, 1, &camUp.x);
        glUniform3fv(uRayOriginLoc, 1, &camPos.x);
        glUniform1f(uTMinLoc, tmin);
        glUniform1i(uMaxRayDepthLoc, maxRayDepth);
        glUniform1i(uImageFramesLoc, g_imageFrames);

        glDrawArrays(GL_TRIANGLES, 0, 6);

        g_imageFrames++;

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();
        ImGui::DockSpaceOverViewport(0, ImGuiDockNodeFlags_PassthruCentralNode);

        if (imguiWinOpen)
        {
            ImGui::Begin("RayTracingOpenGL", &imguiWinOpen);

            ImGui::Text("%.0ffps (%.2fms)", imguiIo.Framerate, 1000.0f / imguiIo.Framerate);
            if (ImGui::InputInt("Scene Index", &sceneIndex)) ResetImageFrames();
            ImGui::DragFloat3("Camera Position", &camPos.x, 0.3f);
            if (ImGui::DragFloat("Vertical FOV", &fovy, 0.3f)) ResetImageFrames();
            if (ImGui::DragFloat("Rotation Right", &rotationRight, 0.2f)) ResetImageFrames();
            if (ImGui::DragFloat("Rotation Up", &rotationUp, 0.1f)) ResetImageFrames();
            ImGui::DragFloat("Move Speed", &moveSpeed, 0.3f);
            ImGui::DragFloat("Rotatation Speed", &rotationSpeed, 0.3f);
            if (ImGui::Checkbox("VSync", &vsync)) glfwSwapInterval(vsync ? 1 : 0);
            ImGui::InputInt("Max Ray Depth", &maxRayDepth);
            if (ImGui::DragFloat("T Min", &tmin)) ResetImageFrames();
            ImGui::Text("Cam Up: %.2f, %.2f, %.2f", camUp.x, camUp.y, camUp.z);
            ImGui::Text("Cam Right: %.2f, %.2f, %.2f", camRight.x, camRight.y, camRight.z);
            ImGui::Text("Forward Dir: %.2f, %.2f, %.2f", forwardDir.x, forwardDir.y, forwardDir.z);
            ImGui::Text("Viewport Width: %.2f", viewportWidth);
            ImGui::Text("Viewport Height: %.2f", viewportHeight);
            ImGui::Text("AvgImage Frames: %d", g_imageFrames);

            ImGui::End();
        }

        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwSwapBuffers(window);
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();
}

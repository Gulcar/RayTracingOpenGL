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

void OnResize(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
    g_winWidth = width;
    g_winHeight = height;
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

    assert(ferror(file) == 0 && "File error");

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

    uint32_t vertexShader = createShader(vertFile, GL_VERTEX_SHADER);
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
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(g_winWidth, g_winHeight, "RayTracingOpenGL", 0, 0);
    glfwMakeContextCurrent(window);
    gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);

    glViewport(0, 0, g_winWidth, g_winHeight);
    glfwSetFramebufferSizeCallback(window, OnResize);

    uint32_t vertexArray = CreateBuffers();
    uint32_t shaderProgram = CreateShaders("src/vert.glsl", "src/frag.glsl");

    glUseProgram(shaderProgram);
    glBindVertexArray(vertexArray);

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& imguiIo = ImGui::GetIO();
    imguiIo.ConfigFlags |= ImGuiConfigFlags_DockingEnable;

    ImGui::StyleColorsDark();

    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");

    bool imguiWinOpen = true;

    Vec3 camPos = { 0.f, 0.f, 1.f };
    float rotationUp = 0.0f;
    float rotationRight = 0.0f;
    float moveSpeed = 2.0f;

    double prevMouseX, prevMouseY;
    glfwGetCursorPos(window, &prevMouseX, &prevMouseY);

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

        if (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT))
        {
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

            double mouseX, mouseY;
            glfwGetCursorPos(window, &mouseX, &mouseY);
            double deltaMouseX = mouseX - prevMouseX;
            double deltaMouseY = mouseY - prevMouseY;

            rotationRight -= deltaMouseX / 1000.0f;
            rotationUp -= deltaMouseY / 1000.0f;

            rotationUp = std::max(rotationUp, -3.14159f / 2.1f);
            rotationUp = std::min(rotationUp, 3.14159f / 2.1f);
        }
        else
        {
            glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
        }

        glfwGetCursorPos(window, &prevMouseX, &prevMouseY);

        if (ImGui::IsKeyPressed(ImGuiKey_G))
            imguiWinOpen = !imguiWinOpen;

        glClear(GL_COLOR_BUFFER_BIT);

        static int uWinWidthLoc = glGetUniformLocation(shaderProgram, "uWinWidth");
        static int uWinHeightLoc = glGetUniformLocation(shaderProgram, "uWinHeight");
        static int uBotLeftRayDirLoc = glGetUniformLocation(shaderProgram, "uBotLeftRayDir");
        static int uCamRightLoc = glGetUniformLocation(shaderProgram, "uCamRight");
        static int uCamUpLoc = glGetUniformLocation(shaderProgram, "uCamUp");
        static int uRayOriginLoc = glGetUniformLocation(shaderProgram, "uRayOrigin");

        glUniform1f(uWinWidthLoc, g_winWidth);
        glUniform1f(uWinHeightLoc, g_winHeight);
        glUniform3fv(uBotLeftRayDirLoc, 1, &botLeftRayDir.x);
        glUniform3fv(uCamRightLoc, 1, &camRight.x);
        glUniform3fv(uCamUpLoc, 1, &camUp.x);
        glUniform3fv(uRayOriginLoc, 1, &camPos.x);

        glDrawArrays(GL_TRIANGLES, 0, 6);

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();
        ImGui::DockSpaceOverViewport(0, ImGuiDockNodeFlags_PassthruCentralNode);

        if (imguiWinOpen)
        {
            ImGui::Begin("RayTracingOpenGL", &imguiWinOpen);

            ImGui::Text("%.0ffps (%.2fms)", imguiIo.Framerate, 1000.0f / imguiIo.Framerate);
            ImGui::Text("Camera Position: %.2f, %.2f, %.2f", camPos.x, camPos.y, camPos.z);
            ImGui::DragFloat("Vertical FOV", &fovy, 0.3f);
            ImGui::DragFloat("Rotation Right", &rotationRight, 0.2f);
            ImGui::DragFloat("Rotation Up", &rotationUp, 0.1f);
            ImGui::Text("Cam Up: %.2f, %.2f, %.2f", camUp.x, camUp.y, camUp.z);
            ImGui::Text("Cam Right: %.2f, %.2f, %.2f", camRight.x, camRight.y, camRight.z);
            ImGui::Text("Forward Dir: %.2f, %.2f, %.2f", forwardDir.x, forwardDir.y, forwardDir.z);
            ImGui::Text("Viewport Width: %.2f", viewportWidth);
            ImGui::Text("Viewport Height: %.2f", viewportHeight);

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

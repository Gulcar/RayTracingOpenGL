#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <cstdio>
#include <cstdlib>
#include <cmath>

int g_winWidth = 1600;
int g_winHeight = 900;

void OnResize(GLFWwindow* window, int width, int height)
{
    glViewport(0, 0, width, height);
    g_winWidth = width;
    g_winHeight = height;
}

struct Vec3
{
    float x, y, z;
};

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
    FILE* file = fopen(filename, "r");
    if (!file) printf("failed to open file %s\n", filename);

    fseek(file, 0, SEEK_END);
    int fileLen = ftell(file);
    fseek(file, 0, SEEK_SET);

    char* buf = (char*)malloc(fileLen);
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
    uint32_t shaderProgram = CreateShaders("../src/vert.glsl", "../src/frag.glsl");

    glUseProgram(shaderProgram);

    Vec3 camPos = { 0.f, 0.f, 0.f };

    while (!glfwWindowShouldClose(window))
    {
        glfwPollEvents();

        if (glfwGetKey(window, GLFW_KEY_ESCAPE))
            glfwSetWindowShouldClose(window, true);
        if (glfwGetKey(window, GLFW_KEY_W))
            camPos.z -= 0.01f;
        if (glfwGetKey(window, GLFW_KEY_S))
            camPos.z += 0.01f;

        glClear(GL_COLOR_BUFFER_BIT);

        static int uWinWidthLoc = glGetUniformLocation(shaderProgram, "uWinWidth");
        static int uWinHeightLoc = glGetUniformLocation(shaderProgram, "uWinHeight");
        static int uBotLeftRayDirLoc = glGetUniformLocation(shaderProgram, "uBotLeftRayDir");
        static int uCamRightLoc = glGetUniformLocation(shaderProgram, "uCamRight");
        static int uCamUpLoc = glGetUniformLocation(shaderProgram, "uCamUp");
        static int uRayOriginLoc = glGetUniformLocation(shaderProgram, "uRayOrigin");

        float fovy = 60.0f;

        float viewportHeight = tan(fovy * 3.14159f / 180.0f / 2.0f) * 2.0f;
        float viewportWidth = viewportHeight * g_winWidth / g_winHeight;

        glUniform1f(uWinWidthLoc, g_winWidth);
        glUniform1f(uWinHeightLoc, g_winHeight);
        glUniform3f(uBotLeftRayDirLoc, -viewportWidth / 2.f, -viewportHeight / 2.f, camPos.z - 1.0f);
        glUniform3f(uCamRightLoc, viewportWidth, 0.f, 0.f);
        glUniform3f(uCamUpLoc, 0.f, viewportHeight, 0.f);
        glUniform3fv(uRayOriginLoc, 1, &camPos.x);

        glDrawArrays(GL_TRIANGLES, 0, 6);

        glfwSwapBuffers(window);
    }

    glfwTerminate();
}

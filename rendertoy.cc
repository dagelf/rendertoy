#include <iostream>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <chrono>

#include <SDL2/SDL.h>
#include <GL/glew.h>

SDL_Window *init(void)
{
        SDL_Init(SDL_INIT_VIDEO);
        SDL_GL_SetSwapInterval(1);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
        return SDL_CreateWindow("Demo", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 720, SDL_WINDOW_OPENGL);
}

int fini(SDL_Window *win)
{
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 0;
}


GLuint quad, shader;
GLint atime, atimeDelta, ares, amouse;
const char *vertexsrc = R"glsl(
        #version 330 core

        in vec2 position;
        out vec2 position_o;

        void main()
        {
            gl_Position = vec4(position, 0.0, 1.0);
            position_o = position;
        }
)glsl";
const char *fragmentprelude = R"glsl(
        #version 330 core

        in vec2 position_o;
        out vec4 outColor;

        uniform float iTime;
        uniform float iTimeDelta;
        uniform vec2 iResolution;
        uniform vec4 iMouse;
)glsl";
const char *fragmentmain = R"glsl(
        void main() {
                mainImage(outColor, (0.5 + 0.5 * position_o) * iResolution.xy);
        }
)glsl";

void prerender(const char *fragmentsrc)
{
        /* Setup VAO; */
        GLuint vao;
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        /* Generate full-screen quad; */
        float tris[] = {
                -1.f, -1.f,
                1.f, -1.f,
                1.f, 1.f,
                -1.f, -1.f,
                -1.f, 1.f,
                1.f, 1.f
        };

        glGenBuffers(1, &quad);
        glBindBuffer(GL_ARRAY_BUFFER, quad);
        glBufferData(GL_ARRAY_BUFFER, sizeof(tris), tris, GL_STATIC_DRAW);

        /* Compile shaders; */
        char buf[4096];
        GLint status;

        GLuint vertex = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vertex, 1, &vertexsrc, NULL);
        glCompileShader(vertex);
        glGetShaderiv(vertex, GL_COMPILE_STATUS, &status);
        if (status == GL_FALSE) {
                glGetShaderInfoLog(vertex, sizeof(buf), NULL, buf);
                std::cerr << "Vertex compilation error:" << std::endl << buf << std::endl;
                std::exit(2);
        }
        GLuint fragment = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fragment, 1, &fragmentsrc, NULL);
        glCompileShader(fragment);
        glGetShaderiv(fragment, GL_COMPILE_STATUS, &status);
        if (status == GL_FALSE) {
                glGetShaderInfoLog(fragment, sizeof(buf), NULL, buf);
                std::cerr << "Fragment compilation error:" << std::endl << buf << std::endl;
                std::exit(3);
        }

        /* Link shaders; */
        GLuint shader = glCreateProgram();
        glAttachShader(shader, vertex);
        glAttachShader(shader, fragment);
        glLinkProgram(shader);
        glUseProgram(shader);
        
        /* Hook up inputs; */
        GLint pos = glGetAttribLocation(shader, "position");
        glVertexAttribPointer(pos, 2, GL_FLOAT, GL_FALSE, 0, 0);
        glEnableVertexAttribArray(pos);
        pos = glGetAttribLocation(shader, "position_o");
        glVertexAttribPointer(pos, 2, GL_FLOAT, GL_FALSE, 0, 0);
        glEnableVertexAttribArray(pos);
        
        atime = glGetUniformLocation(shader, "iTime");
        atimeDelta = glGetUniformLocation(shader, "iTimeDelta");
        ares = glGetUniformLocation(shader, "iResolution");
        amouse = glGetUniformLocation(shader, "iMouse");
}

void render(float timeTime, float timeDiff, const float *mouse)
{
        glUniform1f(atime, timeTime);
        glUniform1f(atimeDelta, timeDiff);
        glUniform2f(ares, 1280, 720);
        glUniform4fv(amouse, 1, mouse);
        glDrawArrays(GL_TRIANGLES, 0, 3);
        glDrawArrays(GL_TRIANGLES, 3, 3);
}



int main(int argc, char **argv)
{
        if (argc < 2) {
                std::cerr << "usage: " << argv[0] << " SHADER.glsl" << std::endl;
                return 1;
        }

        /* Set up window */
        SDL_Window *win = init();
        SDL_GLContext gl = SDL_GL_CreateContext(win);
        glewExperimental = GL_TRUE;
        glewInit();

        /* Read shader */
        std::fstream f(argv[1], std::fstream::in);
        std::stringstream ss;
        ss << fragmentprelude;
        ss << f.rdbuf();
        ss << fragmentmain;
        f.close();

        /* Set up GL */
        std::string fragment = ss.str();
        prerender(fragment.c_str());

        /* Main loop */
        bool running = true;
        float mouse[4];
        auto prev = std::chrono::high_resolution_clock::now();
        while (running) {
                SDL_Event event;
                while (SDL_PollEvent(&event)) switch (event.type) {
                case SDL_MOUSEBUTTONDOWN:
                        if (event.button.button == SDL_BUTTON_LEFT) {
                                mouse[2] = mouse[0];
                                mouse[3] = mouse[1];
                        }
                        break;
                case SDL_MOUSEBUTTONUP:
                        if (event.button.button == SDL_BUTTON_LEFT) {
                                mouse[2] = mouse[3] = 0.f;
                        }
                        break;
                case SDL_MOUSEMOTION:
                        mouse[0] = event.motion.x;
                        mouse[1] = event.motion.y;
                        break;
                case SDL_QUIT:
                        running = false;
                        break;
                }
                
                auto now = std::chrono::high_resolution_clock::now();
                float diff = std::chrono::duration_cast<std::chrono::duration<float>>(now - prev).count();
                float nowTime = std::chrono::duration_cast<std::chrono::duration<float>>(now.time_since_epoch()).count();
                prev = now;

                render(nowTime, diff, mouse);
                SDL_GL_SwapWindow(win);
        }

        SDL_GL_DeleteContext(gl);
        return fini(win);
}

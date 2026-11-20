// SPDX-License-Identifier: GPL-3.0-or-later
// OpenRAC on the Nintendo Switch 2 (OunceDevKit, libounce): the part of SDL3's API the port uses, on Horizon.
//
// SDL3 has no Horizon backend. The port's platform layer (platform/*.cpp) and its window code (game/common/frontend/*) call about a
// hundred SDL3 functions; this file provides them, with SDL3's own headers for every type (so a struct or enum cannot drift):
//   window + OpenGL     one fullscreen window on the console's NWindow; the GL context is EGL's (OunceVK + Zink: OpenGL 4.x on Vulkan)
//   events              a queue; the pad (libnx HID) and the applet (home button, dock changes) feed it from SDL_PumpEvents
//   gamepad             player 1 (any controller or handheld) as one SDL gamepad
//   audio streams       libnx audout, 48 kHz stereo 16-bit, pulled from the stream's callback or filled by SDL_PutAudioStreamData
//   everything else     keyboard, mouse, touch, haptics, Vulkan, clipboard, dynamic loading: present and inert
// Nothing here reads or writes any storage.
#include <SDL3/SDL.h>
#include <SDL3/SDL_vulkan.h>

#include <atomic>
#include <chrono>
#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <mutex>
#include <thread>
#include <vector>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <switch.h>

#include "trace.h"

namespace {

// ---- state ----------------------------------------------------------------------------------------------------------------------
std::mutex g_mutex;
char g_error[256] = "";
std::chrono::steady_clock::time_point g_start = std::chrono::steady_clock::now();
SDL_InitFlags g_init = 0;

struct EventWatch {
    SDL_EventFilter filter;
    void* user;
};
std::deque<SDL_Event> g_events;
std::vector<EventWatch> g_watches;

}  // namespace

struct SDL_Window {
    SDL_WindowID id = 1;
    int w = 1280, h = 720;
    SDL_WindowFlags flags = SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN | SDL_WINDOW_INPUT_FOCUS;
    EGLSurface surface = EGL_NO_SURFACE;
    bool relative_mouse = false;
};

struct SDL_GLContextState {
    EGLContext context = EGL_NO_CONTEXT;
    EGLConfig config = nullptr;
};

struct SDL_Gamepad {
    SDL_JoystickID id = 1;
};

struct SDL_AudioStream {
    SDL_AudioSpec spec{};
    SDL_AudioStreamCallback callback = nullptr;
    void* user = nullptr;
    std::mutex lock;
    std::deque<std::uint8_t> bytes;
    std::atomic<bool> paused{true};
    std::atomic<float> gain{1.0f};
};

namespace {

SDL_Window* g_window = nullptr;
SDL_Gamepad g_gamepad;
bool g_gamepad_open = false;

EGLDisplay g_display = EGL_NO_DISPLAY;
int g_gl_attr[SDL_GL_EGL_PLATFORM + 1] = {};

PadState g_pad;
bool g_pad_ready = false;
u64 g_buttons_prev = 0;
HidAnalogStickState g_stick_prev[2] = {};
bool g_quit_sent = false;
AppletOperationMode g_mode_prev = AppletOperationMode_Handheld;

std::atomic<SDL_AudioStream*> g_audio_stream{nullptr};
std::thread g_audio_thread;
std::atomic<bool> g_audio_run{false};

int set_error(const char* what) {
    std::snprintf(g_error, sizeof(g_error), "%s", what);
    return 0;
}

// The window's size: 1920x1080 docked, 1280x720 in hand. The EGL surface follows nwindow.
void window_size_for_mode(int* w, int* h) {
    const bool docked = appletGetOperationMode() == AppletOperationMode_Console;
    *w = docked ? 1920 : 1280;
    *h = docked ? 1080 : 720;
}

void queue_event(const SDL_Event& e) {
    std::vector<EventWatch> watches;
    {
        std::lock_guard<std::mutex> lock(g_mutex);
        g_events.push_back(e);
        watches = g_watches;
    }
    for (const EventWatch& w : watches) {
        SDL_Event copy = e;
        w.filter(w.user, &copy);
    }
}

void ensure_pad() {
    if (g_pad_ready) {
        return;
    }
    padConfigureInput(1, HidNpadStyleSet_NpadStandard);
    padInitializeDefault(&g_pad);
    g_pad_ready = true;
}

// The gamepad's buttons as SDL names them (position-based: the bottom face button is SOUTH, which is Nintendo's B).
struct ButtonMap {
    SDL_GamepadButton sdl;
    u64 hid;
};
constexpr ButtonMap kButtons[] = {
    {SDL_GAMEPAD_BUTTON_SOUTH, HidNpadButton_B},
    {SDL_GAMEPAD_BUTTON_EAST, HidNpadButton_A},
    {SDL_GAMEPAD_BUTTON_WEST, HidNpadButton_Y},
    {SDL_GAMEPAD_BUTTON_NORTH, HidNpadButton_X},
    {SDL_GAMEPAD_BUTTON_BACK, HidNpadButton_Minus},
    {SDL_GAMEPAD_BUTTON_START, HidNpadButton_Plus},
    {SDL_GAMEPAD_BUTTON_LEFT_STICK, HidNpadButton_StickL},
    {SDL_GAMEPAD_BUTTON_RIGHT_STICK, HidNpadButton_StickR},
    {SDL_GAMEPAD_BUTTON_LEFT_SHOULDER, HidNpadButton_L},
    {SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER, HidNpadButton_R},
    {SDL_GAMEPAD_BUTTON_DPAD_UP, HidNpadButton_Up},
    {SDL_GAMEPAD_BUTTON_DPAD_DOWN, HidNpadButton_Down},
    {SDL_GAMEPAD_BUTTON_DPAD_LEFT, HidNpadButton_Left},
    {SDL_GAMEPAD_BUTTON_DPAD_RIGHT, HidNpadButton_Right},
};

Sint16 stick_axis(int stick, bool y) {
    const HidAnalogStickState s = padGetStickPos(&g_pad, stick);
    const int v = y ? -s.y : s.x;  // SDL: +y is down
    return static_cast<Sint16>(v > 32767 ? 32767 : (v < -32768 ? -32768 : v));
}

Sint16 trigger_axis(u64 hid) {
    return (padGetButtons(&g_pad) & hid) ? 32767 : 0;
}

void pump_pad() {
    ensure_pad();
    padUpdate(&g_pad);
    const u64 now = padGetButtons(&g_pad);
    const u64 changed = now ^ g_buttons_prev;
    if (g_gamepad_open && changed) {
        for (const ButtonMap& b : kButtons) {
            if (changed & b.hid) {
                SDL_Event e{};
                e.type = (now & b.hid) ? SDL_EVENT_GAMEPAD_BUTTON_DOWN : SDL_EVENT_GAMEPAD_BUTTON_UP;
                e.gbutton.which = g_gamepad.id;
                e.gbutton.button = static_cast<Uint8>(b.sdl);
                e.gbutton.down = (now & b.hid) != 0;
                queue_event(e);
            }
        }
    }
    g_buttons_prev = now;
}

void pump_applet() {
    if (!appletMainLoop() && !g_quit_sent) {
        g_quit_sent = true;
        SDL_Event e{};
        e.type = SDL_EVENT_QUIT;
        queue_event(e);
    }
    const AppletOperationMode mode = appletGetOperationMode();
    if (g_window != nullptr && mode != g_mode_prev) {
        g_mode_prev = mode;
        int w, h;
        window_size_for_mode(&w, &h);
        nwindowSetDimensions(nwindowGetDefault(), w, h);
        g_window->w = w;
        g_window->h = h;
        SDL_Event e{};
        e.type = SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED;
        e.window.windowID = g_window->id;
        e.window.data1 = w;
        e.window.data2 = h;
        queue_event(e);
        e.type = SDL_EVENT_WINDOW_RESIZED;
        queue_event(e);
    }
}

// ---- audio ------------------------------------------------------------------------------------------------------------------------
constexpr std::size_t kFrames = 1024;  // one page of 16-bit stereo: audout rejects other sizes
constexpr std::size_t kBytes = kFrames * 4;
constexpr int kBuffers = 4;

void audio_main() {
    AudioOutBuffer descriptors[kBuffers];
    std::vector<std::uint8_t> store(kBytes * kBuffers + 0x1000);
    std::uint8_t* base = reinterpret_cast<std::uint8_t*>((reinterpret_cast<std::uintptr_t>(store.data()) + 0xfff) & ~std::uintptr_t(0xfff));
    for (int i = 0; i < kBuffers; i++) {
        std::memset(&descriptors[i], 0, sizeof(descriptors[i]));
        descriptors[i].buffer = base + i * kBytes;
        descriptors[i].buffer_size = kBytes;
        descriptors[i].data_size = kBytes;
        std::memset(descriptors[i].buffer, 0, kBytes);
        audoutAppendAudioOutBuffer(&descriptors[i]);
    }
    while (g_audio_run.load()) {
        AudioOutBuffer* released = nullptr;
        u32 count = 0;
        if (R_FAILED(audoutWaitPlayFinish(&released, &count, 1000000000ull)) || count == 0 || released == nullptr) {
            continue;
        }
        auto* out = static_cast<std::uint8_t*>(released->buffer);
        std::memset(out, 0, kBytes);
        SDL_AudioStream* s = g_audio_stream.load();
        if (s != nullptr && !s->paused.load()) {
            std::size_t queued;
            {
                std::lock_guard<std::mutex> lock(s->lock);
                queued = s->bytes.size();
            }
            if (queued < kBytes && s->callback != nullptr) {
                s->callback(s->user, s, static_cast<int>(kBytes - queued), static_cast<int>(kBytes));
            }
            const float gain = s->gain.load();
            std::lock_guard<std::mutex> lock(s->lock);
            const std::size_t n = s->bytes.size() < kBytes ? s->bytes.size() : kBytes;
            for (std::size_t i = 0; i < n; i++) {
                out[i] = s->bytes[i];
            }
            s->bytes.erase(s->bytes.begin(), s->bytes.begin() + static_cast<std::ptrdiff_t>(n));
            if (gain != 1.0f) {
                auto* samples = reinterpret_cast<std::int16_t*>(out);
                for (std::size_t i = 0; i < kBytes / 2; i++) {
                    samples[i] = static_cast<std::int16_t>(samples[i] * gain);
                }
            }
        }
        released->data_size = kBytes;
        audoutAppendAudioOutBuffer(released);
    }
}

void audio_start() {
    if (g_audio_run.exchange(true)) {
        return;
    }
    if (R_FAILED(audoutInitialize()) || R_FAILED(audoutStartAudioOut())) {
        g_audio_run = false;
        return;
    }
    g_audio_thread = std::thread(audio_main);
}

}  // namespace

// ---- SDL3 API ---------------------------------------------------------------------------------------------------------------------
extern "C" {

// -- init, errors, hints, time ----------------------------------------------------------------------------------------------------
bool SDL_Init(SDL_InitFlags flags) {
    return SDL_InitSubSystem(flags);
}
bool SDL_InitSubSystem(SDL_InitFlags flags) {
    openrac_switch2_perf_start();
    g_init |= flags;
    if (flags & (SDL_INIT_GAMEPAD | SDL_INIT_JOYSTICK | SDL_INIT_EVENTS | SDL_INIT_VIDEO)) {
        ensure_pad();
    }
    if ((flags & SDL_INIT_GAMEPAD) && !g_gamepad_open) {
        SDL_Event e{};
        e.type = SDL_EVENT_GAMEPAD_ADDED;
        e.gdevice.which = g_gamepad.id;
        queue_event(e);
    }
    return true;
}
void SDL_QuitSubSystem(SDL_InitFlags flags) {
    g_init &= ~flags;
}
SDL_InitFlags SDL_WasInit(SDL_InitFlags flags) {
    return flags ? (g_init & flags) : g_init;
}
void SDL_Quit(void) {
    g_audio_run = false;
    if (g_audio_thread.joinable()) {
        g_audio_thread.join();
        audoutStopAudioOut();
        audoutExit();
    }
    g_init = 0;
}
const char* SDL_GetError(void) {
    return g_error;
}
bool SDL_SetError(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    std::vsnprintf(g_error, sizeof(g_error), fmt, ap);
    va_end(ap);
    return false;
}
bool SDL_ClearError(void) {
    g_error[0] = '\0';
    return true;
}
bool SDL_SetHint(const char*, const char*) {
    return true;
}
bool SDL_SetAppMetadata(const char*, const char*, const char*) {
    return true;
}
const char* SDL_GetBasePath(void) {
    return "sdmc:/switch/openrac/";
}
void SDL_free(void* p) {
    std::free(p);
}
Uint64 SDL_GetTicks(void) {
    return static_cast<Uint64>(std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - g_start).count());
}
Uint64 SDL_GetTicksNS(void) {
    return static_cast<Uint64>(std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now() - g_start).count());
}
void SDL_Delay(Uint32 ms) {
    std::this_thread::sleep_for(std::chrono::milliseconds(ms));
}
void SDL_DelayPrecise(Uint64 ns) {
    std::this_thread::sleep_for(std::chrono::nanoseconds(ns));
}
bool SDL_SetCurrentThreadPriority(SDL_ThreadPriority) {
    return true;
}
bool SDL_ShowSimpleMessageBox(SDL_MessageBoxFlags, const char* title, const char* message, SDL_Window*) {
    std::fprintf(stderr, "%s: %s\n", title ? title : "", message ? message : "");
    return true;
}
bool SDL_OpenURL(const char*) {
    return false;
}
bool SDL_SetClipboardText(const char*) {
    return true;
}
SDL_SharedObject* SDL_LoadObject(const char*) {
    set_error("dynamic loading is not available on this platform");
    return nullptr;
}
SDL_FunctionPointer SDL_LoadFunction(SDL_SharedObject*, const char*) {
    return nullptr;
}
void SDL_UnloadObject(SDL_SharedObject*) {}

// -- properties -------------------------------------------------------------------------------------------------------------------
SDL_PropertiesID SDL_GetWindowProperties(SDL_Window*) {
    return 0;
}
void* SDL_GetPointerProperty(SDL_PropertiesID, const char*, void* def) {
    return def;
}
float SDL_GetFloatProperty(SDL_PropertiesID, const char*, float def) {
    return def;
}
bool SDL_GetBooleanProperty(SDL_PropertiesID, const char*, bool def) {
    return def;
}

// -- events -----------------------------------------------------------------------------------------------------------------------
void SDL_PumpEvents(void) {
    pump_applet();
    pump_pad();
}
bool SDL_PollEvent(SDL_Event* event) {
    SDL_PumpEvents();
    std::lock_guard<std::mutex> lock(g_mutex);
    if (g_events.empty()) {
        return false;
    }
    if (event != nullptr) {
        *event = g_events.front();
    }
    g_events.pop_front();
    return true;
}
bool SDL_WaitEventTimeout(SDL_Event* event, Sint32 timeoutMS) {
    const Uint64 end = SDL_GetTicks() + (timeoutMS < 0 ? 0 : static_cast<Uint64>(timeoutMS));
    for (;;) {
        if (SDL_PollEvent(event)) {
            return true;
        }
        if (timeoutMS >= 0 && SDL_GetTicks() >= end) {
            return false;
        }
        SDL_Delay(1);
    }
}
bool SDL_PushEvent(SDL_Event* event) {
    queue_event(*event);
    return true;
}
int SDL_PeepEvents(SDL_Event* events, int numevents, SDL_EventAction action, Uint32 minType, Uint32 maxType) {
    SDL_PumpEvents();
    std::lock_guard<std::mutex> lock(g_mutex);
    int n = 0;
    for (auto it = g_events.begin(); it != g_events.end() && (action != SDL_GETEVENT || n < numevents);) {
        if (it->type >= minType && it->type <= maxType) {
            if (action == SDL_GETEVENT || action == SDL_PEEKEVENT) {
                if (events != nullptr && n < numevents) {
                    events[n] = *it;
                }
            }
            n++;
            if (action == SDL_GETEVENT) {
                it = g_events.erase(it);
                continue;
            }
        }
        ++it;
    }
    return n;
}
bool SDL_AddEventWatch(SDL_EventFilter filter, void* userdata) {
    std::lock_guard<std::mutex> lock(g_mutex);
    g_watches.push_back({filter, userdata});
    return true;
}
void SDL_RemoveEventWatch(SDL_EventFilter filter, void* userdata) {
    std::lock_guard<std::mutex> lock(g_mutex);
    for (auto it = g_watches.begin(); it != g_watches.end(); ++it) {
        if (it->filter == filter && it->user == userdata) {
            g_watches.erase(it);
            return;
        }
    }
}

// -- keyboard, mouse (none) --------------------------------------------------------------------------------------------------------
SDL_Window* SDL_GetKeyboardFocus(void) {
    return g_window;
}
SDL_Window* SDL_GetMouseFocus(void) {
    return nullptr;
}
const bool* SDL_GetKeyboardState(int* numkeys) {
    static bool keys[SDL_SCANCODE_COUNT] = {};
    if (numkeys != nullptr) {
        *numkeys = SDL_SCANCODE_COUNT;
    }
    return keys;
}
SDL_Keymod SDL_GetModState(void) {
    return SDL_KMOD_NONE;
}
SDL_MouseButtonFlags SDL_GetMouseState(float* x, float* y) {
    if (x) *x = 0;
    if (y) *y = 0;
    return 0;
}
const char* SDL_GetScancodeName(SDL_Scancode) {
    return "";
}
SDL_Scancode SDL_GetScancodeFromName(const char*) {
    return SDL_SCANCODE_UNKNOWN;
}
const char* SDL_GetKeyName(SDL_Keycode) {
    return "";
}
SDL_Keycode SDL_GetKeyFromName(const char*) {
    return SDLK_UNKNOWN;
}
SDL_Keycode SDL_GetKeyFromScancode(SDL_Scancode, SDL_Keymod, bool) {
    return SDLK_UNKNOWN;
}
SDL_Scancode SDL_GetScancodeFromKey(SDL_Keycode, SDL_Keymod*) {
    return SDL_SCANCODE_UNKNOWN;
}
bool SDL_ShowCursor(void) {
    return true;
}
bool SDL_HideCursor(void) {
    return true;
}
bool SDL_CursorVisible(void) {
    return false;
}
bool SDL_SetWindowRelativeMouseMode(SDL_Window* w, bool enabled) {
    if (w) w->relative_mouse = enabled;
    return true;
}
bool SDL_GetWindowRelativeMouseMode(SDL_Window* w) {
    return w != nullptr && w->relative_mouse;
}

// -- display and window -----------------------------------------------------------------------------------------------------------
SDL_DisplayID* SDL_GetDisplays(int* count) {
    auto* ids = static_cast<SDL_DisplayID*>(std::malloc(2 * sizeof(SDL_DisplayID)));
    ids[0] = 1;
    ids[1] = 0;
    if (count) *count = 1;
    return ids;
}
const char* SDL_GetDisplayName(SDL_DisplayID) {
    return "Nintendo Switch 2";
}
static SDL_DisplayMode g_mode_cache;
const SDL_DisplayMode* SDL_GetCurrentDisplayMode(SDL_DisplayID) {
    int w, h;
    window_size_for_mode(&w, &h);
    std::memset(&g_mode_cache, 0, sizeof(g_mode_cache));
    g_mode_cache.displayID = 1;
    g_mode_cache.format = SDL_PIXELFORMAT_RGBA32;
    g_mode_cache.w = w;
    g_mode_cache.h = h;
    g_mode_cache.pixel_density = 1.0f;
    g_mode_cache.refresh_rate = 60.0f;
    g_mode_cache.refresh_rate_numerator = 60;
    g_mode_cache.refresh_rate_denominator = 1;
    return &g_mode_cache;
}
const SDL_DisplayMode* SDL_GetDesktopDisplayMode(SDL_DisplayID id) {
    return SDL_GetCurrentDisplayMode(id);
}
SDL_DisplayID SDL_GetDisplayForWindow(SDL_Window*) {
    return 1;
}
const char* SDL_GetCurrentVideoDriver(void) {
    return "switch2";
}

SDL_Window* SDL_CreateWindow(const char*, int, int, SDL_WindowFlags) {
    if (g_window != nullptr) {
        set_error("the Switch 2 has one window");
        return nullptr;
    }
    openrac_switch2_trace("sdl: window created");
    g_window = new SDL_Window();
    window_size_for_mode(&g_window->w, &g_window->h);
    g_mode_prev = appletGetOperationMode();
    nwindowSetDimensions(nwindowGetDefault(), g_window->w, g_window->h);
    SDL_Event e{};
    e.type = SDL_EVENT_WINDOW_FOCUS_GAINED;
    e.window.windowID = g_window->id;
    queue_event(e);
    return g_window;
}
void SDL_DestroyWindow(SDL_Window* w) {
    if (w == nullptr) {
        return;
    }
    if (w->surface != EGL_NO_SURFACE && g_display != EGL_NO_DISPLAY) {
        eglDestroySurface(g_display, w->surface);
    }
    if (g_window == w) {
        g_window = nullptr;
    }
    delete w;
}
bool SDL_GetWindowSize(SDL_Window* w, int* pw, int* ph) {
    if (pw) *pw = w ? w->w : 0;
    if (ph) *ph = w ? w->h : 0;
    return true;
}
bool SDL_GetWindowSizeInPixels(SDL_Window* w, int* pw, int* ph) {
    return SDL_GetWindowSize(w, pw, ph);
}
bool SDL_SetWindowSize(SDL_Window*, int, int) {
    return true;
}
bool SDL_SetWindowPosition(SDL_Window*, int, int) {
    return true;
}
bool SDL_SetWindowFullscreen(SDL_Window*, bool) {
    return true;
}
bool SDL_SetWindowFullscreenMode(SDL_Window*, const SDL_DisplayMode*) {
    return true;
}
bool SDL_SyncWindow(SDL_Window*) {
    return true;
}
bool SDL_SetWindowIcon(SDL_Window*, SDL_Surface*) {
    return true;
}
SDL_WindowFlags SDL_GetWindowFlags(SDL_Window* w) {
    return w ? w->flags : 0;
}
SDL_WindowID SDL_GetWindowID(SDL_Window* w) {
    return w ? w->id : 0;
}
SDL_Window* SDL_GetWindowFromID(SDL_WindowID id) {
    return (g_window && g_window->id == id) ? g_window : nullptr;
}
float SDL_GetWindowPixelDensity(SDL_Window*) {
    return 1.0f;
}
float SDL_GetWindowDisplayScale(SDL_Window*) {
    return 1.0f;
}
bool SDL_GetWindowSafeArea(SDL_Window* w, SDL_Rect* rect) {
    if (rect != nullptr) {
        rect->x = 0;
        rect->y = 0;
        rect->w = w ? w->w : 0;
        rect->h = w ? w->h : 0;
    }
    return true;
}
SDL_Surface* SDL_CreateSurface(int, int, SDL_PixelFormat) {
    return nullptr;
}
SDL_Surface* SDL_CreateSurfaceFrom(int, int, SDL_PixelFormat, void*, int) {
    return nullptr;
}
void SDL_DestroySurface(SDL_Surface*) {}

// -- OpenGL through EGL -----------------------------------------------------------------------------------------------------------
void SDL_GL_ResetAttributes(void) {
    std::memset(g_gl_attr, 0, sizeof(g_gl_attr));
}
bool SDL_GL_SetAttribute(SDL_GLAttr attr, int value) {
    if (attr >= 0 && attr <= SDL_GL_EGL_PLATFORM) {
        g_gl_attr[attr] = value;
    }
    return true;
}
bool SDL_GL_GetAttribute(SDL_GLAttr attr, int* value) {
    if (value) *value = (attr >= 0 && attr <= SDL_GL_EGL_PLATFORM) ? g_gl_attr[attr] : 0;
    return true;
}
SDL_GLContext SDL_GL_CreateContext(SDL_Window* window) {
    if (window == nullptr) {
        set_error("no window");
        return nullptr;
    }
    if (g_display == EGL_NO_DISPLAY) {
        g_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        EGLint maj, min;
        if (g_display == EGL_NO_DISPLAY || !eglInitialize(g_display, &maj, &min)) {
            set_error("eglInitialize failed");
            return nullptr;
        }
    }
    const bool es = g_gl_attr[SDL_GL_CONTEXT_PROFILE_MASK] == SDL_GL_CONTEXT_PROFILE_ES;
    eglBindAPI(es ? EGL_OPENGL_ES_API : EGL_OPENGL_API);
    const int depth = g_gl_attr[SDL_GL_DEPTH_SIZE] > 0 ? g_gl_attr[SDL_GL_DEPTH_SIZE] : 24;
    const int stencil = g_gl_attr[SDL_GL_STENCIL_SIZE];
    EGLint cfg_attr[] = {EGL_SURFACE_TYPE, EGL_WINDOW_BIT, EGL_RENDERABLE_TYPE, es ? EGL_OPENGL_ES3_BIT : EGL_OPENGL_BIT, EGL_RED_SIZE, 8,
                         EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_DEPTH_SIZE, depth, EGL_STENCIL_SIZE, stencil, EGL_NONE};
    EGLConfig config = nullptr;
    EGLint n = 0;
    if (!eglChooseConfig(g_display, cfg_attr, &config, 1, &n) || n < 1) {
        set_error("eglChooseConfig found no configuration");
        return nullptr;
    }
    if (window->surface == EGL_NO_SURFACE) {
        window->surface = eglCreateWindowSurface(g_display, config, nwindowGetDefault(), nullptr);
        if (window->surface == EGL_NO_SURFACE) {
            set_error("eglCreateWindowSurface failed");
            return nullptr;
        }
    }
    const int major = g_gl_attr[SDL_GL_CONTEXT_MAJOR_VERSION] ? g_gl_attr[SDL_GL_CONTEXT_MAJOR_VERSION] : 4;
    const int minor = g_gl_attr[SDL_GL_CONTEXT_MINOR_VERSION];
    EGLint ctx_attr[] = {EGL_CONTEXT_MAJOR_VERSION, major, EGL_CONTEXT_MINOR_VERSION, minor, EGL_CONTEXT_OPENGL_PROFILE_MASK,
                         EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT, EGL_NONE};
    EGLint es_attr[] = {EGL_CONTEXT_MAJOR_VERSION, major, EGL_CONTEXT_MINOR_VERSION, minor, EGL_NONE};
    EGLContext ctx = eglCreateContext(g_display, config, EGL_NO_CONTEXT, es ? es_attr : ctx_attr);
    if (ctx == EGL_NO_CONTEXT) {
        set_error("eglCreateContext failed");
        return nullptr;
    }
    openrac_switch2_trace("sdl: GL context created (EGL %p)", static_cast<void*>(ctx));
    auto* state = new SDL_GLContextState();
    state->context = ctx;
    state->config = config;
    eglMakeCurrent(g_display, window->surface, window->surface, ctx);
    return state;
}
bool SDL_GL_MakeCurrent(SDL_Window* window, SDL_GLContext context) {
    if (context == nullptr || window == nullptr) {
        return eglMakeCurrent(g_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    }
    return eglMakeCurrent(g_display, window->surface, window->surface, context->context);
}
SDL_GLContext SDL_GL_GetCurrentContext(void) {
    return nullptr;
}
bool SDL_GL_DestroyContext(SDL_GLContext context) {
    if (context != nullptr) {
        eglMakeCurrent(g_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        eglDestroyContext(g_display, context->context);
        delete context;
    }
    return true;
}
bool SDL_GL_SwapWindow(SDL_Window* window) {
    static int swaps;
    if (swaps < 3 || swaps == 60 || swaps == 600) {
        openrac_switch2_trace("sdl: swap %d", swaps);
    }
    swaps++;
    return window != nullptr && eglSwapBuffers(g_display, window->surface);
}
bool SDL_GL_SetSwapInterval(int interval) {
    return g_display == EGL_NO_DISPLAY || eglSwapInterval(g_display, interval);
}
SDL_FunctionPointer SDL_GL_GetProcAddress(const char* proc) {
    return reinterpret_cast<SDL_FunctionPointer>(eglGetProcAddress(proc));
}

// -- Vulkan (not used: the renderer is OpenGL here) -------------------------------------------------------------------------------
bool SDL_Vulkan_LoadLibrary(const char*) {
    return false;
}
void SDL_Vulkan_UnloadLibrary(void) {}
SDL_FunctionPointer SDL_Vulkan_GetVkGetInstanceProcAddr(void) {
    return nullptr;
}
char const* const* SDL_Vulkan_GetInstanceExtensions(Uint32* count) {
    if (count) *count = 0;
    return nullptr;
}

// -- gamepad ----------------------------------------------------------------------------------------------------------------------
SDL_JoystickID* SDL_GetGamepads(int* count) {
    auto* ids = static_cast<SDL_JoystickID*>(std::malloc(2 * sizeof(SDL_JoystickID)));
    ids[0] = g_gamepad.id;
    ids[1] = 0;
    if (count) *count = 1;
    return ids;
}
SDL_Gamepad* SDL_OpenGamepad(SDL_JoystickID id) {
    if (id != g_gamepad.id) {
        return nullptr;
    }
    g_gamepad_open = true;
    return &g_gamepad;
}
void SDL_CloseGamepad(SDL_Gamepad*) {
    g_gamepad_open = false;
}
SDL_Gamepad* SDL_GetGamepadFromID(SDL_JoystickID id) {
    return (g_gamepad_open && id == g_gamepad.id) ? &g_gamepad : nullptr;
}
SDL_JoystickID SDL_GetGamepadID(SDL_Gamepad*) {
    return g_gamepad.id;
}
const char* SDL_GetGamepadName(SDL_Gamepad*) {
    return "Nintendo Switch 2 Controller";
}
const char* SDL_GetGamepadSerial(SDL_Gamepad*) {
    return "switch2-pad-1";
}
SDL_GamepadType SDL_GetGamepadType(SDL_Gamepad*) {
    return SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_PRO;
}
SDL_GamepadType SDL_GetGamepadTypeForID(SDL_JoystickID) {
    return SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_PRO;
}
SDL_GUID SDL_GetGamepadGUIDForID(SDL_JoystickID) {
    SDL_GUID g{};
    std::memcpy(g.data, "switch2-pad-0001", 16);
    return g;
}
void SDL_GUIDToString(SDL_GUID guid, char* out, int size) {
    static const char hex[] = "0123456789abcdef";
    for (int i = 0; i < 16 && 2 * i + 2 < size; i++) {
        out[2 * i] = hex[guid.data[i] >> 4];
        out[2 * i + 1] = hex[guid.data[i] & 15];
        out[2 * i + 2] = '\0';
    }
}
void SDL_UpdateGamepads(void) {
    pump_pad();
}
bool SDL_GetGamepadButton(SDL_Gamepad*, SDL_GamepadButton button) {
    const u64 now = g_buttons_prev;
    for (const ButtonMap& b : kButtons) {
        if (b.sdl == button) {
            return (now & b.hid) != 0;
        }
    }
    return false;
}
Sint16 SDL_GetGamepadAxis(SDL_Gamepad*, SDL_GamepadAxis axis) {
    if (!g_pad_ready) {
        return 0;
    }
    switch (axis) {
    case SDL_GAMEPAD_AXIS_LEFTX: return stick_axis(0, false);
    case SDL_GAMEPAD_AXIS_LEFTY: return stick_axis(0, true);
    case SDL_GAMEPAD_AXIS_RIGHTX: return stick_axis(1, false);
    case SDL_GAMEPAD_AXIS_RIGHTY: return stick_axis(1, true);
    case SDL_GAMEPAD_AXIS_LEFT_TRIGGER: return trigger_axis(HidNpadButton_ZL);
    case SDL_GAMEPAD_AXIS_RIGHT_TRIGGER: return trigger_axis(HidNpadButton_ZR);
    default: return 0;
    }
}
bool SDL_RumbleGamepad(SDL_Gamepad*, Uint16, Uint16, Uint32) {
    return true;
}
bool SDL_RumbleGamepadTriggers(SDL_Gamepad*, Uint16, Uint16, Uint32) {
    return true;
}
SDL_GamepadButtonLabel SDL_GetGamepadButtonLabelForType(SDL_GamepadType, SDL_GamepadButton button) {
    switch (button) {
    case SDL_GAMEPAD_BUTTON_SOUTH: return SDL_GAMEPAD_BUTTON_LABEL_B;
    case SDL_GAMEPAD_BUTTON_EAST: return SDL_GAMEPAD_BUTTON_LABEL_A;
    case SDL_GAMEPAD_BUTTON_WEST: return SDL_GAMEPAD_BUTTON_LABEL_Y;
    case SDL_GAMEPAD_BUTTON_NORTH: return SDL_GAMEPAD_BUTTON_LABEL_X;
    default: return SDL_GAMEPAD_BUTTON_LABEL_UNKNOWN;
    }
}
SDL_GamepadButtonLabel SDL_GetGamepadButtonLabel(SDL_Gamepad*, SDL_GamepadButton button) {
    return SDL_GetGamepadButtonLabelForType(SDL_GAMEPAD_TYPE_NINTENDO_SWITCH_PRO, button);
}
static const char* const kButtonNames[SDL_GAMEPAD_BUTTON_COUNT] = {
    "a", "b", "x", "y", "back", "guide", "start", "leftstick", "rightstick", "leftshoulder", "rightshoulder",
    "dpup", "dpdown", "dpleft", "dpright", "misc1", "paddle1", "paddle2", "paddle3", "paddle4", "touchpad",
    "misc2", "misc3", "misc4", "misc5", "misc6"};
const char* SDL_GetGamepadStringForButton(SDL_GamepadButton button) {
    return (button >= 0 && button < SDL_GAMEPAD_BUTTON_COUNT) ? kButtonNames[button] : nullptr;
}
SDL_GamepadButton SDL_GetGamepadButtonFromString(const char* s) {
    for (int i = 0; s != nullptr && i < SDL_GAMEPAD_BUTTON_COUNT; i++) {
        if (std::strcmp(s, kButtonNames[i]) == 0) {
            return static_cast<SDL_GamepadButton>(i);
        }
    }
    return SDL_GAMEPAD_BUTTON_INVALID;
}
int SDL_AddGamepadMappingsFromFile(const char*) {
    return 0;
}

// -- haptics, touch (none) --------------------------------------------------------------------------------------------------------
SDL_HapticID* SDL_GetHaptics(int* count) {
    if (count) *count = 0;
    return nullptr;
}
SDL_Haptic* SDL_OpenHaptic(SDL_HapticID) {
    return nullptr;
}
void SDL_CloseHaptic(SDL_Haptic*) {}
const char* SDL_GetHapticName(SDL_Haptic*) {
    return "";
}
bool SDL_InitHapticRumble(SDL_Haptic*) {
    return false;
}
bool SDL_PlayHapticRumble(SDL_Haptic*, float, Uint32) {
    return false;
}
bool SDL_StopHapticRumble(SDL_Haptic*) {
    return false;
}

// -- audio ------------------------------------------------------------------------------------------------------------------------
SDL_AudioStream* SDL_OpenAudioDeviceStream(SDL_AudioDeviceID, const SDL_AudioSpec* spec, SDL_AudioStreamCallback callback, void* userdata) {
    auto* s = new SDL_AudioStream();
    if (spec != nullptr) {
        s->spec = *spec;
    }
    s->callback = callback;
    s->user = userdata;
    g_audio_stream = s;
    audio_start();
    return s;
}
void SDL_DestroyAudioStream(SDL_AudioStream* s) {
    if (s == nullptr) {
        return;
    }
    SDL_AudioStream* expected = s;
    g_audio_stream.compare_exchange_strong(expected, nullptr);
    std::this_thread::sleep_for(std::chrono::milliseconds(50));  // a buffer in flight may still read it
    delete s;
}
bool SDL_ResumeAudioStreamDevice(SDL_AudioStream* s) {
    if (s) s->paused = false;
    return true;
}
bool SDL_PauseAudioStreamDevice(SDL_AudioStream* s) {
    if (s) s->paused = true;
    return true;
}
bool SDL_SetAudioStreamGain(SDL_AudioStream* s, float gain) {
    if (s) s->gain = gain;
    return true;
}
bool SDL_PutAudioStreamData(SDL_AudioStream* s, const void* buf, int len) {
    if (s == nullptr || buf == nullptr || len <= 0) {
        return false;
    }
    std::lock_guard<std::mutex> lock(s->lock);
    const auto* p = static_cast<const std::uint8_t*>(buf);
    s->bytes.insert(s->bytes.end(), p, p + len);
    return true;
}
int SDL_GetAudioStreamQueued(SDL_AudioStream* s) {
    if (s == nullptr) {
        return 0;
    }
    std::lock_guard<std::mutex> lock(s->lock);
    return static_cast<int>(s->bytes.size());
}
SDL_AudioDeviceID SDL_GetAudioStreamDevice(SDL_AudioStream*) {
    return 1;
}
bool SDL_GetAudioDeviceFormat(SDL_AudioDeviceID, SDL_AudioSpec* spec, int* sample_frames) {
    if (spec != nullptr) {
        spec->format = SDL_AUDIO_S16;
        spec->channels = 2;
        spec->freq = 48000;
    }
    if (sample_frames != nullptr) {
        *sample_frames = static_cast<int>(kFrames);
    }
    return true;
}

// -- cursor, text input, clipboard, timers (inert or trivial) ---------------------------------------------------------------------
struct SDL_Cursor {
    int unused = 0;
};
SDL_Cursor* SDL_CreateSystemCursor(SDL_SystemCursor) {
    return new SDL_Cursor();
}
void SDL_DestroyCursor(SDL_Cursor* c) {
    delete c;
}
bool SDL_SetCursor(SDL_Cursor*) {
    return true;
}
bool SDL_StartTextInput(SDL_Window*) {
    return true;
}
bool SDL_StopTextInput(SDL_Window*) {
    return true;
}
bool SDL_SetTextInputArea(SDL_Window*, const SDL_Rect*, int) {
    return true;
}
void SDL_WarpMouseInWindow(SDL_Window*, float, float) {}
SDL_MouseButtonFlags SDL_GetGlobalMouseState(float* x, float* y) {
    return SDL_GetMouseState(x, y);
}
bool SDL_CaptureMouse(bool) {
    return true;
}
bool SDL_GetWindowPosition(SDL_Window*, int* x, int* y) {
    if (x) *x = 0;
    if (y) *y = 0;
    return true;
}
char* SDL_strdup(const char* s) {
    return s != nullptr ? strdup(s) : nullptr;
}
char* SDL_GetClipboardText(void) {
    return strdup("");
}
Uint64 SDL_GetPerformanceCounter(void) {
    return SDL_GetTicksNS();
}
Uint64 SDL_GetPerformanceFrequency(void) {
    return 1000000000ull;
}
bool SDL_Vulkan_CreateSurface(SDL_Window*, VkInstance, const struct VkAllocationCallbacks*, VkSurfaceKHR*) {
    return false;
}

}  // extern "C"

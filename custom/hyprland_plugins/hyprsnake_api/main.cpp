#include <string>
#include <any>
#include <unordered_map>
#include <hyprland/src/managers/EventManager.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/devices/IKeyboard.hpp>

static HANDLE s_handle;

static void onKeypress(const std::any &data) {
    const auto &eventMap = std::any_cast<const std::unordered_map<std::string, std::any>&>(data);
    auto       keyboard = std::any_cast<SP<IKeyboard>>(eventMap.at("keyboard"));
    auto       e        = std::any_cast<IKeyboard::SKeyEvent>(eventMap.at("event"));

    const auto mods    = g_pInputManager->accumulateModsFromAllKBs();
    const char *state  = (e.state == WL_KEYBOARD_KEY_STATE_PRESSED) ? "down" : "up";
    const int   keycode = e.keycode + 8;

    std::string payload;
    payload.reserve(keyboard->hlName.size() + 20);
    payload += keyboard->hlName;
    payload += ",";
    payload += std::to_string(mods);
    payload += ",";
    payload += state;
    payload += ",";
    payload += std::to_string(keycode);

    g_pEventManager->postEvent(SHyprIPCEvent{"keypress", payload});
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    s_handle = handle;

    static auto sp_callback = HyprlandAPI::registerCallbackDynamic(
        s_handle,
        "keyPress",
        [&](void*, SCallbackInfo&, std::any data) {
            onKeypress(data);
            return true;
        });

    if (!sp_callback) {
        HyprlandAPI::addNotification(
            s_handle,
            "hyprsnake_api: Failed to register keyPress handler",
            {1.0f, 0.0f, 0.0f, 1.0f},
            5000);
    }

    return {"hyprsnake_api",
            "Custom Hyprland IPC events for hyprsnake",
            "bida",
            "0.1"};
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT void PLUGIN_EXIT() {}

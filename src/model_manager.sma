#define VERSION_STRING "1.0.0"
#define COMPILE_FOR_DEBUG

#include <amxmodx>
#include <logger>

#include "include\\stocks\\dynamic_param_stocks.inc"
#include "include\\stocks\\path_stocks.inc"
#include "include\\stocks\\precache_stocks.inc"

#include "include\\modelmanager-inc\\model_t.inc"

static Logger: g_Logger;

static Trie: g_Models;
static g_numModels;

public plugin_precache() {
    //...
}

public plugin_natives() {
    register_library("model_manager");
}

public plugin_init() {
    new buildId[32];
    getBuildId(buildId);
    register_plugin("Model Manager", buildId, "Tirant");

    create_cvar(
            "model_manager_version",
            buildId,
            FCVAR_SPONLY,
            "Current version of Model Manager being used");
}

stock getBuildId(buildId[], len = sizeof buildId) {
#if defined COMPILE_FOR_DEBUG
    return formatex(buildId, len - 1,
            "%s [%s] [DEBUG]", VERSION_STRING, __DATE__);
#else
    return formatex(buildId, len - 1,
            "%s [%s]", VERSION_STRING, __DATE__);
#endif
}

public Trie: _loadModel(pluginId, numParams) {
    if (!numParamsEqual(g_Logger, 1, numParams)) {
        return Invalid_Trie;
    }
    
    if (g_Models == Invalid_Trie) {
        g_Models = TrieCreate();
        g_numModels = 0;
        LoggerLogDebug(g_Logger,
                "Initialized g_Models as Trie: %d",
                g_Models);
    }

    new path[256];
    get_string(1, path, charsmax(path));
    fixPath(path);
    if (!precacheModel(path, g_Logger)) {
        return Invalid_Trie;
    }

    g_numModels++;
    return Invalid_Trie;
}
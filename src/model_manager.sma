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

public plugin_natives() {
    register_library("model_manager");

    register_native("mdl_logitadModel", "_loadModel", 0);
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
    if (!numParamsEqual(g_Logger, 2, numParams)) {
        return Invalid_Trie;
    }
    
    LoggerLogDebug(g_Logger, "Loading model...");

    if (g_Models == Invalid_Trie) {
        g_Models = TrieCreate();
        g_numModels = 0;
        LoggerLogDebug(g_Logger,
                "Initialized g_Models as Trie: %d",
                g_Models);
    }

    new Trie: trie = Trie:(get_param_byref(1));
    if (trie == Invalid_Trie) {
        LoggerLogDebug(g_Logger, "Invalid_Trie passed, creating trie");
        trie = TrieCreate();
        LoggerLogDebug(g_Logger,
                "Initialized model as Trie: %d",
                trie);
    }

    new path[256];
    get_string(2, path, charsmax(path));
    fixPath(path);
    if (!precacheModel(path, g_Logger)) {
        return Invalid_Trie;
    }

    TrieSetString(trie, MODEL_PATH, path);

    new Trie: existingModel;
    if (TrieGetCell(g_Models, path, existingModel)) {
        LoggerLogDebug(g_Logger,
                "Overwriting existing Trie: %d -> %d",
                existingModel,
                trie);
        TrieDestroy(existingModel);
    } else {
        g_numModels++;
    }
    
    TrieSetCell(g_Models, path, trie);
    set_param_byref(1, any:(trie));
    return trie;
}
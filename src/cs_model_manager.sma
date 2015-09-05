#define VERSION_STRING "0.0.1"
#define DEBUG_MODE

#define BUFFER_LENGTH 255

#define LOG_BUFFER_LENGTH 255
#define LOG_PATH_LENGTH 63

#include <amxmodx>

#include "include/cs_precache_stocks.inc"
#include "include/param_test_stocks.inc"

#include "include/cs_model_manager.inc"

new g_szLogBuffer[LOG_BUFFER_LENGTH+1] = "[cs_model_manager] ";
new g_szLogFilePath[LOG_PATH_LENGTH+1];

enum _:Forward {
    returnVal = 0,
    onModelRegistered
}

static g_fw[Forward] = { INVALID_HANDLE, ... };

static Trie:g_modelLookup = Invalid_Trie;
static g_numModels = 0;

public plugin_natives() {
    register_library("cs_model_manager");

    register_native("cs_registerModel", "_registerModel", 0);
}

public plugin_init() {
    register_plugin("CS Model Manager", VERSION_STRING, "Tirant");

    configureLogFilePath();
    state logging;

    cs_registerModel(.name = "test", .path = "another.mdl");
    cs_registerModel(.name = "test", .path = "another");
}

configureLogFilePath() {
    assert g_szLogFilePath[0] == EOS;
    log("Configuring log file");

    new szTime[16];
    get_time("%Y-%m-%d", szTime, charsmax(szTime));
    formatex(g_szLogFilePath, LOG_PATH_LENGTH, "cs_model_manager_%s.log", szTime);
}

log(format[], any:...) <> {
#pragma unused format
}

log(format[], any:...) <logging> {
    new length = 0;
    g_szLogBuffer[length++] = '[';
    length += copy(g_szLogBuffer[length],
                   LOG_BUFFER_LENGTH-length,
                   "cs_model_manager");
    g_szLogBuffer[length++] = ']';
    g_szLogBuffer[length++] = ' ';
    length += vformat(g_szLogBuffer[length], LOG_BUFFER_LENGTH-length, format, 2);
    g_szLogBuffer[length] = EOS;
    log_to_file(g_szLogFilePath, g_szLogBuffer);
}

public Trie:_registerModel(pluginId, numParams) {
    log("Registering model...");
    new Trie:model = Trie:get_param(5);
    if (model == Invalid_Trie) {
        log("  No valid trie passed, creating trie");
        model = TrieCreate();
    }

    log("  trie = %d", model);

    new buffer[BUFFER_LENGTH+1];
    new pathLen = min(get_param(4)-1, BUFFER_LENGTH);
    getPath(buffer, model, pathLen);
    

    log("  precaching \"%s\"", buffer);
    if (!cs_precache(buffer)) {
        log("  failed to precache \"%s\"", buffer);
        return Invalid_Trie;
    }

    log("  path = \"%s\"", buffer);
    log("  pathLen = %d", pathLen);

    new nameLen = min(get_param(2)-1, BUFFER_LENGTH);
    if (nameLen > 0) {
        get_string(1, buffer, nameLen);
        buffer[nameLen] = EOS;
        log("  writing to trie %d: %s = \"%s\"", model, MODEL_NAME, buffer);
        TrieSetString(model, MODEL_NAME, buffer);
    } else {
        TrieGetString(model, MODEL_NAME, buffer, BUFFER_LENGTH);
        log("  reading from trie %d... %s = \"%s\"", model, MODEL_NAME, buffer);
    }

    log("  name = \"%s\"", buffer);
    log("  nameLen = %d", nameLen);

    if (pathLen > 0 || nameLen > 0) {
        log("  Getting key-value pairs for trie %d", model);
        new len;
        TrieGetString(model, MODEL_PATH, buffer, BUFFER_LENGTH, len);
        buffer[pathLen] = EOS;
        log("    %s = \"%s\" [%d]", MODEL_PATH, buffer, len);
        TrieGetString(model, MODEL_NAME, buffer, BUFFER_LENGTH, len);
        buffer[nameLen] = EOS;
        log("    %s = \"%s\" [%d]", MODEL_NAME, buffer, len);
    }

    return model;
}

fixPath(buffer[], &model, &pathLen) {
    pathLen = min(get_param(4)-1, BUFFER_LENGTH);
    if (pathLen > 0) {
        get_string(3, buffer, pathLen);
        buffer[pathLen] = EOS;
        if (equali(buffer[pathLen-4],".mdl")) {
            log("  path ends with .mdl");
        } else {
            log("  appending .mdl to path");
            log("  buffer = \"%s\"", buffer);
            pathLen += copy(buffer[pathLen], BUFFER_LENGTH, ".mdl");
            buffer[pathLen] = EOS;
            log("  buffer = \"%s\"", buffer);
        }
        
        log("  writing to trie %d: %s = \"%s\"", model, MODEL_PATH, buffer);
        TrieSetString(model, MODEL_PATH, buffer);
    } else {
        TrieGetString(model, MODEL_PATH, buffer, BUFFER_LENGTH);
        log("  reading from trie %d... %s = \"%s\"", model, MODEL_PATH, buffer);
    }
}
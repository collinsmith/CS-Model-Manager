#define VERSION_STRING "0.0.1"
#define DEBUG_MODE

#include <amxmodx>

#include "include/templates/model_t.inc"
#include "include/cs_precache_stocks.inc"
#include "include/param_test_stocks.inc"

#define INITIAL_MODELS_SIZE 16

#define copyAndTerminate(%1,%2,%3,%4)\
    %4 = get_string(%1, %2, %3);\
    %2[%4] = EOS

#define isEmpty(%1)\
    (%1[0] == EOS)

enum _:Forward {
    returnVal = 0,
    onModelRegistered
};

static g_fw[Forward] = { INVALID_HANDLE, ... };

static Array:g_modelList = Invalid_Array;
static Trie:g_modelTrie = Invalid_Trie;
static g_numModels = 0;

static g_tempModel[model_t];

public plugin_natives() {
    register_library("cs_model_manager");

    register_native("cs_registerModel", "_registerModel", 0);
    register_native("cs_findModelByName", "_findModelByName", 0);
    register_native("cs_getModelData", "_getModelData", 0);
    register_native("cs_isValidModel", "_isValidModel", 0);
}

public plugin_init() {
    register_plugin("CS Model Manager", VERSION_STRING, "Tirant");
    create_cvar(
            "cs_model_manager_version",
            VERSION_STRING,
            FCVAR_SPONLY,
            "The current version of cs_model_manager being used");
}

public plugin_end() {
    ArrayDestroy(g_modelList);
    TrieDestroy(g_modelTrie);
}

bool:isValidModel(Model:model) {
    return Invalid_Model < model && any:model <= g_numModels;
}

Model:findModelByName(name[]) {
    strtolower(name);
    new Model:model;
    if (TrieGetCell(g_modelTrie, name, model)) {
        return model;
    }

    return Invalid_Model;
}

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * @link #cs_registerModel(name[],path[])
 */
public Model:_registerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_registerModel", 2, numParams)) {
        return Invalid_Model;
    }
#endif

    if (g_modelList == Invalid_Array) {
        g_modelList = ArrayCreate(model_t, INITIAL_MODELS_SIZE);
    }

    if (g_modelTrie == Invalid_Trie) {
        g_modelTrie = TrieCreate();
    }

    copyAndTerminate(1,g_tempModel[model_Name],model_Name_length,g_tempModel[model_NameLength]);
    if (isEmpty(g_tempModel[model_Name])) {
        log_error(AMX_ERR_NATIVE, "[cs_registerModel] Invalid parameter specified: 'name' cannot be empty");
        return Invalid_Model;
    }

    new Model:model = findModelByName(g_tempModel[model_Name]);
    if (isValidModel(model)) {
        return model;
    }

    copyAndTerminate(2,g_tempModel[model_Path],model_Path_length,g_tempModel[model_PathLength]);
    if (isEmpty(g_tempModel[model_Path])) {
        log_error(AMX_ERR_NATIVE, "[cs_registerModel] Invalid parameter specified: 'path' cannot be empty");
        return Invalid_Model;
    } else if (!cs_precache(g_tempModel[model_Path])) {
        log_error(AMX_ERR_NATIVE, "[cs_registerModel] Failed to precache model: %s [%s]", g_tempModel[model_Name], g_tempModel[model_Path]);
        return Invalid_Model;
    }

    model = Model:(ArrayPushArray(g_modelList, g_tempModel)+1);
    TrieSetCell(g_modelTrie, g_tempModel[model_Name], model);
    g_numModels++;

    if (g_fw[onModelRegistered] == INVALID_HANDLE) {
        g_fw[onModelRegistered] = CreateMultiForward(
                "cs_onModelRegistered",
                ET_IGNORE,
                FP_CELL,
                FP_ARRAY);
    }

    g_fw[returnVal] = ExecuteForward(
            g_fw[onModelRegistered],
            g_fw[returnVal],
            model,
            PrepareArray(g_tempModel, model_t));

    if (g_fw[returnVal] == 0) {
        log_error(AMX_ERR_NATIVE, "[cs_registerModel] Failed to execute cs_onModelRegistered for model: %s [%s]", g_tempModel[model_Name], g_tempModel[model_Path]);
    }

    return model;
}

/**
 * @link #cs_findModelByName(name[])
 */
public Model:_findModelByName(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_findModelByName", 1, numParams)) {
        return Invalid_Model;
    }
#endif

    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        return Invalid_Model;
    }

    copyAndTerminate(1,g_tempModel[model_Name],model_Name_length,g_tempModel[model_NameLength]);
    if (isEmpty(g_tempModel[model_Name])) {
        return Invalid_Model;
    }

    return findModelByName(g_tempModel[model_Name]);
}

/**
 * @link #cs_getModelData(model,data[model_t])
 */
public Model:_getModelData(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_findModelByName", 2, numParams)) {
        return Invalid_Model;
    }

    // TODO: Perform validation on the outgoing array size
    //if () {
    //    return Invalid_Model;
    //}
#endif

    new Model:model = Model:get_param(1);
    if (!isValidModel(model)) {
        return Invalid_Model;
    }
    
    ArrayGetArray(g_modelList, any:model-1, g_tempModel);
    set_array(2, g_tempModel, model_t);
    return model;
}

/**
 * @link #cs_isValidModel(model)
 */
public bool:_isValidModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_isValidModel", 1, numParams)) {
        return false;
    }
#endif

    new Model:model = Model:get_param(1);
    return isValidModel(model);
}
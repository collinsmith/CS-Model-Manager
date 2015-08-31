#define VERSION_STRING "0.0.1"
#define DEBUG_MODE

#include <amxmodx>
#include <cstrike>

#include "include/templates/playermodel_t.inc"
#include "include/cs_model_manager.inc"
#include "include/cs_precache_stocks.inc"
#include "include/param_test_stocks.inc"

#define INITIAL_MODELS_SIZE 4

#define copyAndTerminate(%1,%2,%3,%4)\
    %4 = get_string(%1, %2, %3);\
    %2[%4] = EOS

#define isEmpty(%1)\
    (%1[0] == EOS)

enum internal_playermodel_t {
    Model:internal_playermodel_ParentHandle
}

enum _:Forward {
    returnVal = 0,
    onPlayerModelRegistered,
    onSetUserPlayerModelPre,
    onSetUserPlayerModelPost
};

static g_fw[Forward] = { INVALID_HANDLE, ... };

static Array:g_modelList = Invalid_Array;
static Trie:g_modelTrie = Invalid_Trie;
static g_numModels = 0;

static PlayerModel:g_currentModel[MAX_PLAYERS+1] = { Invalid_Player_Model, ... };
static PlayerModel:g_newModel;
static bool:g_isInOnSetUserModelPre = false;
static g_tempModel[model_t];
static g_tempPlayerModel[playermodel_t];
static g_tempInternalPlayerModel[internal_playermodel_t];

public plugin_natives() {
    register_library("cs_player_model_manager");

    register_native("cs_registerPlayerModel", "_registerPlayerModel", 0);
    register_native("cs_findPlayerModelByName", "_findPlayerModelByName", 0);
    register_native("cs_getPlayerModelData", "_getPlayerModelData", 0);
    register_native("cs_isValidPlayerModel", "_isValidPlayerModel", 0);
    register_native("cs_validatePlayerModel", "_validatePlayerModel", 0);

    register_native("cs_setUserPlayerModel", "_setUserPlayerModel", 0);
    register_native("cs_getUserPlayerModel", "_getUserPlayerModel", 0);
    register_native("cs_resetUserPlayerModel", "_resetUserPlayerModel", 0);
    register_native("cs_changeOnSetUserModelModel", "_changeOnSetUserModelModel", 0);
}

public plugin_init() {
    register_plugin("CS Player Model Manager", VERSION_STRING, "Tirant");
    create_cvar(
            "cs_player_model_manager_version",
            VERSION_STRING,
            FCVAR_SPONLY,
            "The current version of cs_player_model_manager being used");

    g_fw[onSetUserPlayerModelPre] = CreateMultiForward(
            "cs_onSetUserPlayerModelPre",
            ET_STOP,
            FP_CELL,
            FP_CELL,
            FP_CELL);

    g_fw[onSetUserPlayerModelPost] = CreateMultiForward(
            "cs_onSetUserPlayerModelPost",
            ET_IGNORE,
            FP_CELL,
            FP_CELL,
            FP_CELL);
}

public plugin_end() {
    ArrayDestroy(g_modelList);
    TrieDestroy(g_modelTrie);
}

bool:isValidPlayerModel(PlayerModel:model) {
    return Invalid_Player_Model < model && any:model <= g_numModels;
}

bool:validateParent(PlayerModel:model) {
    assert isValidPlayerModel(model);
    ArrayGetArray(g_modelList, any:model-1, g_tempInternalPlayerModel);
    return cs_isValidModel(
            g_tempInternalPlayerModel[internal_playermodel_ParentHandle]);
}

PlayerModel:findPlayerModelByName(name[]) {
    strtolower(name);
    new PlayerModel:model;
    if (TrieGetCell(g_modelTrie, name, model)) {
        return model;
    }

    return Invalid_Player_Model;
}

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * @link #cs_registerPlayerModel(name[])
 */
public PlayerModel:_registerPlayerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_registerPlayerModel", 1, numParams)) {
        return Invalid_Player_Model;
    }
#endif

    if (g_modelList == Invalid_Array) {
        g_modelList = ArrayCreate(internal_playermodel_t, INITIAL_MODELS_SIZE);
    }

    if (g_modelTrie == Invalid_Trie) {
        g_modelTrie = TrieCreate();
    }

    copyAndTerminate(1,g_tempPlayerModel[playermodel_Parent][model_Name],model_Name_length,g_tempPlayerModel[playermodel_Parent][model_NameLength]);
    
    new PlayerModel:model = findPlayerModelByName(g_tempPlayerModel[playermodel_Parent][model_Name]);
    if (isValidPlayerModel(model)) {
        return model;
    }

    g_tempPlayerModel[playermodel_Parent][model_PathLength] = cs_formatPlayerModelPath(
            g_tempPlayerModel[playermodel_Parent][model_Name],
            g_tempPlayerModel[playermodel_Parent][model_Path],
            model_Path_length);

    g_tempInternalPlayerModel[internal_playermodel_ParentHandle] = cs_registerModel(
            g_tempPlayerModel[playermodel_Parent][model_Name],
            g_tempPlayerModel[playermodel_Parent][model_Path]);
    if (!cs_isValidModel(g_tempInternalPlayerModel[internal_playermodel_ParentHandle])) {
        // Error already reported while registering
        return Invalid_Player_Model;
    }

    model = PlayerModel:(ArrayPushArray(g_modelList, g_tempInternalPlayerModel)+1);
    TrieSetCell(g_modelTrie, g_tempPlayerModel[playermodel_Parent][model_Name], model);
    g_numModels++;

    if (g_fw[onPlayerModelRegistered] == INVALID_HANDLE) {
        g_fw[onPlayerModelRegistered] = CreateMultiForward(
                "cs_onPlayerModelRegistered",
                ET_IGNORE,
                FP_CELL,
                FP_ARRAY);
    }

    g_fw[returnVal] = ExecuteForward(
            g_fw[onPlayerModelRegistered],
            g_fw[returnVal],
            model,
            PrepareArray(g_tempPlayerModel, playermodel_t));

    if (g_fw[returnVal] == 0) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_registerPlayerModel] Failed to execute \
                    cs_onPlayerModelRegistered for model: %s [%s]",
                g_tempPlayerModel[playermodel_Parent][model_Name],
                g_tempPlayerModel[playermodel_Parent][model_Path]);
    }

    return model;
}

/**
 * @link #cs_findPlayerModelByName(name[])
 */
public PlayerModel:_findPlayerModelByName(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_findPlayerModelByName", 1, numParams)) {
        return Invalid_Player_Model;
    }
#endif

    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        return Invalid_Player_Model;
    }

    copyAndTerminate(1,g_tempPlayerModel[playermodel_Parent][model_Name],model_Name_length,g_tempPlayerModel[playermodel_Parent][model_NameLength]);
    if (isEmpty(g_tempPlayerModel[playermodel_Parent][model_Name])) {
        return Invalid_Player_Model;
    }

    return findPlayerModelByName(g_tempPlayerModel[playermodel_Parent][model_Name]);
}

/**
 * @link #cs_getPlayerModelData(model,data[playermodel_t])
 */
public PlayerModel:_getPlayerModelData(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_getPlayerModelData", 2, numParams)) {
        return Invalid_Player_Model;
    }

    // TODO: Perform validation on the outgoing array size
    //if () {
    //    return Invalid_Player_Model;
    //}
#endif

    new PlayerModel:model = PlayerModel:get_param(1);
    if (!isValidPlayerModel(model)) {
        return Invalid_Player_Model;
    }

    ArrayGetArray(g_modelList, any:model-1, g_tempInternalPlayerModel);
    
    new Model:parentModel = cs_getModelData(
        g_tempInternalPlayerModel[internal_playermodel_ParentHandle],
        g_tempModel);
    assert cs_isValidModel(parentModel);
    g_tempPlayerModel[playermodel_Parent] = g_tempModel;
    set_array(2, g_tempPlayerModel, playermodel_t);
    return model;
}

/**
 * @link #cs_isValidPlayerModel(model)
 */
public bool:_isValidPlayerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_isValidPlayerModel", 1, numParams)) {
        return false;
    }
#endif

    new PlayerModel:model = PlayerModel:get_param(1);
    return isValidPlayerModel(model);
}

/**
 * @link #cs_validatePlayerModel(model)
 */
public bool:_validatePlayerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_validatePlayerModel", 1, numParams)) {
        return false;
    }
#endif

    new PlayerModel:model = PlayerModel:get_param(1);
    return isValidPlayerModel(model) && validateParent(model);
}

/**
 * @link #cs_setUserPlayerModel(id,model)
 */
public _setUserPlayerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_setUserPlayerModel", 2, numParams)) {
        return;
    }
#endif

    new id = get_param(1);
    if (id < 1 || MaxClients < id) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_setUserPlayerModel] Invalid player index specified: %d",
                id);
        return;
    }

    if (!is_user_connected(id)) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_setUserPlayerModel] User is not connected: %d",
                id);
        return;
    }

    g_newModel = PlayerModel:get_param(2);

    if (!isValidPlayerModel(g_newModel)) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_setUserPlayerModel] Invalid player model specified: %d",
                g_newModel);
        return;
    }

#if defined DEBUG_MODE
    if (!validateParent(g_newModel)) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_setUserPlayerModel] Invalid player model for parent: %d",
                g_tempInternalPlayerModel[internal_playermodel_ParentHandle]);
        return;
    }
#endif

    new PlayerModel:oldModel = g_currentModel[id];
    g_isInOnSetUserModelPre = true;
    g_fw[returnVal] = ExecuteForward(
            g_fw[onSetUserPlayerModelPre],
            g_fw[returnVal],
            oldModel,
            g_newModel);
    g_isInOnSetUserModelPre = false;

    if (g_fw[returnVal] == 0) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_setUserPlayerModel] Failed to execute \
                    cs_onSetUserPlayerModelPre on player %N",
                id);
    }

    new Model:parentModel = cs_getModelData(
        g_tempInternalPlayerModel[internal_playermodel_ParentHandle],
        g_tempModel);
    assert cs_isValidModel(parentModel);
    g_tempPlayerModel[playermodel_Parent] = g_tempModel;
    cs_set_user_model(id, g_tempPlayerModel[playermodel_Parent][model_Name]);
    g_currentModel[id] = g_newModel;

    g_fw[returnVal] = ExecuteForward(
            g_fw[onSetUserPlayerModelPost],
            g_fw[returnVal],
            oldModel,
            g_currentModel[id]);

    if (g_fw[returnVal] == 0) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_setUserPlayerModel] Failed to execute \
                    cs_onSetUserPlayerModelPost on player %N",
                id);
    }
}

/**
 * @link #cs_resetUserPlayerModel(id)
 */
public _resetUserPlayerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_resetUserPlayerModel", 1, numParams)) {
        return;
    }
#endif
    
    new id = get_param(1);
    if (id < 1 || MaxClients <= id) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_resetUserPlayerModel] Invalid player index specified: %d",
                id);
        return;
    }

    if (!is_user_connected(id)) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_resetUserPlayerModel] User is not connected: %d",
                id);
        return;
    }
    
    cs_reset_user_model(id);
    g_currentModel[id] = Invalid_Player_Model;
}

/**
 * @link #cs_getUserPlayerModel(id)
 */
public PlayerModel:_getUserPlayerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_getUserPlayerModel", 1, numParams)) {
        return Invalid_Player_Model;
    }
#endif

    new id = get_param(1);
    if (id < 1 || MaxClients <= id) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_getUserPlayerModel] Invalid player index specified: %d",
                id);
        return Invalid_Player_Model;
    }

    if (!is_user_connected(id)) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_getUserPlayerModel] User is not connected: %d",
                id);
        return Invalid_Player_Model;
    }

    return g_currentModel[id];
}

/**
 * @link #cs_changeOnSetUserModelModel(model)
 */
public _changeOnSetUserModelModel(pluginId, numParams) {
    if (!g_isInOnSetUserModelPre) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_changeOnSetUserModelModel] Invalid state. Can only call \
                    this during cs_onSetUserPlayerModelPre");
        return;
    }

#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_changeOnSetUserModelModel", 1, numParams)) {
        return;
    }
#endif

    new PlayerModel:newModel = PlayerModel:get_param(1);
    if (!isValidPlayerModel(newModel)) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_changeOnSetUserModelModel] Invalid player model \
                    specified: %d",
                newModel);
        return;
    }

#if defined DEBUG_MODE
    if (!validateParent(newModel)) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_changeOnSetUserModelModel] Invalid player model for \
                    parent: %d",
                g_tempInternalPlayerModel[internal_playermodel_ParentHandle]);
        return;
    }
#endif

    g_newModel = newModel;
}
#define VERSION_STRING "0.0.1"
#define DEBUG_MODE

#include <amxmodx>
#include <cstrike>

#include "include/templates/playermodel_t.inc"
#include "include/cs_model_manager.inc"
#include "include/cs_precache_stocks.inc"
#include "include/param_test_stocks.inc"

#define INITIAL_MODELS_SIZE 8

#define copyAndTerminate(%1,%2,%3,%4)\
    %4 = get_string(%1, %2, %3);\
    %2[%4] = EOS

#define copyInto(%1,%2)\
    new Model:parentModel = cs_getModelData(\
            %1[internal_playermodel_ParentHandle],\
            g_tempModel);\
        assert cs_isValidModel(parentModel);\
        %2[playermodel_Parent] = g_tempModel

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
static bool:g_isInOnSetUserPlayerModelPre = false;
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

#if defined DEBUG_MODE
    register_concmd(
            "models.players.list",
            "printModels",
            ADMIN_CFG,
            "Prints the list of registered player models");

    register_concmd(
            "models.players.get",
            "printCurrentModels",
            ADMIN_CFG,
            "Prints each player and the current model they have applied");
#endif
}

public plugin_end() {
    ArrayDestroy(g_modelList);
    TrieDestroy(g_modelTrie);
}

/*******************************************************************************
 * Console Commands
 ******************************************************************************/

#if defined DEBUG_MODE
public printModels(id) {
    console_print(id, "Outputting player models list...");
    for (new i = 0; i < g_numModels; i++) {
        ArrayGetArray(g_modelList, i, g_tempInternalPlayerModel);
        cs_getModelData(
                g_tempInternalPlayerModel[internal_playermodel_ParentHandle],
                g_tempModel);
        console_print(
                id,
                "%d. %s [%s]",
                i+1,
                g_tempModel[model_Name],
                g_tempModel[model_Path]);
    }
    
    console_print(id, "%d player models registered", g_numModels);
}

public printCurrentModels(id) {
    console_print(id, "Outputting players...");
    for (new i = 1; i <= MaxClients; i++) {
        if (!is_user_connected(i)) {
            console_print(id, "%d. DISCONNECTED", i);
        } else if (!isValidPlayerModel(g_currentModel[i])) {
            console_print(id, "%d. %N []", i, i);
        } else {
            ArrayGetArray(g_modelList, any:g_currentModel[i]-1, g_tempInternalPlayerModel);
            cs_getModelData(
                    g_tempInternalPlayerModel[internal_playermodel_ParentHandle],
                    g_tempModel);
            console_print(
                    id,
                    "%d. %N [%s]",
                    i,
                    i,
                    g_tempModel[model_Name]);
        }
    }
    
    console_print(id, "Done.");
}
#endif

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

bool:isInvalidPlayerModelHandleParam(const function[], PlayerModel:model) {
    if (!isValidPlayerModel(model)) {
        log_error(
                AMX_ERR_NATIVE,
                "[%s] Invalid player model handle specified: %d",
                function,
                model);
        return true;
    }

    return false;
}

stock bool:isInvalidModelHandleParam(const function[], PlayerModel:model) {
    if (!validateParent(model)) {
        log_error(
                AMX_ERR_NATIVE,
                "[%s] Invalid model handle for parent of player model: %d",
                function,
                g_tempInternalPlayerModel[internal_playermodel_ParentHandle]);
        return true;
    }

    return false;
}

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * @link #cs_registerPlayerModel(name[])
 */
public PlayerModel:_registerPlayerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_registerPlayerModel", numParams, 1)) {
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

    new Model:parent = g_tempInternalPlayerModel[internal_playermodel_ParentHandle]
            = cs_registerModel(
                g_tempPlayerModel[playermodel_Parent][model_Name],
                g_tempPlayerModel[playermodel_Parent][model_Path]);
    if (!cs_isValidModel(parent)) {
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
 * @link #cs_findPlayerModelByName(name[],...)
 */
public PlayerModel:_findPlayerModelByName(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParamsInRange("cs_findPlayerModelByName", numParams, 1, 2)) {
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

    new PlayerModel:model = findPlayerModelByName(g_tempPlayerModel[playermodel_Parent][model_Name]);
    if (isValidPlayerModel(model) && numParams == 2) {
        ArrayGetArray(g_modelList, any:model-1, g_tempInternalPlayerModel);
        copyInto(g_tempInternalPlayerModel,g_tempPlayerModel);
        set_array(2, g_tempPlayerModel, playermodel_t);
    }

    return model;
}

/**
 * @link #cs_getPlayerModelData(model,data[playermodel_t])
 */
public PlayerModel:_getPlayerModelData(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_getPlayerModelData", numParams, 2)) {
        return Invalid_Player_Model;
    }

    // TODO: Perform validation on the outgoing array size
    //if () {
    //    return Invalid_Player_Model;
    //}
#endif

    new PlayerModel:model = PlayerModel:get_param(1);
    if (isInvalidPlayerModelHandleParam("cs_getPlayerModelData", model)) {
        return Invalid_Player_Model;
    }

    ArrayGetArray(g_modelList, any:model-1, g_tempInternalPlayerModel);
    copyInto(g_tempInternalPlayerModel,g_tempPlayerModel);
    set_array(2, g_tempPlayerModel, playermodel_t);
    return model;
}

/**
 * @link #cs_isValidPlayerModel(model)
 */
public bool:_isValidPlayerModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_isValidPlayerModel", numParams, 1)) {
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
    if (isInvalidNumberOfParams("cs_validatePlayerModel", numParams, 1)) {
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
    if (isInvalidNumberOfParams("cs_setUserPlayerModel", numParams, 2)) {
        return;
    }
#endif

    new id = get_param(1);
    if (isInvalidPlayerIndexParam("cs_setUserPlayerModel", id)) {
        return;
    }

    if (isInvalidPlayerConnectedParam("cs_setUserPlayerModel", id)) {
        return;
    }

    g_newModel = PlayerModel:get_param(2);
    if (isInvalidPlayerModelHandleParam("cs_setUserPlayerModel", g_newModel)) {
        return;
    }

#if defined DEBUG_MODE
    if (isInvalidModelHandleParam("cs_setUserPlayerModel", g_newModel)) {
        return;
    }
#endif

    if (g_fw[onSetUserPlayerModelPre] == INVALID_HANDLE) {
        g_fw[onSetUserPlayerModelPre] = CreateMultiForward(
                "cs_onSetUserPlayerModelPre",
                ET_STOP,
                FP_CELL,
                FP_CELL,
                FP_CELL);
    }

    new PlayerModel:oldModel = g_currentModel[id];
    g_isInOnSetUserPlayerModelPre = true;
    g_fw[returnVal] = ExecuteForward(
            g_fw[onSetUserPlayerModelPre],
            g_fw[returnVal],
            oldModel,
            g_newModel);
    g_isInOnSetUserPlayerModelPre = false;

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

    if (g_fw[onSetUserPlayerModelPost] == INVALID_HANDLE) {
        g_fw[onSetUserPlayerModelPost] = CreateMultiForward(
                "cs_onSetUserPlayerModelPost",
                ET_IGNORE,
                FP_CELL,
                FP_CELL,
                FP_CELL);
    }

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
    if (isInvalidNumberOfParams("cs_resetUserPlayerModel", numParams, 1)) {
        return;
    }
#endif
    
    new id = get_param(1);
    if (isInvalidPlayerIndexParam("cs_resetUserPlayerModel", id)) {
        return;
    }

    if (isInvalidPlayerConnectedParam("cs_resetUserPlayerModel", id)) {
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
    if (isInvalidNumberOfParams("cs_getUserPlayerModel", numParams, 1)) {
        return Invalid_Player_Model;
    }
#endif

    new id = get_param(1);
    if (isInvalidPlayerIndexParam("cs_getUserPlayerModel", id)) {
        return Invalid_Player_Model;
    }

    if (isInvalidPlayerConnectedParam("cs_getUserPlayerModel", id)) {
        return Invalid_Player_Model;
    }

    return g_currentModel[id];
}

/**
 * @link #cs_changeOnSetUserModelModel(model)
 */
public _changeOnSetUserModelModel(pluginId, numParams) {
    if (!g_isInOnSetUserPlayerModelPre) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_changeOnSetUserModelModel] Invalid state. Can only call \
                    this during cs_onSetUserPlayerModelPre");
        return;
    }

#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_changeOnSetUserModelModel", numParams, 1)) {
        return;
    }
#endif

    new PlayerModel:newModel = PlayerModel:get_param(1);
    if (isInvalidPlayerModelHandleParam("cs_changeOnSetUserModelModel", newModel)) {
        return;
    }

#if defined DEBUG_MODE
    if (isInvalidModelHandleParam("cs_setUserPlayerModel", newModel)) {
        return;
    }
#endif

    g_newModel = newModel;
}
#define VERSION_STRING "0.0.1"
#define DEBUG_MODE

#include <amxmodx>
#include <cstrike>

#include "include/templates/weaponmodel_t.inc"
#include "include/cs_model_manager.inc"
#include "include/cs_precache_stocks.inc"
#include "include/param_test_stocks.inc"

#define INITIAL_MODELS_SIZE 8

#define copyAndTerminate(%1,%2,%3,%4)\
    %4 = get_string(%1, %2, %3);\
    %2[%4] = EOS

#define copyInto(%1,%2)\
    new Model:parentModel = cs_getModelData(\
            %1[internal_weaponmodel_ParentHandle],\
            g_tempModel);\
        assert cs_isValidModel(parentModel);\
        %2[weaponmodel_Parent] = g_tempModel;\
        %2[weaponmodel_Weapon] = %1[internal_weaponmodel_Weapon]

#define isEmpty(%1)\
    (%1[0] == EOS)

enum internal_weaponmodel_t {
    Model:internal_weaponmodel_ParentHandle,
    internal_weaponmodel_Weapon
}

enum _:Forward {
    returnVal = 0,
    onWeaponModelRegistered,
    onSetUserWeaponModelPre,
    onSetUserWeaponModelPost
};

static g_fw[Forward] = { INVALID_HANDLE, ... };

static Array:g_modelList = Invalid_Array;
static Trie:g_modelTrie = Invalid_Trie;
static g_numModels = 0;

static g_weapon[2];
static Trie:g_currentModel[MAX_PLAYERS+1] = { Invalid_Trie, ... };
static WeaponModel:g_newModel;
static bool:g_isInOnSetUserWeaponModelPre;
static g_tempModel[model_t];
static g_tempWeaponModel[weaponmodel_t];
static g_tempInternalWeaponModel[internal_weaponmodel_t];

public plugin_natives() {
    register_library("cs_weapon_model_manager");

    register_native("cs_registerWeaponModel", "_registerWeaponModel", 0);
    register_native("cs_findWeaponModelByName", "_findWeaponModelByName", 0);
    register_native("cs_getWeaponModelData", "_getWeaponModelData", 0);
    register_native("cs_getWeaponForModel", "_getWeaponForModel", 0);
    register_native("cs_isValidWeaponModel", "_isValidWeaponModel", 0);
    register_native("cs_validateWeaponModel", "_validateWeaponModel", 0);

    register_native("cs_setUserWeaponModel", "_setUserWeaponModel", 0);
    register_native("cs_getUserWeaponModel", "_getUserWeaponModel", 0);
    register_native("cs_resetUserWeaponModel", "_resetUserWeaponModel", 0);
    register_native("cs_changeOnSetUserWeaponModelModel", "_changeOnSetUserWeaponModelModel", 0);
}

public plugin_init() {
    register_plugin("CS Weapon Model Manager", VERSION_STRING, "Tirant");
}

stock const _validWeapon1 = 0xFFFFFFFD;
stock const _validWeapon2 = 0x2D;

stock bool:isValidWeapon(weapon) {
    switch (weapon) {
        case  1..32: return ((1<<(weapon- 1))&_validWeapon1) != 0;
        case 33..38: return ((1<<(weapon-33))&_validWeapon2) != 0;
        default:     return false;
    }

    return false;
}

bool:isValidWeaponModel(WeaponModel:model) {
    return Invalid_Weapon_Model < model && any:model <= g_numModels;
}

bool:validateParent(WeaponModel:model) {
    assert isValidWeaponModel(model);
    ArrayGetArray(g_modelList, any:model-1, g_tempInternalWeaponModel);
    return cs_isValidModel(
            g_tempInternalWeaponModel[internal_weaponmodel_ParentHandle]);
}

WeaponModel:findWeaponModelByName(name[]) {
    strtolower(name);
    new WeaponModel:model;
    if (TrieGetCell(g_modelTrie, name, model)) {
        return model;
    }

    return Invalid_Weapon_Model;
}

getWeaponForModel(WeaponModel:model) {
    assert isValidWeaponModel(model);
    ArrayGetArray(g_modelList, any:model-1, g_tempInternalWeaponModel);
    return g_tempInternalWeaponModel[internal_weaponmodel_Weapon];
}

bool:isInvalidWeaponModelHandleParam(const function[], WeaponModel:model) {
    if (!isValidWeaponModel(model)) {
        log_error(
                AMX_ERR_NATIVE,
                "[%s] Invalid weapon model handle specified: %d",
                function,
                model);
        return true;
    }

    return false;
}

stock bool:isInvalidModelHandleParam(const function[], WeaponModel:model) {
    if (!validateParent(model)) {
        log_error(
                AMX_ERR_NATIVE,
                "[%s] Invalid model handle for parent of weapon model: %d",
                function,
                g_tempInternalWeaponModel[internal_weaponmodel_ParentHandle]);
        return true;
    }

    return false;
}

bool:isInvalidWeaponParam(const function[], weapon) {
    if (!isValidWeapon(weapon)) {
        log_error(
                AMX_ERR_NATIVE,
                "[%s] Invalid weapon specified: $d",
                function,
                weapon);
        return true;
    }

    return false;
}

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * @link #cs_registerWeaponModel(weapon, name[])
 */
public WeaponModel:_registerWeaponModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_registerWeaponModel", numParams, 2)) {
        return Invalid_Weapon_Model;
    }
#endif

    if (g_modelList == Invalid_Array) {
        g_modelList = ArrayCreate(internal_weaponmodel_t, INITIAL_MODELS_SIZE);
    }

    if (g_modelTrie == Invalid_Trie) {
        g_modelTrie = TrieCreate();
    }

    new weapon = g_tempWeaponModel[weaponmodel_Weapon]
            = g_tempInternalWeaponModel[internal_weaponmodel_Weapon]
            = get_param(1);

    if (isInvalidWeaponParam("cs_registerWeaponModel", weapon)) {
        return Invalid_Weapon_Model;
    }

    copyAndTerminate(2,g_tempWeaponModel[weaponmodel_Parent][model_Name],model_Name_length,g_tempWeaponModel[weaponmodel_Parent][model_NameLength]);
    
    new WeaponModel:model = findWeaponModelByName(g_tempWeaponModel[weaponmodel_Parent][model_Name]);
    if (isValidWeaponModel(model)) {
        return model;
    }

    g_tempWeaponModel[weaponmodel_Parent][model_PathLength] = cs_formatModelPath(
            g_tempWeaponModel[weaponmodel_Parent][model_Name],
            g_tempWeaponModel[weaponmodel_Parent][model_Path],
            model_Path_length);

    new Model:parent = g_tempInternalWeaponModel[internal_weaponmodel_ParentHandle]
             = cs_registerModel(
                g_tempWeaponModel[weaponmodel_Parent][model_Name],
                g_tempWeaponModel[weaponmodel_Parent][model_Path]);
    if (!cs_isValidModel(parent)) {
        // Error already reported while registering
        return Invalid_Weapon_Model;
    }

    model = WeaponModel:(ArrayPushArray(g_modelList, g_tempInternalWeaponModel)+1);
    TrieSetCell(g_modelTrie, g_tempWeaponModel[weaponmodel_Parent][model_Name], model);
    g_numModels++;

    if (g_fw[onWeaponModelRegistered] == INVALID_HANDLE) {
        g_fw[onWeaponModelRegistered] = CreateMultiForward(
                "cs_onWeaponModelRegistered",
                ET_IGNORE,
                FP_CELL,
                FP_ARRAY);
    }

    g_fw[returnVal] = ExecuteForward(
            g_fw[onWeaponModelRegistered],
            g_fw[returnVal],
            model,
            PrepareArray(g_tempWeaponModel, weaponmodel_t));

    if (g_fw[returnVal] == 0) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_registerWeaponModel] Failed to execute \
                    cs_onWeaponModelRegistered for model: %s [%s]",
                g_tempWeaponModel[weaponmodel_Parent][model_Name],
                g_tempWeaponModel[weaponmodel_Parent][model_Path]);
    }

    return model;
}

/**
 * @link #cs_findWeaponModelByName(name[],...)
 */
public WeaponModel:_findWeaponModelByName(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParamsInRange("cs_findWeaponModelByName", numParams, 1, 2)) {
        return Invalid_Weapon_Model;
    }
#endif

    if (g_modelList == Invalid_Array || g_modelTrie == Invalid_Trie) {
        return Invalid_Weapon_Model;
    }

    copyAndTerminate(1,g_tempWeaponModel[weaponmodel_Parent][model_Name],model_Name_length,g_tempWeaponModel[weaponmodel_Parent][model_NameLength]);
    if (isEmpty(g_tempWeaponModel[weaponmodel_Parent][model_Name])) {
        return Invalid_Weapon_Model;
    }

    new WeaponModel:model = findWeaponModelByName(g_tempWeaponModel[weaponmodel_Parent][model_Name]);
    if (isValidWeaponModel(model) && numParams == 2) {
        ArrayGetArray(g_modelList, any:model-1, g_tempInternalWeaponModel);
        copyInto(g_tempInternalWeaponModel,g_tempWeaponModel);
        set_array(2, g_tempWeaponModel, weaponmodel_t);
    }

    return model;
}

/**
 * @link #cs_getWeaponModelData(model,data[weaponmodel_t])
 */
public WeaponModel:_getWeaponModelData(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_getWeaponModelData", numParams, 2)) {
        return Invalid_Weapon_Model;
    }

    // TODO: Perform validation on the outgoing array size
    //if () {
    //    return Invalid_Weapon_Model;
    //}
#endif

    new WeaponModel:model = WeaponModel:get_param(1);
    if (isInvalidWeaponModelHandleParam("cs_getWeaponModelData", model)) {
        return Invalid_Weapon_Model;
    }

    ArrayGetArray(g_modelList, any:model-1, g_tempInternalWeaponModel);
    copyInto(g_tempInternalWeaponModel,g_tempWeaponModel);
    set_array(2, g_tempWeaponModel, weaponmodel_t);
    return model;
}

/**
 * @link #cs_getWeaponForModel(model)
 */
public _getWeaponForModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_getWeaponForModel", numParams, 1)) {
        return -1;
    }
#endif

    new WeaponModel:model = WeaponModel:get_param(1);
    if (!isValidWeaponModel(model)) {
        return -1;
    }

    return getWeaponForModel(model);
}

/**
 * @link #cs_isValidWeaponModel(model)
 */
public bool:_isValidWeaponModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_isValidWeaponModel", numParams, 1)) {
        return false;
    }
#endif

    new WeaponModel:model = WeaponModel:get_param(1);
    return isValidWeaponModel(model);
}

/**
 * @link #_validateWeaponModel(model)
 */
public bool:cs_validateWeaponModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_validateWeaponModel", numParams, 1)) {
        return false;
    }
#endif

    new WeaponModel:model = WeaponModel:get_param(1);
    return isValidWeaponModel(model) && validateParent(model);
}

/**
 * @link #cs_setUserWeaponModel(id,model)
 */
public _setUserWeaponModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_setUserWeaponModel", numParams, 2)) {
        return;
    }
#endif

    new id = get_param(1);
    if (isInvalidPlayerIndexParam("cs_setUserWeaponModel", id)) {
        return;
    }

    if (isInvalidPlayerConnectedParam("cs_setUserWeaponModel", id)) {
        return;
    }

    g_newModel = WeaponModel:get_param(2);
    if (isInvalidWeaponModelHandleParam("cs_setUserWeaponModel", g_newModel)) {
        return;
    }

#if defined DEBUG_MODE
    if (isInvalidModelHandleParam("cs_setUserWeaponModel", g_newModel)) {
        return;
    }
#endif

    if (g_fw[onSetUserWeaponModelPre] == INVALID_HANDLE) {
        g_fw[onSetUserWeaponModelPre] = CreateMultiForward(
                "cs_onSetUserWeaponModelPre",
                ET_STOP,
                FP_CELL,
                FP_CELL,
                FP_CELL);
    }

    g_weapon[0] = getWeaponForModel(g_newModel);
    if (g_currentModel[id] == Invalid_Trie) {
        g_currentModel[id] = TrieCreate();
        TrieSetCell(g_currentModel[id], g_weapon, Invalid_Weapon_Model);
    }

    new WeaponModel:oldModel;
    TrieGetCell(g_currentModel[id], g_weapon, oldModel);
    g_isInOnSetUserWeaponModelPre = true;
    g_fw[returnVal] = ExecuteForward(
            g_fw[onSetUserWeaponModelPre],
            g_fw[returnVal],
            oldModel,
            g_newModel);
    g_isInOnSetUserWeaponModelPre = false;

    if (g_fw[returnVal] == 0) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_setUserWeaponModel] Failed to execute \
                    cs_onSetUserWeaponModelPre on player %N",
                id);
    }

    copyInto(g_tempInternalWeaponModel,g_tempWeaponModel);
    //cs_set_user_model(id, g_tempPlayerModel[playermodel_Parent][model_Name]);
    TrieSetCell(g_currentModel[id], g_weapon, g_newModel);

    if (g_fw[onSetUserWeaponModelPost] == INVALID_HANDLE) {
        g_fw[onSetUserWeaponModelPost] = CreateMultiForward(
                "cs_onSetUserWeaponModelPost",
                ET_IGNORE,
                FP_CELL,
                FP_CELL,
                FP_CELL);
    }

    g_fw[returnVal] = ExecuteForward(
            g_fw[onSetUserWeaponModelPost],
            g_fw[returnVal],
            oldModel,
            g_newModel);

    if (g_fw[returnVal] == 0) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_setUserWeaponModel] Failed to execute \
                    cs_onSetUserWeaponModelPost on player %N",
                id);
    }
}

/**
 * @link #cs_getUserWeaponModel(id,weapon)
 */
public WeaponModel:_getUserWeaponModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_getUserWeaponModel", numParams, 2)) {
        return Invalid_Weapon_Model;
    }
#endif

    new id = get_param(1);
    if (isInvalidPlayerIndexParam("cs_getUserWeaponModel", id)) {
        return Invalid_Weapon_Model;
    }

    if (isInvalidPlayerConnectedParam("cs_getUserWeaponModel", id)) {
        return Invalid_Weapon_Model;
    }

    g_weapon[0] = get_param(2);
    if (isInvalidWeaponParam("cs_getUserWeaponModel", g_weapon[0])) {
        return Invalid_Weapon_Model;
    }

    if (g_currentModel[id] == Invalid_Trie) {
        return Invalid_Weapon_Model;
    }

    new WeaponModel:weapon;
    TrieGetCell(g_currentModel[id], g_weapon, weapon);
    return weapon;
}

/**
 * @link #cs_resetUserWeaponModel(id,weapon)
 */
public _resetUserWeaponModel(pluginId, numParams) {
#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_resetUserWeaponModel", numParams, 2)) {
        return;
    }
#endif
    
    new id = get_param(1);
    if (isInvalidPlayerIndexParam("cs_resetUserWeaponModel", id)) {
        return;
    }

    if (isInvalidPlayerConnectedParam("cs_resetUserWeaponModel", id)) {
        return;
    }

    g_weapon[0] = get_param(2);
    if (isInvalidWeaponParam("cs_resetUserWeaponModel", g_weapon[0])) {
        return;
    }
    
    //cs_reset_user_model(id, weapon);
    
    if (g_currentModel[id] != Invalid_Trie) {
        TrieSetCell(g_currentModel[id], g_weapon, Invalid_Weapon_Model);
    }
}

/**
 * @link #cs_changeOnSetUserWeaponModelModel(model)
 */
public _changeOnSetUserWeaponModelModel(pluginId, numParams) {
    if (!g_isInOnSetUserWeaponModelPre) {
        log_error(
                AMX_ERR_NATIVE,
                "[cs_changeOnSetUserWeaponModelModel] Invalid state. Can only \
                    call this during cs_onSetUserWeaponModelPre");
        return;
    }

#if defined DEBUG_MODE
    if (isInvalidNumberOfParams("cs_changeOnSetUserWeaponModelModel", numParams, 1)) {
        return;
    }
#endif

    new WeaponModel:newModel = WeaponModel:get_param(1);
    if (isInvalidWeaponModelHandleParam("cs_changeOnSetUserWeaponModelModel", newModel)) {
        return;
    }

#if defined DEBUG_MODE
    if (isInvalidModelHandleParam("cs_changeOnSetUserWeaponModelModel", newModel)) {
        return;
    }
#endif

    g_newModel = newModel;
}
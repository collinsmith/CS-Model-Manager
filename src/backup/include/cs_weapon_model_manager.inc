#if defined _cs_weapon_model_manager_included
    #endinput
#endif
#define _cs_weapon_model_manager_included

/*******************************************************************************
 * STOCKS
 ******************************************************************************/

/**
 * Checks whether or not a weapon model has been registered under a specified
 * name.
 * 
 * @param name Name of the weapon model
 * 
 * @return {@literal true} if one has, otherwise {@literal false}
 * 
 * @see #cs_findWeaponModelByName(name[])
 */
stock cs_isWeaponModelRegistered(const name[]) {
    return cs_findWeaponModelByName(name) != Invalid_Weapon_Model
}

stock bool:cs_isWeaponForModel(weapon, const name[]) {
    return weapon == cs_getWeaponForModel(name);
}

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

/**
 * Called when a new weapon model is registered. This forward cannot be blocked,
 * so the return value is ignored.
 * 
 * @param weapon CSI_* constant for the weapon that this model was designed to
 *                   be used for.
 * @param model  Unique handle created for the weapon model
 * @param data   Array of size {@link #templates/weaponmodel_t.weaponmodel_t}
 *                   containing the data representing the weapon model
 */
forward cs_onWeaponModelRegistered(weapon, WeaponModel:model, data[weaponmodel_t]);

forward cs_onSetUserWeaponModelPre(id, weapon, WeaponModel:oldModel, WeaponModel:newModel);
forward cs_onSetUserWeaponModelPost(id, weapon, WeaponModel:oldModel, WeaponModel:newModel);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

native WeaponModel:cs_registerWeaponModel(weapon, const name[]);
native WeaponModel:cs_findWeaponModelByName(const name[], any:...);
native WeaponModel:cs_getWeaponModelData(WeaponModel:model, data[weaponmodel_t]);
native cs_getWeaponForModel(WeaponModel:model); // returns -1 for invalid model
native bool:cs_isValidWeaponModel({WeaponModel,any}:model);
native bool:cs_validateWeaponModel({WeaponModel,any}:model);
native cs_setUserWeaponModel(id, WeaponModel:model);
native cs_getUserWeaponModel(id, weapon);
native cs_resetUserWeaponModel(id, weapon);
native cs_changeOnSetUserWeaponModelModel(WeaponModel:model);
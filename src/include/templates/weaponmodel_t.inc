#if defined _weaponmodel_t_included
    #endinput
#endif
#define _weaponmodel_t_included

#include "include/templates/model_t.inc"

/**
 * Constant representing the value used for a weapon model which is invalid.
 */
enum WeaponModel {
    Invalid_Weapon_Model
};

/**
 * Represents a template for a weapon model.
 */
enum weaponmodel_t {
    /**
     * Base model for this weapon model
     */
    weaponmodel_Parent[model_t],

    /**
     * CSI_* constant representing which weapon this model applies to.
     */
    weaponmodel_Weapon,
};
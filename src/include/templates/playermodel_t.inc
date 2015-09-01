#if defined _playermodel_t_included
    #endinput
#endif
#define _playermodel_t_included

#include "include/templates/model_t.inc"

/**
 * Constant representing the value used for a player model which is invalid.
 */
enum PlayerModel {
    Invalid_Player_Model
};

/**
 * Represents a template for a player model.
 */
enum playermodel_t {
    /**
     * Base model for this player model
     */
    playermodel_Parent[model_t],
};

#define getPlayerModelParent(%1)\
    %1[playermodel_Parent]
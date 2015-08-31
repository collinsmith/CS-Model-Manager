#if defined _cs_player_model_manager_included
    #endinput
#endif
#define _cs_player_model_manager_included

#pragma reqlib cs_player_model_manager

#include "include/cs_model_manager.inc"
#include "include/templates/playermodel_t.inc"

/*******************************************************************************
 * STOCKS
 ******************************************************************************/

/**
 * Checks whether or not a player model has been registered under a specified
 * name.
 * 
 * @param name Name of the player model
 * 
 * @return {@literal true} if one has, otherwise {@literal false}
 * 
 * @see #cs_findPlayerModelByName(name[])
 */
stock cs_isPlayerModelRegistered(const name[]) {
    return cs_findPlayerModelByName(name) != Invalid_Player_Model
}

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

/**
 * Called when a new player model is registered. This forward cannot be blocked,
 * so the return value is ignored.
 * 
 * @param model Unique handle created for the player model
 * @param data  Array of size {@link #templates/playermodel_t.playermodel_t}
 *                  containing the data representing the player model
 */
forward cs_onPlayerModelRegistered(PlayerModel:model, data[playermodel_t]);

/**
 * Called when a player model is set on a player via {@link
 * #cs_setUserPlayerModel(id,model)}. Returning {@code PLUGIN_HANDLED} will
 * prevent the player model from being applied. Additionally, the model can be
 * altered at this time by calling {@link #cs_changeOnSetUserModelModel(model)}.
 * 
 * @param id       Player index whose model is being changed.
 * @param oldModel Unique handle for the player model currently applied
 * @param newModel Unique handle for the player model being applied
 * 
 * @see #cs_changeOnSetUserModelModel(model)
 */
forward cs_onSetUserPlayerModelPre(id, PlayerModel:oldModel, PlayerModel:newModel);

/**
 * Called when a player model is set on a player via {@link
 * #cs_setUserPlayerModel(id,model)}. This forward cannot be stopped, and the
 * new model cannot be changed via modifying the parameters at this point.
 * 
 * @param id       Player index whose model is being changed.
 * @param oldModel Unique handle for the player model currently applied
 * @param newModel Unique handle for the player model being applied
 */
forward cs_onSetUserPlayerModelPost(id, PlayerModel:oldModel, PlayerModel:newModel);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * Registers a player model into the player model manager and model manager, and
 * returns the unique handle for that player model. Model names must me unique,
 * i.e., each name must correspond with a single path, and registering a second
 * player model using the name of an already registered player model will result
 * in this native returning the handle for the already registered player model.
 * Additionally, player model names are case-insensitive, so "EXAMPLE" is the
 * same as "example".
 * 
 * @example new PlayerModel:model = cs_registerPlayerModel("example");
 * 
 * @param name Name of the model
 * 
 * @return Unique handle created for this player model or for the model
 *         which is already registered by this name, otherwise {@code
 *         Invalid_Player_Model} if an error occurred when registering.
 * 
 * @error An error will be thrown if an empty name is specified, or if
 *        there was a problem precaching the player model at the path,
 *        e.g., when the player model does not exist.
 */
native PlayerModel:cs_registerPlayerModel(const name[]);

/**
 * Performs a lookup on a particular player model name and returns the unique
 * handle for that player model. Model names are case-insensitive, so "EXAMPLE"
 * is the same as "example".
 * 
 * @example new PlayerModel:model = cs_findPlayerModelByName("example");
 * @example if (cs_findPlayerModelByName("example") != Invalid_Player_Model) { ... }
 * 
 * @param name Name of the player model to look up
 * 
 * @return Unique handle for the player model under the given name,
 *         otherwise {@code Invalid_Player_Model} if none was found.
 * 
 * @see #cs_isPlayerModelRegistered(name[])
 */
native PlayerModel:cs_findPlayerModelByName(const name[]);

/**
 * Copies the data representing the specified player model into arrays of sizes
 * {@link #templates/model_t.model_t} and {@link #templates/playermodel_t.playermodel_t}.
 * 
 * @example new data[playermodel_t];
 *          cs_getPlayerModelData(model, data);
 * 
 * @param model Unique handle of the player model
 * @param data  Array of size {@link #templates/playermodel_t.playermodel_t}
 *                  containing the data representing the player model
 * 
 * @return {@param model} if the operation was carried out successfully,
 *         otherwise {@code Invalid_Model}
 */
native PlayerModel:cs_getPlayerModelData(PlayerModel:model, data[playermodel_t]);

/**
 * Tests whether or not a specified cell value is a valid handle for a player
 * model.
 * 
 * @note If the player model should be validated completely (i.e.,
 *       checked whether or not the parent Model of this player model is
 *       also valid), then {@link #cs_validatePlayerModel(model)} should
 *       be used instead.
 * 
 * @param model Cell value to test
 * 
 * @return {@literal true} if it is, otherwise {@literal false}
 * 
 * @see #cs_validatePlayerModel(model)
 */
native bool:cs_isValidPlayerModel({PlayerModel,_}:model);

/**
 * Tests whether or not a specified cell value is a valid handle for a player
 * model. Additionally, this native will also recursively test the parent Model
 * for validitity. This is usually unnecessary, as a {@code Invalid_Player_Model}
 * will be returned when registering a player model if the underlying model is
 * not valid.
 * 
 * @param model Cell and then player model handle to test
 * 
 * @return {@literal true} if it is, otherwise {@literal false}
 * 
 * @see #cs_isValidPlayerModel(model)
 */
native bool:cs_validatePlayerModel({PlayerModel,_}:model);

/**
 * Applies a player model on the player with the specified index, if that index
 * is valid (i.e., between 1 and MaxClients inclusive), and that user is
 * connected.
 * 
 * @param id    Player index to apply model for
 * @param model Player model to apply on the given player
 * 
 * @error If the player index is not valid, the player is not connected,
 *        or the specified player model handle is not valid.
 */
native cs_setUserPlayerModel(id, PlayerModel:model);

/**
 * Resets the current player model on the player with the specified index to
 * their default cstrike player model if the player index is valid (i.e.,
 * between 1 and MaxClients inclusive), and that user is connected.
 * 
 * @param id Player index whose player model should be reset
 * 
 * @error If the player index is not valid, or the player is not connected.
 */
native cs_resetUserPlayerModel(id);

/**
 * Gets the player model handle on the player with the specified index, if that
 * index is valid (i.e., between 1 and MaxClients inclusive), and that user is
 * connected.
 * 
 * @param id Player index to apply model for
 * 
 * @error If the player index is not valid, or the player is not connected.
 */
native PlayerModel:cs_getUserPlayerModel(id);

/**
 * Changes the model currently being set by {@link #cs_setUserPlayerModel(id,model)}
 * during {@link #cs_onSetUserPlayerModelPre(id,oldModel,newModel)} to the
 * specified model. This new value will then be checked for validation, however
 * this will not generate an additional {@link
 * #cs_onSetUserPlayerModelPre(id,oldModel,newModel)} call.
 * 
 * @param model Player model handle to change the player model to instead of
 *                  the one currently passing through {@link
 *                  #cs_onSetUserPlayerModelPre(id,oldModel,newModel)}
 * 
 * @error If an invalid player model handle is specified, or if this is called
 *        outside of {@link #cs_onSetUserPlayerModelPre(id,oldModel,newModel)}
 */
native cs_changeOnSetUserModelModel(PlayerModel:model);
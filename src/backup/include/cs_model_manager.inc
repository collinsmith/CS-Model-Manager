#if defined _cs_model_manager_included
    #endinput
#endif
#define _cs_model_manager_included

#pragma reqlib cs_model_manager

#include "include/templates/model_t.inc"

/*******************************************************************************
 * MACROS
 ******************************************************************************/

/**
 * Checks whether or not a model has been registered under a specified name.
 * 
 * @param name Name of the model
 * 
 * @return {@literal true} if one has, otherwise {@literal false}
 * 
 * @see #cs_findModelByName(name[])
 */
stock cs_isModelRegistered(const name[]) {
    return cs_findModelByName(name) != Invalid_Model
}

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/

/**
 * Called when a new model is registered. This forward cannot be blocked, so the
 * return value is ignored.
 * 
 * @param model Unique handle created for the model
 * @param data  Array of size {@link #templates/model_t.model_t} containing the
 *                  data representing the model
 */
forward cs_onModelRegistered(Model:model, data[model_t]);

/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * Registers a model into the model manager and returns the unique handle for
 * that model. Model names must me unique, i.e., each name must correspond with
 * a single path, and registering a second model using the name of an already
 * registered model will result in this native returning the handle for the
 * already registered model. Additionally, model names are case-insensitive, so
 * "EXAMPLE" is the same as "example".
 * 
 * @example new Model:model = cs_registerModel("example", "models/example.mdl");
 * 
 * @param name Name of the model
 * @param path Path to the model
 * 
 * @return Unique handle created for this model or for the model which is
 *         already registered by this name, otherwise {@code Invalid_Model}
 *         if an error occurred when registering.
 * 
 * @error An error will be thrown if an empty name or path is specified,
 *        or if there was a problem precaching the model at the path, e.g.,
 *        when the model does not exist.
 */
native Model:cs_registerModel(const name[], const path[]);

/**
 * Performs a lookup on a particular model name and returns the unique handle
 * for that model. Model names are case-insensitive, so "EXAMPLE" is the same as
 * "example".
 * 
 * @example new Model:model = cs_findModelByName("example");
 * @example if (cs_findModelByName("example") != Invalid_Model) { ... }
 * 
 * @param name Name of the model to look up
 * 
 * @return Unique handle for the model under the given name, otherwise
 *         {@code Invalid_Model} if none was found.
 * 
 * @see #cs_isModelRegistered(name[])
 */
native Model:cs_findModelByName(const name[]);

/**
 * Copies the data representing the specified model into an array of size {@link
 * #templates/model_t.model_t}.
 * 
 * @example new data[model_t];
 *          cs_getModelData(model, data);
 * 
 * @param model Unique handle of the model
 * @param data  Array of size model_t to copy the model's data into
 * 
 * @return {@param model} if the operation was carried out successfully,
 *         otherwise {@code Invalid_Model}
 */
native Model:cs_getModelData(Model:model, data[model_t]);

/**
 * Tests whether or not a specified cell value is a valid handle for a model.
 * 
 * @param model Cell value to test
 * 
 * @return {@literal true} if it is, otherwise {@literal false}
 */
native bool:cs_isValidModel({Model,_}:model);
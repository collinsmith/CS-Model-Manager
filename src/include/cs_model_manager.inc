#if defined _cs_model_manager_included
    #endinput
#endif
#define _cs_model_manager_included

#pragma reqlib cs_model_manager

stock const MODEL_NAME[] = "model_name";
stock const MODEL_PATH[] = "model_path";

/*******************************************************************************
 * FORWARDS
 ******************************************************************************/


/*******************************************************************************
 * NATIVES
 ******************************************************************************/

/**
 * @param name  unique name for this model
 * @param path  path to the model file
 * @param copy  trie handle to copy (or overwrite) name and path 
 * @param model existing trie handle which already contains the keys
 */
native Trie:cs_registerModel(
        const name[] = NULL_STRING,
        const nameLen = sizeof name,
        const path[] = NULL_STRING,
        const pathLen = sizeof path,
        const Trie:model = Invalid_Trie);
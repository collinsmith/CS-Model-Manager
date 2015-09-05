#if defined _cs_precache_stocks_included
    #endinput
#endif
#define _cs_precache_stocks_included

#include <file>
#include <string>
#include <fakemeta>

/*******************************************************************************
 * Stocks
 ******************************************************************************/

/**
 * Formats the path for a player model.
 * 
 * @param model  Name of the player model file without the extension. This
 *                   file is assumed to be located at: "models/player/${model}/
 *                   ${model}.mdl". E.g., "gign" would format to "models/player/
 *                   gign/gign.mdl"
 * @param copy   Array to populate with the path of the model (see above)
 * @param length Number of cells in the copy array that the path can fill
 * 
 * @return       The number of cells copied.
 */
stock cs_formatPlayerModelPath(const model[], path[], length) {
    return formatex(path, length, "models/player/%s/%s.mdl", model, model);
}

/**
 * Formats the path for a model.
 * 
 * @param model  Name of the model file without the extension. This file is
 *                   assumed to be located at "models/${model}.mdl". Models can
 *                   be specified as a subpath, e.g., "knives/v_machete" would
 *                   equate to the file named "models/zm/hands/v_classic.mdl"
 * @param copy   Array to populate with the path of the model (see above)
 * @param length Number of cells in the copy array that the path can fill
 * 
 * @return       The number of cells copied.
 */
stock cs_formatModelPath(const model[], path[], length) {
    return formatex(path, length, "models/%s.mdl", model);
}

/**
 * Precaches a given model. Models should begin with "models/", and typical
 * names can be formatted using {@link #cs_formatPlayerModelPath(model[],path[],
 * length)} and {@link #cs_formatModelPath(model[],path[],length)} for player
 * and other models respectively.
 * 
 * @param model Path of the model
 * 
 * @return      {@literal true} if the model exists and was precached, otherwise
 *                  {@literal false}
 */
stock bool:cs_precacheModel(const model[]) {
	if (file_exists(model)) {
		engfunc(EngFunc_PrecacheModel, model);
		return true;
	}
	
	return false;
}

/**
 * Precaches a given sound file. Sounds are assumed to be located within the
 * sound directory (i.e., "sound/${sound}"). E.g., "explosion.wav" would equate
 * to "sound/explosion.wav"
 * 
 * @param sound Path of the sound
 * 
 * @return      {@literal true} if the sound exists and was precached, otherwise
 *                  {@literal false}
 */
stock bool:cs_precacheSound(const sound[]) {
	new temp[64];
	formatex(temp, 63, "sound/%s", sound);
	return cs_precache(temp);
}

/**
 * Precaches a given file.
 * 
 * @param file Path of the file
 * 
 * @return     {@literal true} if the file exists and was precached, otherwise
 *                 {@literal false}
 */
stock bool:cs_precache(const file[]) {
	if (file_exists(file)) {
		engfunc(EngFunc_PrecacheGeneric, file);
		return true;
	}
	
	return false;
}
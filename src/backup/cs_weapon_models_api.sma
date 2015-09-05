#define PLUGIN_VERSION "1.2.0"

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define NULL cellmin

#define PDATA_SAFE 2

#define OFFSET_WEAPON_OWNER_WIN32 41
#define OFFSET_WEAPON_OWNER_LINUX 4

#define OFFSET_ACTIVE_ITEM 373

static const g_szWEAPON_NAME[][] = {
    "",
    "weapon_p228",
    "",
    "weapon_scout",
    "weapon_hegrenade",
    "weapon_xm1014",
    "weapon_c4",
    "weapon_mac10",
    "weapon_aug",
    "weapon_smokegrenade",
    "weapon_elite",
    "weapon_fiveseven",
    "weapon_ump45",
    "weapon_sg550",
    "weapon_galil",
    "weapon_famas",
    "weapon_usp",
    "weapon_glock18",
    "weapon_awp",
    "weapon_mp5navy",
    "weapon_m249",
    "weapon_m3",
    "weapon_m4a1",
    "weapon_tmp",
    "weapon_g3sg1",
    "weapon_flashbang",
    "weapon_deagle",
    "weapon_sg552",
    "weapon_ak47",
    "weapon_knife",
    "weapon_p90"
};

static g_vModel[MAX_PLAYERS+1][sizeof g_szWEAPON_NAME+1] = { NULL, ... };
static g_wModel[MAX_PLAYERS+1][sizeof g_szWEAPON_NAME+1] = { NULL, ... };

public plugin_natives() {
    register_library("cs_weapon_models_api");
}

public plugin_init() {
    register_plugin("[CS] Weapon Models API", PLUGIN_VERSION, "Tirant & WiLS");

    new len = sizeof g_szWEAPON_NAME;
    for (new i = 0; i < len; i++) {
        if (g_szWEAPON_NAME[i][0] == EOS) {
            continue;
        }

        RegisterHam(Ham_Item_Deploy, g_szWEAPON_NAME[i], "ham_fwItemDeployPost", 1);
    }
}

public ham_fwItemDeployPost(weaponEnt) {
    new owner = fm_getWeaponEntOwner(weaponEnt);
    if (!is_user_alive(owner)) {
        return HAM_IGNORED;
    }

    new weaponId = cs_get_weapon_id(weaponEnt);
    return HAM_CONTINUE;
}

public plugin_cfg() {
    //...
}

public plugin_precache() {
    //...
}



fm_getWeaponEntOwner(ent) {
    if (pev_valid(ent) != PDATA_SAFE) {
        return NULL;
    }

    return get_pdata_cbase(ent, OFFSET_WEAPON_OWNER_WIN32, OFFSET_WEAPON_OWNER_LINUX);
}
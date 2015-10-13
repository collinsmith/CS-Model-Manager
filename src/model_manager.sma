#include <amxmodx>
#include <amxmisc>

#include "include\\modelmanager-inc\\model_t.inc"

static Trie: g_models;

public plugin_precache() {
    //...
}

public plugin_natives() {
    //...
}

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    //...
}

loadModel() {
    if (g_models == Invalid_Trie) {
        g_models = TrieCreate();
    }
}
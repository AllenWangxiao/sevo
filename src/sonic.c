/*
 *  sonic.c
 *
 *  copyright (c) 2018 Xiongfei Shi
 *
 *  author: Xiongfei Shi <jenson.shixf(a)gmail.com>
 *  license: Apache-2.0
 */

#include "common/stacktrace.h"
#include "common/runtime.h"
#include "common/bigint.h"
#include "modules/boot/boot.h"
#include "modules/mc/wrap_mc.h"
#include "common/version.h"
#include <ffi.h>

#define DONE_QUIT       0
#define DONE_RESTART    1

static const luaL_Reg modules[] = {
    { "ffi", luaopen_ffi },
    { LUAX_LIBNAME ".int", luaopen_sonic_int },
    { LUAX_LIBNAME ".mc", luaopen_sonic_mc },
    { LUAX_LIBNAME ".boot", luaopen_sonic_boot },
    { NULL, NULL }
};

static int luaopen_sonic(lua_State * L) {
    const luaL_Reg *l;

    lua_newtable(L);
    lua_pushvalue(L, -1);
    lua_setglobal(L, LUAX_LIBNAME);

    lua_pushinteger(L, SONIC_VERSION_NUM);
    lua_setfield(L, -2, "_version");

    lua_pushinteger(L, SONIC_VERSION_FULL);
    lua_setfield(L, -2, "_version_full");

    lua_pushinteger(L, SONIC_MAJOR);
    lua_setfield(L, -2, "_version_major");

    lua_pushinteger(L, SONIC_MINOR);
    lua_setfield(L, -2, "_version_minor");

    lua_pushinteger(L, SONIC_PATCH);
    lua_setfield(L, -2, "_version_patch");

#if defined(_WIN32)
    lua_pushstring(L, "Windows");
#elif defined(__linux__)
    lua_pushstring(L, "Linux");
#elif defined(__APPLE__)
    lua_pushstring(L, "OSX");
#else
    lua_pushstring(L, "Unknown");
#endif
    lua_setfield(L, -2, "_os");

    /* Preload module loaders */
    for (l = modules; NULL != l->name; ++l) {
        luaX_preload(L, l->name, l->func);
    }

    luaX_require(L, LUAX_LIBNAME ".int");
    lua_pop(L, 1);  /* pop returned by require */

    luaX_require(L, LUAX_LIBNAME ".mc");
    lua_pop(L, 1);  /* pop returned by require */

    lua_pop(L, 1);  /* pop table */

    return 0;
}

static int sonic_run(int argc, char *argv[], int *retval) {
    lua_State *L;

    if ((argc > 1) && (0 == strcasecmp("--version", argv[1]))) {
        printf("Sonic %s\n", sonic_version());
        *retval = 0;
        return DONE_QUIT;
    }

    L = luaL_newstate();

    luaL_checkversion(L);
    luaL_openlibs(L);

    luaX_preload(L, LUAX_LIBNAME, luaopen_sonic);

    luaX_require(L, LUAX_LIBNAME);
    lua_pop(L, 1);

    luaX_require(L, LUAX_LIBNAME ".boot");
    lua_pop(L, 1);

    lua_close(L);

    *retval = 0;
    return DONE_QUIT;
}

int main(int argc, char *argv[]) {
    int done, retval = 0;

    mc_init();
    install_stacktrace(NULL);

    do {
        done = sonic_run(argc, argv, &retval);
    } while (DONE_QUIT != done);

    mc_destroy();

    return retval;
}
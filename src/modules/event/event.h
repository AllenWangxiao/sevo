/*
 *  event.h
 *
 *  copyright (c) 2018 Xiongfei Shi
 *
 *  author: Xiongfei Shi <jenson.shixf(a)gmail.com>
 *  license: Apache-2.0
 */

#ifndef __EVENT_H__
#define __EVENT_H__

#include "common/runtime.h"

#ifdef __cplusplus
extern "C" {
#endif

    int event_init(void);
    void event_deinit(void);

    int luaopen_sevo_event(lua_State* L);

#ifdef __cplusplus
};
#endif

#endif  /* __EVENT_H__ */

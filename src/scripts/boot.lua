------------------------------------------------------------
--  boot.lua
--
--  copyright (c) 2018 Xiongfei Shi
--
--  author: Xiongfei Shi <jenson.shixf(a)gmail.com>
--  license: Apache-2.0
------------------------------------------------------------

local sevo = require("sevo")
local env = {}

local function error_handler(errmsg)
    sevo.error(debug.traceback(tostring(errmsg), 3))
end

function sevo.boot()
    -- Hack require for extensions
    env.require = _G["require"]
    _G["require"] = function(name)
        local ok, mod

        -- find global
        ok, mod = pcall(env.require, name)
        if ok then return mod end

        -- find sevo extensions
        ok, mod = pcall(env.require, "_extensions_." .. name)
        if ok then return mod end

        -- find project extensions
        ok, mod = pcall(env.require, "extensions." .. name)
        if ok then return mod end

        return error("module '" .. name .. "' not found:")
    end

    require("sevo.int")
    require("sevo.logger")
    require("sevo.vfs")

    -- Redirect print to sevo.info
    _G["print"] = sevo.info

    local function get_fullpath(p)
        local np = p:gsub("\\", "/")

        if np:find("/") == 1 or np:find("%a:") == 1 then
            return np
        end

        local cwd = sevo.vfs.getcwd()
        cwd = cwd:gsub("\\", "/")

        if cwd:sub(-1) ~= "/" then
            cwd = cwd .. "/"
        end

        return cwd .. np
    end

    if #arg < 2 then
        sevo.error("Parameter error, no working directory!")
        return false
    end

    -- source directory
    local fullpath = get_fullpath(arg[2])
    local _, mdir = xpcall(sevo.vfs.mount, error_handler, fullpath, "/")
    if not mdir then
        local _, mzip = xpcall(sevo.vfs.mount, error_handler, fullpath .. ".zip", "/")
        if not mzip then
            sevo.error("Source mounting failed, " .. arg[2])
            return false
        end
    end

    return true
end

function sevo.init()
    local c = {
        version = sevo._VERSION,
        loglevel = "debug",
        modules = {
            id = true,
            time = true,
            event = true,
            hash = true,
            rand = true,
            net = true,
            secure = true,
            thread = true,
        }
    }

    local result

    if sevo.vfs.info("conf.lua") then
        result = xpcall(require, error_handler, "conf");
        if not result then return false end
    end

    if sevo.conf then
        result = xpcall(sevo.conf, error_handler, c);
        if not result then return false end
    end

    sevo.loglevel(c.loglevel)

    for i, v in ipairs({
        "id",
        "time",
        "event",
        "hash",
        "rand",
        "net",
        "secure",
        "thread",
    }) do
        if c.modules[v] then
            require("sevo." .. v)
        end
    end

    if sevo.event then
        local function createhandlers()
            env.handlers = setmetatable({
                quit = function()
                    return
                end,
            }, {
                __index = function(self, name)
                    error("Unknown event: " .. name)
                end,
            })
        end

        sevo.event.init()
        createhandlers()

        sevo.event.poll_i = function()
            return table.unpack(sevo.event.poll_t() or {})
        end
        sevo.event.poll = function()
            return sevo.event.poll_i
        end
        sevo.event.push = function(...)
            sevo.event.push_t(table.pack(...))
        end
        sevo.event.quit = function(a)
            sevo.event.push("quit", a or 0)
        end
    end

    if not sevo.vfs.info("servo.lua") then
        sevo.error("'servo.lua' is not found! What can i do for you?")
        return false
    end

    result = xpcall(require, error_handler, "servo");
    if not result then return false end

    return true
end

function sevo.run()
    if sevo.load then sevo.load(arg) end

    local fps = sevo.time.fps(100)

    return function()
        fps:wait();

        if sevo.event then
            sevo.event.pump()

            for name, a, b, c, d, e, f in sevo.event.poll() do
                if name == "quit" then
                    if sevo.quit then sevo.quit() end
                    return a or 0
                end
                env.handlers[name](a, b, c, d, e, f)
            end
        end

        if sevo.update then sevo.update(fps:delta()) end
    end
end

return function ()
    local func

    local function earlyinit()
        local _, isbooted = xpcall(sevo.boot, error_handler)
        if not isbooted then return 1 end

        local _, isinited = xpcall(sevo.init, error_handler)
        if not isinited then return 1 end

        local result, main = xpcall(sevo.run, error_handler)
        if not result then return 1 end

        func = main
    end

    func = earlyinit

    while func do
        local _, retval = xpcall(func, error_handler)
        if retval then return retval end
        coroutine.yield()
    end

    return 1
end

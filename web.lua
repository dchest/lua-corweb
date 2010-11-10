require "wsapi.request"
require "wsapi.response"

-- module (..., package.seeall)

-- Table of handlers for requests in format:
-- { METHOD = { path = function, ... }, ...}

local HANDLERS  = {
    GET  = {},
    POST = {}
}

-- Default headers
local HEADERS = {
    html = { ["Content-type"] = "text/html" },
    text = { ["Content-type"] = "text/plain" }
}

-- Table of suspended coroutines
local STATES = {}

-- Table of cid = os.time to gc coroutines by timeout
local TIMES  = {}
-- Max time for coroutines to live when not active, in sec
local TIMEOUT = 60 * 60 -- 1 hour
-- Max number of requests before doing gc
local GC_MAX_REQUESTS = 100
-- Global no of requests counter, used by gc 
local GC_REQUEST_COUNTER = 0

math.randomseed (os.time())

-- Returns the same string. 
-- In future, allows for easy translations for this string.
-- This function should be global so that app developers could change it.

function tr (s)
    return s
end

-- Private functions --

local function resumestate (req)
    local cid = req.params.cid
    local c = STATES[cid]
    TIMES[cid] = os.time() -- update timeout for gc
    if not c then
        print ("no coroutine for cid " .. cid)
        return false, tr"no coroutine"
    end
    --[[ 
    if coroutine.status(c) == "dead" then
        STATES[cid] = nil
        TIMES[cid]  = nil
        print ("coroutine for cid " .. cid .. " is dead")
        --return false, tr"coroutine is dead"
    end
    --]]
    return coroutine.resume (c, req)
end

local function gencid ()
    return string.format("%x%x", math.random (2^30), math.random (2^30))
end

local function createstate (req, fn)
    local cid
    repeat
        cid = gencid()
    until STATES[cid] == nil
    STATES[cid] = coroutine.create (fn)
    return cid
end

local function findhandler (method, path)
    local h = HANDLERS[method]
    if not h then
        return notallowed
    end
    return h[path] or notfound
end

local function shouldcollect ()
    GC_REQUEST_COUNTER = GC_REQUEST_COUNTER + 1 -- global
    if GC_REQUEST_COUNTER > GC_MAX_REQUESTS then
        GC_REQUEST_COUNTER = 0
        return true
    else
        return false
    end
end

local function collectunused ()
    local now = os.time()
    local coll = {}
    for cid, time in pairs(TIMES) do
        if os.difftime(now, time) > TIMEOUT then
            table.insert(coll, cid)
        end
    end
    for _, cid in ipairs(coll) do
        STATES[cid] = nil
        TIMES[cid]  = nil
    end
    collectgarbage()
end

-- Public functions --

function addhandler (method, first, second)
    if type (first) == "table" then
        for path, fn in pairs(first) do
            HANDLERS[method][path] = fn
        end
    else
        HANDLERS[method][first] = second
    end
end

function get (path, fn)
    addhandler ("GET", path, fn)
end

function post (path, fn)
    addhandler ("POST", path, fn)
end

function ok (...)
    return coroutine.yield (200, HEADERS.html, table.concat(arg))
end

function notfound ()
    return coroutine.yield (404, HEADERS.html, tr"not found")
end

function servererror (msg)
    return coroutine.yield (200, HEADERS.html, tr("server error")..": "..msg)
end

function seeother (location)
    return coroutine.yield (303, { ["Location"] = location }, tr"see other")
end

-- Main WSAPI dispatcher function.
-- Looks for functions in handlers table and calls them.

function run (wsapi_env)
    local req = wsapi.request.new  (wsapi_env)
    local res = wsapi.response.new (wsapi_env)
    local result, output, h

    if req.params.cid == nil then 
        h = findhandler (req.method, req.path_info) 
        req.params.cid = createstate (req, h) 
    end
    result, res.status, res.headers, output = resumestate (req)
    if not res.headers then
        res.headers = HEADERS.html
    end
    if result and type (res.status) == "number" then
        output = string.gsub(output, "<# cid #>", req.params.cid)
        local loc = res.headers["Location"]
        if loc then
            res.headers["Location"] = string.gsub(loc, "<# cid #>", req.params.cid)
        end
        res:write (output)
    else
        if type (res.status) == "string" then
            -- we have error (script error, dead or no-existant coroutine)
            res:write ("error: " .. res.status .. "<br>")
        else
            -- coroutine function finished
            res:write ("couroutine finished")
        end
        res.status = 200 -- change to 500
    end
    if shouldcollect() then 
        collectunused()
    end
    return res:finish ()
end


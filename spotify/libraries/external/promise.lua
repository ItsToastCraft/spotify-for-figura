---@param func fun()
---@param time number|fun():boolean
---@vararg any
local function delay(func, time, ...)
    local timer = 0
    local id = "delay-" .. math.random()
    local args = {...}

    local function execute()
        func(table.unpack(args))
        events.WORLD_TICK:remove(id)
    end

    events.WORLD_TICK:register(function ()
        timer = timer + 1
        if type(time) == "function" then
            if time() then
                execute()
            end
        elseif timer >= time then
            execute()
        end
    end, id)

    return function(_func, _time, ...)
        return delay(_func, time + _time, ...)
    end
end

---@param func fun(i: integer)
---@param time number|fun(i: integer): boolean
---@param done? fun(i: integer)
local function run(func, time, done)
    local id = "run-" .. math.random()
    local runner = nil
    local function finish(i)
        events.WORLD_TICK:remove(id)
        if done then
            done(i)
        end
    end
    if type(time) == "function" then
        function runner(i)
            (time(i) and finish or func)(i)
        end
    else
        local i = 0
        function runner()
            (i >= time and finish or func)(i)
            i = i + 1
        end
    end
    events.WORLD_TICK:register(runner, id)
end

---@class Promise
---@field callbacks fun(...: any)[]
---@field errbacks fun(...: any)[]
---@field fulfilled boolean
---@field rejected boolean
---@field result any
local Promise = {}
Promise.__index = Promise

---@param executor fun(resolve: fun(...: any), reject: fun(...: any))
function Promise.new(executor)
    local self = setmetatable({}, Promise)
    self.callbacks = {}
    self.errbacks = {}
    self.fulfilled = false
    self.rejected = false
    self.result = {}

    local function resolve(...)
        if self.fulfilled or self.rejected then return end
        self.fulfilled = true
        self.result = {...}
        for i = 1, #self.callbacks do
            delay(self.callbacks[i], 0, ...)
        end
        self.callbacks = {}
    end

    local function reject(...)
        if self.fulfilled or self.rejected then return end
        self.rejected = true
        self.result = {...}
        for i = 1, #self.errbacks do
            delay(self.errbacks[i], 0, ...)
        end
        self.errbacks = {}
    end

    executor(resolve, reject)
    return self
end

---@param future Future
---@param timeout? integer
function Promise.await(future, timeout)
    return Promise.new(function(resolve, reject)
        local start = client.getSystemTime()
        delay(function()
            local value = future:getValue()
            if value then
                resolve(value:getData(), value:getHeaders())
            else
                reject()
            end
        end, function()
            return future:isDone() or (timeout and client.getSystemTime() - start >= timeout) or false
        end)
    end)
end

---@param url string
---@param timeout? integer
function Promise.awaitGet(url, timeout)
    return Promise.await(net.http:request(url):method("GET"):send(), timeout)
end

---@param ... Promise
function Promise.awaitAll(...)
    local promises = {...}
    return Promise.new(function(resolve, reject)
        local results = {}
        local total = #promises
        local completed = 0

        local function resolver(index)
            return function(...)
                completed = completed + 1
                results[index] = {...}
                if completed == total then
                    resolve(results)
                end
            end
        end

        local function rejecter(reason)
            reject(reason)
        end

        for i = 1, #promises do
            promises[i]:then_(resolver(i), rejecter)
        end
    end)
end

---@param callback? fun(data: any, headers: any): Promise?
---@param errback? fun(reason: any): Promise?
function Promise:then_(callback, errback)
    local chained = Promise.new(function(resolve, reject)
        local function fulfill(...)
            if callback then
                local result = callback(...)
                if result and getmetatable(result) == Promise then
                    result:then_(resolve, reject)
                else
                    resolve(result)
                end
            else
                resolve(...)
            end
        end

        local function fail(...)
            if errback then
                local result = errback(...)
                if result and getmetatable(result) == Promise then
                    result:then_(resolve, reject)
                else
                    reject(result)
                end
            else
                reject(...)
            end
        end

        if self.fulfilled then
            delay(fulfill, 10, table.unpack(self.result))
        elseif self.rejected then
            delay(fail, 10, table.unpack(self.result))
        else
            self.callbacks[#self.callbacks + 1] = fulfill
            self.errbacks[#self.errbacks + 1] = fail
        end
    end)

    return chained
end

---@param errback fun(reason: any): Promise?
function Promise:catch(errback)
    return self:then_(nil, errback)
end

local downloads = {}
---@param stream InputStream
---@param headers HttpHeaders
local function asyncBuffer(stream, headers, callback)
    local limit = headers["content-length"] and tonumber(headers["content-length"][1]) or 0
    local buffer = data:createBuffer(limit)
    local done = false
    local progress = 0
    run(function ()
        local read = buffer:readFromStream(stream, stream:available())
        local next = stream:read()
        if next == -1 then
            done = true
        else
            buffer:write(next)
        end
        progress = progress + read + 1
        downloads[stream] = { count = progress, limit = limit }
    end, function ()
        return done
    end, function ()
        buffer:setPosition(0)
        callback(buffer, progress)
        downloads[stream] = nil
    end)
end

local function readStreamAsync(stream, headers, callback)
    return Promise.new(function(resolve, reject)
        asyncBuffer(stream, headers, function(buffer, length)
            local result = callback(buffer, length)
            resolve(result)
        end)
    end)
end

---@param callback fun(value: string, headers: HttpHeaders): Promise?
---@param errback? fun(reason: any): Promise?
function Promise:then64(callback, errback)
    return self:then_(function(stream, headers)
        return readStreamAsync(stream, headers, function(buffer, length)
            return buffer:readBase64(length)
        end):then_(callback, errback)
    end, errback)
end

---@param callback fun(value: string, headers: HttpHeaders): Promise?
---@param errback? fun(reason: any): Promise?
function Promise:thenString(callback, errback)
    return self:then_(function(stream, headers)
        return readStreamAsync(stream, headers, function(buffer, length)
            return buffer:readString(length):gsub("\0", "")
        end):then_(callback, errback)
    end, errback)
end

---@param callback fun(value: any): Promise?
---@param errback? fun(reason: any): Promise?
function Promise:thenJson(callback, errback)
    return self:thenString(function(value)
        return callback(parseJson(value))
    end, errback)
end

return Promise, downloads
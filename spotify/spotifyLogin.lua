local base64 = require("base64")
local runLater = require("runLater")
config:setName("spotify_preferences")


-- Creates a new login token and saves it for future use
local function createToken()
    local clientData = config:load("client_data")
    
    if host:isHost() then
        if clientData == nil then
            clientData = parseJson(file:readString("spotify/client_data"))
            assert(clientData ~= nil, "Add credentials to file in figura/data/spotify/client_data!")
            config:save(clientData)
            file:writeString("spotify/client_data", "")
        end
        
        local buf = data:createBuffer()
        buf:writeString("grant_type=refresh_token&refresh_token=" .. clientData.refresh_token)
        buf:setPosition(0)

        local regenToken = net.http:request("https://accounts.spotify.com/api/token")
            :method("POST")
            :body(buf)
            :header("content-type", "application/x-www-form-urlencoded")
            :header("authorization",
                "Basic " .. base64.encode(clientData.id .. ":" .. clientData.secret))
            :send() -- requests a new token using the id, secret, and the refresh token

        runLater(
            function() return regenToken:isDone() end, -- wait for the token
            function()
                local async = regenToken:getValue():getData():readAsync(4096)
                buf:close()
                runLater(
                    function() return async:isDone() end,
                    function()
                        local data = parseJson(async:getValue())
                        clientData.token = data.access_token -- extracts the token
                        clientData.token_expires_in = 3600 -- token expires in one hour
                        clientData.generated_at = client:getSystemTime() -- set the time that this token was generated
                        data = nil
                        config:save("client_data", clientData)
                    end)
            end)
    end
end
-- Regenerates the spotify token, which expires every hour
local function refreshToken()
    local clientData = config:load("client_data")
    if host:isHost() then
    if clientData.generated_at + (3600*1000) <= client:getSystemTime() then
        createToken()
    end
end
end
events.tick:register(refreshToken, "refresh_token")



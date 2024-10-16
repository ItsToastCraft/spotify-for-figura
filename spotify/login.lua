--=Libraries=--
local promise = require("libraries.external.promise")
local base64 = require("libraries.external.base64")
local runLater = require("libraries.external.runLater")

--=Config=--
config:setName("spotify_preferences")

-- I'm extremely paranoid and I keep getting errors because it somehow leaks out of host.
if host:isHost() then
-- Gets data for the client, such as the login token and regeneration token.
---@return  table?
local function getClientData()
    if host:isHost() then
        local clientData = config:load("client_data")
        if clientData == nil then
            clientData = parseJson(file:readString("spotify/client_data.json"))
            assert(clientData ~= nil, "Add credentials to file in figura/data/spotify/client_data.json!")
            config:save("client_data", clientData)
            file:writeString("spotify/client_data.json", "")
        end
        return clientData
    end
end

local clientData = getClientData() --gets data
-- Creates a new login token and saves it for future use
local function createToken()
    if host:isHost() then
        local buf = data:createBuffer() -- for some reason figura likes to make things harder than they need to be...
        buf:writeString("grant_type=refresh_token&refresh_token=" .. clientData.refresh_token) -- ask for spotify to return a new access token using the static previous token generated
        buf:setPosition(0)

        local regenToken = net.http:request("https://accounts.spotify.com/api/token") -- requests a new token using the id, secret, and the refresh token
            :method("POST")
            :body(buf)
            :header("content-type", "application/x-www-form-urlencoded")
            :header("authorization",
                "Basic " .. base64.encode(clientData.id .. ":" .. clientData.secret))
            :send() -- sends the request made above
            promise.await(regenToken):thenJson(function(data) 
                clientData.token = data.access_token -- extracts the token
                clientData.generated_at = client:getSystemTime() -- set the time that this token was generated
                data = nil
                        config:save("client_data", clientData) -- saves everything for future use
                end)
    end
end
-- Regenerates the spotify token, which expires every hour
local function refreshToken()
    if clientData.token == nil then
        createToken()
    end
    if clientData.generated_at == nil then
        clientData.generated_at = client:getSystemTime()
    else
    runLater(function() return clientData.generated_at + (3600*1000) <= client:getSystemTime() end, createToken)
    end
end
refreshToken()
end
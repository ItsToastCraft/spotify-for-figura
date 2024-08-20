local album = {}
--=Libraries=--
local runLater = require("runLater")
local base64 = require("base64")
local clientData, songData, albumCache
--=Data Storage=--

if host:isHost() then
    config:name("spotify_preferences")
    clientData = config:load("client_data")
    songData = parseJson(file:readString("spotify/song"))
    albumCache = parseJson(file:readString("spotify/cache"))
    if albumCache == nil then
        albumCache = {}
    end
end

--Gets the information of the current song, such as the duration, album, song name, artist, and images.
function album.getSongInfo(token)
    local songInfo
    local songDataRequest = net.http
        :request("https://api.spotify.com/v1/me/player/currently-playing")
        :header("authorization", "Bearer " .. token)
        :send() -- Request for current spotify information
    runLater(function()
            return songDataRequest:isDone() and songDataRequest:getValue():getResponseCode() == 200
        end,
        function()
            songInfo = songDataRequest:getValue():getData():readAsync(100000)
            
        end
        
    )
    runLater(
                function() return songDataRequest:isDone() and songInfo ~= nil and (songInfo:isDone()) end,
                function()
                    
                    songData = parseJson(songInfo:getValue())
                    songData.requestedTimestamp = client:getSystemTime()
                    songData.available_markets = ""
                    file:writeString("spotify/song", toJson(songData))
                    print("Done!")
                end)
end

--Checks the cache for an album cover. Returns a base64 string of the texture of the album cover
function album.cache()
    local async

    if albumCache[songData.item.album.name] == nil then
        local request = net.http:request("<CONVERTER>" .. -- Add link to jpg to png thing
            songData.item.album.images[3].url)
        local future = request:send() -- Fetches the album cover image from a cdn that converts it to png form

        runLater(
            function() return future:isDone() and future:getValue():getResponseCode() == 200 end, -- waits for image
            function()
                async = future:getValue():getData():readAsync(8192)                         -- waits for the image to finish transferring
            end)
        runLater(
            function() return async ~= nil and async:isDone() end,
            function()
                albumCache[songData.item.album.name] = base64.encode(async:getValue())         -- encodes the image to be used in the TextureAPI later.
                file:writeString("spotify/cache", toJson(albumCache))
            end)
    end
    return albumCache[songData.item.album.name]
end
album.cache()


local time = 0
--Updates the song once it is done.
function album.updateTrack()
    time = time + 1
    if host:isHost() then
        if songData ~= nil then
            if client:getSystemTime() > songData.requestedTimestamp + songData.item.duration_ms - songData.progress_ms then
                album.getSongInfo(clientData.token)
                songData.requestedTimestamp = client:getSystemTime()
            end
        end

        if time % 1200 == 1 then
            album.getSongInfo(clientData.token)
        end
    end
end

return album

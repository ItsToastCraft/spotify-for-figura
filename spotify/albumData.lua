local album = {}
--=Libraries=--
local promise = require("libraries.external.promise")
local songData, albumCache
local size = 32
--=Data Storage=--
if host:isHost() then
    config:name("spotify_preferences")
    songData = parseJson(file:readString("spotify/song.json"))
    albumCache = parseJson(file:readString("spotify/cache.json"))
    if albumCache == nil then
        albumCache = {}
    end
end

--Gets the information of the current song, such as the duration, album, song name, artist, and images.
function album.getSongInfo(token, callback)
    local songDataRequest = net.http
        :request("https://api.spotify.com/v1/me/player/currently-playing")
        :header("authorization", "Bearer " .. token)
        :send() -- Request for current spotify information
    promise.await(songDataRequest):thenJson(function(data)
        songData = {}
        songData.album_cover = data.item.album.images[3].url
        songData.name = data.item.name
        songData.progress_ms = data.progress_ms
        songData.duration_ms = data.item.duration_ms
        songData.artists = {}
        songData.album_name = data.item.album.name
        songData.requestedTimestamp = client:getSystemTime()
        for _, artist in pairs(data.item.artists) do
            table.insert(songData.artists, artist.name)
            end
        file:writeString("spotify/song.json", toJson(songData))
        album.cache(callback)
    end)
    
end

--Checks the cache for an album cover. Returns a base64 string of the texture of the album cover
function album.cache(callback)
    local cache = albumCache
    if cache[songData.album_name] == nil then
        local request = net.http:request(
            "https://res.cloudinary.com/toasts/image/fetch/f_png/c_scale,h_" .. size .. ",w_" .. size .. "/" ..                              -- Add link to jpg to png thing
            songData.album_cover)
        local future = request:send()                                                                                                             -- Fetches the album cover image from a cdn that converts it to png form
        return promise.await(future):then64(function(data) 
            cache[songData.album_name] = data-- encodes the image to be used in the TextureAPI later.
            file:writeString("spotify/cache.json", toJson(cache))
            callback(data)
            return data
            end)
    else
        callback(cache[songData.album_name])
        return cache[songData.album_name]
    end
end

--Updates the song once it is done.
local function formatTime(time)
    local minutes = math.floor((time % 3600) / 60)
    local seconds = math.floor(time % 60)
    return string.format("%02d:%02d", minutes, seconds)
end

-- Creates a progress bar for the song
function album.createProgressBar(timeData)
    
    local current_time = client:getSystemTime() - timeData[3] + timeData[1]
    local total_duration = timeData[2]
    local bar_length = 15
    local progress_ratio = current_time / total_duration
    local progress_length = math.floor(bar_length * progress_ratio)
    local progress_bar = ("="):rep(progress_length) .. ("-"):rep(bar_length - progress_length)
    progress_bar = formatTime(current_time /1000) .. "  " .. progress_bar .. "  " .. formatTime(timeData[2] / 1000)
    return progress_bar
end


return album

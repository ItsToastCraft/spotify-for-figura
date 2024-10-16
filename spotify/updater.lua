
local album = require("albumData")
local images = require("libraries.images")
local runLater = require("libraries.external.runLater")

local clientData, songData, albumCache, startup, oldData, oldCover -- shut up I have a lot of data :sob:
local time = 2

--=Data Storage=--
if host:isHost() then
    config:name("spotify_preferences")
    clientData = config:load("client_data")
    songData = parseJson(file:readString("spotify/song.json"))
    albumCache = parseJson(file:readString("spotify/cache.json"))
    if albumCache == nil then
        albumCache = {}
    end
    oldData = songData
end

local display = models.spotify.Head.Camera
local artistSlots = {
    display:newText("Artist1"), display:newText("Artist2"), display:newText("Artist3"), display:newText("Artist4")  -- this looks bad but like I'm stupid so
} -- if there are more than 4 artists on ONE song I'm dying
local title = display:newText("Song Title"):setText("Starting..."):setOutline(true):setPos(9, 8, 0):setScale(0.2)
local albumText = display:newText("Album name"):setOutline(true):setPos(9, 6, 0):setScale(0.2)
local progressBar = display:newText("Time"):setOutline(true):setScale(0.2):setPos(9,-5, 0)

local function updateDisplay(name, albumName, artists)
    title:setText(name)
    albumText:setText(toJson({
        { text = "on ",                    color = "white" },
        { text = albumName, color = "gray" } }))
    for _, text in pairs(artistSlots) do
        text:setText("")
    end
    for i, artist in pairs(artists) do
        artistSlots[i]:setText(artist):setOutline(true):setScale(0.2):setPos(9, 4 - (i - 1) * 2, 0)
    end
end

function pings.showData(name, albumName, artists, requestedTime, totalTime, currentTime)
    name = name or oldData.name
    albumName = albumName or oldData.album_name
    artists = artists or oldData.artists
    totalTime = totalTime or oldData.duration_ms

    startup = {currentTime, totalTime, requestedTime}
    updateDisplay(name, albumName, artists)
end

local function update()
    album.getSongInfo(clientData.token,
    function(data)
        local name, albumName, artists, duration
        songData = parseJson(file:readString("spotify/song.json"))

        for key, value in pairs(songData) do
            if value ~= oldData[key] then
                if key == "name" then
                    name = value
                elseif key == "album_name" then
                    albumName = value
                elseif key == "duration_ms" then
                    duration = value
                end
            end
            if key == "artists" then
                if table.concat(value) ~= table.concat(oldData[key]) then
                artists = value
                end
            end
        end
        pings.showData(name, albumName, artists, songData.requestedTimestamp, duration, songData.progress_ms)
        if songData.album_cover ~= oldCover then
            runLater(2, function() images.dataSplit(data) end)
            oldCover = songData.album_cover
        end
    end)
end
function pings.oldData(info)
    oldData = info
end

local count = 1
local prevCount = 0
local function updateTrack()
    time = time + 1
    if host:isHost() then
        if songData ~= nil then
            if client:getSystemTime() >= songData.requestedTimestamp + songData.duration_ms - songData.progress_ms + 500 then
                songData.requestedTimestamp = client:getSystemTime()
                update()
            end
        end
        if time % 1200 == 1 then
            update()
        end
        count = 0
        if time % 240 == 0 then
            for _, _ in pairs(world.getPlayers()) do
                count = count + 1
            end
            if prevCount ~= count then
                runLater(20, function() pings.oldData(songData) update() end)
                prevCount = count
                end
        end
        if time % 2400 == 600 then
            runLater(20, function() pings.oldData(songData) update() end)
        end
    end
end
-- Oh yea these won't work for y'all unless you have a keybind that skips it outside of Minecraft.
--local skip = keybinds:newKeybind("Skip", "scancode.281")
--skip:onPress(function() runLater(10,function() update() end) end) -- add a little delay so you don't get the same song :p

events.tick:register(function() updateTrack() if startup then progressBar:setText(album.createProgressBar(startup)) end end)

runLater(4, function()
    if host:isHost() then
        update()
        pings.oldData(songData)
    end
end)

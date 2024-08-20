local songData
local album = require("spotifyAlbum")
local runLater = require("runLater")
if host:isHost() then
    
    if not file:exists("spotify") then
        file:mkdir("spotify")
        file:writeString("spotify/cache", "")
        file:writeString("spotify/song", "")
        file:writeString("spotify/stats", "")
    end
    songData = parseJson(file:readString("spotify/song"))
    
    events.tick:register(album.updateTrack, "updateTrack")

end
local function thing(data)
            log(data.name)
            log(data.album_name)
            models.spotify.Skull.Camera.Body:newText("Song Title"):setText(data.name)
                :setOutline(true):setScale(0.2):setPos(-8, 8, 0)
            models.spotify.Skull.Camera.Body:newText("Album name"):setText(toJson({
                { text = "on ",                    color = "white" },
                { text = data.album_name, color = "gray" } })):setOutline(true):setScale(0.2)
                :setPos(-8, 6, 0)
    
            for i, artist in pairs(data.artists) do
                models.spotify.Skull.Camera.Body:newText("Album name" .. i):setText(artist.name)
                    :setOutline(true):setScale(0.2):setPos(-8, 4 - (i - 1) * 2, 0)
            end
        end

function pings.showData(data)

    
    thing(data)
end
local function dataUpdate()
    local info = {["name"] = songData.item.name, ["artists"] = songData.item.artists, ["album_name"] = songData.item.album.name}
    pings.showData(info)
    
end
function packetSplit(inputString, numSlices)
    local length = #inputString
    local sectionSize = math.floor(length / numSlices)
    local slices = {}

    for i = 1, numSlices do
        local startIdx = (i - 1) * sectionSize + 1
        local endIdx = i * sectionSize
        if i == numSlices then
            endIdx = length  -- include any remaining characters in the last slice
        end
        table.insert(slices, string.sub(inputString, startIdx, endIdx))
    end

    return slices
end
local final = ""

function pings.image(data, index, last)
    final = final .. data
    if index == last then
        textures:read("album", final)
        models.spotify.Skull.Camera.Body:setPrimaryTexture("CUSTOM", textures:get("album"))
    end
end
local function dataSplit()
    if host:isHost() then
        textures:read("album", album.cache())
        models.spotify.Skull.Camera.Body:setPrimaryTexture("CUSTOM", textures:get("album"))
    end
    final = ""
    local slices = 13
    local image = packetSplit(album.cache(), slices)
for i, thingy in pairs(image) do
    runLater(12 * i, function() pings.image(thingy, i, slices) end)
end
end

local a = action_wheel:newPage("beans")
a:newAction():setOnLeftClick(dataUpdate)
action_wheel:setPage(a)
a:newAction():setOnLeftClick(dataSplit)


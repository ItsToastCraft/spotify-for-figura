local images = {}
local base64 = require("libraries.external.base64")
local runLater = require("libraries.external.runLater")
local function packetSplit(inputString, maxSliceSize)
    local length = #inputString
    local slices = {}

    for startIdx = 1, length, maxSliceSize do
        local endIdx = math.min(startIdx + maxSliceSize - 1, length)  -- Calculate end index
        table.insert(slices, string.sub(inputString, startIdx, endIdx))
    end

    return slices
end

local final = ""

function pings.image(data, index, last)
    final = final .. data
    if index == last then
        final = base64.encode(final)
        runLater(20, function()
        if not host:isHost() then -- so it doesn't error on the host and everyone else tells you that your avatar errored :trol:
            textures:read("album", final)
            models.spotify.Head.Camera.Body:setPrimaryTexture("CUSTOM", textures:get("album"))
            final = ""
        end
            end)
        
    end
end
function images.dataSplit(imageData)
    if host:isHost() then
        textures:read("albumHost", imageData)
        models.spotify.Head.Camera.Body:setPrimaryTexture("CUSTOM", textures:get("albumHost"))
    end
    local data = base64.decode(imageData)
    local slices = packetSplit(data, 800)  -- In ideal cirumstances (when the backend is stable), this would be 1000
    for i, chunk in ipairs(slices) do
        runLater(32 * i, function() pings.image(chunk, i, #slices) end)
    end
end
return images
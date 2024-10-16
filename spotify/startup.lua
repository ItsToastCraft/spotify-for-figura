local runLater = require("libraries.external.runLater")

if host:isHost() then
    if not file:exists("spotify") then
        file:mkdir("spotify")
        file:writeString("spotify/cache.json", "")
        file:writeString("spotify/song.json", "")
        file:writeString("spotify/stats.json", "") -- unused for now but I just wanted to add it for a later update :trol:
    end
    
end
runLater(4, function() require("updater") end)
# -THIS IS A WORK IN PROGRESS-

# Spotify for Figura
BEFORE YOU DOWNLOAD THIS
### Errors
Sometimes this errors because I suck at coding :sob:
The code will probably explode at some point
I have no idea how to fix so just wait for an update ig
Uhm I also don't really trust that the http requests are secure so like use at your own risk :skull:
If someone says the avatar errored, just tell them to reload you and then reload yourself from the backend."

If y'all want to fix this be my guest this is atrocious :sob:
##### Known Issues
* Code explodes when loading next song after first song is finished
* Song will not auto update after song is skipped (because the data is requested every minute)
### Start

This is a project that allows you to visualize the currently playing track in figura
To start, create a `client_data.json` file in `figura/data/spotify/client_data.json` and insert a json table of credentials

### Example
```
{
    "id": <CLIENT_ID>,
    "secret", <CLIENT_SECRET>
    "refresh_token": <REFRESH_TOKEN>
}
```
To get the client ID and secret, create a Spotify app [here](https://developer.spotify.com/dashboard).
You can get a refresh token by running the program [here](https://github.com/spotify/web-api-examples/tree/master/authorization/authorization_code).

Once the credentials are provided in `client_data`, the code should automatically create a new token once it expires using the refresh token.

### Visualization
By default, the skull of the player will be a Spotify Display. You can customize this by just retrieving the data provided by the function `album.getSongInfo()` in `albumData.lua`. This function gives info such as the artists, song title, album title, current play time, track duration, etc.
The album cover is stored in `album.cache()` in `albumData.lua` as a base64 string which can be used as a texture. It gets requested from a server and then stored in ``figura/data/spotify/cache.json` so that it doesn't have to request the image again.

By default it will fetch album covers from `https://res.cloudinary.com/toasts/` You can change the size of the image by changing the `size` variable in `albumData.lua`. By default it will not go above 64x64, it's simple to figure out how to get higher quality images up to 640x640 if you look at what a request returns.

### Credits
* [manuel_2867](https://github.com/Manuel-3) - [runLater](https://github.com/Manuel-3/figura-scripts/blob/a598b44bdbed7877f1440d106d91ef1e194bc635/src/runLater/runLater.lua)
* [auriafoxgirl](https://github.com/auriafoxgirl) - base64 library
![Spotify Display in-game](image.png)

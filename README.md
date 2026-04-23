<p align="center">
    <img src="Resources/Textures/Icon/konata_mlg.png"><br>
    Basic RPC chat with BBCode support via Godot!
</p>

<h1>Koteksu</h1>

I wonder what a random chatbox Konata would make on her free time? Mayhaps this kind of thing.

![preview.gif](preview.gif)

## Features
- BBCode styles: https://docs.godotengine.org/en/3.6/tutorials/ui/bbcode_in_richtextlabel.html
- BBCode snippets via buttons
- Responsive UI
- Custom themes (see [Theme](#theme))

## Theme
The Main node now uses the `Default.tres` Theme Resource by default. It is then used by its children nodes.

![theme_resource_preview.png](theme_resource_preview.png)

## Usage
1. To test, export a build first.
2. Have 2 instances of build.
3. Input a username and local address for the host, then press `Host` button.
4. Once the host is done, input the same address but choose `Join` this time.
5. Enjoy testing!

## TO-DO
- [ ] GIF API
- [x] Theme

## Credits
- Konata Izumi edit, Pin: https://www.pinterest.com/pin/konata-and-co--9288742975346064/
- Uses [Ubuntu]() and [Noto Sans Mono]() fonts
- Icons8 *Fill Color* icon: https://icons8.com/icons/set/fill-color--os-android

## License
- Ubuntu is under its [Ubuntu Font License](Resources/Font/Ubuntu/UFL.txt) while Noto Sans Mono on [SIL Open Font License](Resources/Font/Noto_Sans_Mono/OFL.txt).
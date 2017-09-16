# OpenTaiko
Open source, cross-platform Taiko no Tatsujin clone written in the D programming language using SDL 2.0 ([DerelictSDL2][3])

# Compilation
The easiest way to compile and install this would be with DUB and DMD, with a simple "dub build" in the directory the repository was cloned/downloaded to. If you don't have them installed you can download them from [dlang.org][1].
Additionally, on Windows, you'll have to download the required .dll files for SDL2 from [libsdl.org][2] and put them in the same directory as the binary file if you don't have them installed globally, in order for the game to work. SDL2 itself, SDL_Mixer, SDL_Image and SDL_ttf (all version 2) are required. On Linux it should be sufficient to simply install the libsdl2 packages for your system, they should be properly linked for you by default.

Once the game has reached maturity/is actually fun and playable, pre-compiled binaries/packages would be distributed.

# Goals
A platform agnostic Taiko no Tatsujin clone that runs well on most hardware; old or weak hardware in particular, and splendidly on cutting-edge systems.

The ability to map songs by simply editing a text file. Conversion from other map formats should be possible, as well as including other utilities for making the whole process easier.

All contributions are welcome!

[1]: http://dlang.org/
[2]: http://libsdl.org/
[3]: https://github.com/DerelictOrg/DerelictSDL2

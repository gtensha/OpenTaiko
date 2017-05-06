# OpenTaiko
Open source, cross-platform Taiko no Tatsujin clone
Written in the D programming language using SDL 2.0 ([DerelictSDL2][3])

# Installation
The easiest way to compile and install this would be with DUB and DMD, with a simple "dub build" in the directory the repository was cloned/downloaded to. If you don't have them installed you can download them from [dlang.org][1].
Additionally, on Windows, you'll have to download the required .dll files for SDL2 from [libsdl.org][2] and put them in the same directory as the binary file if you don't have them installed globally, in order for the game to work. SDL2 itself, SDL_Mixer, SDL_Image and SDL_ttf (all version 2) are required. On Linux it should be sufficient to simply install the libsdl2 packages for your system, they should be properly linked for you by default.

Once the game has reached maturity/is actually fun and playable, pre-compiled binaries/packages would be distributed, but we're nowhere near there yet...

# Goals
A fully working Taiko no Tatsujin clone with the elements (and more) from the game we all know and love. The main goal of this project is to do just that while being platform agnostic. While Linux, Windows and Mac are obvious targets, other platforms such as devices running Android would be interesting in the long run. But support for the three major personal computer platforms is the biggest priority. Performance is also essential, it should be able to run alright on poorer/older hardware, and run splendidly without hiccups on cutting-edge systems.

It should be easy and pleasant to make your own maps for the songs you love, through the editing of a text file. Utilities to help you along the way could be included in the future.

[1]: http://dlang.org/
[2]: http://libsdl.org/
[3]: https://github.com/DerelictOrg/DerelictSDL2
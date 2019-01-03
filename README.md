# OpenTaiko
Cross-platform drum rhythm game written in the D programming language using SDL2 ([DerelictSDL2][3]) for graphics and SFML2 ([DerelictSFML2][4]) for audio, available under the GNU GPLv3.

## Other languages
* [日本語 (Japanese)](README.jp.md)

## Screenshots

![Song select](screenshot0.png)

![Gameplay](screenshot1.png)

_(Screenshots do not necessarily represent the current state of the game)_

# Getting started
To start using OpenTaiko, you need a compiler, and the necessary dependencies. The acquisition method of these vary from platform to platform. There are currently no binary releases available, as not all the features related to such a release have been decided and implemented yet.

## Compiler
dmd is the only supported compiler right now, but other compilers could work, and support is planned for ldc in particular. Compiling with -release flag will generate a segfaulting binary; only debug builds are supported currently, due to a bug with dmd and derelict-sdl2. This should be fixed at a later time.

## Dependencies
* dmd
* dub
* SDL >= 2.0
* SDL2\_ttf
* SDL2\_image
* ffmpeg, the command line tool (optional, but highly recommended with csfml-audio-2 to automatically convert mp3 files in game)
* csfml-audio-2

csfml-audio-2 is available on all major platforms, and most of the minor platforms too. In case csfml-audio-2 is not available on your current platform, support with SDL2\_mixer is still implemented. You will need this library instead. Please note that music timing is not supported in this case, so the game may not function properly, and audio quality will be reduced (depending on the platform's implementation)

## DUB dependencies
See dub.sdl.

## Platform-specific instructions
Feel free to add your own operating system specific instructions to this list.
If you already have any of the dependencies installed you may of course skip that step.

### Linux
OpenTaiko should compile and run on nearly any Linux distribution.

#### General
Use your package manager to find and install the dependencies listed in the _dependencies_ section. This is usually the extent of all you need to do.

#### Debian/Devuan (stable)
Use apt and install the following packages, if you haven't already:

* libsdl2-2.0-0
* libsdl2-image-2.0-0
* libsdl2-ttf-2.0-0
* libcsfml-audio2.3
* ffmpeg

```
apt install libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-ttf-2.0-0 libcsfml-audio2.3 ffmpeg
```

For dub and dmd, you might want to use the [official installer](https://dlang.org/download.html) from dlang.org, as Debian stable (currently) does not supply them in the package repositories.

```
wget http://downloads.dlang.org/releases/2.x/2.084.0/dmd_2.084.0-0_amd64.deb
```

You should verify the .deb file with the associated .sig before you proceed any further.

```
sudo dpkg -i dmd_2.084.0-0_amd64.deb
```

### Windows
Download the dmd installer from [dlang.org](https://dlang.org/download.html#dmd) (the non-nightly Windows exe is recommended), and follow the installation instructions. You do not need any extras. Select "Do nothing" when prompted to choose Visual Studio Installation. You now have dmd and dub installed.

If you have git installed, you can use it to clone the OpenTaiko repository into your desired directory. If you only wish to test the game, you can download a zip archive instead, as installing and using git on Windows platforms can be tricky. If you chose the zip archive, extract it anywhere you like.

Next, download all the required .dll files and ffmpeg. If you have 64-bit Windows, download the 64-bit libraries, and if you have 32-bit, download the 32-bit ones.
Extract the archives and move the .dll files to the OpenTaiko directory. SDL2 includes several other .dll files; you need to move them all.

* [SDL2](http://libsdl.org/download-2.0.php)
* [SDL2-ttf](https://www.libsdl.org/projects/SDL_ttf/), latest version for Windows under "Runtime Binaries"
* [SDL2-image](https://www.libsdl.org/projects/SDL_image/), do as above, replace or keep zlib when prompted, it shouldn't matter
* [CSFML](https://www.sfml-dev.org/download/csfml/), latest version for Windows, Visual C++/GCC 32/64 bit. Only move the csfml-audio-2.dll file, found in the "bin" directory.

Once you have these moved, download [ffmpeg.exe](https://ffmpeg.zeranoe.com/builds/), latest version, your architecture, with static linking (but dynamic works as well). Find ffmpeg.exe in the "bin" directory in the zip archive. Do as above and place it in the OpenTaiko directory.

Install the [OpenAL redistributable](http://openal.org/downloads/oalinst.zip). In case you don't want to use the installer, you can download one of the [SFML builds](https://www.sfml-dev.org/download/sfml/2.5.1/) and use the openal32.dll included there, as the csfml builds do not bundle it and it is required for the library to work.

If you have successfully completed all the steps above, you may now compile OpenTaiko. Open a command prompt and navigate to the OpenTaiko directory; this can usually be done easily by copying from the address bar in Explorer and pasting it after the cd command (you may have to enclose the path in quotes if it contains spaces), e.g:

```
cd C:\Users\gtensha\Projects\OpenTaiko-0.2
```

Finally, to build OpenTaiko, run dub build with --config="SFMLMixer" and --arch=x86 (for 32-bit) or --arch=x86\_64 (for 64-bit), like so:

```
dub build --config=SFMLMixer --arch=x86_64
```

You may have to wait a couple of seconds the first time as dub fetches dependencies from the package archives; make sure you have a working internet connection during this time.

If the command succeeds, you will find OpenTaiko.exe has appeared in the directory. You may now run it, and hopefully you'll be able to play. If it crashes, go through the steps above once more, and check that you did everything correctly, especially note whether you downloaded 32-bit .dll files or 64-bit ones, as they must match your system architecture.

### BSD
BSD has not been tested but assuming you can get dmd working, it could work, as most BSDs supply the necessary libraries. Apply the same ideas as with Linux.

### MacOS
Unknown, but should work.

## Building
dub is used to build OpenTaiko. dub should be run from your OS' command line, and the working directory set to whereever OpenTaiko was cloned/downloaded to.

```
dub run
```

...will build and run the game.

```
dub build
```

...will build only. Don't forget the
```--config=SFMLMixer```
flag which is currently still required to build with SFML2 audio support (although that requirement will probably be removed in the near future.)

Running either of these commands will place a binary in the current working directory, which can be run directly afterwards.

In general, you do not need to specify the processor architecture you are building on, if you plan to compile for your current machine only. An exception is when building on 64-bit x86 Windows, where this must be specified.
```
--arch=x86_64
```
will build for 64-bit x86. You may combine these as you please:

```
dub build --config=SFMLMixer --arch=x86
```

...will build OpenTaiko with SFML2 audio support for 32-bit x86.

An internet connection is required when building for the first time, as dub dependencies must be downloaded. After that you may work offline as you please. It is also possible to download the code manually, see the links at the top of this document and the dub documentation for more details.

# Goals
OpenTaiko is to be a platform agnostic drum rhythm game that works well on most hardware, including old and/or weak hardware, as well as cutting-edge systems.

The game should be easy and straightforward to use. It should have fun and intuitive features, splitscreen and network multiplayer support, and support different map formats provided by other, similar games.
Its own native map format should be easily editable through a text file, while providing means to make the whole process as painless as possible.

The code should eventually be robust and easy to understand, so that anyone can easily work on the game and its code. But in the meantime, contributions are still welcome, there's a lot to be improved and implemented.

OpenTaiko is free software licensed under the GNU GPLv3. Therefore the components used to make the game must be free as well, so the game could be distributed in both binary and code form entirely as free software.

[3]: https://github.com/DerelictOrg/DerelictSDL2
[4]: https://github.com/DerelictOrg/DerelictSFML2

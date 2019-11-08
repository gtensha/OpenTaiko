module opentaiko.gamevars;

/// Structure for basic game config options
struct GameVars {

    /// Fallback keyboard mapping.
    int[4] defaultKeys;

    /// Display options.
    int[2] resolution; // w * h
    // int maxFPS
    bool vsync; /// ditto

	string assets; /// Directory in assets/ to get custom assets from.
	string language; /// Active language to load.

}

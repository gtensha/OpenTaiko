module opentaiko.gamevars;

/// Structure for basic game config options
struct GameVars {

    /// Keyboard mapping
    int[4] defaultKeys;

    /// Display options
    int[2] resolution; // w * h
    // int maxFPS
    bool vsync; /// ditto

}

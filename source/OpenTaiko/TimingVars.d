module opentaiko.timingvars;

/// A struct that holds millisecond values related to gameplay timing.
struct TimingVars {

	/// Hits will be added (or subtracted) this many milliseconds before
	/// registering.
	int hitOffset;
	/// Hits will have to be this many milliseconds late or early in order to
	/// count as a successful hit.
	uint hitWindow;
	/// As hitWindow, but for hits that will give the highest score.
	uint goodHitWindow;
	/// The size of the window before a hit can be registered. If hit within
	/// this many milliseconds before hitWindow, the hit will be registered as
	/// a miss.
	uint preHitDeadWindow;

}

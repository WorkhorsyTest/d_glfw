

import bindbc.sdl;


import global;


class Stopwatch {
	this(u32 offset) {
		_offset = offset;
		this.reset();
	}

	void reset() {
		_ticks = SDL_GetTicks();
	}

	u32 ticks_since_reset() {
		return SDL_GetTicks() - _ticks;
	}

	bool is_time() {
		return this.ticks_since_reset() >= _offset;
	}

	void print(string message) {
		import helpers : print;
		print(message, this.ticks_since_reset());
	}

	u32 _ticks = 0;
	u32 _offset = 0;
}

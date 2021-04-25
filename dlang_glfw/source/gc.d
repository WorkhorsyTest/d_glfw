
module GC;

import bindbc.sdl;
import global;


u32 Run(bool minimize_memory = false) {
	static import core.memory;

	u32 before = SDL_GetTicks();

	core.memory.GC.enable();
	core.memory.GC.collect();
	if (minimize_memory) {
		core.memory.GC.minimize();
	}
	core.memory.GC.disable();

	return SDL_GetTicks() - before;
}

void Disable() {
	static import core.memory;

	core.memory.GC.collect();
	core.memory.GC.disable();
}

void Enable() {
	static import core.memory;

	core.memory.GC.enable();
}

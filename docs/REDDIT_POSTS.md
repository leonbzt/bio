Bio — Reddit posts for the prototype launch

Four subs. Replace [link] with the itch.io URL before posting. Stagger them over a few days so they don't all land in the same hour.


================================================================
SUB: r/incremental_games
================================================================

TITLE
-----
Made an incremental where placement matters more than numbers. Prototype, one map, looking for feedback.

BODY
----
Solo dev, few months in. The pitch is that you play in the Carboniferous and grow a swamp until the plants drown, pile up, and become coal.

Genre angle: you play life itself as a category, not a character. Each run you pick a starting species and colonize an ecosystem from a single tile out. The grid is 32x48 portrait. Tile placement matters as much as count.

Mechanics come from real paleobiology rather than arbitrary buff stacks. Calamites does about 60% more yield on Wetland than on dry ground because horsetails really did. Mycorrhizal Network adjacent to a plant gives a +20% bond on both sides because mycorrhizae really do that. Real species, real Latin names, real ecological roles. The same logic drives interactions: a giant millipede recycles dead plant matter so the loop keeps moving, fungi feed plants, predators (later) cull herbivores. The strategy is in arranging tiles so these effects stack.

The grid also has emergent structures. Five Tree Ferns in a + cross forms a Fern Grove worth +30% yield on every grove tile. More structures are designed (Mycorrhizal Hub, Old-Growth Stand, Fairy Ring, eventually Coral Reef) but only the Fern Grove is built into this prototype.

Long-term plan is a cross-kingdom evolution tree where playing fungi unlocks animal abilities and playing animals unlocks new plant niches. None of that is built yet. What's in this build is the within-run loop plus a basic prestige that converts your work into Evolution Points for faster restarts.

One map ships, the Coal Swamp. A run is about 10 to 15 minutes. There's a web build so you can try it in a browser tab.

Things I'd love feedback on. Whether the placement-and-adjacency layer feels like real strategy or just flavor on top of a standard tap-and-wait loop. Whether the gauge fill felt earned. Whether you'd replay.

Even "tutorial confused me" or "gauge felt too slow" is useful.

[link]


================================================================
SUB: r/playmygame
================================================================

TITLE
-----
[Web/Android] Bio. 15-min ecology incremental prototype. Want feedback on whether the loop works.

BODY
----
Solo dev. Prototype incremental, a few months in. I want to know if the core idea is worth continuing before I spend another half year on it.

Premise: you grow a Carboniferous swamp until enough plants have died that the biomass becomes coal. Win when the gauge fills.

Things I'm trying to find out:
- Did the tutorial make sense to you
- Did the gauge feel earned, or like grinding
- Would you replay for a faster run

Portrait mobile layout. A phone or a vertical browser window works best. Free.

[link]

Thanks for any time you spare.


================================================================
SUB: r/godot
================================================================

TITLE
-----
Coal-swamp incremental prototype, made solo in Godot 4. Link inside.

BODY
----
A few months building this on my own. It's an incremental where you grow a Carboniferous swamp into coal. Mechanics grounded in real paleobiology. Real species, real biome affinities, adjacency interactions like mycorrhizal fungi boosting plants.

Some Godot bits I built that might be interesting to look at:

A pattern matcher for emergent structures (NxM blocks, rings, 5-tile cross). Tiles get tagged when a pattern forms; bonus systems read those tags.

An action-triggered tutorial overlay that advances on EventBus signals instead of tap-to-advance. Steps can gate themselves too. The "introduce mycelium" hint stays hidden until the player actually has enough biomass to act on it.

Procedural biome tile textures with authored-PNG overrides. BiomeData has a tile_texture field and the renderer prefers it over the procedural fallback.

Custom tooltips via _make_custom_tooltip override so multi-line evolution tree descriptions actually wrap instead of clipping off-screen.

One map playable. Web and Android. Would love feedback. Happy to talk implementation if anyone's curious.

[link]


================================================================
SUB: r/IndieDev
================================================================

TITLE
-----
Solo prototype after a few months. Honest feedback wanted before I commit another six.

BODY
----
Hi. I'm Leon. I've been building an incremental on my own (Godot, no team) for a few months. It's mobile-first, about growing a prehistoric swamp until enough plants have died that the biomass becomes coal.

This is the first build I've shown anyone outside my house. One map playable. The full plan is 4 or 5 geological eras. I haven't built any past the first because I want to find out whether the core loop is actually interesting before another half year goes into it.

What I'd love to hear:
- Whether the loop has a hook for you
- Whether the paleobiology framing landed or felt pretentious
- Where you bounced off if you did

Honest critique is what I'm here for. I'd rather hear "this isn't working" now than later.

[link]

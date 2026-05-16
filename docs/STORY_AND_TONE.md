# Story and Tone

## Voice
**Mythic and scientific.** Like Carl Sagan writing for poets — or Annie Dillard, Lewis Thomas, Robin Wall Kimmerer. The language is grounded in real biological observation but framed at a scale and intensity that makes it feel weighty, almost devotional.

Second-person introspective is the default voice. Occasional shifts to third-person observational for distance.

### What this is NOT
- Not whimsical or cute. No anthropomorphic plants chatting.
- Not grimdark or mock-religious. No "the great life god commands you".
- Not didactic. Avoid lecturing the player on biology.
- Not generic fantasy. No "ancient", "mystical", "primordial" filler adjectives.

### Examples of the voice

```
[After first colonized tile, plantae]
"You unfurl. The light meets the chlorophyll meets the carbon and the carbon stays.
 This is the first deal you made with the world."

[After first prestige]
"The biomass cycles back. The substrate remembers everything you grew.
 In this world, death is just a different shape of life."

[After first herbivore wave]
"Movement on the edge of your territory. Something is hungry.
 You learn that you are food."

[After unlocking fungi]
"The decomposers were already here, waiting.
 They wait for everything."

[After mass extinction event]
"Most of what you built is gone. The world goes on without it.
 So do you, in some form."

[After unlocking animals]
"Something moves on its own now. Not pushed by wind or hunger for light.
 It is hungry for you."

[After Anthropocene era unlock — far future]
"A species learns to ask what it is.
 The asking changes the world more than the asking knew."
```

The voice should feel like the world *noticing itself*. The player isn't the protagonist; life is. The player just rents a role for a while.

## Story delivery mechanism

### Discovery log
A browsable journal in the pause menu. Entries are added automatically when:
- A kingdom is unlocked.
- A niche is unlocked.
- A species is first played.
- A specific event fires for the first time (per kingdom).
- An era transitions.
- A meta-progression milestone is reached (5 prestiges, 50 prestiges, first symbiotic species, etc.).

Each entry is 1–4 sentences. Authored by hand (not procedural). ~50 entries by end of Tier 2 is a reasonable target.

Discovery log shows a count: "Discoveries: 23 / 57". Completionists chase the rest.

### Event flavor text
Event toasts already display `display_name` + `description` from `EventData`. The description field is where flavor lives. Replace the current functional descriptions with mythic-scientific voice:

```
[Current] "A herd has wandered into your territory."

[Proposed] "Bodies move through your light. They take what they take.
            They cannot be reasoned with — only outlasted."
```

Both convey the same gameplay; the proposed version carries voice.

### Era transitions
The richest narrative moments. When an era ends, a 4–8 sentence passage plays before the next era opens. This is the *one* place where it's OK to be a bit more expansive.

```
[Cryogenian → Devonian transition]
"For ages, ice. The fungi held on in cracks and crevices, eating the dead
 of things that died before they had names.

 Then the warm. The seas opened. Something climbed out of the water
 with a structure that could hold itself up.

 You are about to be a plant. You have never been a plant before.
 Begin again."
```

These transitions are the closest the game gets to "cutscenes". Text only, on a black screen, with kingdom-appropriate music swelling.

## Tonal anchors (for writers / Kilo prompts)

When asking Kilo (or any model) to generate flavor text, anchor with this prompt fragment:

> Write in a mythic-scientific voice — grounded in real biological observation but spoken at a scale and weight that makes it feel devotional. Second-person introspective. Avoid generic fantasy adjectives (ancient, mystical, primordial). Avoid whimsy. 1–4 sentences. Reference real biology where possible (chlorophyll, cellulose, hyphae, oxygenation) without lecturing.

## What this is NOT, again

No characters. No dialogue. No quest givers. No NPCs. No skill trees with portraits.

The world has voice but no face. That's the point.

## Open design questions

1. **Discovery-log gating**: should we let the player read entries for content they haven't unlocked yet (with text fields blacked out, just titles shown)? Lean YES — teases content nicely.
2. **Skippable era transitions?** Yes, but make them visually fade-in slowly so a player who skips is consciously choosing to.
3. **Multilingual flavor**: deferred. English-only at launch. Voice is hard to translate; commit to it.

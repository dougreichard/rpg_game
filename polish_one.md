# Polish Pass One — Next Steps

## Gameplay Feel

- **Real audio** — replace the procedural SFX synth with actual WAV/OGG files; add per-location background music tracks. This is the single biggest remaining immersion gap.
- **Playtesting pass** — run all 13 locations end-to-end looking for balance, pacing, and puzzle clarity issues. The stealth/patrol system and timing gates haven't been stress-tested across a full playthrough.
- **Controller support** — the input map has P2 bindings but no gamepad events are wired. A full controller pass (deadzone, rumble) would unlock co-op and couch play.

## Content Gaps

- **Enemy mix per location** — several locations still have "TBD" enemy types in CLAUDE.md. Placing Sentries and Brutes in locations that narratively fit them (Library: Sentry watchtower; Underground: Brute blocking a fork) would immediately add variety without new systems.
- **Endgame moment** — the Grand Marquee Cinema clear currently just triggers ResultScreen. The "Uncle Doug found in the projection booth" payoff has no cutscene, dialogue, or reveal animation. Even a few programmatic frames here would make the ending land.
- **Pocket lantern / dark rooms** — the Underground Tunnels has a `pocket_lantern` item but the "reveals hidden loot boxes in the dark" mechanic was deferred. A darkness layer (a semi-opaque overlay with a cutout around the active player) would be a strong environmental moment in that location.

## Polish

- **Overworld map visual pass** — location nodes are drawn as plain circles with text. Distinct landmark icons per location (procedurally generated shapes matching each location's identity) would make the map readable at a glance.
- **Character select UI** — the select screen exists but has had layout issues. A polished character-swap/preference screen would make the duo system feel more intentional before entering a level.
- **Hit feedback** — the combat FX system has shake and sparks, but adding a brief screen flash on player hurt and a camera recoil on boss slam would make combat hits feel heavier.

## Infrastructure

- **Export build** — configure Godot export presets and verify a macOS `.app` or Windows `.exe` runs cleanly outside the editor.
- **Options/settings menu** — volume sliders (master/SFX/music), possibly key rebinding, accessible from the pause menu.

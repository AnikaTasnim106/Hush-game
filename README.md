# HUSH
A girl, a brass bell, and a town that went silent. By Anika, for thatgamejam #02.

## Play
- Windows: unzip HUSH_Windows.zip, then open HUSH.exe. Godot is not required.
- Browser: upload HUSH_itch_browser.zip to an itch.io project set to HTML. Tick “This file will be played in the browser”. Use a 1280 × 720 viewport and enable fullscreen. The ZIP has index.html at its root. Desktop keyboard required. WebGL 2 required. Single-thread export; no cross-origin isolation setup required.
- Source: import project.godot in Godot 4.5 and press F5. Export presets are included; install the official Godot 4.5 export templates to export again.

## Controls
A/D or arrows: move. Space/W: jump; hold to glide after Chapter One. Hold Jump inside a restored mill's wind to rise. J: ring bell. S/K in air: stomp. S+Space: drop through a ledge. E/Enter: talk. Tab: journal; Left/Right changes the chapter archive. Esc or the menu button: pause/settings. M or speaker button: mute. Sound settings save locally. Mouse clicks only operate menus.

Click any of the four chapter cards on the title to start there, or press 1–4. Space starts Chapter One. A chapter end card continues to the next chapter, keeping notes, collected song pages and clues. Hearts refill. Chapter select starts a fresh run; collect all pages in one continuous run to see the true ending.

## Four chapters
1. The Lantern Market — townsfolk, rooftops and The Mute Bell.
2. Windmill Fields — updrafts, gliding, a fog chase and The Scarecrow Choir.
3. The Sunken Concert Hall — Listeners, rafts, chandeliers and The Hollow Organ.
4. The Silent Tower — a vertical clock-tower climb, three festival memories and The Hush Heart.

## Endings (spoilers)
At the Heart's final choice, keep ringing for The Quiet Town, or hold Down/S on the ground to lower the bell. Then walk right toward Lark, jumping the pale waves. Lowering the bell with fewer than 12 song pages leads to Not Yet. Find every page (0–11) and lower the bell for The Song Goes On.

The true ending plays the full 60-second Jason Grace theme once, at its original speed. The supplied WAV uses an extensible header unsupported by Godot 4.5; theme_track.wav repackages that header while preserving every original 24-bit PCM audio sample. theme_track_original.bin contains the complete original uploaded file, byte for byte, for provenance. The song is not cut, looped, remixed or layered with effects. Applause starts only after playback finishes.

## Development and verification
`godot --headless --path . --fixed-fps 120 -- --chapter 2 --autoplay`
Use chapters 1–4. `--pagetest` checks chapter page routes; `--shot` saves visual review images. Chapter Four ending branch checks: `--chapter 4 --autoplay --finaltest`, add `--ending-a` for A or `--all-pages` for the true ending. These are development flags, not player controls.

See TEST_REPORT.md for exactly what was verified and the remaining platform-test limits. The source contains original procedural art and sound generators. Re-running tools/make_sfx.py requires Python and NumPy. It never regenerates or edits the theme.

## Credits
Anika. AI assistance: Claude (Chapters One and Three and original systems), OpenAI Codex (Chapters Two and Four, menus, integration and testing). Assistance covers code, procedural art, generated sound effects and writing. Theme: Jason Grace, thatgamejam #02. Fonts: Fraunces and Nunito, SIL Open Font License (licences included).

# HUSH verification — 24 October 2026

## Passed
- Godot 4.5 headless editor import: no script parse/compile errors.
- Chapter One full input-driven bot: reached end card, exit 0.
- Chapter Two full input-driven bot: all three rescues, chase, pond, Scarecrow Choir, end card; exit 0.
- Chapter Three full input-driven bot: flooded hall, three rescues, organ stops, end card; exit 0. Automatic page popups no longer pause the bot indefinitely.
- Chapter Four full input-driven bot: clock stairs, all three echoes, Hush Heart and Not Yet credits; exit 0.
- Scoped final-arena input-driven tests for The Quiet Town and true ending: credits reached, exit 0. These do not claim a full continuous all-pages human run.
- All four chapter page routes: [0,1,2], [3,4,5], [6,7,8], [9,10,11]. Tests start at local route checkpoints and use player input to jump/rise/glide/stomp to each pickup; they do not grant those pages directly.
- True ending: complete 60-second track playback finished before clap trigger. Original uploaded WAV kept byte for byte as theme_track_original.bin. The playable WAV has a standard PCM header; the full original PCM payload has SHA-256 6fecb906c400ea9fa6636f7909bf5a33d16255a498d3f106003e1ab7f3acc6bb.
- Native OpenGL screenshots reviewed for restored fields/glide, choir, journal, tower and ending staging. HUD controls moved away from statistics.
- Windows release export: successful, embedded game pack, valid x86-64 PE executable.
- Web release export: successful, single-threaded WebGL 2; index.html and required files at ZIP root.
- Actual exported Web build launched in Chromium 150 headless shell: WebGL 2 initialization, title, clickable chapter cards, settings panel and chapter loading; no browser console errors. AudioContext starts after a player gesture, as required by browsers.
- Left mouse button removed from strike and dialogue advance mappings; menu clicks cannot ring the bell.

## Platform and polish limits
- Native Windows launch was attempted through Wine, but the test host blocks the Unix socket Wine requires. The Windows export was structurally checked, not run on a real Windows desktop. Please perform a Windows double-click smoke test before submitting.
- Browser smoke checks are not a full four-chapter browser playthrough. The full chapter runs used the same game scripts in native Godot.
- Godot reports resource-cleanup warnings on automated exit (ObjectDB/resources/PagedAllocator); the completed runs still exit 0. No claim is made that engine shutdown diagnostics are fully clean.
- Total human play time has not been measured. Difficulty, gamepad feel and browser performance across devices still benefit from human playtesting.
- macOS was not exported: the requested deliverables are Windows, browser and source.

## Included development checks
Use --chapter N --autoplay, --chapter N --pagetest, and --chapter N --shot after the Godot -- separator. Finale test flags are documented in README.md. Screenshots in screenshots/ can help prepare the itch page.

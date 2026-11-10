# Little Reef

Little Reef is a pixel-art aquarium game for Godot 4.7. It is a port of the Aquarium v2 design from Claude Design. You feed, clean, decorate, breed and collect fish. Your tank keeps running while you are away.

Play it in your browser: https://bjarneo.github.io/little-reef/

## Run the game

Open the project in the Godot 4.7 editor and press F5. To run it from a terminal, use this command:

```sh
godot --path .
```

## Controls

| Action | Desktop | Touch |
| --- | --- | --- |
| Pick a tool | Keys `1` to `4`, or the tool bar | The tool bar |
| Inspect a fish | Click it with Look | Tap it with Look |
| Zoom | Mouse wheel, `+` and `-`, or the zoom buttons | Pinch, or the zoom buttons |
| Pan a large tank | Drag with Look, right-drag, or the arrow keys | Drag with Look, or drag with two fingers |
| Close a panel | `Esc` | The CLOSE button |

## What is new compared to the design

- Five new fish. Goby, Angel, Tang and Betta are in the shop. Lantern comes only from breeding, and its lure glows at night.
- The keeper. A large pixel-art portrait of the keeper rises from behind the tank every one to three minutes. It looks in through the back glass, blinks and smiles now and then. Tap the face with Look for a tip and 5 coins.
- Seven new decorations: starfish, moss ball, driftwood, amphora, anemone, diver and castle. The moss ball is a plant and cleans the water. The diver sends up bubbles. Each "Bigger tank" level holds more decorations, up to 30.
- A larger Clean tool. It siphons waste within 14 tank pixels and scrubs algae within 17 tank pixels.
- A bigger tank. Each "Bigger tank" upgrade makes the tank wider and taller, and the camera zooms out to show it. Zoom in to see the fish up close.
- Three new achievements: Say Hello, Mixed Shoal and Glow Up. A fourth achievement, Curator, fills 40 book entries.

## Export for the web

The web build is single-threaded. It runs on any static host and does not need cross-origin isolation headers. It also runs in mobile browsers.

1. Install the Godot 4.7.2 web export templates. The export needs `web_nothreads_release.zip` and `web_nothreads_debug.zip` in `~/.local/share/godot/export_templates/4.7.2.stable/`.
2. Export the build:

   ```sh
   godot --headless --path . --export-release "Web" build/web/index.html
   ```

3. Test the build on your computer:

   ```sh
   python3 -m http.server 8765 --directory build/web
   ```

   Then open `http://127.0.0.1:8765/`.

4. Upload the contents of `build/web/` to a static host, for example GitHub Pages, Netlify, Cloudflare Pages or itch.io. For itch.io, zip the folder and upload it as an HTML game.

The host must serve `.wasm` files as `application/wasm`. Most static hosts do this by default.

## Save data

The game saves to `user://little-reef-save.json`. In a browser, this file is in IndexedDB for the page's origin. To start again, open Awards and use RESET TANK.

## Project layout

- `scripts/game.gd` holds the simulation, the camera, saving and the keeper.
- `scripts/sprites.gd` builds every fish and decor sprite at runtime.
- `scripts/keeper_art.gd` holds the keeper portrait: a neutral, a smile and a blink frame.
- `scripts/face_view.gd` draws the keeper behind the back glass.
- `scripts/tank_view.gd` and `scripts/overlay_view.gd` draw the tank into a low-resolution viewport.
- `scripts/tank_display.gd` shows that viewport and handles mouse, touch and pinch input.
- `scripts/hud.gd`, `scripts/ui.gd` and `scripts/px_button.gd` build the interface.
- `scripts/synth.gd` synthesizes all sound effects and music at runtime.
- `shaders/` holds the background and algae shaders.

## Fonts

Pixelify Sans and Silkscreen use the SIL Open Font License. The license files are in `fonts/`.

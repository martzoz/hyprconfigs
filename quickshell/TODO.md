# YoRHa HUD — TODO

## Next up
1. **Player.qml redesign** — centred floating panel, CRT snap animation (compress to thin sepia line with spark on close, like an old CRT turning off)
2. **Triangle visualiser** — re-enable and optimise TriangleViz.qml. Currently commented out in Audio.qml. Fix: only repaint when max bar delta since last frame exceeds ~3 units. See PERFORMANCE.md for full notes.
3. **Disk status widget** — drives: Internal, Nipaa, BigBoy, Garbage Speed, Peony, Noppy. Design once when building the statusbar — small segment there + full widget later.
4. **Volume control widget** — replace pavucontrol, themed to match HUD
5. **Waybar → Quickshell bar** — replace waybar entirely, expandable top bar with calendar/stats + disk status segment
6. **Notification styling** — Notifications.qml works but uses light sepia theme; retheme to dark HUD style
7. **Theme switcher** — toggle between dark tactical HUD and light paperink NieR themes
8. **Game launcher** — NieR-styled grid of covers, Lutris integration
9. **Yazi rice** — match the HUD aesthetic in the file explorer

## Polish / revisit
- **Ticker scanlines** — 5 thin bands on COMMS/TACTICAL. Undecided — revisit when vibe-checking full HUD.
- **Flying comment misfire** — `flyingModel.remove(index)` can misfire if two animations finish simultaneously. Fix if ghost items appear.
- **Cava tuning** — `sensitivity=100`, `noise_reduction=65`, power curve `0.65`, 120fps, `sleep_timer=5`. Dial if music genres feel off.
- **Menu.qml + ControlCenter.qml** — noted as slow, not yet investigated.
- **scanY timer** — currently 16ms, could be slowed to 32ms for minor saving. Low priority.

## Already done ✓
- All 4 panels fully built and working
- Modularised into separate files
- Menu.qml terminal app launcher fix
- All panel animations fixed and smooth
- COMMS sine waves, history graphs, diagnostics, signal bars, coordinates, IP
- TACTICAL scramble animation, colour-coded log entries
- COMBAT sparklines, pixel grid, threat level, status row
- Per-panel IPC toggles — `hud toggle/combat/comms/tactical/audio`
- binds.conf cleanup — dead weight stripped, conflicts resolved
- Tactical live diagnostics — MULLVAD + MINECRAFT with SYNC/SCAN/WARN states
- Tactical ticker rewritten — live panel state + service status
- AUDIO album art background with right-edge fade, 3 scrolling text rows
- AUDIO Nico-style flying track title comments
- AUDIO triangle visualiser built — audio-reactive, palette edges, sweep (disabled pending optimisation)
- Cava: 120fps, sleep_timer=5, noise_reduction=65, power curve, always running
- **Performance pass** — all timers gated on visibility, hardware polling delayed 500ms on reveal
- **Idle CPU: ~2%, active CPU: ~6-7%**
- COMMS wave canvas throttled to 40fps, x loop step 2

## Known quirks & notes
- Animation mashing: rapid panel toggles can glitch mid-animation. Fix: add `.stop()` calls before starting opposing animation in each `onShowXChanged` handler in SystemHUD.qml.
- Scanline modulo set to `900` in SystemHUD.qml.
- Player.qml has a duplicate IpcHandler warning on load — pre-existing, investigate during redesign.
- See PERFORMANCE.md for full performance audit and mitigation notes.

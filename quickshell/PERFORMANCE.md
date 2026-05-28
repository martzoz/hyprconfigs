# YoRHa HUD — Performance Notes

## Baseline
- CPU target: ≤3% idle (all panels hidden), ≤8% active (all panels visible)
- RAM: ~500-900MB (not a concern, 64GB DDR5)
- Monitor: DP-1 @ 165hz

---

## Known Performance Costs

### COMMS — Sine Wave Canvas
**Cost:** High. 1220×420px canvas, 6 waves, Math.sin per pixel.
**Mitigation:**
- Canvas repaint throttled to 40fps (25ms timer) via local Timer instead of binding to wavePhase
- Inner x loop steps by 2 instead of 1 (half the sin calculations)
- wavePhase timer slowed to 20ms (50fps), increment adjusted to 0.05 to keep wave speed consistent
- Canvas only runs when COMMS is visible (`running: root.showComms`)
**Notes:** Do NOT bind onPhaseChanged directly to requestPaint() — that was firing 60-120x/second on a 1220px canvas.

### AUDIO — Triangle Visualiser (TriangleViz.qml)
**Cost:** Very high. Canvas repainting on every cava update (120fps) across a 12×6 grid.
**Status:** Currently commented out in Audio.qml pending a better repaint strategy.
**Mitigation attempted:**
- Reduced grid from 36×18 → 24×12 → 12×6
- Replaced 50ms unconditional timer with data-driven repaints (on cavaBars change)
- Ripple replaced with slower sweep animation
**Remaining issue:** Even at 12×6, canvas repaints driven by 120fps cava data is too expensive during wipe animations.
**TODO:** Re-enable with a repaint threshold — only repaint if max bar delta since last frame exceeds ~3 units. This would reduce repaints dramatically during quiet passages.

### AUDIO — Cava Data Pipeline
**Cost:** Medium. Was running at 165fps, killing/restarting caused audio pop on toggle.
**Mitigation:**
- Framerate reduced to 120fps
- sleep_timer=5 (idles quietly instead of being killed)
- cava now runs always (no more audio pop on reveal)
- smoothBars lerp timer removed — cava's own noise_reduction=65 handles smoothing
- Power curve (Math.pow x 0.65) applied at render time only, not in data pipeline

### SystemHUD — Timer Proliferation
**Cost:** High at idle. Multiple 16ms timers running unconditionally even with all panels hidden.
**Mitigation — all timers gated on panel visibility:**
| Timer | Runs when |
|-------|-----------|
| scanY (16ms) | COMBAT or TACTICAL visible |
| tick (500ms) | COMBAT visible |
| logIndex (3500ms) | TACTICAL visible |
| wavePhase/smoothDl/smoothUl (20ms) | COMMS visible |
| hardware polling (2000ms) | any panel visible, delayed 500ms after reveal |
| cava (always) | always — stopping caused audio pop |

**Result:** Idle CPU dropped from ~15% to ~2%.

### Hardware Polling — Reveal Stutter
**Issue:** All processes firing simultaneously on reveal competed with wipe animation causing stutter.
**Mitigation:** 500ms delay via `pollDelayTimer` before `hardwareTimer` starts after reveal.

---

## General Rules

- **Never bind Canvas.requestPaint() directly to a fast-changing property** — use a throttled Timer instead.
- **Never use `running: true` on 16ms timers unconditionally** — always gate on relevant panel visibility.
- **Canvas inner loops** — step by 2 or more for large canvases. Visually indistinguishable on smooth curves.
- **Property array writes** (smoothBars, history arrays) — each write triggers all QML bindings on that property. Keep them infrequent or eliminate where possible.
- **WlrLayer.Bottom** — bottom layer windows don't get the same compositor optimisations as Overlay. This is a hard limit; we can't change it without losing the behind-windows aesthetic.

---

## CPU Utilisation Log
| State | Before optimisation | After optimisation |
|-------|--------------------|--------------------|
| All hidden | ~15-20% | ~2% |
| All visible (no triangles) | ~15% | ~6-7% |
| All visible (with triangles) | very laggy | disabled |

---

## Future Investigations
- **COMBAT sparkline canvases** — three history graph canvases updating every 2s. Low priority but worth checking.
- **HudPanel scanline overlay** — scanY timer drives a Rectangle y position at 16ms. Cheap but could be slowed to 32ms without visible difference.
- **Player.qml** — not yet audited for performance. IpcHandler duplicate warning suggests something is registered twice.

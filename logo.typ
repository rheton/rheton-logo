// Rheton logo: square-wave pulse icon (a straight-edged rising/falling
// signal — horizontal, ramp, horizontal, vertical, horizontal), optionally
// paired with the "rheton" wordmark. bg/text/text-color are wired up as
// CLI --input flags in generate.sh:
//
//   typst compile --input bg=black --input text=true \
//     --format png --ppi 300 sketch-wave.typ out.png
//
//   typst compile --input bg=white --input text=false \
//     --format svg sketch-wave.typ out.svg

// -- CLI-controlled arguments ------------------------------------------
#let bg = sys.inputs.at("bg", default: "black")       // "black" | "white" | "transparent"
#let show-text = sys.inputs.at("text", default: "true") == "true"
// Only used when bg == "transparent" — with a black/white background the
// wordmark color is forced for contrast (see fg-color below) instead.
#let text-color = sys.inputs.at("text-color", default: "black") // "black" | "white"
// -----------------------------------------------------------------------

// -- code-only tuning ----------------------------------------------------
// Icon size relative to the wordmark. 1.0 = icon's natural size; lower it
// if the icon looks too big next to "rheton", raise it to make the icon
// more dominant. Not exposed via generate.sh — edit this value directly.
#let icon-scale = 0.5
// -----------------------------------------------------------------------

#let bg-color = if bg == "white" {
  rgb("#FFFFFF")
} else if bg == "transparent" {
  none
} else {
  rgb("#000000")
}
// Black/white backgrounds force a contrasting wordmark color; a
// transparent background has no fixed contrast, so the caller picks
// black or white text via --text-color depending on where the logo will
// be placed.
#let fg-color = if bg == "black" {
  rgb("#FFFFFF")
} else if bg == "white" {
  rgb("#000000")
} else if text-color == "white" {
  rgb("#FFFFFF")
} else {
  rgb("#000000")
}

#let page-margin = 28pt
#set text(font: "Hanken Grotesk")

// -- wave icon -------------------------------------------------------------
// Same contrasting color as the wordmark (black/white, forced against a
// black/white background or picked via --text-color against transparent)
// rather than a fixed brand color, so the icon stays visible on any bg.
#let stroke-color = fg-color
#let base-thickness = 20pt

// Natural (icon-scale = 1.0) shape — 5 segments: horizontal, ramp,
// horizontal, vertical, horizontal. See sketch-wave's original standalone
// version for how each of these controls the shape.
#let baseline-y = 150pt // bottom of the icon (segments 1 and 5)
#let height = 130pt     // vertical rise from baseline to plateau
#let seg1-len = 50pt
#let ramp-run = 40pt    // steepness is height / ramp-run
#let seg3-len = 80pt
#let seg5-len = 50pt
// -----------------------------------------------------------------------

// The wordmark's size is derived from the icon's *natural* (unscaled)
// height, so icon-scale only resizes the icon and doesn't affect the text.
#let text-size = baseline-y * 0.73

// icon-scale shrinks/grows the icon itself (every length + the stroke
// thickness) rather than using a layout transform, so the strokes stay
// crisp at any size.
#let s(len) = len * icon-scale
#let icon-w = s(seg1-len) + s(ramp-run) + s(seg3-len) + s(seg5-len)
#let icon-h = s(baseline-y)
#let top-y = icon-h - s(height)

#let x0 = 0pt
#let x1 = x0 + s(seg1-len)
#let x2 = x1 + s(ramp-run)
#let x3 = x2 + s(seg3-len)
#let x4 = x3 + s(seg5-len)

#let anchors = (
  (x0, icon-h),
  (x1, icon-h),
  (x2, top-y),
  (x3, top-y),
  (x3, icon-h),
  (x4, icon-h),
)

#let segs = (curve.move(anchors.at(0)),)
#for p in anchors.slice(1) { segs.push(curve.line(p)) }

#let icon = box(width: icon-w, height: icon-h)[
  #place(top + left)[
    #curve(
      stroke: (paint: stroke-color, thickness: s(base-thickness), join: "round", cap: "round"),
      ..segs,
    )
  ]
]

#let wordmark = text(
  fill: fg-color,
  size: text-size,
  weight: "bold",
  tracking: 0.6pt,
)[rheton]

// Icon-only renders get a square canvas (sized to the icon's longer
// side) so the mark sits centered with even padding on all sides,
// instead of the wide rectangle its natural (non-square) shape would
// otherwise auto-size the page to. The wordmark lockup keeps auto-sizing
// to its own (wider) content.
#let square-side = calc.max(icon-w, icon-h) + 2 * page-margin
#set page(
  width: if show-text { auto } else { square-side },
  height: if show-text { auto } else { square-side },
  margin: page-margin,
  fill: bg-color,
)

#align(center + horizon)[
  #if show-text {
    stack(
      dir: ltr,
      spacing: baseline-y * 0.12,
      align(horizon)[#icon],
      align(horizon)[#wordmark],
    )
  } else {
    icon
  }
]

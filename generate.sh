#!/usr/bin/env bash
# Generate the rheton logo (sketch-wave.typ) with a chosen background,
# output format, and with/without the wordmark.
#
# Usage:
#   ./generate.sh [--bg black|white|transparent] [--format png|svg]
#                  [--text|--no-text] [--text-color black|white]
#                  [--ppi N] [-o OUTPUT]
#
# Every flag is a *filter*: omit it and that dimension is swept in full,
# pass it and the sweep is narrowed to just that value. So no arguments
# sweeps everything (14 files), and pinning every dimension (as below)
# narrows the sweep down to exactly one file, which is when -o is allowed.
#
# --text-color only matters for bg=transparent, text=true combinations
# (with black/white backgrounds the wordmark/icon color is forced for
# contrast); it's ignored (and not swept) for every other combination.
#
# Icon size relative to the wordmark is a code-only setting — see
# icon-scale in sketch-wave.typ — not exposed here.
#
# Examples:
#   ./generate.sh                                    # every combination (14 files)
#   ./generate.sh --bg white --format svg --no-text
#   ./generate.sh --bg black --format png --text -o build/rheton-dark.png
#   ./generate.sh --bg transparent --format png --no-text
#   ./generate.sh --bg transparent --format png --text --text-color white

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
typ_file="$script_dir/logo.typ"
out_dir="$script_dir/output"
export TYPST_FONT_PATHS="$script_dir/fonts"

mkdir -p "$out_dir"

usage() {
  sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'
}

# Renders one bg x format x text x text-color combination.
render_one() {
  local bg="$1" format="$2" text="$3" text_color="${4:-black}"

  local out="$output"
  if [[ -z "$out" ]]; then
    local text_suffix="with-text"
    [[ "$text" == "false" ]] && text_suffix="icon-only"
    local color_suffix=""
    [[ "$bg" == "transparent" && "$text" == "true" ]] && color_suffix="-${text_color}-text"
    out="$out_dir/rheton-${bg}-${text_suffix}${color_suffix}.${format}"
  fi

  local args=(compile --input "bg=$bg" --input "text=$text" --input "text-color=$text_color" --format "$format")
  if [[ "$format" == "png" ]]; then
    args+=(--ppi "$ppi")
  fi
  args+=("$typ_file" "$out")

  typst "${args[@]}"
  echo "Wrote $out"
}

# -- defaults: every dimension swept in full unless a flag narrows it -----
bgs=(black white transparent)
formats=(png svg)
texts=(true false)
text_colors=(black white)
ppi="300"
output=""
# ---------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bg)
      bgs=("$2"); shift 2 ;;
    --bg=*)
      bgs=("${1#*=}"); shift ;;
    --format)
      formats=("$2"); shift 2 ;;
    --format=*)
      formats=("${1#*=}"); shift ;;
    --text)
      texts=(true); shift ;;
    --no-text)
      texts=(false); shift ;;
    --text-color)
      text_colors=("$2"); shift 2 ;;
    --text-color=*)
      text_colors=("${1#*=}"); shift ;;
    --ppi)
      ppi="$2"; shift 2 ;;
    --ppi=*)
      ppi="${1#*=}"; shift ;;
    -o|--output)
      output="$2"; shift 2 ;;
    -o=*|--output=*)
      output="${1#*=}"; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1 ;;
  esac
done

for bg in "${bgs[@]}"; do
  if [[ "$bg" != "black" && "$bg" != "white" && "$bg" != "transparent" ]]; then
    echo "Error: --bg must be 'black', 'white', or 'transparent' (got '$bg')" >&2
    exit 1
  fi
done
for format in "${formats[@]}"; do
  if [[ "$format" != "png" && "$format" != "svg" ]]; then
    echo "Error: --format must be 'png' or 'svg' (got '$format')" >&2
    exit 1
  fi
done
for text_color in "${text_colors[@]}"; do
  if [[ "$text_color" != "black" && "$text_color" != "white" ]]; then
    echo "Error: --text-color must be 'black' or 'white' (got '$text_color')" >&2
    exit 1
  fi
done

# Count how many files this sweep would produce, so -o (a single explicit
# path) can be rejected if it would be reused across multiple renders.
combo_count=0
for bg in "${bgs[@]}"; do
  for format in "${formats[@]}"; do
    for text in "${texts[@]}"; do
      if [[ "$bg" == "transparent" && "$text" == "true" ]]; then
        combo_count=$((combo_count + ${#text_colors[@]}))
      else
        combo_count=$((combo_count + 1))
      fi
    done
  done
done

if [[ -n "$output" && "$combo_count" -ne 1 ]]; then
  echo "Error: -o/--output needs a single combination, but the given filters match $combo_count. Add more filters (--bg/--format/--text/--text-color) to narrow it to one." >&2
  exit 1
fi

for bg in "${bgs[@]}"; do
  for format in "${formats[@]}"; do
    for text in "${texts[@]}"; do
      if [[ "$bg" == "transparent" && "$text" == "true" ]]; then
        for text_color in "${text_colors[@]}"; do
          render_one "$bg" "$format" "$text" "$text_color"
        done
      else
        render_one "$bg" "$format" "$text"
      fi
    done
  done
done

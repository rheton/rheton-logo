#!/usr/bin/env bash
# Generate the rheton logo (logo.typ) with a chosen background, output
# format, and with/without the wordmark.
#
# Usage:
#   ./generate.sh [--bg black|white|transparent] [--format png|svg]
#                  [--text|--no-text] [--text-color black|white]
#                  [--corners sharp|rounded] [--ppi N] [-o OUTPUT]
#
# Every flag is a *filter*: omit it and that dimension is swept in full,
# pass it and the sweep is narrowed to just that value. So no arguments
# sweeps everything (24 files), and pinning every dimension (as below)
# narrows the sweep down to exactly one file, which is when -o is allowed.
#
# Output filenames are `{shape}_{color}_{bg}[_r].{ext}`:
#   shape: icon (--no-text) | wordmark (--text)
#   color: b|w — the icon/text color. Forced by --bg (black bg -> w,
#     white bg -> b); free to pick via --text-color only on a
#     transparent background, which is the only case both b and w
#     actually get generated.
#   bg:    b|w|t — black | white | transparent
#   _r:    only appended for icon shapes rendered with --corners rounded
#     (sharp is the default and stays untagged)
# Examples: icon_w_b.png (icon, white, on black), wordmark_b_t.svg
# (wordmark, black text, on transparent), icon_b_t_r.png (icon, black,
# on transparent, rounded corners).
#
# Icon size relative to the wordmark is a code-only setting — see
# icon-scale in logo.typ — not exposed here.
#
# Examples:
#   ./generate.sh                                    # every combination (24 files)
#   ./generate.sh --bg white --format svg --no-text
#   ./generate.sh --bg black --format png --text -o build/wordmark_w_b.png
#   ./generate.sh --bg transparent --format png --no-text
#   ./generate.sh --bg transparent --format png --text --text-color white
#   ./generate.sh --no-text --corners rounded

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
typ_file="$script_dir/logo.typ"
out_dir="$script_dir/output"
export TYPST_FONT_PATHS="$script_dir/fonts"

mkdir -p "$out_dir"

usage() {
  sed -n '2,37p' "$0" | sed 's/^# \{0,1\}//'
}

# The icon/text color isn't a free choice against a black or white
# background — it's forced for contrast — so only a transparent
# background actually has two color variants to sweep.
colors_for_bg() {
  case "$1" in
    black) echo white ;;
    white) echo black ;;
    transparent) printf '%s\n' "${text_colors[@]}" ;;
  esac
}

# Renders one bg x format x text x color x corners combination.
render_one() {
  local bg="$1" format="$2" text="$3" color="$4" corners="${5:-sharp}"

  local out="$output"
  if [[ -z "$out" ]]; then
    local shape="wordmark"
    [[ "$text" == "false" ]] && shape="icon"
    local base="${shape}_${color:0:1}_${bg:0:1}"
    [[ "$shape" == "icon" && "$corners" == "rounded" ]] && base="${base}_r"
    out="$out_dir/${base}.${format}"
  fi

  local args=(compile --input "bg=$bg" --input "text=$text" --input "text-color=$color" --input "corners=$corners" --format "$format")
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
text_colors=(black white) # only actually used for a transparent bg
corners_opts=(sharp rounded)
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
    --corners)
      corners_opts=("$2"); shift 2 ;;
    --corners=*)
      corners_opts=("${1#*=}"); shift ;;
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
for corners in "${corners_opts[@]}"; do
  if [[ "$corners" != "sharp" && "$corners" != "rounded" ]]; then
    echo "Error: --corners must be 'sharp' or 'rounded' (got '$corners')" >&2
    exit 1
  fi
done

# Count how many files this sweep would produce, so -o (a single explicit
# path) can be rejected if it would be reused across multiple renders.
combo_count=0
for bg in "${bgs[@]}"; do
  n_colors=0
  while IFS= read -r _; do n_colors=$((n_colors + 1)); done < <(colors_for_bg "$bg")
  for format in "${formats[@]}"; do
    for text in "${texts[@]}"; do
      if [[ "$text" == "false" ]]; then
        combo_count=$((combo_count + n_colors * ${#corners_opts[@]}))
      else
        combo_count=$((combo_count + n_colors))
      fi
    done
  done
done

if [[ -n "$output" && "$combo_count" -ne 1 ]]; then
  echo "Error: -o/--output needs a single combination, but the given filters match $combo_count. Add more filters (--bg/--format/--text/--text-color/--corners) to narrow it to one." >&2
  exit 1
fi

for bg in "${bgs[@]}"; do
  mapfile -t colors < <(colors_for_bg "$bg")
  for format in "${formats[@]}"; do
    for text in "${texts[@]}"; do
      for color in "${colors[@]}"; do
        if [[ "$text" == "false" ]]; then
          for corners in "${corners_opts[@]}"; do
            render_one "$bg" "$format" "$text" "$color" "$corners"
          done
        else
          render_one "$bg" "$format" "$text" "$color"
        fi
      done
    done
  done
done

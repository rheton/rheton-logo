# rheton-logo

Generates the Rheton logo (a square-wave pulse icon, optionally paired with the
"rheton" wordmark) as PNG or SVG, in a few background/text variants.

## Usage

```
./generate.sh                                    # every combination (24 files)
./generate.sh --bg white --format svg --no-text
./generate.sh --bg black --format png --text -o build/wordmark_w_b.png
./generate.sh --no-text --corners rounded         # app-icon-style rounded square
```

Every flag (`--bg`, `--text`/`--no-text`, `--text-color`, `--corners`,
`--format`) is a filter: omit it and that dimension is swept in full, pass it
and the sweep narrows to just that value. Run `./generate.sh --help` for the
full list. Requires [Typst](https://typst.app) on `PATH`.

### Output naming

Generated files are named `{shape}_{color}_{bg}[_r].{ext}`:

- `shape` — `icon` (icon only) or `wordmark` (icon + "rheton" text)
- `color` — `b`/`w`, the icon/text color. This is forced by the background
  for contrast (black bg → white, white bg → black), so it's only ever a
  free choice — via `--text-color` — on a transparent background.
- `bg` — `b`/`w`/`t` for black/white/transparent
- `_r` — only appended to `icon` shapes rendered with `--corners rounded`
  (sharp corners are the default and stay untagged)

For example: `icon_w_b.png` (icon, white, on black), `wordmark_b_t.svg`
(wordmark, black text, on transparent), `icon_b_t_r.png` (icon, black, on
transparent, rounded corners).

## Licensing

This repository contains two different things, under two different licenses:

- **Code** (`generate.sh`, `logo.typ`, and the rest of the generator) is
  open-source under the [MIT license](LICENSE).
- **The Rheton logo itself**, including the mark's design and any rendered
  output (the PNG/SVG files this generator produces), is proprietary brand
  material. See [LOGO-LICENSE](LOGO-LICENSE). Being able to read or run the
  code that draws the logo does not grant any rights to the logo as a brand
  asset.

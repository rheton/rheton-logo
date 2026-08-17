# rheton-logo

Generates the Rheton logo (a square-wave pulse icon, optionally paired with the
"rheton" wordmark) as PNG or SVG, in a few background/text variants.

## Usage

```
./generate.sh                                    # every combination (14 files)
./generate.sh --bg white --format svg --no-text
./generate.sh --bg black --format png --text -o build/rheton-dark.png
```

Run `./generate.sh --help` for the full list of flags. Requires
[Typst](https://typst.app) on `PATH`.

## Licensing

This repository contains two different things, under two different licenses:

- **Code** (`generate.sh`, `logo.typ`, and the rest of the generator) is
  open-source under the [MIT license](LICENSE).
- **The Rheton logo itself**, including the mark's design and any rendered
  output (the PNG/SVG files this generator produces), is proprietary brand
  material. See [LOGO-LICENSE](LOGO-LICENSE). Being able to read or run the
  code that draws the logo does not grant any rights to the logo as a brand
  asset.

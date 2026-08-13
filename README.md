# gdal.art

Generated [Arturo](https://arturo-lang.org) bindings for the public GDAL/OGR C
API, built entirely on [`arturo-ffi`](https://github.com/Lulzx/arturo-ffi).

The bindings are **not** hand-written. Arturo reads the installed GDAL C
headers, derives the foreign interface, generates the Arturo source, records
anything it cannot safely bind, and verifies the generated ABI against the
installed library. No GDAL-specific native wrapper exists.

```text
installed GDAL headers
        |
 Arturo C declaration extractor
        |
 normalized ABI schema
        |
 Arturo binding generator
        |
 generated gdal.art
        |
    arturo-ffi
        |
      libffi
        |
     libgdal
```

## Status

The generated bindings cover raster, vector, spatial-reference, and GDAL
utility workflows. The test suite reads and writes GeoTIFF and GeoJSON data,
transforms coordinates and geometries, runs GEOS predicates, and exercises
translation, warping, rasterization, and dataset inspection.

Generation against GDAL 3.13.2 on macOS arm64 currently finds 1,609 public C
functions. It binds 1,259 and defers 350 that cannot yet be represented safely.
Every deferred declaration is recorded with a reason; none are silently
dropped.

| Core surface | Bound | Coverage |
| --- | ---: | ---: |
| Raster | 13 / 13 | 100% |
| Vector | 17 / 17 | 100% |
| Spatial reference | 10 / 10 | 100% |

The parser includes `cpl_port.h` and `gdal_utils.h`. At the raw layer, owned
`char*` results are exposed as `ptr` and must be released with `VSIFree`. This
includes results from functions such as `GDALInfo` and
`OGR_G_ExportToJson`.

See [`SPEC.md`](SPEC.md) for the staged implementation plan and ABI rules.

## Requirements

- [Arturo](https://arturo-lang.org)
- GDAL ≥ 3.8 headers and `libgdal`
- a C compiler (`cc`) and `libffi` (for the `arturo-ffi` native adapter)

## Build

| Target | What it does |
| --- | --- |
| `make native` | build the `arturo-ffi` native adapter |
| `make generate` | discover installed GDAL and regenerate bindings |
| `make check` | determinism (regenerate twice) + golden drift compare |
| `make test` | run the nine test suites |
| `make examples` | run the ten worked examples under `examples/` |
| `make coverage` | print coverage and deferred reasons |

For a full local verification run:

```sh
make native generate check test examples coverage
make -C arturo-ffi test
```

The generator looks for GDAL in this order:

1. `GDAL_CONFIG`
2. `gdal-config`
3. `pkg-config`
4. standard include and library paths
5. `GDAL_INCLUDE_PATH` and `GDAL_LIBRARY_PATH`

GitHub Actions runs the full verification command and the `arturo-ffi` adapter
suite on macOS arm64 and Linux x86_64. The Linux matrix covers GDAL 3.8.5 and
3.10.1. CI uses checksum-verified Arturo v0.10.0 release binaries; the GDAL 3.8
job uses Arturo's legacy Linux build for compatibility with its older runtime.

## Use

```arturo
import "gdal"

do [
    ds: gdalOpen "map.tif"
    print rasterSize ds                 ; #[width: .. height: .. bands: ..]
    print driverName ds                 ; "GTiff"
    print geotransform ds               ; [gt0 gt1 gt2 gt3 gt4 gt5]
    closeDataset ds

    layer: layerNamed ds "points"
    eachFeature layer 'f [
        print featureId f
        print featureWkt f
    ]
]
```

`gdalOpen` opens any driver read-only (raster or vector); `gdalOpenMode`
restricts the kind or asks for write access (`'raster`, `'vector`,
`'update`).

The raw generated bindings stay available and recognizable (`gdalOpenEx`,
`ogr_G_ExportToWkt`, ...) for callers who need the full C surface;
`sugar.art` is a thin convenience layer that never hides them.

## Tests

`make test` runs nine suites:

| Suite | Covers |
| --- | --- |
| `generation.art` | generation round-trip and missing-dataset behavior |
| `raster.art` | raster metadata, pixels, projection, and geotransform |
| `vector.art` | layers, features, fields, and WKT export |
| `srs.art` | coordinate and WKT transformations |
| `sugar.art` | the convenience API and symbol checks |
| `write.art` | raster creation and read-back |
| `vector_write.art` | vector creation, read-back, GEOS, and transforms |
| `utilities.art` | translate, warp, vector translate, rasterize, and info |
| `adversarial.art` | errors, scalar raster types, and streamed iteration |

`make check` covers generated output rather than runtime behavior. It
regenerates the bindings twice to catch nondeterminism, verifies the ABI, and
checks for golden-file drift when the installed GDAL version matches
`GDAL_CHECK_VERSION` (3.8 by default).

## Layout

```text
generator/   the Arturo binding generator (entry: generator/main.art)
generated/   generated bindings + constants + types + ownership + manifest
main.art     self-contained package entry (ffi + generated + sugar)
sugar.art    idiomatic layer over the raw bindings
tests/       test suite
examples/    worked examples + fixtures (make examples)
```

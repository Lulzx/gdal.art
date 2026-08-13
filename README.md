# gdal.art

Generated Arturo bindings for the public GDAL/OGR C API, built entirely on
[`arturo-ffi`](https://github.com/Lulzx/arturo-ffi).

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

Stages A–D (see `SPEC.md` §41–§44): generation is proven end to end, and
both halves of GDAL are exercised — a GeoTIFF is opened and read through
`GDALRasterIO`, a GeoJSON layer is walked with WKT export through the
`char**` out-slot, and an EPSG:4326 coordinate is transformed to a
projected CRS through a coordinate transformer.

For the installed GDAL (currently **3.13.2** on macOS arm64), generation
discovers **1549** public C functions, of which **1119** are bound and
**430** are deferred with an explicit reason. Unsupported declarations are
reported, never silently dropped.

```text
raster core   13 / 13   (100%)
vector core   16 / 17   (94%)
SRS core      10 / 10   (100%)
```

`make test` runs four suites: the Stage A generation round-trip, the
`SPEC` §21 raster success test, the §23 vector success test, and the §44
CRS transform test.

## Requirements

- [Arturo](https://arturo-lang.org)
- GDAL >= 3.8 headers and `libgdal`
- a C compiler (`cc`) and `libffi` (for the `arturo-ffi` native adapter)

## Build

```bash
make native      # build the arturo-ffi native adapter
make generate    # discover installed GDAL and regenerate bindings
make check       # determinism + golden drift
make test        # run the test suite
make coverage    # print coverage and deferred reasons
```

GDAL discovery order (SPEC §6.1): `GDAL_CONFIG`, `gdal-config`, `pkg-config`,
standard paths, then `GDAL_INCLUDE_PATH` / `GDAL_LIBRARY_PATH`.

## Use

```arturo
import "gdal"

do [
    ds: gdalOpenEx "map.tif" GDAL_OF_RASTER null null null
    print gdalGetRasterXSize ds
    print gdalGetRasterYSize ds
    gdalClose ds
]
```

Raw names stay recognizable (`GDALOpenEx` -> `gdalOpenEx`,
`OGR_G_ExportToWkt` -> `ogr_G_ExportToWkt`). A small sugar layer
(`openDataset`, `closeDataset`, `rasterWidth`, ...) sits on top.

## Layout

```text
generator/   the Arturo binding generator (entry: generator/main.art)
generated/   generated bindings + constants + types + ownership + manifest
main.art     self-contained package entry (ffi + generated + sugar)
sugar.art    idiomatic layer over the raw bindings
tests/       test suite
```

`make check` regenerates twice into temp dirs and fails on drift; the golden
compare runs only when the installed GDAL matches `GDAL_CHECK_VERSION`
(default 3.8).

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

Stages A–F (see `SPEC.md` §41–§46): generation is proven end to end, and
both halves of GDAL are exercised in both directions — a GeoTIFF is read
through `GDALRasterIO` and **created** through `GDALCreate`; a GeoJSON
layer is walked with WKT export and **written** by creating a dataset,
layer, fields, features, and point/line geometries; an EPSG:4326
coordinate is transformed to a projected CRS through a coordinate
transformer, and geometries can be transformed and tested with GEOS
predicates (`distance`, `intersects`, `contains`, `within`, `union`).

For the installed GDAL (currently **3.13.2** on macOS arm64), generation
discovers **1549** public C functions, of which **1186** are bound and
**363** are deferred with an explicit reason. `cpl_port.h` is part of the
parsed surface, so the GInt/CSL type aliases resolve and `GDALCreate`,
`GDALSetGeoTransform`, `GDALGetMetadata`, the `OGR_F_*`/`OGR_G_*`/`OGR_L_*`
create/set predicates, and friends are bound. Unsupported declarations are
reported, never silently dropped.

```text
raster core   13 / 13   (100%)
vector core   16 / 17   (94%)
SRS core      10 / 10   (100%)
```

`make test` runs seven suites: the Stage A generation round-trip, the
`SPEC` §21 raster success test, the §23 vector success test, the §44 CRS
transform test, a suite that locks in the idiomatic layer (`gdalOpen`,
`rasterSize`, `eachFeature`, `featureFields`, ...), a §45 raster
write/read round-trip, and a §46 vector write/read round-trip with GEOS
predicates and geometry transform. `make examples` runs the nine worked
examples under `examples/`.

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
`'update`). Run the seven worked examples and read them for the pattern:

```sh
make examples
```

The raw generated bindings stay available and recognizable
(`gdalOpenEx`, `ogr_G_ExportToWkt`, ...) for callers who need the full C
surface; `sugar.art` is a thin convenience layer that never hides them.

## Layout

```text
generator/   the Arturo binding generator (entry: generator/main.art)
generated/   generated bindings + constants + types + ownership + manifest
main.art     self-contained package entry (ffi + generated + sugar)
sugar.art    idiomatic layer over the raw bindings
tests/       test suite
examples/    worked examples + fixtures (make examples)
```

`make check` regenerates twice into temp dirs and fails on drift; the golden
compare runs only when the installed GDAL matches `GDAL_CHECK_VERSION`
(default 3.8).

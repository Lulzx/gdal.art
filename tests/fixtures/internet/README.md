# Internet-sourced GDAL fixtures

These compact fixtures exercise formats and edge cases beyond the package's
handwritten GeoTIFF and GeoJSON oracles. They come from GDAL's upstream test
corpus, pinned to commit
[`4431fbec`](https://github.com/OSGeo/gdal/tree/4431fbecf5edeb0e7e3d98ba13cc34cc97257f96).

| Local file | Upstream path | What it exercises |
| --- | --- | --- |
| `byte.tif` | `autotest/gcore/data/byte.tif` | georeferenced byte GeoTIFF, pixels and CRS |
| `byte_with_xmp.jpg` | `autotest/gdrivers/data/jpeg/byte_with_xmp.jpg` | JPEG raster and embedded XMP metadata |
| `uint16_interlaced.png` | `autotest/gdrivers/data/png/uint16_interlaced.png` | interlaced 16-bit PNG raster |
| `sparse_fields.geojson` | `autotest/ogr/data/geojson/sparse_fields.geojson` | sparse and evolving GeoJSON properties |
| `typed.csv` | `autotest/ogr/data/csv/testtypeautodetect.csv` | CSV values suitable for type-detection tests |
| `geometries.kml` | `autotest/ogr/data/kml/geometries.kml` | KML geometry variants |
| `shapefile/poly.*` | `autotest/ogr/data/shp/testshp/poly.*` | multi-file Shapefile with projection sidecar |
| `poly.gpkg` | `autotest/ogr/data/gpkg/poly_golden.gpkg` | vector GeoPackage |
| `raster_and_vector.gpkg` | `autotest/gdrivers/data/gpkg/raster_and_vector.gpkg` | one GeoPackage containing raster and vector data |

`CHECKSUMS.sha256` records the exact downloaded bytes. To verify them from
this directory:

```sh
shasum -a 256 -c CHECKSUMS.sha256
```

The source repository is distributed under GDAL's permissive
[license](https://github.com/OSGeo/gdal/blob/4431fbecf5edeb0e7e3d98ba13cc34cc97257f96/LICENSE.TXT).

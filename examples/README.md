# examples

Runnable from the repository root:

```sh
arturo examples/01_open_dataset.art
```

Each example is self-contained and uses only the idiomatic layer on top of
the generated bindings (see `sugar.art`). The fixtures live in
`examples/fixtures/`.

| example | what it shows |
|---|---|
| `01_open_dataset.art` | the hello world: open, driver, size, geotransform |
| `02_read_pixels.art` | `readBand`, min/max/mean, ASCII rendering of the band |
| `03_geojson_features.art` | `eachFeature` over a point layer: FIDs, fields, WKT |
| `04_feature_fields.art` | `featureFields` and lookup by field name |
| `05_crs_transform.art` | `spatialReference` + `transformPoint` (EPSG:4326 → UTM) |
| `06_dataset_report.art` | driver, size, band info, geotransform, projection, metadata |
| `07_layers_and_routes.art` | `eachLayer` + `eachFeature` over line geometries |
| `08_write_geotiff.art` | `createDataset` + `setGeotransform` + `writeBand`, then read back |
| `09_write_geojson.art` | build a GeoJSON from nothing: layer, fields, point features, read back |

The same API at a glance:

```arturo
import "gdal"

ds: gdalOpen "map.tif"              ; raster or vector, read-only
print rasterSize ds                 ; #[width: .. height: .. bands: ..]

layer: layerNamed ds "points"
eachFeature layer 'f [
    print featureId f
    print featureWkt f
]
closeDataset ds
```

Run every example and check exit codes with:

```sh
make examples
```

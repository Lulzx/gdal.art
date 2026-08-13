#!/usr/bin/env bash
# Run the full non-interactive gdal.art test suite.
set -euo pipefail
cd "$(dirname "$0")/.."

for t in tests/generation.art tests/raster.art tests/vector.art tests/srs.art tests/sugar.art tests/write.art tests/vector_write.art tests/utilities.art; do
    echo "==== $t ===="
    arturo "$t"
    echo
done

echo "ALL TESTS PASSED"

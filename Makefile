# gdal.art development tasks
#
#   make native    build the arturo-ffi native adapter (requires libffi)
#   make generate  discover installed GDAL and regenerate bindings
#   make check     regenerate twice (determinism) + golden drift compare
#   make test      run generator, ABI, raster, vector, SRS, ownership tests
#   make coverage  print declaration coverage + deferred reasons
#
# GDAL discovery (SPEC 6.1):
#   GDAL_CONFIG            absolute path to a gdal-config-compatible binary
#   gdal-config            on PATH
#   pkg-config gdal
#   standard include/lib paths
#   GDAL_INCLUDE_PATH / GDAL_LIBRARY_PATH  (explicit, Windows route)

.PHONY: native generate check test examples coverage clean

ARTURO ?= arturo
GDAL_CHECK_VERSION ?= 3.8

native:
	@test -d arturo-ffi/native || (echo "arturo-ffi/ missing (symlink to ../arturo-ffi)"; exit 1)
	make -C arturo-ffi native

generate: native
	$(ARTURO) generator/main.art generate

check: native
	$(ARTURO) generator/main.art check $(GDAL_CHECK_VERSION)

test: native
	./tests/run_tests.sh

examples: native
	@for e in examples/[0-9]*.art; do \
		echo "==== $$e ===="; \
		$(ARTURO) "$$e" || exit 1; \
	done

coverage: native
	$(ARTURO) generator/main.art coverage

clean:
	rm -rf .gen_tmp_* generated main.art

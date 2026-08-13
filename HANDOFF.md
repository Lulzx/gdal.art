# gdal.art handoff

Implement generated GDAL/OGR bindings for Arturo. The contract is `SPEC.md` in this repo. This note is the current tree state, the Arturo FFI limits that already bit us, and the first slice of work.

Read `SPEC.md` end to end before writing generator code. If SPEC and this file disagree, fix SPEC and say so.

## Repos

Three siblings under `/Users/lulzx/work/`:

| Path | Role |
| --- | --- |
| `gdal.art/` | This package. Today: `SPEC.md` and this file. No generator yet. |
| `arturo-ffi/` | Generic libffi adapter. Source of truth for FFI changes. |
| `raylib.art/` | Existing consumer. Vendors `arturo-ffi` as a git submodule and **inlines** `arturo-ffi/main.art` into `raylib.art/main.art` via `make gen`. |

`arturo-ffi/ffi` is a symlink to `.` so `import "ffi"` resolves.

Canonical Arturo install for this machine is `/Users/lulzx/work/arturo`.

## What is already done (uncommitted)

None of this is committed. Three dirty trees.

### `gdal.art/SPEC.md`

Decisions that were open are now written into the spec:

- arturo-ffi contract is required for v0.1 (adapter version ≥ 3)
- after every FFI change, re-test `raylib.art`
- no generation timestamp in `generated/`
- `make check` golden files pin one GDAL version (default 3.8.x). Other CI GDAL versions skip golden drift
- parse **two views**: raw public headers for typedef/handle names, `cc -E` only for constants
- filter symbols to the headers in §4. Transitive libc is `IGNORED`
- one disposition enum: `BOUND` / `DEFERRED` / `IGNORED`
- `char**` out-owned-string is `BOUND` (needed for `OGR_G_ExportToWkt`)
- C `NULL` pointers become Arturo `null` in generated wrappers (`0` is truthy in Arturo)
- LP64 vs LLP64 table for `long` / `size_t`
- Stage B/C fixtures are checked-in oracles, not built by the bindings under test

### `arturo-ffi` (adapter version 3, package `0.2.0`)

New native entry points, additive to `adapter_call`:

- `adapter_alloc(n)` / `adapter_free(p)` / `adapter_load_cstr(p)` (one integer argument)
- `adapter_mem(op, args)` (two strings, same shape as `adapter_call`)

Arturo wrappers: `ffiAlloc`, `ffiFree`, `ffiLoadCString`, `ffiLoadU8` / `ffiStoreU8` / … / `ffiLoadF64` / `ffiStorePtr` / `ffiMemset` / `ffiCopy`.

`ffiCall` on a `void` return now actually calls C (`ffiDoVoid`). The old arm was `return null` and skipped the call. raylib was not hit by that because it emits `ffiRawCall` / `rlRawCall` directly.

Tests: `cd ../arturo-ffi && make test` (includes `tests/buffer.art`).

### `raylib.art`

The submodule working tree was copied from `../arturo-ffi`. `make gen` was run so `main.art` contains the new FFI. `make native && make test` passed. `make check` will fail against git because `main.art` changed. That is expected until someone commits the regen.

## Arturo FFI limits (do not rediscover)

These are measured, not guessed.

1. **`call.external` only reliably forwards the first integer argument.** A second or third integer arrives as 0. Four integer arguments can hang the VM (killed after ~20s). One integer is fine (`adapter_alloc`). Two **strings** are fine (`adapter_call`, `adapter_mem`).
2. **Do not add `adapter_load(ptr, off, width, signed)` or any other multi-int native.** Put extra scalars in the `adapter_mem` text payload: `"ptr;off"` or `"ptr;off;value"`.
3. **Arturo `return f a b c` does not call `f` with four args.** `return` takes one term. Use a last expression or parentheses: `ffiMemI "u8" (ffiJoin2 ffP ffOff)`.
4. **`case` with a block arm is broken** in this Arturo build. See the comment above `ffiEncodeArray` in `arturo-ffi/main.art`. Use a helper that `return`s.
5. **Function locals leak into the caller.** Every local, parameter, and loop iterator in `arturo-ffi` and in generated gdal code must be uniquely prefixed (`ff`, `gdal`, something that cannot collide).
6. **`ptr` is an integer address.** `ffiLoadCString 0` returns `null`. Generated GDAL wrappers must map a 0 pointer to `null` before user code sees it. Never write `while [feature: ogr_L_GetNextFeature layer]`.
7. **`cc -E` erases handles.** `GDALDatasetH` is `typedef void *`. After preprocess, every handle is `void *`. Keep names from the un-preprocessed headers (§6.2).

## What to implement next

### Stage A (first slice, about a day)

Prove generation on three functions, no GIS yet. SPEC §41.

```c
GDALDatasetH GDALOpenEx(const char *pszFilename, unsigned int nOpenFlags,
                        const char *const *papszAllowedDrivers,
                        const char *const *papszOpenOptions,
                        const char *const *papszSiblingFiles);
int GDALGetRasterXSize(GDALDatasetH);
void GDALClose(GDALDatasetH);
```

Pass: parse → normalize → emit → load symbol → call.

For the first call, `GDALOpenEx path GDAL_OF_RASTER null null null` is enough. The three `char**` list args may be NULL. Do not implement CSL yet.

Suggested tree (SPEC §5):

```text
gdal.art/
  SPEC.md
  HANDOFF.md
  Makefile
  arturo-ffi/          # submodule of github.com/Lulzx/arturo-ffi, or a copy of ../arturo-ffi
  generator/
    main.art
    preprocess.art
    tokenize.art
    declarations.art
    normalize.art
    types.art
    emit.art
  generated/           # created by the generator
  main.art             # package entry, may inline ffi like raylib
  tests/
    generation.art
```

Copy the raylib pattern where it helps: `raylib.art/tools/generate.art` inlines `arturo-ffi/main.art` + generated bindings into one importable `main.art`.

Minimum `Makefile` targets from SPEC §32: `native`, `generate`, `check`, `test`. `check` = generate twice into temp dirs and diff (determinism). Golden compare against checked-in files only when installed GDAL matches `GDAL_CHECK_VERSION` (default 3.8).

Discover GDAL as in §6.1. `GDAL_CONFIG` is an absolute path to a `gdal-config`-compatible binary. Pass the recorded library path as the `Lib::` prefix on generated calls (or prepend `GDAL_LIBRARY_PATH` to `ARTURO_FFI_PATH`).

Raw names follow raylib: `GDALOpenEx` → `gdalOpenEx`, `GDALGetRasterXSize` → `gdalGetRasterXSize`. Keep interior underscores (`OGR_G_ExportToWkt` → `ogr_G_ExportToWkt`). Do not invent the `gdal\openEx` namespace surface in Stage A.

Require `ffiAdapterVersion >= 3` at generate or load time.

### Stage B (after A is green)

Tiny GeoTIFF, `GDALRasterIO` into `ffiAlloc` buffer, decode with `ffiLoadU8` / `ffiLoadF32` / etc., `GDALClose`. Fixture is a checked-in oracle plus a sidecar of expected pixels. SPEC §19–§21, §51.

### Stage C

GeoJSON layer walk, `OGR_G_ExportToWkt` via `ffiAlloc` of a `char*` slot, `ffiStorePtr`, call, `ffiLoadPtr`, `ffiLoadCString`, `CPLFree`. SPEC §22–§23.

## How to change arturo-ffi

Allowed. Required, if GDAL needs a new *generic* capability. Forbidden: a GDAL-specific `.c` wrapper.

After any adapter or `arturo-ffi/main.art` change:

```bash
cd ../arturo-ffi && make test
# copy or bump the submodule in raylib.art
cd ../raylib.art
# if main.art of arturo-ffi changed:
make gen
make native && make test
```

New symbols only. Do not change `adapter_call` text format or existing `ffiCall` / struct / color behavior.

raylib's `make check` is `git diff --exit-code main.art src/generated.art`. A FFI `main.art` change forces a raylib regen commit.

## Commands that should stay green

```bash
cd /Users/lulzx/work/arturo-ffi && make test
cd /Users/lulzx/work/raylib.art && make native && make test
# after Stage A exists:
cd /Users/lulzx/work/gdal.art && make native && make generate && make check && make test
```

Need GDAL ≥ 3.8 headers and `libgdal` for generate/test. `gdal-config --version` / `--cflags` / `--libs` on this Mac if Homebrew GDAL is installed.

## Do not

- Hand-write `gdalOpenEx` as a permanent binding. Stage A may hardcode the three-function *test*, not the production emit path.
- Edit files under `generated/` by hand.
- Infer ownership from a name when it is ambiguous. Unknown stays unknown.
- Bind the C++ API.
- Claim “complete GDAL bindings” in a README.
- Check in a generation timestamp.
- Assume `gdal-config` exists on Windows.
- Walk pixels through `adapter_call` argument text.

## SPEC map

| Topic | Section |
| --- | --- |
| Goals / non-goals | §1–§2 |
| Headers | §4 |
| Repo layout | §5 |
| Discover + two-view parse | §6 |
| IR | §7 |
| Types / handles / ownership | §8–§12 |
| `char*` / `char**` / CSL | §13 |
| Raw names | §16 |
| Raster / vector / SRS milestones | §19–§24 |
| Buffers + FFI contract | §20 |
| Dispositions | §26, §40 |
| Deferred list | §27 |
| ABI + symbols | §28–§29 |
| GDAL ≥ 3.8 | §30 |
| Determinism + commands | §31–§32 |
| NULL / errors | §16, §37 |
| Stages A–H | §41–§48 |
| Hard constraints | §49 |
| CI / fixtures | §50–§51 |
| v0.1 / v1.0 | §54–§55 |

## First commit suggestion (three repos)

1. `arturo-ffi`: adapter v3, `adapter_mem`, `ffiDoVoid`, `tests/buffer.art`
2. `raylib.art`: submodule bump + `make gen` so inlined FFI matches
3. `gdal.art`: `SPEC.md` + this handoff, then the Stage A generator on its own commit

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

BAFF (Bristol Aircraft File Format) — MATLAB OOP toolbox for platform/tool-agnostic aircraft geometry definition. Outputs HDF5 files readable by any language/tool. Primary consumer: ADS tool (Nastran aeroelastic simulations).

## Running Tests

```matlab
runtests('tests')
```

All 18 test files live in `tests/`. MATLAB built-in unit test framework — no external test runner.

## Architecture

### Namespace

All code in `+baff` package (`tbx/+baff/`). Import: `baff.ClassName`.

Sub-packages:
- `+baff.+station` — station classes for spanwise property variation
- `+baff.+util` — plotting callbacks, ICARO utility

### Element Hierarchy (Composite Pattern)

`Element` (abstract base) → concrete elements: `Wing`, `Beam`, `BluffBody`, `ControlSurface`, `Hinge`, `Mass`, `Fuel`, `Payload`, `Constraint`, `Point`

`Model` is the top-level container. Elements form a parent-child tree via `element.add(child)`. Each element has:
- `A` — 3×3 rotation matrix (local frame)
- `Offset` — 3-vector position offset
- `Eta` / `EtaLength` — normalized position (0–1) scaled to physical length
- `Parent` / `Children` — tree links

### Station Classes (`+baff.+station`)

Stations parameterize properties along span (Eta 0–1). All inherit from `station.Base`. Key subclasses:
- `Aero` — chord, twist, beam location, airfoil, lift curve slope, linear mass/inertia
- `Beam` — structural beam cross-section properties
- `Body` — bluff body cross-section (radius)
- `GBeam` — general beam (arbitrary/composite cross-sections)
- `ShellStation` / `Shell` / `Ply` — shell/laminate layup

Stations support operator overloading (`+`, `-`, `*`, `/`) for algebraic manipulation.

### HDF5 Serialization

Every `Element` and `Station` class implements three methods:
- `ToBaff(filename, loc)` — write to HDF5
- `FromBaff(filename, loc)` (static) — read from HDF5
- `TemplateHdf5(filename, loc)` (static) — generate empty schema

`Model.ToBaff()` / `Model.FromBaff()` serialize the full tree.

### Factory Methods (Static Constructors)

Prefer static factories over direct construction:
- `Wing.UniformWing(span, thickness, chord, material, chord_val, beamLoc)` — uniform spanwise properties
- `Beam.Bar(length, width, height, material)` — rectangular cross-section
- `BluffBody.Cylinder()`, `.Cone()`, `.SemiSphere()`, `.FromEta()`
- `Material.Aluminium()`, `.IsoCarbonFibre()`, `.Stainless304()`, `.Stainless316()`, `.Stiff()`

### Key Conventions

- **Named arguments** (MATLAB R2021a+): `Constraint(Eta=0.5, Name="Root")`
- **Coordinate system**: elements defined in local frame; parent chain computes global position
- **Eta**: normalized 0–1 spanwise/lengthwise coordinate; always paired with `EtaLength` for physical scale
- **`draw(ax, Type='stick'|'surf'|'mesh')`** — all elements implement visualization

## Versioning & Release

SemVer. Version in `version.txt`. GitHub Actions:
1. `increment-version.yml` — manual trigger, bumps version, opens PR
2. `tag-and-release.yml` — fires on merge when `version.txt` changes, creates tag + release

Current: `0.4.0`

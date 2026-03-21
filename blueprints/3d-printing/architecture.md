# 3D Printing Blueprint — Architecture

## System Architecture Overview

The 3D printing blueprint system follows a pipeline architecture where each stage transforms input specifications into progressively more concrete physical fabrication instructions.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     SKForge 3D Print Pipeline                       │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────┐│
│  │ driver.md│─▶│ Material │─▶│ Geometry │─▶│ Slicer   │─▶│G-code││
│  │ (intent) │  │ Resolver │  │ Engine   │  │ Profile  │  │Output││
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────┘│
│       │             │             │             │             │     │
│       ▼             ▼             ▼             ▼             ▼     │
│  [features]   [constraints]  [STL/3MF]   [.ini/.json]  [.gcode]  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Validation Layer                           │  │
│  │  manifold ─ walls ─ volume ─ overhang ─ tolerance ─ safety  │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. Specification Parser

Reads `driver.md` and resolves feature selections against `features.yml`.

```
Input:  driver.md (user intent)
Output: Resolved feature set + material + printer constraints

Process:
  1. Parse markdown front-matter (category, language, features)
  2. Load features.yml for the 3d-printing category
  3. Resolve dependencies (if "Assembly Instructions" selected,
     auto-include "Multi-Part Assembly" and "STL Export")
  4. Validate no conflicting features
  5. Load material spec from material-specs/{material}.yml
  6. Load printer profile if specified
  7. Emit resolved specification object
```

### 2. Material Resolver

Matches functional requirements to material properties and constrains downstream settings.

```
Input:  Functional requirements from driver.md
Output: MaterialSpec with print settings

Decision Matrix:
  ┌────────────────┬──────┬──────┬──────┬──────┬──────┐
  │ Requirement    │ PLA  │ PETG │ ABS  │ TPU  │ ASA  │
  ├────────────────┼──────┼──────┼──────┼──────┼──────┤
  │ Easy to print  │  ★★★ │  ★★  │  ★   │  ★   │  ★   │
  │ Strength       │  ★★  │  ★★★ │  ★★  │  ★   │  ★★  │
  │ Heat resist.   │  ★   │  ★★  │  ★★★ │  ★   │  ★★★ │
  │ Flexibility    │  ★   │  ★   │  ★   │  ★★★ │  ★   │
  │ UV resistant   │  ★   │  ★   │  ★   │  ★   │  ★★★ │
  │ Chemical res.  │  ★   │  ★★★ │  ★★  │  ★★  │  ★★  │
  │ Food safe      │  ★★  │  ★   │  ✗   │  ✗   │  ✗   │
  │ Biodegradable  │  ★★★ │  ✗   │  ✗   │  ✗   │  ✗   │
  └────────────────┴──────┴──────┴──────┴──────┴──────┘
  ★ = limited  ★★ = good  ★★★ = excellent  ✗ = not applicable
```

### 3. Geometry Engine

Generates or validates 3D models based on object specifications.

```
Two Modes:

A) Parametric Generation (OpenSCAD/CadQuery)
   Input:  Dimensions, features, constraints
   Output: Generated STL/3MF

   Pipeline:
   1. Load parametric template for object type
   2. Inject user-specified dimensions
   3. Apply feature modifications (cutouts, fillets, channels)
   4. Render to mesh (STL)
   5. Run validation pipeline

B) Mesh Validation (Pre-made STL)
   Input:  User-provided STL file
   Output: Validated + repaired STL

   Pipeline:
   1. Load mesh file
   2. Check manifold integrity
   3. Repair if possible (hole fill, normal flip)
   4. Validate wall thickness
   5. Check build volume fit
   6. Report issues
```

### 4. Slicer Profile Generator

Translates material specs and quality settings into slicer-specific configuration files.

```
Input:  MaterialSpec + quality tier + printer profile
Output: Slicer configuration file(s)

PrusaSlicer (.ini):
  [print:SKForge-PETG-Standard]
  layer_height = 0.2
  first_layer_height = 0.2
  perimeters = 3
  fill_density = 20%
  fill_pattern = gyroid
  support_material = 0
  ...

Cura (.curaprofile):
  [general]
  name = SKForge-PETG-Standard
  [values]
  layer_height = 0.2
  wall_line_count = 3
  infill_sparse_density = 20
  infill_pattern = gyroid
  ...

Bambu Studio (.json):
  {
    "name": "SKForge-PETG-Standard",
    "layer_height": 0.2,
    "wall_loops": 3,
    "sparse_infill_density": "20%",
    "sparse_infill_pattern": "gyroid",
    ...
  }
```

### 5. Validation Layer

Cross-cutting concern that validates at every pipeline stage.

```
Validation Checks (in order):

Pre-Geometry:
  ✓ Material + printer compatibility (e.g., ABS needs enclosure)
  ✓ Dimensions fit within build volume
  ✓ Feature dependencies satisfied

Post-Geometry:
  ✓ Mesh is manifold (watertight)
  ✓ No non-manifold edges
  ✓ No zero-area faces
  ✓ Wall thickness ≥ minimum (material-dependent)
  ✓ No features thinner than nozzle diameter
  ✓ Overhang analysis complete

Post-Slicer:
  ✓ G-code temperatures within printer limits
  ✓ Print time within reasonable bounds
  ✓ Material usage estimate generated
  ✓ No layer adhesion warnings (min layer time respected)

Safety:
  ✓ Fume warnings for ABS/ASA
  ✓ Enclosure warnings where required
  ✓ Food safety warnings for non-certified materials
```

## Design Patterns

### Pattern: Material-Driven Configuration Cascade

Material selection cascades constraints through the entire pipeline:

```
Material: ABS
  → nozzle_temp: 240°C
  → bed_temp: 100°C
  → enclosure: REQUIRED
  → cooling_fan: 0% first 3 layers, 30% thereafter
  → retraction: 0.8mm at 40mm/s (less stringing)
  → adhesion: brim recommended (warping prevention)
  → post_processing: acetone smoothing available
  → safety_warning: "Print in ventilated area. ABS fumes are harmful."
```

### Pattern: Quality Tier Presets

Three standard quality tiers that adjust multiple parameters simultaneously:

```
Draft (0.3mm):
  Speed: Fast | Infill: 15% | Walls: 2 | Top/Bottom: 3
  Use: Prototyping, fit checks, non-visible parts

Standard (0.2mm):
  Speed: Normal | Infill: 20% | Walls: 3 | Top/Bottom: 4-5
  Use: Functional parts, everyday objects, enclosures

Fine (0.1mm):
  Speed: Slow | Infill: 25% | Walls: 4 | Top/Bottom: 6-8
  Use: Visible parts, miniatures, high-detail objects
```

### Pattern: Tolerance Compensation Table

Systematic dimensional adjustments based on measured FDM accuracy:

```
Feature Type          Compensation    Reason
─────────────────────────────────────────────────
Press-fit holes       +0.2mm          Filament shrinkage + over-extrusion
Clearance holes       +0.3mm          Allow free rotation/movement
Snap-fit clips        -0.1mm gap      Slight interference for secure lock
Sliding fit           +0.15mm         Smooth movement without wobble
Thread (M3)           +0.3mm hole     Tap or self-tap into printed hole
Pin joint             +0.1mm          Tight fit without permanent bond
Screw counterbore     +0.4mm          Clear screw head without binding
```

## Integration Points

### With Existing SKForge Software Blueprints

The 3D printing blueprint complements software blueprints:

```
Example: IoT Sensor Platform
  Software Blueprint: web-servers (for data dashboard)
  + 3D Print Blueprint: sensor enclosure (weatherproof PETG)
  + 3D Print Blueprint: mounting bracket (ABS, outdoor rated)

The forge CLI can generate both in a single stack:
  forge stack iot-sensor --software web-servers --hardware 3d-printing
```

### With Future Phase 2 (CNC / Laser)

Geometry and material specs feed into alternative manufacturing:

```
Same PrintObject spec → Different output:
  FDM:   STL + G-code + slicer profile
  CNC:   STEP + toolpath + feeds/speeds
  Laser: DXF + power/speed settings
```

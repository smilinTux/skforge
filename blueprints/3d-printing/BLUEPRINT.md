# 3D Printing Blueprint

## Overview & Purpose

A 3D printing blueprint is a structured specification that enables AI to generate complete, production-ready 3D printable objects — from parametric geometry through slicing configuration to post-processing instructions. It bridges the gap between digital design intent and physical fabrication, encoding material science, mechanical engineering constraints, and manufacturing best practices into a format any LLM can consume.

### Core Responsibilities
- **Geometry Definition**: Parametric or mesh-based 3D model specification with dimensional constraints
- **Material Selection**: Match material properties (strength, flexibility, temperature resistance) to functional requirements
- **Print Configuration**: Layer height, infill pattern/density, wall count, speed, temperature — per material
- **Validation**: Manifold mesh checks, wall thickness minimums, build volume fit, overhang analysis
- **Slicer Integration**: Generate ready-to-use profiles for PrusaSlicer, Cura, and Bambu Studio
- **Post-Processing**: Sanding, smoothing, painting, assembly instructions for multi-part prints
- **Quality Assurance**: Dimensional tolerance specs, fit checks, stress analysis baselines

## Core Concepts

### 1. Print Object Specification

**Definition**: The complete description of a 3D printable object, including geometry, material, and functional requirements.

```
PrintObject {
    name: Human-readable object name
    description: Purpose and functional requirements
    dimensions: { x_mm, y_mm, z_mm }
    geometry_source: Parametric | MeshFile | Primitive
    material: Reference to MaterialSpec
    functional_requirements: {
        load_bearing: Boolean
        waterproof: Boolean
        heat_resistant_c: Temperature in Celsius
        outdoor_rated: Boolean
        food_safe: Boolean
        flexible: Boolean
    }
    tolerances: {
        general: ±0.2mm (FDM standard)
        press_fit_holes: +0.2mm compensation
        clearance_gaps: +0.3mm minimum
        thread_pitch_compensation: -0.1mm
    }
    assembly: Optional assembly configuration
}
```

### 2. Material Specifications

**Definition**: Physical and printing properties of filament materials that constrain all downstream decisions.

```
MaterialSpec {
    name: Material identifier (PLA, PETG, ABS, TPU, etc.)
    type: Thermoplastic | Resin | Composite
    properties: {
        density_g_cm3: Float
        tensile_strength_mpa: Float
        elongation_at_break_pct: Float
        heat_deflection_c: Temperature
        glass_transition_c: Temperature
        moisture_absorption: Low | Medium | High
        uv_resistance: Poor | Fair | Good | Excellent
        chemical_resistance: List of chemicals
        food_safe: Boolean (FDA/EU compliant grades)
    }
    print_settings: {
        nozzle_temp_c: { min, recommended, max }
        bed_temp_c: { min, recommended, max }
        enclosure_required: Boolean
        bed_adhesion: BuildTak | PEI | Glass | Tape
        cooling_fan_pct: { first_layer, other_layers }
        max_print_speed_mm_s: Integer
        retraction_distance_mm: Float
        retraction_speed_mm_s: Integer
    }
    post_processing: {
        sandable: Boolean
        acetone_smoothable: Boolean
        paintable: Boolean
        glueable_with: List of adhesive types
        annealable: Boolean
        annealing_temp_c: Optional temperature
    }
    storage: {
        humidity_sensitive: Boolean
        max_humidity_pct: Integer
        drying_temp_c: Optional temperature
        drying_hours: Optional integer
    }
}
```

### 3. Slicer Configuration

**Definition**: Software-specific settings that translate a 3D model into printer instructions (G-code).

```
SlicerConfig {
    slicer: PrusaSlicer | Cura | BambuStudio
    layer_height_mm: { draft: 0.3, standard: 0.2, fine: 0.1, ultra: 0.06 }
    first_layer_height_mm: 0.2
    line_width_mm: NozzleDiameter (typically 0.4)
    infill: {
        pattern: Grid | Gyroid | Honeycomb | Cubic | AdaptiveCubic | Lightning
        density_pct: { light: 10, standard: 20, strong: 40, solid: 100 }
    }
    walls: {
        perimeter_count: { minimum: 2, standard: 3, structural: 4 }
        external_perimeter_first: Boolean
    }
    top_bottom: {
        top_layers: Integer (typically 4-6)
        bottom_layers: Integer (typically 3-4)
        top_fill_pattern: Monotonic | Rectilinear | Concentric
    }
    speed_mm_s: {
        perimeters: Integer
        infill: Integer
        travel: Integer
        first_layer: Integer (typically 50% of normal)
    }
    support: {
        enabled: Boolean
        type: Normal | Tree | Organic
        overhang_angle_deg: 45
        interface_layers: Integer
        z_distance_mm: Float
        xy_distance_mm: Float
        pattern: Grid | Lines | Zigzag
        density_pct: Integer
    }
    adhesion: {
        type: Skirt | Brim | Raft | None
        brim_width_mm: Float
        raft_layers: Integer
    }
    retraction: {
        enabled: Boolean
        distance_mm: Float (material-dependent)
        speed_mm_s: Integer
        z_hop_mm: Float
    }
    cooling: {
        fan_speed_pct: Integer
        min_layer_time_s: Integer
        slow_down_if_layer_time_below_s: Integer
    }
}
```

### 4. Build Volume & Printer Constraints

**Definition**: Physical limits of the target 3D printer.

```
PrinterProfile {
    name: Printer model identifier
    build_volume_mm: { x, y, z }
    nozzle_diameter_mm: Float (0.4 standard)
    heated_bed: Boolean
    enclosure: Boolean
    direct_drive: Boolean
    multi_material: Boolean
    max_temp_nozzle_c: Integer
    max_temp_bed_c: Integer
    filament_diameter_mm: 1.75 | 2.85
    auto_bed_leveling: Boolean
    input_shaping: Boolean
    max_acceleration_mm_s2: Integer
    max_speed_mm_s: Integer
}

# Common Profiles:
# Prusa MK4S:  250x210x220, direct drive, input shaping
# Bambu X1C:   256x256x256, enclosed, multi-material capable
# Ender 3 V3:  220x220x250, direct drive, budget-friendly
# Voron 2.4:   350x350x340 (max), enclosed, CoreXY
```

### 5. Mesh Validation Pipeline

**Definition**: Automated checks that a 3D model is printable.

```
Validation Pipeline:
1. Manifold Check     → Mesh is watertight (no holes, no inverted normals)
2. Non-Manifold Edges → No edges shared by more than 2 faces
3. Zero-Area Faces    → Remove degenerate triangles
4. Wall Thickness     → All walls meet minimum for material (typ. 0.8mm+)
5. Overhang Analysis  → Flag unsupported overhangs > 45°
6. Build Volume Fit   → Object fits within printer dimensions
7. Thin Feature Check → Flag features below nozzle diameter
8. Bridging Analysis  → Identify spans needing support or bridging config
9. STL Repair         → Auto-fix minor mesh issues (hole filling, normal flip)
```

## Data Flow Diagrams

### Complete Print Workflow
```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────┐
│   Blueprint  │     │   Geometry   │     │    Slicer    │     │ Printer  │
│   (driver)   │     │  Generation  │     │  Processing  │     │          │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘     └────┬─────┘
       │                     │                     │                  │
       │  1. Parse specs     │                     │                  │
       ▼                     │                     │                  │
  ┌─────────────┐            │                     │                  │
  │ Material    │            │                     │                  │
  │ Selection   │            │                     │                  │
  │ + Constraints│           │                     │                  │
  └──────┬──────┘            │                     │                  │
         │  2. Generate      │                     │                  │
         ▼──────────────────▶│                     │                  │
                    ┌────────┘                     │                  │
                    ▼                              │                  │
             ┌─────────────┐                       │                  │
             │ Parametric  │                       │                  │
             │ Model / STL │                       │                  │
             │ Generation  │                       │                  │
             └──────┬──────┘                       │                  │
                    │  3. Validate                  │                  │
                    ▼                              │                  │
             ┌─────────────┐                       │                  │
             │ Mesh        │                       │                  │
             │ Validation  │                       │                  │
             │ Pipeline    │                       │                  │
             └──────┬──────┘                       │                  │
                    │  4. Slice                     │                  │
                    ▼──────────────────────────────▶│                  │
                                          ┌────────┘                  │
                                          ▼                           │
                                   ┌─────────────┐                   │
                                   │ G-code      │                   │
                                   │ Generation  │                   │
                                   │ + Preview   │                   │
                                   └──────┬──────┘                   │
                                          │  5. Print                 │
                                          ▼──────────────────────────▶│
                                                              ┌──────┘
                                                              ▼
                                                       ┌─────────────┐
                                                       │ Physical    │
                                                       │ Object      │
                                                       │ + QA Check  │
                                                       └─────────────┘
```

### Material Decision Tree
```
Functional Requirements → Material Selection:

  Load-bearing?
    ├── Yes → Temperature resistant?
    │           ├── Yes (>80°C) → ABS (enclosed printer required)
    │           └── No          → PETG (strong, easy to print)
    └── No  → Flexible?
                ├── Yes → TPU (direct drive required)
                └── No  → Outdoor use?
                            ├── Yes → PETG or ASA
                            └── No  → PLA (easiest, biodegradable)
```

### Multi-Part Assembly Flow
```
┌────────────┐    ┌────────────┐    ┌────────────┐
│  Part A    │    │  Part B    │    │  Part C    │
│ (housing)  │    │ (lid)      │    │ (bracket)  │
└─────┬──────┘    └─────┬──────┘    └─────┬──────┘
      │                 │                 │
      │  Print each part separately      │
      ▼                 ▼                 ▼
┌────────────┐    ┌────────────┐    ┌────────────┐
│ Post-      │    │ Post-      │    │ Post-      │
│ Processing │    │ Processing │    │ Processing │
└─────┬──────┘    └─────┬──────┘    └─────┬──────┘
      │                 │                 │
      └────────┬────────┘                 │
               │                          │
               ▼                          │
        ┌─────────────┐                   │
        │  Fit Check  │◀──────────────────┘
        │ (tolerance  │
        │  validation)│
        └──────┬──────┘
               │
               ▼
        ┌─────────────┐
        │  Assembly   │
        │ (fasteners, │
        │  adhesive,  │
        │  snap-fit)  │
        └─────────────┘
```

## Configuration Model

### driver.md Format for 3D Printing

```markdown
# driver.md — Raspberry Pi 5 Enclosure

## Blueprint
category: 3d-printing

## Object
name: Raspberry Pi 5 Enclosure
dimensions: 92x62x30mm (interior clearance for Pi 5 board)
parts: 2 (base + lid)

## Material
target: PETG
reason: Good strength, heat resistant for Pi thermals, no enclosure needed

## Features
- [x] STL Export
- [x] PETG Support
- [x] PrusaSlicer Profile
- [x] Cura Profile
- [x] Manifold Check
- [x] Wall Thickness Validation
- [x] Assembly Instructions
- [ ] Waterproofing
- [ ] ABS Support
- [ ] Tolerance Engineering
- [ ] Bambu Studio Profile

## Requirements
- Ventilation slots for passive cooling
- GPIO header access slot on one side
- USB-C power port access
- Micro HDMI port access (x2)
- SD card slot access
- M2.5 brass heat-insert mounting posts (x4)
- Snap-fit lid with 0.3mm clearance

## Printer
target: Prusa MK4S (250x210x220mm build volume)
nozzle: 0.4mm
```

### Hierarchical Configuration
```yaml
print_project:
  name: "Raspberry Pi 5 Enclosure"
  version: "1.0.0"
  
  object:
    type: enclosure
    interior_dimensions_mm: [92, 62, 30]
    wall_thickness_mm: 2.0
    corner_radius_mm: 3.0
    parts:
      - name: base
        features: [mounting_posts, port_cutouts, ventilation]
      - name: lid
        features: [snap_fit, ventilation, logo_emboss]

  material:
    primary: PETG
    color: black
    brand_recommendation: "Prusament PETG"

  print_settings:
    layer_height_mm: 0.2
    infill_pattern: gyroid
    infill_density_pct: 20
    wall_count: 3
    top_layers: 5
    bottom_layers: 4
    support: false
    brim: true
    brim_width_mm: 5.0

  post_processing:
    - step: "Remove brim with flush cutters"
    - step: "Insert M2.5 brass heat-set inserts (x4) using soldering iron at 220°C"
    - step: "Light sanding on mating surfaces (220 grit)"
    - step: "Test fit lid snap mechanism"

  quality_checks:
    - "All port cutouts aligned within ±0.5mm"
    - "Lid snap-fit engages with audible click"
    - "Board sits flat on mounting posts"
    - "No visible warping on base bottom surface"
```

## Security Considerations

### File Format Safety
- STL files: Validate triangle count is reasonable (< 5M for typical objects)
- 3MF files: Validate XML structure, reject embedded scripts
- G-code files: Sanitize temperature commands (reject temps above printer max)
- Never execute arbitrary G-code from untrusted sources

### Print Safety
- Temperature limits: Enforce max nozzle/bed temps per printer profile
- Enclosure monitoring: ABS/ASA prints should warn about fume extraction
- Thermal runaway: G-code should include thermal runaway protection commands
- Unattended printing: Include pause/resume points for multi-hour prints

### Material Safety
- ABS fumes: Require ventilation warning in post-processing steps
- Food safety: Only FDA/EU approved filament grades for food-contact parts
- Resin handling: Include PPE requirements for resin-based prints
- Material compatibility: Warn about material degradation from chemical exposure

## Performance Targets

### Print Time Estimates (Raspberry Pi enclosure example)
- **Draft quality (0.3mm)**: ~1.5 hours
- **Standard quality (0.2mm)**: ~2.5 hours
- **Fine quality (0.1mm)**: ~5 hours

### Dimensional Accuracy
- **FDM general tolerance**: ±0.2mm on XY, ±0.1mm on Z
- **Hole accuracy (compensated)**: ±0.1mm
- **Surface roughness (Ra)**: 12-15μm (0.2mm layer), 6-8μm (0.1mm layer)

### Structural Targets
- **PLA tensile**: 30-60 MPa depending on print orientation
- **PETG tensile**: 40-50 MPa
- **ABS tensile**: 30-45 MPa
- **Layer adhesion**: Typically 50-80% of material tensile strength

### Material Usage
- **Infill savings**: 20% infill uses ~40% less material than solid
- **Gyroid vs Grid**: Gyroid 10-15% stronger at same density
- **Support waste**: Tree supports use 30-50% less material than normal

## Extension Points

### Custom Material Profiles
Add new material YAML files to `material-specs/` following the MaterialSpec schema. The blueprint system automatically discovers and validates new materials.

### Slicer Plugin Integration
Each slicer directory under `slicer-configs/` can contain:
- `.ini` files for PrusaSlicer
- `.curaprofile` files for Cura
- `.json` profiles for Bambu Studio

### Parametric Geometry Hooks
The blueprint supports two geometry approaches:
1. **Mesh-based**: Pre-made STL/3MF files in `stl-templates/`
2. **Parametric**: OpenSCAD or CadQuery scripts that accept dimensions as parameters

### Future: Phase 2 Integration Points
- CNC milling profiles (subtractive manufacturing)
- Laser cutting DXF generation (2D fabrication)
- Injection mold cavity design (mass production transition)
- Multi-material print planning (dual/quad extrusion)

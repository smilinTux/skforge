# 3D Printing Blueprint — Benchmarks

## Overview

Benchmarks define measurable quality and performance targets for 3D printed objects generated from SKForge blueprints. These serve as acceptance criteria for both the blueprint system and the physical prints it produces.

---

## 1. Dimensional Accuracy Benchmarks

### 1.1 XY Accuracy (per material)
```
BENCHMARK: Printed dimensions match design within tolerance
METHOD: Print calibration cube (20x20x20mm), measure with calipers

Target Accuracy:
  PLA:   ±0.15mm on X/Y
  PETG:  ±0.20mm on X/Y
  ABS:   ±0.25mm on X/Y (more warping)
  TPU:   ±0.40mm on X/Y (elastic deformation)

Measurement: 3 cubes per material, average deviation
Pass: Average deviation within target
```

### 1.2 Z Accuracy
```
BENCHMARK: Layer stacking produces accurate Z height
METHOD: Print calibration cube, measure Z dimension

Target: ±0.10mm for all materials (Z is stepper-controlled)
Pass: Average Z deviation within ±0.10mm over 3 prints
```

### 1.3 Hole Accuracy
```
BENCHMARK: Compensated holes match target diameter
METHOD: Print test block with 3mm, 5mm, 8mm, 10mm holes

Without compensation: holes typically 0.2-0.4mm undersized
With compensation (+0.2mm): ±0.1mm of target

Pass: Compensated holes within ±0.15mm of target diameter
```

---

## 2. Structural Benchmarks

### 2.1 Tensile Strength (per material, per orientation)
```
BENCHMARK: Printed parts meet minimum tensile strength
METHOD: ASTM D638 Type V specimen, pull test

Minimum Targets (flat orientation, 100% infill):
  PLA:   45 MPa
  PETG:  40 MPa
  ABS:   30 MPa
  TPU:   25 MPa

Minimum Targets (upright orientation — weakest):
  PLA:   25 MPa (layer adhesion limited)
  PETG:  30 MPa (excellent layer adhesion)
  ABS:   20 MPa
  TPU:   20 MPa
```

### 2.2 Impact Resistance
```
BENCHMARK: Parts survive drop test
METHOD: Drop printed enclosure from 1m onto concrete

Pass Criteria:
  PLA:   No structural failure (may show stress whitening)
  PETG:  No cracks, no deformation
  ABS:   No cracks, slight deformation acceptable
  TPU:   Bounces, no damage
```

### 2.3 Infill Strength Efficiency
```
BENCHMARK: Infill pattern strength relative to material used
METHOD: Compression test on 40x40x40mm cubes at different infill %

Expected Relative Strength (vs solid):
  Grid 20%:     35% strength at 40% material savings
  Gyroid 20%:   45% strength at 40% material savings (winner)
  Honeycomb 20%: 40% strength at 40% material savings
  Lightning 20%: 20% strength at 60% material savings (top surface only)

Pass: Gyroid outperforms Grid by ≥10% at same density
```

---

## 3. Print Quality Benchmarks

### 3.1 Surface Roughness
```
BENCHMARK: Surface finish meets quality tier targets
METHOD: Profilometer or visual comparison to reference samples

Target Surface Roughness (Ra):
  Draft (0.3mm):    15-20 μm (visible layers, acceptable for hidden parts)
  Standard (0.2mm): 10-15 μm (visible layers, acceptable for functional parts)
  Fine (0.1mm):      6-8 μm (minimal layer visibility)
  Ultra (0.06mm):    3-5 μm (near-smooth, post-processing optional)
```

### 3.2 Overhang Quality
```
BENCHMARK: Overhangs print cleanly up to rated angle
METHOD: Print overhang test model (20° to 70° in 5° increments)

Pass Criteria (without support):
  PLA:   Clean up to 55° overhang
  PETG:  Clean up to 50° overhang
  ABS:   Clean up to 45° overhang
  TPU:   Clean up to 40° overhang

"Clean" = no sagging > 0.5mm, no curling, no detachment
```

### 3.3 Bridging Capability
```
BENCHMARK: Unsupported horizontal spans print without sag
METHOD: Print bridging test (10mm to 100mm spans)

Pass Criteria (without support):
  PLA:   Clean bridge up to 60mm
  PETG:  Clean bridge up to 40mm
  ABS:   Clean bridge up to 30mm
  TPU:   Clean bridge up to 20mm

"Clean" = sag < 1mm at center of span
```

---

## 4. Material Usage Benchmarks

### 4.1 Material Waste
```
BENCHMARK: Actual material used vs estimated
METHOD: Weigh filament before and after print, compare to slicer estimate

Pass: Actual usage within ±5% of slicer estimate
```

### 4.2 Support Material Waste
```
BENCHMARK: Support structures use minimal material
METHOD: Compare normal vs tree support material usage

Target:
  Tree supports use ≤60% of material compared to normal supports
  Support interface (when enabled) adds ≤10% to support material
```

### 4.3 Print Time Accuracy
```
BENCHMARK: Actual print time matches estimate
METHOD: Time actual print vs slicer time estimate

Pass: Actual time within ±15% of estimate
Note: First layer typically adds 2-5 minutes (slower speed)
```

---

## 5. Fit and Assembly Benchmarks

### 5.1 Press-Fit Tolerance
```
BENCHMARK: Press-fit joints hold without adhesive
METHOD: Print mating parts with specified tolerance compensation

Pass Criteria:
  Insertion: Requires firm push but not hammer
  Retention: Holds under 5N pull force
  Alignment: Parts centered within ±0.2mm
```

### 5.2 Snap-Fit Engagement
```
BENCHMARK: Snap-fit features engage reliably
METHOD: Print snap-fit test pieces, test 50 engagement cycles

Pass Criteria:
  Engagement: Audible/tactile click on each engagement
  Retention: Holds under 3N pull force
  Durability: No visible crack or deformation after 50 cycles
  Material: PETG recommended (PLA too brittle for snap-fits)
```

### 5.3 Heat-Set Insert Pull-Out
```
BENCHMARK: Heat-set inserts hold under load
METHOD: Install M3 brass insert, apply tensile load

Pass Criteria:
  Pull-out force: ≥100N for M3 in PETG
  Torque resistance: ≥0.5 Nm for M3 bolt
  Alignment: Insert perpendicular within ±2°
```

---

## 6. Reference Print Benchmarks

### 6.1 Benchy (3D Boat)
```
BENCHMARK: Standard community benchmark model
METHOD: Print #3DBenchy at standard settings

Pass Criteria:
  - Hull waterline smooth and consistent
  - Overhangs under roof clean (no sag)
  - Chimney top round (not squished)
  - No stringing between features
  - Text on stern readable
  - Total height within ±0.2mm of 48mm target
```

### 6.2 Calibration Cube
```
BENCHMARK: XYZ calibration accuracy
METHOD: Print 20x20x20mm cube

Pass Criteria:
  - X: 20.0 ±0.2mm
  - Y: 20.0 ±0.2mm
  - Z: 20.0 ±0.1mm
  - Corners square (90° ±0.5°)
  - Top surface flat (no pillowing)
  - Bottom surface smooth (good first layer)
```

### 6.3 Temperature Tower
```
BENCHMARK: Optimal temperature for material
METHOD: Print temp tower spanning material range in 5°C steps

Pass Criteria:
  - Identify temperature with best overhang quality
  - Identify temperature with best stringing behavior
  - Identify temperature with best layer adhesion
  - Optimal = best compromise of all three
```

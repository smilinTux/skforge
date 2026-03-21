# 3D Printing Blueprint — Unit Test Specifications

## Overview

Unit tests validate that the generated 3D printing artifacts (geometry, slicer configs, material selections) meet correctness and safety requirements. These tests should be run after any blueprint generation to ensure the output is printable.

---

## 1. Mesh Validation Tests

### 1.1 Manifold Integrity
```
TEST: Generated STL mesh is manifold (watertight)
INPUT: Any generated STL file
ASSERT:
  - Every edge is shared by exactly 2 triangles
  - No holes in the mesh surface
  - All face normals point outward
  - No self-intersecting triangles
TOOLS: admesh, meshlab CLI, or numpy-stl validation
```

### 1.2 Non-Manifold Edge Detection
```
TEST: No non-manifold edges exist
INPUT: Generated STL file
ASSERT:
  - Zero edges shared by 0 or 3+ faces
  - Zero isolated vertices
  - Zero degenerate triangles (zero area)
```

### 1.3 Wall Thickness Minimum
```
TEST: All walls meet minimum thickness for selected material
INPUT: STL + MaterialSpec
ASSERT:
  - PLA: all walls >= 0.8mm
  - PETG: all walls >= 0.8mm
  - ABS: all walls >= 1.2mm
  - TPU: all walls >= 1.2mm
METHOD: Ray-casting thickness analysis or cross-section sampling
```

### 1.4 Build Volume Fit
```
TEST: Object fits within target printer build volume
INPUT: STL + PrinterProfile
ASSERT:
  - bounding_box.x <= printer.build_volume.x
  - bounding_box.y <= printer.build_volume.y
  - bounding_box.z <= printer.build_volume.z
  - If brim enabled: bounding_box.x + 2*brim_width <= build_volume.x
  - If raft enabled: bounding_box.x + 2*raft_margin <= build_volume.x
```

### 1.5 Dimension Accuracy
```
TEST: Generated geometry matches specified dimensions within tolerance
INPUT: STL + driver.md dimensions
ASSERT:
  - |actual_x - specified_x| <= tolerance (default ±0.5mm)
  - |actual_y - specified_y| <= tolerance
  - |actual_z - specified_z| <= tolerance
```

---

## 2. Material Specification Tests

### 2.1 Temperature Range Validity
```
TEST: Print temperatures are within material safe range
INPUT: SlicerConfig + MaterialSpec
ASSERT:
  - nozzle_temp >= material.nozzle_temp_c.min
  - nozzle_temp <= material.nozzle_temp_c.max
  - bed_temp >= material.bed_temp_c.min
  - bed_temp <= material.bed_temp_c.max
```

### 2.2 Printer Compatibility
```
TEST: Selected material is compatible with target printer
INPUT: MaterialSpec + PrinterProfile
ASSERT:
  - If material requires enclosure → printer has enclosure
  - If material is TPU → printer has direct drive extruder
  - printer.max_temp_nozzle >= material.nozzle_temp_c.recommended
  - printer.max_temp_bed >= material.bed_temp_c.recommended
```

### 2.3 Material Constraint Cascade
```
TEST: Material selection correctly constrains print settings
INPUT: MaterialSpec (ABS)
ASSERT:
  - cooling_fan_pct.other_layers == 0 (ABS needs no fan)
  - enclosure_required == true
  - safety.ventilation_required == true
  - bed_temp >= 90
```

### 2.4 Material File Schema Validation
```
TEST: All material YAML files conform to MaterialSpec schema
INPUT: Each file in material-specs/*.yml
ASSERT:
  - Has required fields: name, type, properties, print_settings, post_processing, storage
  - Temperature values are numeric and within sane ranges (0-350°C)
  - density is positive float
  - All referenced post-processing methods are valid
```

---

## 3. Slicer Configuration Tests

### 3.1 PrusaSlicer Profile Validity
```
TEST: Generated .ini file is valid PrusaSlicer config
INPUT: slicer-configs/prusa/*.ini
ASSERT:
  - File parses as valid INI format
  - layer_height > 0 and <= nozzle_diameter
  - first_layer_height > 0
  - perimeters >= 2
  - fill_density between 0 and 100
  - temperatures match MaterialSpec
```

### 3.2 Cura Profile Validity
```
TEST: Generated .curaprofile is valid Cura config
INPUT: slicer-configs/cura/*.curaprofile
ASSERT:
  - File parses as valid INI/JSON format
  - layer_height matches quality tier
  - wall_line_count >= 2
  - infill_sparse_density between 0 and 100
```

### 3.3 Bambu Studio Profile Validity
```
TEST: Generated .json is valid Bambu Studio config
INPUT: slicer-configs/bambu/*.json
ASSERT:
  - File parses as valid JSON
  - Required fields present (layer_height, wall_loops, sparse_infill_density)
  - Values within valid ranges
```

### 3.4 Cross-Slicer Consistency
```
TEST: All slicer profiles produce equivalent settings for same input
INPUT: Same driver.md → PrusaSlicer, Cura, Bambu Studio profiles
ASSERT:
  - Layer heights match across all slicers
  - Infill density within ±2% across slicers
  - Wall count matches across slicers
  - Temperatures match across slicers
  - Material-specific settings (fan, retraction) are consistent
```

---

## 4. Feature Dependency Tests

### 4.1 Dependency Resolution
```
TEST: Selecting a feature auto-includes its dependencies
INPUT: features.yml + selected features
ASSERT:
  - "Assembly Instructions" selected → "Multi-Part Assembly" included
  - "Multi-Part Assembly" selected → "STL Export" included
  - "Acetone Smoothing" selected → "ABS Support" included
  - "Waterproofing" selected → "Wall Thickness Validation" included
  - "Waterproofing" selected → "PETG Support" included
```

### 4.2 No Circular Dependencies
```
TEST: Feature dependency graph has no cycles
INPUT: features.yml
ASSERT:
  - Topological sort of dependency graph succeeds
  - No feature depends on itself (directly or transitively)
```

### 4.3 Default Feature Set Completeness
```
TEST: Default features form a valid minimal print configuration
INPUT: features.yml (all default: true features)
ASSERT:
  - At least one geometry format selected (STL Export)
  - At least one material selected (PLA)
  - At least one slicer profile selected (PrusaSlicer)
  - Manifold check is enabled
  - Bill of materials is included
```

---

## 5. Safety Tests

### 5.1 Temperature Safety
```
TEST: Generated G-code temperatures do not exceed printer maximums
INPUT: G-code + PrinterProfile
ASSERT:
  - All M104/M109 (nozzle temp) commands <= printer.max_temp_nozzle
  - All M140/M190 (bed temp) commands <= printer.max_temp_bed
  - No negative temperature values
```

### 5.2 Fume Warnings
```
TEST: ABS/ASA materials include ventilation warnings
INPUT: MaterialSpec where fumes == true
ASSERT:
  - safety.ventilation_required == true
  - safety.fume_description is non-empty
  - Post-processing acetone steps include safety notes
```

### 5.3 Food Safety Warnings
```
TEST: Non-food-safe materials warn against food contact
INPUT: MaterialSpec where food_safe == false
ASSERT:
  - Material is NOT listed in food-contact use cases
  - Warning exists in documentation output
```

---

## 6. Documentation Tests

### 6.1 Bill of Materials Completeness
```
TEST: BOM includes all required items
INPUT: Generated BOM
ASSERT:
  - Filament weight in grams listed
  - Filament cost estimate (if cost feature enabled)
  - All fasteners listed with size and quantity
  - All heat-set inserts listed with size
  - Print time estimate included
```

### 6.2 Assembly Instructions Ordering
```
TEST: Multi-part assembly instructions are in logical order
INPUT: Generated assembly guide
ASSERT:
  - Parts are listed in print order
  - Post-processing steps before assembly steps
  - Fastener installation before fit check
  - Final QA check is last step
```

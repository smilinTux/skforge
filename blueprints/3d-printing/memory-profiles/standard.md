# 3D Printing — Standard Printer Profile

## Target Hardware

Mid-range FDM 3D printers suitable for functional prototyping and production of enclosures, brackets, and household items.

## Reference Printers

| Printer | Build Volume | Features | Price Range |
|---------|-------------|----------|-------------|
| Prusa MK4S | 250x210x220mm | Direct drive, input shaping, auto bed level | $700-900 |
| Bambu Lab P1S | 256x256x256mm | Enclosed, CoreXY, high speed, AMS compatible | $600-800 |
| Creality K1 Max | 300x300x340mm | CoreXY, direct drive, input shaping | $500-700 |
| Anycubic Kobra 3 | 250x250x260mm | Multi-color capable, direct drive | $400-500 |

## Capabilities

### Materials Supported
- **PLA**: Full support, excellent quality
- **PETG**: Full support, good quality
- **ABS**: Supported if enclosed (P1S, K1 Max with enclosure)
- **TPU**: Supported (direct drive required — all standard-tier printers have this)

### Print Quality
- **Resolution**: 0.06mm - 0.3mm layer height
- **Speed**: 50-300mm/s (with input shaping)
- **Accuracy**: ±0.15mm XY, ±0.1mm Z
- **Max object size**: ~250x250x250mm typical

### Features Available
- Auto bed leveling (mesh-based)
- Direct drive extruder
- Input shaping / resonance compensation
- Heated bed (up to 100°C)
- PEI build plate (textured + smooth)
- Filament runout detection
- Power loss recovery
- Wi-Fi / LAN connectivity
- Camera monitoring (some models)

## Recommended Settings by Material

### PLA on Standard Printer
```yaml
layer_height: 0.2mm
nozzle_temp: 210°C
bed_temp: 60°C
speed: 100mm/s (with input shaping)
cooling: 100%
retraction: 0.8mm at 45mm/s
adhesion: none (PEI sufficient)
```

### PETG on Standard Printer
```yaml
layer_height: 0.2mm
nozzle_temp: 240°C
bed_temp: 80°C
speed: 60mm/s
cooling: 50%
retraction: 0.8mm at 40mm/s
adhesion: brim (5mm) on textured PEI
z_offset: +0.02mm (avoid bed adhesion damage)
```

### ABS on Standard Printer (enclosed only)
```yaml
layer_height: 0.2mm
nozzle_temp: 245°C
bed_temp: 100°C
speed: 50mm/s
cooling: 0% (bridges only at 30%)
retraction: 0.8mm at 40mm/s
adhesion: brim (8mm)
enclosure_temp: 40°C ambient
ventilation: REQUIRED
```

## Limitations
- Build volume limited to ~250-300mm per axis
- Single material (unless multi-material upgrade installed)
- ABS requires enclosed models only
- No heated chamber (ambient enclosure heat only)
- Composite filaments require hardened nozzle upgrade ($30-50)

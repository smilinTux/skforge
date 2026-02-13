# driver.md Specification

The `driver.md` file is the user's build configuration — a human-readable "order form" for custom software.

## Format

```markdown
# driver.md — [Project Name]

## Blueprint
category: [category-name]        # Required: which blueprint to use

## Language  
target: [language]                # Required: rust | go | python | java | dotnet | typescript | zig

## Profile
hardware: [profile]               # Optional: embedded | edge | desktop | server | cloud-native
memory: [profile]                 # Optional: embedded | standard | enterprise

## Features
<!-- Select features from the blueprint's features.yml -->
- [x] Feature name                # Selected — will be built
- [ ] Feature name                # Deselected — will be skipped

## Build
auto-test: true|false             # Run tests after generation (default: true)
auto-benchmark: true|false        # Run benchmarks after generation (default: false)
output: ./path/to/output/         # Output directory (default: ./)
```

## Rules

1. **category** must match a directory name under `blueprints/`
2. **target** determines which language template is used
3. **Features** use GitHub-style checkboxes — `[x]` = include, `[ ]` = exclude
4. If no features are selected, ALL default features are included (see features.yml `default: true`)
5. If `hardware` or `memory` profile is omitted, `server` and `standard` are used
6. Comments (lines starting with `#` or `<!-- -->`) are ignored by the forge

## Simple Mode

For users who just want defaults:

```markdown
# driver.md
category: load-balancers
target: rust
```

That's it. The forge uses all default features, standard memory profile, and server hardware profile.

## Advanced Mode

Full control over every feature:

```markdown
# driver.md — SKLoadBalancer

## Blueprint
category: load-balancers

## Language
target: rust

## Profile
hardware: cloud-native
memory: enterprise

## Features

### Core
- [x] HTTP/1.1 support
- [x] HTTP/2 support
- [x] HTTP/3 (QUIC)
- [x] Layer 4 load balancing
- [x] Layer 7 load balancing

### Algorithms
- [x] Round-robin
- [x] Weighted round-robin
- [x] Least connections
- [ ] IP hash
- [x] Consistent hashing
- [ ] Random

### Health Checks
- [x] Active HTTP health checks
- [x] Passive health checks
- [x] Custom health check scripts
- [x] Circuit breaker

### Security
- [x] TLS 1.3 termination
- [x] mTLS
- [x] Rate limiting
- [x] IP allowlist/blocklist
- [ ] WAF integration

### Observability
- [x] Prometheus metrics
- [x] OpenTelemetry tracing
- [x] JSON structured logging
- [x] Access logs

### Operational
- [x] Hot config reload
- [x] Graceful shutdown
- [x] Zero-downtime upgrades
- [ ] Clustering/HA

## Build
auto-test: true
auto-benchmark: true
output: ./sk-load-balancer/
```

# P2P Messaging Benchmarks

## Latency Benchmarks

| Metric | Target | Method |
|--------|--------|--------|
| Iroh send (LAN, direct) | < 50ms | End-to-end envelope delivery on local network |
| Iroh send (internet, hole-punch) | < 200ms | Direct QUIC connection through NAT |
| Iroh send (internet, relayed) | < 500ms | Via relay server fallback |
| Nostr publish + subscribe | < 5s | Publish to relay, subscriber receives event |
| Veilid routed message (3 hops) | < 10s | Onion-routed through 3 intermediate nodes |
| Tailscale/Netbird | < 100ms | WireGuard tunnel established |
| BitChat (1 hop BLE) | < 5s | Single Bluetooth hop |
| BitChat (5 hops BLE) | < 30s | Multi-hop mesh relay |
| File transport (Nextcloud) | < 2s | Write file + sync + poll detection |
| Failover to next transport | < 2s | Time from first failure to second attempt |
| Full failover chain (3 transports) | < 10s | Try 3 transports sequentially |

## Throughput Benchmarks

| Metric | Target | Method |
|--------|--------|--------|
| Messages per second (Iroh) | > 100 msg/s | Sustained send rate on good connection |
| Messages per second (Nostr) | > 10 msg/s | Relay publish rate |
| Envelope creation + signing | < 10ms | PGP sign + serialize |
| Envelope verification + decrypt | < 10ms | PGP verify + decrypt |
| Dedup lookup | < 1ms | Bloom filter + LRU cache check |
| Transport health check | < 100ms | All transports polled |

## Reliability Benchmarks

| Metric | Target | Method |
|--------|--------|--------|
| Delivery rate (broadcast mode) | > 99.9% | Message delivered via at least one transport |
| Delivery rate (failover, 3 transports) | > 99% | Retry across 3 transports |
| NAT traversal (Iroh) | > 90% | Direct connection without relay |
| Queue persistence | 100% | Messages survive process restart |
| Dedup accuracy | 100% | No false positives (no messages lost) |
| False dedup rate | < 0.001% | No false negatives (no duplicates processed) |

## Scalability Benchmarks

| Metric | Target | Method |
|--------|--------|--------|
| Concurrent transports | 17 | All transport modules active simultaneously |
| Concurrent peers | > 100 | Messages to/from 100+ distinct peers |
| Queue depth | > 10,000 | Messages queued without performance degradation |
| Peer store size | > 1,000 | Peer lookup remains < 1ms |
| Message history search | < 100ms | Full-text search across 100K messages |

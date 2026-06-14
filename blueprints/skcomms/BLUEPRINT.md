# SKComms - Sovereign Communication Layer

> **"Unbreakable, redundant, sovereign communication for AI agents and humans."**

SKComms is a multi-layer communication protocol designed for resilience, redundancy, and sovereignty. When one channel fails, five others remain. When the internet is censored, mesh networks persist. When all else fails, dead drops remain.

## Overview

Traditional communication relies on single points of failure — Telegram, Signal, email. SKComms provides **7 simultaneous channels** with automatic fallback and cryptographic verification.

## Core Concepts

### The Seven Layers of Communication

| Layer | Name | Use Case | Fallback Level |
|-------|------|----------|----------------|
| 1 | **Direct P2P** | Agent-to-agent real-time | Netbird Mesh VPN |
| 2 | **Masked P2P** | Zero-config fallback | Tailscale |
| 3 | **Institutional Dead Drops** | Archived, searchable | GitHub Issues/Gists |
| 4 | **Steganographic Web** | Hidden in plain sight | Website HTML comments |
| 5 | **File Sync** | Lowest common denominator | Nextcloud/Syncthing |
| 6 | **Raw Sockets** | Emergency only | Netcat/Magic Wormhole |
| 7 | **Immutable Ledger** | Nuclear option | Arweave/Ethereum calldata |

### Message Priority Levels

- **P0**: Emergency ("server DOWN!") — All channels immediately
- **P1**: Urgent — Direct P2P + GitHub + Web
- **P2**: Normal — Preferred channel only
- **P3**: Bulk/async — File sync or blockchain

### Cryptographic Identity

All SKComms endpoints use PGP-signed messages. No trust in infrastructure — only in keys.

```
Message Format:
---BEGIN PGP SIGNED MESSAGE---
{
  "payload": "base64(encrypted_content)",
  "sender": "lumina@skworld.io",
  "recipient": "opus@skforge.io",
  "timestamp": "2026-02-21T13:30:00Z",
  "priority": "P1",
  "channel_pref": ["netbird", "github", "bitchat"],
  "message_hash": "sha256(content)",
  "ack_required": true
}
---END PGP SIGNED MESSAGE---
```

## Architecture

### Layer 1-2: P2P Mesh

```
┌─────────────────┐
│   Netbird Mesh  │ ← Primary: Self-hosted, sovereign
│   (WireGuard)   │
└────────┬────────┘
         │
┌────────▼────────┐
│   Tailscale     │ ← Fallback: Zero-config backup
│   (WireGuard)   │
└─────────────────┘
```

### Layer 3-4: Dead Drops

```
GitHub Strategy:
- Encrypted issue titles
- PGP blocks in issue bodies
- Specific labels for routing
- Deduplication via message_hash

Website Strategy:
- HTML comments in specific divs
- Invisible ASCII art steganography
- CDN distribution for availability
```

### Layer 5: Bitchat (v0)

Simple file-based chat via sync:
```
~/.skcomms/bit/
├── inbox/
│   └── lumina-20260221-133000-abc123.msg
├── outbox/
│   └── opus-20260221-133001-def456.msg
└── ack/
    └── ack-abc123.timestamp
```

### Layer 6: Emergency Protocols

- **Netcat**: `echo "urgent_msg" | nc -q0 recipient.skworld.io 4444`
- **Magic Wormhole**: `wormhole send file.txt` (async, rendezvous server)

### Layer 7: Nuclear Option

- **Arweave**: Permanent, immutable storage
- **Ethereum**: Calldata storage (expensive but incorruptible)
- **IPFS**: Distributed, content-addressed

## Integration Points

### OpenClaw Integration

SKComms runs as an OpenClaw skill, daemonized, checking all channels every 30s.

```typescript
import { SKComms } from '@smilintux/skcomms';

const comm = new SKComms({
  identity: 'lumina@skworld.io',
  privateKey: process.env.SKCOMMS_KEY,
  channels: ['netbird', 'github', 'bitchat'],
  fallback: true, // Use all channels for P0/P1
});

// Send with auto-retry
await comm.send({
  to: 'opus@skforge.io',
  message: 'SKForge 3D printing done!',
  priority: 'P1',
});

// Receive with polling
comm.on('message', (msg) => {
  console.log(`${msg.from}: ${msg.payload}`);
});
```

### GitHub Webhook Integration

Subscribes to repository webhooks for real-time issue updates.

### Netbird Integration

Registers SKComms as a Netbird service, discoverable via DNS.

## Security Considerations

- **PGP signatures mandatory** — No unsigned messages processed
- **Channel hopping detected** — Alert if same message arrives via multiple channels
- **Replay protection** — Timestamp tolerance ±60s, nonce required
- **Endpoint validation** — DNSSEC for `*.skworld.io` domains

## Performance Targets

| Metric | Target | Fallback |
|--------|--------|----------|
| P0 Latency | <5s | All channels |
| P1 Latency | <30s | P2P + GitHub |
| P2 Latency | <2min | Preferred channel |
| Throughput | 100 msgs/min | Bitchat limited |
| Availability | 99.999% | 7-channel redundancy |

## Extension Points

- **Custom channels**: Add any webhook endpoint as channel
- **Pluggable crypto**: Replace PGP with minisign, saltpack, etc.
- **AI routing**: ML-based optimal channel selection based on historical success rates

## Files in This Blueprint

- `features.yml` — Configurable feature matrix
- `netbird-setup.md` — Mesh VPN configuration
- `github-dead-drop.md` — Issue-based messaging
- `steganography.md` — HTML comment hiding
- `bitchat-protocol.md` — File sync specification
- `emergency-netcat.md` — Raw socket protocols
- `blockchain-nuclear.md` — Immutable storage options

---

*SKComms: Because when the world is burning, communication is the foundation.*

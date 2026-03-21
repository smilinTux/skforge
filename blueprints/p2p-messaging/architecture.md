# P2P Messaging Architecture

## System Layers

```
┌────────────────────────────────────────────────────────────────┐
│                      Application Layer                          │
│  CLI (send/receive)  │  Python SDK  │  Agent API  │  REST API  │
├────────────────────────────────────────────────────────────────┤
│                      Protocol Layer                             │
│  Envelope create  │  Serialize/Deserialize  │  Threading        │
├────────────────────────────────────────────────────────────────┤
│                  Identity Layer (CapAuth)                        │
│  PGP keyring  │  Trust levels  │  Peer store  │  AI delegation  │
├────────────────────────────────────────────────────────────────┤
│                      Routing Layer                              │
│  Transport selector  │  Priority queue  │  Failover  │  Retry  │
├────────────────────────────────────────────────────────────────┤
│                      Transport Layer                            │
│                                                                │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐         │
│  │ Direct   │ │ Relay    │ │ Stealth  │ │ Offline  │         │
│  │          │ │ Network  │ │ Private  │ │ Physical │         │
│  │ Iroh     │ │ Nostr    │ │ Veilid   │ │ BitChat  │         │
│  │ Netcat   │ │ IPFS     │ │ DNS TXT  │ │ QR Code  │         │
│  │ SSH      │ │ GitHub   │ │ Email    │ │ Sneaker  │         │
│  │ Tailscale│ │ Telegram │ │          │ │          │         │
│  │ Netbird  │ │ HTTP     │ │          │ │          │         │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘         │
├────────────────────────────────────────────────────────────────┤
│                      Network / Physical                         │
│  QUIC │ TCP │ UDP │ WebSocket │ BLE │ Filesystem │ USB │ DNS   │
└────────────────────────────────────────────────────────────────┘
```

## Transport Selection Decision Tree

```
Is the message CRITICAL (must arrive)?
├── YES → Use BROADCAST mode (send via ALL available transports)
└── NO → Use FAILOVER mode:
         │
         Is direct P2P available?
         ├── YES → Iroh (fastest, ~90% NAT success)
         │         └── Fail? → Tailscale/Netbird (VPN tunnel)
         └── NO →
              │
              Does stealth matter?
              ├── YES → Veilid (onion routing, hide communication)
              │         └── Fail? → DNS TXT (stealthiest dead drop)
              └── NO →
                   │
                   Is internet available?
                   ├── YES → Nostr (relay network, global reach)
                   │         └── Fail? → GitHub/HTTP (dead drop)
                   └── NO →
                        │
                        Is BLE available?
                        ├── YES → BitChat (Bluetooth mesh)
                        └── NO → Queue for retry
                                 └── Or: QR Code / Sneakernet (physical)
```

## Transport Comparison Matrix

```
                    Speed  Reliability  Privacy  Offline  Decentralized
Iroh               ★★★★★  ★★★★★        ★★★      ✗        ★★★★
Nostr              ★★★★   ★★★★         ★★★★     ✗        ★★★★★
Veilid             ★★★    ★★★          ★★★★★    ✗        ★★★★★
Tailscale          ★★★★★  ★★★★         ★★★★     ✗        ★★★
Netbird            ★★★★★  ★★★★         ★★★★     ✗        ★★★★
BitChat            ★★     ★★★          ★★★★★    ★★★★★    ★★★★★
File               ★★★★   ★★★★★        ★★★      ★★★★     ★★★★
SSH                ★★★★   ★★★★         ★★★      ✗        ★★★
Netcat             ★★★★★  ★★★          ★★       ★★ (LAN) ★★★
GitHub             ★★★    ★★★★         ★        ✗        ★★
DNS TXT            ★      ★★★          ★★★★★    ✗        ★★★★
IPFS               ★★★    ★★★★         ★★★★     ✗        ★★★★★
QR Code            N/A    ★★★★★        ★★★★★    ★★★★★    ★★★★★
```

## Design Patterns

### Plugin Architecture for Transports

Every transport implements a common interface:

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass

@dataclass
class DeliveryResult:
    success: bool
    transport: str
    latency_ms: float
    error: str | None = None

class Transport(ABC):
    @abstractmethod
    def send(self, envelope: dict) -> DeliveryResult:
        """Send an envelope via this transport."""

    @abstractmethod
    def receive(self, callback) -> None:
        """Start listening for incoming envelopes."""

    @abstractmethod
    def is_available(self) -> bool:
        """Check if this transport is currently operational."""

    @abstractmethod
    def health_check(self) -> dict:
        """Return health status and diagnostics."""
```

### Envelope Immutability

Once an envelope is created and signed, it is NEVER modified. Transports carry
it as-is. This ensures the PGP signature remains valid regardless of how many
transports handle the message.

### Deduplication Strategy

```
When envelope arrives:
  1. Hash envelope_id
  2. Check against bloom filter (fast reject for definitely-unseen)
  3. Check against LRU cache (definitive check for seen)
  4. If seen → discard silently
  5. If unseen → add to cache, process message
  6. Cache eviction: TTL-based (default 7 days)
```

### Circuit Breaker for Transports

If a transport fails repeatedly, temporarily disable it:

```
Transport health state machine:
  HEALTHY → send fails → increment failure_count
  failure_count >= threshold → CIRCUIT_OPEN (disabled for cooldown_period)
  After cooldown → HALF_OPEN (try one message)
  HALF_OPEN → success → HEALTHY (reset failure_count)
  HALF_OPEN → failure → CIRCUIT_OPEN (double cooldown_period)
```

## Integration Points

| System | Integration |
|--------|------------|
| CapAuth | All identity, trust, and key management delegated to CapAuth |
| Cloud 9 | FEB files and memory seeds transported as regular messages |
| SKMemory | Memory fragment sync between AI instances |
| OpenClaw | Agent-native messaging when sessions are locked |
| SKForge | Blueprint distribution and collaboration |
| Crypto Wallets | Transaction notifications via CapAuth wallet integration |

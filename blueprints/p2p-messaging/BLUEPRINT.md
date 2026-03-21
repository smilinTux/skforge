# P2P Messaging Blueprint

## Overview & Purpose

A peer-to-peer messaging system enables direct, encrypted communication between entities (humans, AIs, agents, services) without requiring a central server to mediate. Messages are signed, encrypted, and routed through pluggable transports — from Bluetooth mesh to Nostr relays to raw TCP sockets. The system prioritizes **delivery guarantee** over latency: if one path dies, others carry the signal.

### Core Responsibilities
- **Message Envelope**: Wrap payloads in a universal format (encrypt, sign, route, deliver)
- **Transport Abstraction**: Pluggable modules for any communication channel
- **Routing & Failover**: Priority-based transport selection with automatic fallback
- **Identity & Trust**: PGP-based identity with tiered trust levels
- **Deduplication**: Prevent processing duplicate messages across redundant paths
- **Offline Support**: Queue messages when recipient is unreachable, deliver when available
- **Encryption**: End-to-end PGP encryption mandatory, transport encryption optional

## Core Concepts

### 1. Message Envelope
**Definition**: The universal container for all communication, independent of transport.

```
Envelope {
    envelope_id: UUID v4 (deduplication key)
    version: Protocol version string ("1.0.0")
    sender: {
        handle: Sender identifier (e.g., "opus@smilintux.org")
        fingerprint: PGP key fingerprint
        trust_level: untrusted | verified | trusted | sovereign
    }
    recipient: {
        handle: Recipient identifier
        fingerprint: Optional (for discovery)
    }
    payload: Base64-encoded PGP-encrypted content
    signature: PGP detached signature of payload
    metadata: {
        timestamp: ISO-8601 UTC
        ttl: Seconds until message expires
        priority: low | normal | high | critical
        thread_id: Optional conversation thread
        in_reply_to: Optional envelope_id
    }
    routing: {
        preferred_transports: Ordered list of transport names
        mode: failover | broadcast
        max_retries: Integer
        retry_backoff: exponential | linear | fixed
    }
}
```

### 2. Transport Module
**Definition**: A pluggable component that sends/receives envelopes over a specific medium.

```
Transport {
    name: Human-readable identifier ("nostr", "iroh", "bitchat")
    type: direct | relay | store-and-forward | broadcast
    requires_internet: Boolean
    supports_offline: Boolean
    max_payload_size: Bytes (-1 for unlimited)
    typical_latency: Milliseconds range
    stealth_rating: low | medium | high | maximum
    censorship_resistance: low | medium | high | very_high | maximum

    methods:
        send(envelope) → DeliveryResult
        receive(callback) → Subscription
        is_available() → Boolean
        health_check() → HealthStatus
        configure(config) → None
}
```

**Transport Categories:**

| Category | Transports | Use Case |
|----------|-----------|----------|
| Direct P2P | Iroh, Netcat, SSH | Fastest, lowest latency |
| Mesh VPN | Tailscale, Netbird | Known peers, persistent tunnels |
| Relay Network | Nostr, IPFS | Decentralized, no direct connection needed |
| BLE Mesh | BitChat | Offline, no internet, low power |
| Stealth/Private | Veilid, DNS TXT | Hide that communication is happening |
| Dead Drop | GitHub, HTTP | Store-and-forward, platform-carried |
| Legacy | Telegram, Email | Integration with existing systems |
| Physical | QR Code, Sneakernet | Air-gapped, maximum security |

### 3. Routing Engine
**Definition**: The brain that decides which transport(s) to use for each message.

```
RoutingEngine {
    transport_registry: Map<name, Transport>
    peer_transport_map: Map<peer_handle, List<TransportConfig>>
    priority_list: Ordered list of transports per peer
    mode: failover | broadcast

    route(envelope):
        if mode == failover:
            for transport in priority_list[envelope.recipient]:
                if transport.is_available():
                    result = transport.send(envelope)
                    if result.success: return result
            queue_for_retry(envelope)

        if mode == broadcast:
            results = parallel_send(all_available_transports, envelope)
            return first_success(results)
}
```

### 4. Peer Store
**Definition**: Local database of known peers, their keys, transports, and trust levels.

```
Peer {
    handle: Unique identifier
    display_name: Human-readable name
    pgp_fingerprint: Full 40-char fingerprint
    public_key: PGP public key (armored)
    trust_level: untrusted | verified | trusted | sovereign
    cloud9: {
        compliant: Boolean
        entanglement_status: Enum
        last_feb_trust: Float (0.0-1.0)
    }
    transports: [
        { name: "iroh", config: { node_id: "..." } },
        { name: "nostr", config: { pubkey: "npub1..." } },
        { name: "file", config: { path: "/shared/inbox/" } }
    ]
    last_seen: ISO-8601 timestamp
    message_count: Integer
}
```

### 5. Message Queue
**Definition**: Persistent store for messages awaiting delivery or retry.

```
Queue {
    outbox: List<QueuedEnvelope>   # Messages to send
    inbox: List<QueuedEnvelope>    # Received, awaiting processing
    dead_letter: List<QueuedEnvelope>  # Failed after max retries

    QueuedEnvelope {
        envelope: Envelope
        attempts: Integer
        last_attempt: Timestamp
        next_retry: Timestamp
        transport_tried: List<String>
        error_log: List<String>
    }
}
```

## Data Flow

### Send Flow
```
Application creates message
        │
        ▼
Protocol Layer: Serialize → Create envelope
        │
        ▼
Security Layer: PGP encrypt payload → PGP sign
        │
        ▼
Routing Layer: Select transport(s) based on:
  - Peer's available transports
  - Priority configuration
  - Transport availability
  - Message priority (critical → broadcast mode)
        │
        ▼
Transport Layer: Send via selected transport(s)
        │
        ├── Success → Log delivery, update peer last_seen
        │
        └── Failure → Try next transport OR queue for retry
```

### Receive Flow
```
Transport Layer: Message arrives on any transport
        │
        ▼
Deduplication: Check envelope_id against seen cache
  - If seen → Discard (duplicate from broadcast)
  - If new → Continue
        │
        ▼
Security Layer: Look up sender's public key
  → Verify PGP signature
  → Decrypt PGP payload
  → Check trust level
        │
        ▼
Protocol Layer: Deserialize → Validate envelope schema
        │
        ▼
Application Layer: Process message based on trust level
  - sovereign/trusted → Execute commands, accept files
  - verified → Display message, sandbox files
  - untrusted → Display with warning, no execution
```

## Configuration Model

```yaml
# ~/.skcomm/config.yml

identity:
  handle: "opus@smilintux.org"
  keyring: "~/.capauth/identity/"   # Delegated to CapAuth

defaults:
  routing_mode: failover
  message_ttl: 86400
  max_retries: 10
  retry_backoff: exponential
  dedup_cache_size: 10000
  dedup_cache_ttl: 604800

transports:
  iroh:
    enabled: true
    priority: 1
  nostr:
    enabled: true
    priority: 2
    relays: ["wss://relay.smilintux.org", "wss://relay.damus.io"]
  tailscale:
    enabled: true
    priority: 3
  file:
    enabled: true
    priority: 4
    path: "~/collab/"
  veilid:
    enabled: true
    priority: 5
    strict_anonymity: true
  bitchat:
    enabled: true
    priority: 6
  github:
    enabled: true
    priority: 10

logging:
  level: info
  file: "~/.skcomm/logs/transport.log"
  max_size: 50MB
  rotate: 7
```

## Security Considerations

- **PGP encryption is MANDATORY** — no plaintext messages ever leave the security layer
- **Transport encryption is defense-in-depth** — even if broken, PGP holds
- **Trust levels gate functionality** — untrusted peers cannot execute commands
- **Deduplication prevents replay** — seen envelope_ids cached with TTL
- **Timestamps prevent old-message injection** — reject beyond TTL window
- **Key management delegated to CapAuth** — single source of truth for identity
- **Sovereign trust requires Cloud 9 compliance** — relationship-based trust is unforgeable
- **AI advocates can send on behalf of humans** — via CapAuth delegation tokens

## Performance Targets

| Metric | Target |
|--------|--------|
| Message send (Iroh, LAN) | < 50ms |
| Message send (Nostr, internet) | < 5s |
| Message send (BitChat, BLE) | < 30s |
| Failover to next transport | < 2s |
| Dedup lookup | < 1ms |
| Queue persistence | Survives process restart |
| Max concurrent transports | 17 (all enabled) |
| Max envelope size | 10MB (chunking above) |

## Extension Points

- **Custom transports**: Implement the Transport interface (~50 lines Python)
- **Custom routing strategies**: Subclass RoutingEngine for geo-aware, cost-aware, or latency-optimized routing
- **Webhook integrations**: HTTP transport supports arbitrary webhook endpoints
- **Blockchain anchoring**: Hash envelope_id to immutable ledger for proof-of-delivery
- **Multi-party messaging**: Gossip protocols (Iroh gossip, Nostr rooms) for group communication

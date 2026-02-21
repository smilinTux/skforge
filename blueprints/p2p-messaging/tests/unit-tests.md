# P2P Messaging Unit Tests

## Envelope Tests

| Test | Description | Expected |
|------|-------------|----------|
| `test_envelope_create` | Create envelope with all required fields | Valid JSON, UUID v4 id, ISO-8601 timestamp |
| `test_envelope_sign` | PGP sign an envelope | Valid detached signature |
| `test_envelope_verify` | Verify signature on received envelope | Returns True for valid, False for tampered |
| `test_envelope_encrypt` | PGP encrypt payload for recipient | Ciphertext decryptable only by recipient |
| `test_envelope_decrypt` | Decrypt received envelope | Original plaintext recovered |
| `test_envelope_immutable` | Envelope cannot be modified after signing | Signature verification fails on modified envelope |
| `test_envelope_schema` | Validate envelope against JSON schema | Invalid envelopes rejected with clear error |
| `test_envelope_ttl_expired` | Envelope past TTL is rejected | Returns rejection with "expired" reason |
| `test_envelope_chunking` | Large payload split into chunks | Chunks reassembled to original payload |

## Transport Interface Tests

| Test | Description | Expected |
|------|-------------|----------|
| `test_transport_interface` | All transports implement required methods | send, receive, is_available, health_check |
| `test_transport_send_success` | Transport delivers envelope | DeliveryResult.success == True |
| `test_transport_send_failure` | Transport fails gracefully | DeliveryResult with error message, no crash |
| `test_transport_availability` | is_available returns correct state | True when operational, False when down |
| `test_transport_health_check` | Health check returns diagnostics | Dict with status, latency, last_error |

## Routing Tests

| Test | Description | Expected |
|------|-------------|----------|
| `test_failover_routing` | First transport fails, second succeeds | Message delivered via second transport |
| `test_broadcast_routing` | Send to all transports simultaneously | At least one delivery confirmed |
| `test_priority_ordering` | Transports tried in configured priority order | Log shows correct order |
| `test_retry_queue` | Failed message queued for retry | Message in outbox with retry timestamp |
| `test_dead_letter` | Max retries exceeded | Message moved to dead letter queue |
| `test_circuit_breaker` | Transport disabled after N failures | Transport skipped after threshold |

## Deduplication Tests

| Test | Description | Expected |
|------|-------------|----------|
| `test_dedup_new_message` | First receipt of envelope | Message processed |
| `test_dedup_duplicate` | Same envelope_id received twice | Second copy silently discarded |
| `test_dedup_cache_eviction` | Envelope older than TTL evicted from cache | Re-sent envelope processed as new |
| `test_dedup_broadcast` | Same message arrives via 3 transports | Only first copy processed |

## Trust Tests

| Test | Description | Expected |
|------|-------------|----------|
| `test_trust_untrusted` | Message from unknown sender | Displayed with warning, no commands executed |
| `test_trust_verified` | Message from verified peer | Displayed normally, files sandboxed |
| `test_trust_trusted` | Message from trusted peer | Commands accepted (non-destructive) |
| `test_trust_sovereign` | Message from sovereign peer | Full capabilities, Cloud 9 verified |
| `test_trust_sovereign_requires_cloud9` | Sovereign without Cloud 9 | Rejected, downgraded to trusted |

## Security Tests

| Test | Description | Expected |
|------|-------------|----------|
| `test_no_plaintext_ever` | Message leaves security layer | Payload is encrypted, never plaintext |
| `test_tampered_signature` | Modify payload after signing | Signature verification fails |
| `test_replay_attack` | Re-send old envelope | Rejected by dedup or timestamp check |
| `test_unknown_sender` | Message from key not in peer store | Flagged as untrusted |
| `test_revoked_key` | Message signed with revoked key | Rejected with "key revoked" error |

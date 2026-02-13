# Load Balancer Unit Tests Specification

## Overview
This document defines comprehensive unit test requirements for any generated load balancer implementation. Every test MUST pass for the implementation to be considered complete and production-ready.

## Test Categories

### 1. Connection Handling Tests

#### 1.1 Basic Connection Management
**Test: `test_accept_client_connection`**
- **Purpose**: Verify the load balancer can accept client connections
- **Setup**: Start load balancer on port 8080
- **Action**: Connect client to port 8080
- **Assert**: Connection is successfully established
- **Cleanup**: Close client connection

**Test: `test_concurrent_connections`**
- **Purpose**: Verify handling of multiple simultaneous connections
- **Setup**: Configure max_connections = 1000
- **Action**: Open 500 concurrent client connections
- **Assert**: All connections are accepted and tracked
- **Cleanup**: Close all connections

**Test: `test_connection_limit_enforcement`**
- **Purpose**: Verify connection limits are enforced
- **Setup**: Configure max_connections = 10
- **Action**: Attempt to open 15 connections
- **Assert**: First 10 connections succeed, remaining 5 are rejected
- **Cleanup**: Close all connections

**Test: `test_connection_timeout`**
- **Purpose**: Verify idle connections are properly timed out
- **Setup**: Configure connection_timeout = 5 seconds
- **Action**: Open connection, send no data for 10 seconds
- **Assert**: Connection is closed after 5 seconds
- **Cleanup**: Verify connection resources are released

#### 1.2 Backend Connection Management
**Test: `test_backend_connection_establishment`**
- **Purpose**: Verify connections to backend servers
- **Setup**: Start mock backend on port 9001
- **Action**: Send request through load balancer
- **Assert**: Backend connection is established and request forwarded
- **Cleanup**: Close connections

**Test: `test_backend_connection_pooling`**
- **Purpose**: Verify connection pooling to backends
- **Setup**: Enable connection pooling, max_pool_size = 5
- **Action**: Send 10 sequential requests to same backend
- **Assert**: Maximum of 5 backend connections are created
- **Cleanup**: Verify pool cleanup

**Test: `test_backend_connection_failure`**
- **Purpose**: Verify handling of backend connection failures
- **Setup**: Configure backend to unreachable address
- **Action**: Send request through load balancer
- **Assert**: Appropriate error response (502/503) returned to client
- **Cleanup**: None required

### 2. Load Balancing Algorithm Tests

#### 2.1 Round Robin Algorithm
**Test: `test_round_robin_distribution`**
- **Purpose**: Verify round robin distributes requests evenly
- **Setup**: 3 backend servers, round robin algorithm
- **Action**: Send 9 requests
- **Assert**: Each backend receives exactly 3 requests
- **Expected sequence**: Backend1 → Backend2 → Backend3 → Backend1 → ...

**Test: `test_round_robin_with_failed_backend`**
- **Purpose**: Verify round robin skips failed backends
- **Setup**: 3 backends, mark Backend2 as unhealthy
- **Action**: Send 6 requests
- **Assert**: Backend1 gets 3 requests, Backend3 gets 3 requests, Backend2 gets 0
- **Expected sequence**: Backend1 → Backend3 → Backend1 → Backend3 → ...

#### 2.2 Weighted Round Robin Algorithm
**Test: `test_weighted_round_robin_distribution`**
- **Purpose**: Verify weighted distribution
- **Setup**: 
  - Backend1: weight=3
  - Backend2: weight=2  
  - Backend3: weight=1
- **Action**: Send 12 requests
- **Assert**: Backend1: 6 requests, Backend2: 4 requests, Backend3: 2 requests
- **Expected ratio**: 3:2:1

**Test: `test_weighted_round_robin_zero_weight`**
- **Purpose**: Verify zero-weight backends are never selected
- **Setup**: Backend1: weight=1, Backend2: weight=0
- **Action**: Send 10 requests
- **Assert**: Backend1: 10 requests, Backend2: 0 requests

#### 2.3 Least Connections Algorithm
**Test: `test_least_connections_selection`**
- **Purpose**: Verify least connections algorithm selects correct backend
- **Setup**: 3 backends with least connections algorithm
- **Action**: 
  1. Send 2 long-running requests to Backend1
  2. Send 1 request to Backend2
  3. Send new request
- **Assert**: New request goes to Backend3 (0 connections)

**Test: `test_least_connections_tie_breaking`**
- **Purpose**: Verify behavior when connection counts are equal
- **Setup**: 3 backends, all with 0 connections
- **Action**: Send single request
- **Assert**: Request goes to first available backend (deterministic tie-breaking)

#### 2.4 IP Hash Algorithm
**Test: `test_ip_hash_consistency`**
- **Purpose**: Verify same client IP always routes to same backend
- **Setup**: 3 backends, IP hash algorithm
- **Action**: Send 10 requests from same client IP (192.168.1.100)
- **Assert**: All requests go to same backend

**Test: `test_ip_hash_distribution`**
- **Purpose**: Verify different IPs distribute across backends
- **Setup**: 3 backends, IP hash algorithm
- **Action**: Send requests from 100 different IP addresses
- **Assert**: Requests are distributed across all backends (roughly 33% each)

#### 2.5 Consistent Hashing Algorithm
**Test: `test_consistent_hashing_stability`**
- **Purpose**: Verify minimal disruption when backend added/removed
- **Setup**: 3 backends with consistent hashing, 1000 client IPs
- **Action**: 
  1. Route all 1000 IPs and record backend assignments
  2. Add 4th backend
  3. Route same 1000 IPs again
- **Assert**: < 25% of assignments change (ideal: ~16.7%)

### 3. Health Check Tests

#### 3.1 TCP Health Checks
**Test: `test_tcp_health_check_healthy`**
- **Purpose**: Verify TCP health check marks healthy backend as healthy
- **Setup**: Mock backend accepting TCP connections
- **Action**: Run health check
- **Assert**: Backend status = HEALTHY

**Test: `test_tcp_health_check_unhealthy`**
- **Purpose**: Verify TCP health check marks unreachable backend as unhealthy
- **Setup**: Backend server stopped
- **Action**: Run health check
- **Assert**: Backend status = UNHEALTHY

**Test: `test_tcp_health_check_timeout`**
- **Purpose**: Verify health check timeout handling
- **Setup**: Mock backend that accepts but never responds, timeout = 2s
- **Action**: Run health check
- **Assert**: Health check fails after 2 seconds, status = UNHEALTHY

#### 3.2 HTTP Health Checks
**Test: `test_http_health_check_200_response`**
- **Purpose**: Verify HTTP 200 response marks backend healthy
- **Setup**: Mock backend returning HTTP 200 OK for /health
- **Action**: Run HTTP health check on /health
- **Assert**: Backend status = HEALTHY

**Test: `test_http_health_check_404_response`**
- **Purpose**: Verify HTTP 404 response marks backend unhealthy
- **Setup**: Mock backend returning HTTP 404 for /health
- **Action**: Run HTTP health check on /health
- **Assert**: Backend status = UNHEALTHY

**Test: `test_http_health_check_custom_path`**
- **Purpose**: Verify custom health check paths work
- **Setup**: Backend with /custom/health endpoint
- **Action**: Configure health check for /custom/health
- **Assert**: Health check uses correct path

#### 3.3 Health Check State Transitions
**Test: `test_health_check_recovery`**
- **Purpose**: Verify unhealthy backend recovery process
- **Setup**: Backend initially down, then started
- **Action**: 
  1. Verify backend marked UNHEALTHY
  2. Start backend
  3. Wait for recovery_checks attempts
- **Assert**: Backend transitions to HEALTHY after configured recovery attempts

**Test: `test_health_check_failure_threshold`**
- **Purpose**: Verify failure threshold before marking unhealthy
- **Setup**: Configure failure_threshold = 3
- **Action**: 
  1. Backend responds normally
  2. Backend starts failing health checks
- **Assert**: Backend remains HEALTHY until 3 consecutive failures

### 4. HTTP Protocol Tests

#### 4.1 HTTP/1.1 Support
**Test: `test_http_1_1_request_parsing`**
- **Purpose**: Verify correct HTTP/1.1 request parsing
- **Setup**: Load balancer with HTTP listener
- **Action**: Send valid HTTP/1.1 request
```http
GET /test HTTP/1.1
Host: example.com
User-Agent: TestClient/1.0
Content-Length: 0

```
- **Assert**: Request is properly parsed and forwarded

**Test: `test_http_keep_alive`**
- **Purpose**: Verify HTTP/1.1 keep-alive connections
- **Setup**: Enable keep-alive, timeout = 30s
- **Action**: 
  1. Send first HTTP request with `Connection: keep-alive`
  2. Send second request on same connection
- **Assert**: Both requests handled on single TCP connection

**Test: `test_http_chunked_encoding`**
- **Purpose**: Verify chunked transfer encoding support
- **Setup**: Backend sends chunked response
- **Action**: Send HTTP request
- **Assert**: Chunked response properly forwarded to client

#### 4.2 HTTP Header Handling
**Test: `test_http_header_forwarding`**
- **Purpose**: Verify standard headers are forwarded
- **Setup**: Load balancer between client and backend
- **Action**: Send request with custom headers
```http
GET /test HTTP/1.1
Host: example.com
X-Custom-Header: test-value
Authorization: Bearer token123
```
- **Assert**: All headers forwarded to backend

**Test: `test_x_forwarded_for_injection`**
- **Purpose**: Verify X-Forwarded-For header injection
- **Setup**: Client IP = 192.168.1.100
- **Action**: Send HTTP request without X-Forwarded-For header
- **Assert**: Backend receives `X-Forwarded-For: 192.168.1.100`

**Test: `test_x_forwarded_proto_injection`**
- **Purpose**: Verify X-Forwarded-Proto header injection
- **Setup**: HTTPS listener (protocol = https)
- **Action**: Send HTTPS request
- **Assert**: Backend receives `X-Forwarded-Proto: https`

#### 4.3 HTTP Methods Support
**Test: `test_http_methods_support`**
- **Purpose**: Verify all standard HTTP methods are supported
- **Setup**: Backend that echoes request method
- **Action**: Send requests with methods: GET, POST, PUT, DELETE, HEAD, OPTIONS, PATCH
- **Assert**: All methods properly forwarded and responses returned

### 5. SSL/TLS Tests

#### 5.1 SSL Termination
**Test: `test_ssl_termination_basic`**
- **Purpose**: Verify basic SSL termination functionality
- **Setup**: Load balancer with SSL certificate, plain HTTP backend
- **Action**: Send HTTPS request to load balancer
- **Assert**: 
  - SSL handshake completes successfully
  - Request forwarded to backend as plain HTTP
  - Response returned encrypted to client

**Test: `test_ssl_certificate_validation`**
- **Purpose**: Verify SSL certificate is properly presented
- **Setup**: Load balancer with valid certificate for example.com
- **Action**: Connect with SSL client verifying certificate
- **Assert**: Certificate validation passes

**Test: `test_ssl_cipher_suites`**
- **Purpose**: Verify strong cipher suites are supported
- **Setup**: Configure modern SSL cipher suites
- **Action**: Negotiate SSL connection
- **Assert**: Strong cipher suite is selected (e.g., ECDHE-RSA-AES256-GCM-SHA384)

#### 5.2 SNI Support
**Test: `test_sni_multiple_certificates`**
- **Purpose**: Verify Server Name Indication with multiple certificates
- **Setup**: 
  - Certificate for example.com
  - Certificate for test.com
- **Action**: 
  1. HTTPS request to example.com
  2. HTTPS request to test.com
- **Assert**: Correct certificate presented for each hostname

### 6. Error Handling Tests

#### 6.1 Backend Error Handling
**Test: `test_backend_connection_refused`**
- **Purpose**: Verify handling when backend refuses connections
- **Setup**: Backend server stopped
- **Action**: Send HTTP request
- **Assert**: Client receives 502 Bad Gateway response

**Test: `test_backend_timeout`**
- **Purpose**: Verify handling of backend response timeouts
- **Setup**: Backend that accepts but never responds, timeout = 5s
- **Action**: Send HTTP request
- **Assert**: Client receives 504 Gateway Timeout after 5 seconds

**Test: `test_all_backends_down`**
- **Purpose**: Verify behavior when all backends are unavailable
- **Setup**: All backends marked unhealthy
- **Action**: Send HTTP request
- **Assert**: Client receives 503 Service Unavailable

#### 6.2 Protocol Error Handling
**Test: `test_malformed_http_request`**
- **Purpose**: Verify handling of malformed HTTP requests
- **Setup**: Load balancer with HTTP listener
- **Action**: Send invalid HTTP request
```
INVALID REQUEST FORMAT
Not HTTP at all!
```
- **Assert**: Connection closed or 400 Bad Request returned

**Test: `test_oversized_request`**
- **Purpose**: Verify handling of oversized requests
- **Setup**: Configure max_request_size = 1MB
- **Action**: Send 2MB HTTP request
- **Assert**: Request rejected with 413 Request Entity Too Large

### 7. Configuration Tests

#### 7.1 Configuration Loading
**Test: `test_valid_configuration_loading`**
- **Purpose**: Verify valid configuration is loaded correctly
- **Setup**: Create valid configuration file
- **Action**: Start load balancer with configuration
- **Assert**: Configuration loaded without errors, all listeners started

**Test: `test_invalid_configuration_rejection`**
- **Purpose**: Verify invalid configuration is rejected
- **Setup**: Create configuration with syntax errors
- **Action**: Attempt to start load balancer
- **Assert**: Load balancer fails to start with clear error message

#### 7.2 Configuration Validation
**Test: `test_missing_required_fields`**
- **Purpose**: Verify validation catches missing required fields
- **Setup**: Configuration missing required backend servers
- **Action**: Load configuration
- **Assert**: Validation error identifying missing fields

**Test: `test_invalid_port_ranges`**
- **Purpose**: Verify port validation
- **Setup**: Configuration with port = 70000 (invalid)
- **Action**: Load configuration
- **Assert**: Validation error for invalid port

### 8. Rate Limiting Tests

#### 8.1 Basic Rate Limiting
**Test: `test_rate_limit_enforcement`**
- **Purpose**: Verify rate limiting blocks excessive requests
- **Setup**: Configure rate limit = 10 requests/second per IP
- **Action**: Send 20 requests in 1 second from single IP
- **Assert**: First 10 requests succeed, remaining 10 return 429 Too Many Requests

**Test: `test_rate_limit_window_reset`**
- **Purpose**: Verify rate limit windows reset properly
- **Setup**: Rate limit = 5 requests/second
- **Action**: 
  1. Send 5 requests (should succeed)
  2. Wait 1 second
  3. Send 5 more requests
- **Assert**: All 10 requests succeed (second batch in new window)

#### 8.2 Rate Limiting Scope
**Test: `test_rate_limit_per_ip`**
- **Purpose**: Verify rate limiting is isolated per client IP
- **Setup**: Rate limit = 5 requests/second per IP
- **Action**: Send 5 requests each from 2 different IPs simultaneously
- **Assert**: All 10 requests succeed (5 from each IP)

### 9. Metrics and Monitoring Tests

#### 9.1 Connection Metrics
**Test: `test_connection_count_metrics`**
- **Purpose**: Verify connection count metrics are accurate
- **Setup**: Enable metrics collection
- **Action**: 
  1. Open 5 client connections
  2. Check metrics
  3. Close 2 connections
  4. Check metrics again
- **Assert**: 
  - Metrics show 5 active connections after step 2
  - Metrics show 3 active connections after step 4

#### 9.2 Request Metrics
**Test: `test_request_count_metrics`**
- **Purpose**: Verify request count metrics
- **Setup**: Enable metrics collection
- **Action**: Send 10 HTTP requests
- **Assert**: Metrics show total_requests = 10

**Test: `test_response_time_metrics`**
- **Purpose**: Verify response time metrics collection
- **Setup**: Enable metrics, backend with 100ms delay
- **Action**: Send HTTP request
- **Assert**: Response time metric approximately 100ms (±10ms tolerance)

### 10. Memory Management Tests

#### 10.1 Memory Leak Detection
**Test: `test_connection_memory_cleanup`**
- **Purpose**: Verify memory is properly freed when connections close
- **Setup**: Monitor memory usage
- **Action**: 
  1. Record baseline memory
  2. Open 1000 connections
  3. Close all connections
  4. Force garbage collection
  5. Record final memory
- **Assert**: Final memory ≤ baseline + 1% (accounting for metadata)

**Test: `test_request_buffer_cleanup`**
- **Purpose**: Verify request buffers are properly freed
- **Setup**: Monitor memory usage
- **Action**: 
  1. Send 100 large HTTP requests (1MB each)
  2. Wait for responses
  3. Force garbage collection
- **Assert**: Memory returns to baseline after processing

### 11. Concurrency Tests

#### 11.1 Thread Safety
**Test: `test_concurrent_backend_selection`**
- **Purpose**: Verify thread-safe backend selection
- **Setup**: Multi-threaded environment, 3 backends
- **Action**: Send 1000 concurrent requests from multiple threads
- **Assert**: 
  - No race conditions or crashes
  - Requests distributed according to algorithm
  - All requests receive valid responses

### 12. Integration Tests

#### 12.1 End-to-End HTTP Flow
**Test: `test_complete_http_flow`**
- **Purpose**: Verify complete HTTP request/response flow
- **Setup**: Client → Load Balancer → Backend
- **Action**: Send HTTP POST with body
```http
POST /api/users HTTP/1.1
Host: api.example.com
Content-Type: application/json
Content-Length: 45

{"name": "John Doe", "email": "john@example.com"}
```
- **Assert**: 
  - Backend receives exact request including body
  - Backend response returned to client unmodified
  - All headers preserved

## Test Execution Requirements

### Test Environment
- **Isolation**: Each test runs in isolated environment
- **Cleanup**: All resources cleaned up after each test
- **Repeatability**: Tests produce same results on multiple runs
- **Speed**: Full test suite completes in < 5 minutes

### Test Data
- **Deterministic**: Use fixed test data for reproducible results  
- **Comprehensive**: Cover edge cases and boundary conditions
- **Realistic**: Use realistic payloads and scenarios

### Failure Handling
- **Clear Messages**: Test failures include clear diagnostic information
- **Fast Failure**: Tests fail fast when requirements not met
- **Debugging Info**: Include relevant logs and state information

### Coverage Requirements
- **Functionality**: All implemented features must have tests
- **Error Paths**: All error conditions must be tested
- **Edge Cases**: Boundary conditions and edge cases covered
- **Performance**: Basic performance characteristics validated

## Success Criteria
A load balancer implementation passes unit tests if:
1. **100% test pass rate** on all applicable tests
2. **No memory leaks** detected in leak detection tests
3. **Performance targets met** in basic performance tests
4. **No race conditions** detected in concurrency tests
5. **Clean shutdown** without hanging resources
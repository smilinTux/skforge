# Load Balancer Performance Benchmarks

## Overview
This document defines performance benchmarks and targets for load balancer implementations. These benchmarks establish minimum acceptable performance thresholds and provide standardized testing methodology.

## Test Environment Specifications

### Hardware Requirements
- **CPU**: 4+ cores, 2.0+ GHz
- **RAM**: 8GB minimum, 16GB recommended  
- **Network**: Gigabit Ethernet (1 Gbps)
- **Storage**: SSD for logs and temporary files

### Software Environment
- **OS**: Linux (Ubuntu 20.04+ or equivalent)
- **Kernel**: Version 5.4+ (for modern networking features)
- **Network Stack**: Optimized TCP settings
- **Monitoring**: System resource monitoring enabled

### Network Configuration
```bash
# Optimize TCP settings for high-performance testing
echo 'net.core.somaxconn = 65535' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 65535' >> /etc/sysctl.conf
echo 'net.core.netdev_max_backlog = 30000' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf
```

## Performance Targets by Feature Set

### 1. Minimal Feature Set (TCP Proxy Only)
**Features**: Basic TCP proxy, round-robin load balancing

| Metric | Target | Minimum Acceptable |
|--------|--------|-------------------|
| **Requests/Second** | 100,000 RPS | 75,000 RPS |
| **Concurrent Connections** | 10,000 | 5,000 |
| **Latency P50** | < 0.5ms | < 1ms |
| **Latency P95** | < 2ms | < 5ms |
| **Latency P99** | < 10ms | < 20ms |
| **Memory per Connection** | < 2KB | < 4KB |
| **CPU Usage** | < 50% | < 70% |

### 2. Basic HTTP Feature Set
**Features**: HTTP/1.1, health checks, multiple algorithms

| Metric | Target | Minimum Acceptable |
|--------|--------|-------------------|
| **Requests/Second** | 50,000 RPS | 35,000 RPS |
| **Concurrent Connections** | 8,000 | 5,000 |
| **Latency P50** | < 1ms | < 2ms |
| **Latency P95** | < 5ms | < 10ms |
| **Latency P99** | < 15ms | < 30ms |
| **Memory per Connection** | < 4KB | < 8KB |
| **CPU Usage** | < 60% | < 80% |

### 3. SSL Termination Feature Set  
**Features**: HTTPS, SSL termination, certificate management

| Metric | Target | Minimum Acceptable |
|--------|--------|-------------------|
| **Requests/Second** | 25,000 RPS | 15,000 RPS |
| **Concurrent Connections** | 5,000 | 3,000 |
| **SSL Handshakes/Second** | 2,000 | 1,000 |
| **Latency P50** | < 2ms | < 5ms |
| **Latency P95** | < 10ms | < 20ms |
| **Latency P99** | < 25ms | < 50ms |
| **Memory per Connection** | < 8KB | < 16KB |
| **CPU Usage** | < 70% | < 85% |

### 4. Full Feature Set
**Features**: HTTP/2, caching, compression, WAF, rate limiting

| Metric | Target | Minimum Acceptable |
|--------|--------|-------------------|
| **Requests/Second** | 15,000 RPS | 10,000 RPS |
| **Concurrent Connections** | 3,000 | 2,000 |
| **Latency P50** | < 3ms | < 6ms |
| **Latency P95** | < 15ms | < 30ms |
| **Latency P99** | < 40ms | < 80ms |
| **Memory per Connection** | < 16KB | < 32KB |
| **CPU Usage** | < 80% | < 90% |

## Detailed Benchmark Tests

### 1. Raw Throughput Tests

#### Test: `benchmark_tcp_throughput`
**Purpose**: Measure maximum TCP proxy throughput
**Setup**:
- Load balancer in TCP proxy mode
- 3 backend servers (echo servers)
- Round-robin algorithm

**Test Procedure**:
```bash
# Use multiple wrk instances for load generation
for i in {1..8}; do
  wrk -t 4 -c 125 -d 60s --latency http://loadbalancer:8080/ &
done
wait

# Total: 32 threads, 1000 connections, 60 seconds
```

**Measurements**:
- Total requests per second
- Latency distribution (P50, P90, P95, P99, P99.9, P99.99)
- Error rate (must be < 0.01%)
- Connection establishment rate

**Success Criteria**:
- Achieve target RPS for feature set
- Latency percentiles within targets
- Zero connection errors
- Stable performance throughout test duration

#### Test: `benchmark_http_throughput`
**Purpose**: Measure HTTP/1.1 throughput with realistic payloads
**Setup**:
- Load balancer with HTTP parsing enabled
- 3 backend servers (Nginx serving 1KB static files)
- Keep-alive connections enabled

**Test Procedure**:
```bash
wrk -t 16 -c 500 -d 120s --latency \
  -H "User-Agent: BenchmarkClient/1.0" \
  -H "Accept: text/html,application/json" \
  http://loadbalancer:8080/test.html
```

**Payload Details**:
- Request size: ~200 bytes (headers + path)
- Response size: 1KB HTML content
- Connection reuse: HTTP keep-alive

**Success Criteria**:
- Meet HTTP throughput targets
- Parse all HTTP headers correctly
- Maintain connection pools efficiently

#### Test: `benchmark_https_throughput`
**Purpose**: Measure HTTPS throughput with SSL termination
**Setup**:
- Load balancer with SSL certificate
- TLS 1.3 enabled
- Backend servers over plain HTTP

**Test Procedure**:
```bash
# Test with existing connections (no handshake overhead)
wrk -t 12 -c 400 -d 60s --latency https://loadbalancer:8443/test.html

# Test with new connections (includes handshake overhead)
wrk -t 12 -c 400 -d 60s --latency -H "Connection: close" \
  https://loadbalancer:8443/test.html
```

**Measurements**:
- HTTPS throughput vs HTTP throughput ratio
- SSL handshake latency
- CPU utilization during SSL operations
- Memory usage for SSL contexts

### 2. Latency Tests

#### Test: `benchmark_latency_distribution`
**Purpose**: Measure detailed latency characteristics
**Setup**:
- Single backend with 1ms artificial delay
- Various load levels: 100, 1000, 5000, 10000 RPS

**Test Procedure**:
```bash
# Test at different load levels
for rps in 100 1000 5000 10000; do
  wrk -t 8 -c $((rps/10)) -d 30s --latency \
    -R $rps http://loadbalancer:8080/
done
```

**Measurements**:
- Latency at each percentile (P1, P5, P10, P25, P50, P75, P90, P95, P99, P99.9, P99.99)
- Latency vs load correlation
- Tail latency behavior under stress

**Success Criteria**:
- P99 latency remains within targets even at high load
- Latency increase is sub-linear with load
- No latency spikes > 10x median

#### Test: `benchmark_latency_under_load`
**Purpose**: Measure latency degradation under increasing load
**Setup**:
- Gradually increase load from 0 to maximum throughput
- Measure latency at each load level

**Test Procedure**:
```bash
# Ramp test: increase load every 30 seconds
for rps in 1000 5000 10000 20000 30000 40000 50000; do
  echo "Testing at $rps RPS"
  wrk -t 16 -c 300 -d 30s --latency -R $rps http://loadbalancer:8080/ > latency_$rps.txt
done
```

**Analysis**:
- Plot latency percentiles vs RPS
- Identify throughput ceiling (where latency spikes)
- Measure graceful degradation characteristics

### 3. Connection Scaling Tests

#### Test: `benchmark_connection_scaling`
**Purpose**: Test concurrent connection handling capacity
**Setup**:
- Long-lived connections (WebSocket simulation)
- Gradually increase connection count

**Test Procedure**:
```bash
# Custom connection test tool
for conns in 1000 2500 5000 7500 10000 15000 20000; do
  echo "Testing $conns concurrent connections"
  ./connection_test --connections $conns --duration 60s \
    --target loadbalancer:8080 > connections_$conns.txt
done
```

**Measurements**:
- Maximum stable concurrent connections
- Memory usage per connection
- File descriptor usage
- Connection establishment rate
- Connection close rate

**Success Criteria**:
- Handle target concurrent connections without errors
- Memory usage scales linearly
- Connection establishment rate > 1000/second
- Clean connection cleanup

#### Test: `benchmark_connection_churn`
**Purpose**: Test rapid connection establishment/termination
**Setup**:
- High rate of short-lived connections
- Measure connection lifecycle overhead

**Test Procedure**:
```bash
# High connection churn test
wrk -t 16 -c 100 -d 60s --latency \
  -H "Connection: close" \
  http://loadbalancer:8080/
```

**Measurements**:
- Connection establishment rate
- Connection cleanup efficiency  
- Memory fragmentation
- File descriptor recycling

### 4. Backend Failure Tests

#### Test: `benchmark_failover_performance`
**Purpose**: Measure performance impact during backend failures
**Setup**:
- 3 healthy backends under steady load
- Simulate backend failure during test

**Test Procedure**:
```bash
# Start load test
wrk -t 8 -c 200 -d 120s --latency http://loadbalancer:8080/ &
WRK_PID=$!

# Kill one backend after 30 seconds
sleep 30
kill $BACKEND1_PID

# Kill second backend after 60 seconds  
sleep 30
kill $BACKEND2_PID

wait $WRK_PID
```

**Measurements**:
- Request success rate during failures
- Latency spike duration and magnitude
- Recovery time after backend restoration
- Error rate during failure window

**Success Criteria**:
- < 1% request failure rate during single backend failure
- < 5% failure rate during multiple backend failures
- Recovery within 5 seconds of backend restoration
- Latency returns to baseline within 10 seconds

### 5. Algorithm Performance Tests

#### Test: `benchmark_algorithm_overhead`
**Purpose**: Compare performance overhead of different algorithms
**Setup**:
- Same backend configuration
- Test each algorithm separately

**Algorithms to Test**:
- Round Robin
- Weighted Round Robin
- Least Connections
- IP Hash
- Consistent Hashing

**Test Procedure**:
```bash
algorithms=("round_robin" "weighted_rr" "least_conn" "ip_hash" "consistent_hash")

for algo in "${algorithms[@]}"; do
  echo "Testing algorithm: $algo"
  # Update load balancer config
  update_config --algorithm $algo
  
  # Run benchmark
  wrk -t 12 -c 300 -d 60s --latency http://loadbalancer:8080/ > ${algo}_perf.txt
done
```

**Measurements**:
- Throughput difference between algorithms
- CPU overhead per algorithm
- Memory usage per algorithm
- Algorithm selection latency

**Expected Results**:
- Round Robin: Baseline performance
- Weighted RR: < 5% overhead vs Round Robin
- Least Connections: < 15% overhead vs Round Robin
- IP Hash: < 10% overhead vs Round Robin
- Consistent Hash: < 20% overhead vs Round Robin

### 6. Memory Performance Tests

#### Test: `benchmark_memory_efficiency`
**Purpose**: Measure memory usage patterns and efficiency
**Setup**:
- Monitor memory usage during various load patterns
- Track memory allocation/deallocation

**Test Procedure**:
```bash
# Memory usage under different loads
for connections in 100 1000 5000 10000; do
  echo "Memory test with $connections connections"
  
  # Start memory monitoring
  ./memory_monitor.sh loadbalancer_pid &
  MONITOR_PID=$!
  
  # Generate load
  ./connection_test --connections $connections --duration 120s
  
  # Stop monitoring
  kill $MONITOR_PID
  
  # Analyze results
  analyze_memory_usage memory_${connections}.log
done
```

**Measurements**:
- Peak memory usage
- Memory growth rate
- Memory fragmentation
- Memory leak detection
- Garbage collection frequency (if applicable)

**Success Criteria**:
- Memory usage within targets per connection
- No memory leaks over 24-hour test
- Memory usage stabilizes under steady load
- Efficient memory reclamation after load removal

### 7. Protocol-Specific Benchmarks

#### Test: `benchmark_http2_performance`
**Purpose**: Measure HTTP/2 multiplexing performance
**Setup**:
- HTTP/2 enabled load balancer
- Backend supporting HTTP/2 or HTTP/1.1
- Client supporting HTTP/2 multiplexing

**Test Procedure**:
```bash
# HTTP/2 multiplexing test
h2load -n 100000 -c 100 -m 10 https://loadbalancer:8443/test.html

# Compare with HTTP/1.1
curl -w "@curl-format.txt" -o /dev/null -s \
  --http1.1 http://loadbalancer:8080/test.html

curl -w "@curl-format.txt" -o /dev/null -s \
  --http2 https://loadbalancer:8443/test.html
```

**Measurements**:
- Requests per second vs HTTP/1.1
- Connection utilization efficiency
- Stream multiplexing overhead
- Header compression effectiveness

#### Test: `benchmark_websocket_performance`
**Purpose**: Measure WebSocket proxy performance  
**Setup**:
- WebSocket backend servers
- Long-lived WebSocket connections
- Message throughput testing

**Test Procedure**:
```bash
# WebSocket connection and message throughput
./websocket_bench --connections 1000 --messages 10000 \
  --message-size 1024 ws://loadbalancer:8080/ws
```

**Measurements**:
- WebSocket connection establishment rate
- Message throughput (messages/second)
- Message latency
- Connection stability over time

### 8. Stress Tests

#### Test: `benchmark_stress_test`
**Purpose**: Determine breaking point and failure modes
**Setup**:
- Gradually increase load until failure
- Monitor system resources

**Test Procedure**:
```bash
# Stress test with increasing load
max_rps=100000
step=5000

for rps in $(seq 5000 $step $max_rps); do
  echo "Stress testing at $rps RPS"
  
  # Monitor system resources
  sar -u 1 30 > cpu_usage_${rps}.txt &
  free -s 1 -c 30 > memory_usage_${rps}.txt &
  
  # Run load test
  timeout 30s wrk -t 16 -c 500 -d 30s --latency -R $rps \
    http://loadbalancer:8080/ > stress_${rps}.txt
  
  # Check if test completed successfully
  if [ $? -ne 0 ]; then
    echo "Breaking point reached at $rps RPS"
    break
  fi
  
  # Brief recovery period
  sleep 10
done
```

**Measurements**:
- Maximum sustainable throughput
- Failure mode analysis (what fails first)
- Resource exhaustion patterns
- Recovery characteristics

### 9. Endurance Tests

#### Test: `benchmark_endurance_test`
**Purpose**: Long-term stability and performance consistency
**Setup**:
- 24-hour continuous load test
- Moderate but sustained load
- Resource monitoring

**Test Procedure**:
```bash
# 24-hour endurance test
echo "Starting 24-hour endurance test"

# Start monitoring
./resource_monitor.sh 86400 > endurance_monitor.log &
MONITOR_PID=$!

# Start load generation (50% of maximum capacity)
wrk -t 8 -c 200 -d 86400s --latency http://loadbalancer:8080/ > endurance_results.txt &
LOAD_PID=$!

# Wait for completion
wait $LOAD_PID
kill $MONITOR_PID

echo "Endurance test completed"
```

**Measurements**:
- Performance consistency over time
- Memory leak detection
- Connection leak detection
- Error rate trends
- Resource usage patterns

**Success Criteria**:
- < 5% performance degradation over 24 hours
- No memory leaks
- No connection leaks
- Error rate < 0.001% throughout test

## Performance Analysis and Reporting

### Metrics Collection
All benchmark tests must collect the following metrics:

#### Response Time Metrics
```
response_time_p50
response_time_p90
response_time_p95
response_time_p99
response_time_p99_9
response_time_p99_99
response_time_max
response_time_mean
response_time_stddev
```

#### Throughput Metrics
```
requests_per_second
bytes_per_second
connections_per_second
errors_per_second
error_rate_percentage
```

#### System Resource Metrics
```
cpu_usage_percent
memory_usage_bytes
memory_usage_percent
network_rx_bytes
network_tx_bytes
file_descriptors_used
context_switches_per_second
```

#### Load Balancer Specific Metrics
```
active_connections
backend_connections
health_check_success_rate
algorithm_selection_time
configuration_reload_time
ssl_handshakes_per_second
```

### Reporting Format

#### Performance Summary Report
```markdown
# Load Balancer Benchmark Results

## Test Configuration
- **Date**: 2024-01-15
- **Duration**: 60 seconds  
- **Load Generator**: wrk 4.1.0
- **Target**: http://loadbalancer:8080
- **Feature Set**: Basic HTTP

## Results Summary
| Metric | Target | Actual | Status |
|--------|---------|---------|---------|
| RPS | 35,000 | 42,150 | ✅ PASS |
| P99 Latency | < 30ms | 18.2ms | ✅ PASS |
| Error Rate | < 0.01% | 0.001% | ✅ PASS |
| Memory/Conn | < 8KB | 5.2KB | ✅ PASS |

## Detailed Metrics
...
```

### Regression Testing
- **Baseline**: Establish performance baselines for each feature set
- **Comparison**: Compare current results with baseline
- **Alerting**: Flag any performance regression > 10%
- **History**: Track performance trends over time

## Benchmark Automation

### Continuous Integration
```yaml
# Example CI pipeline step
benchmark_tests:
  stage: test
  script:
    - ./setup_test_environment.sh
    - ./run_benchmarks.sh --suite basic
    - ./analyze_results.sh
    - ./compare_with_baseline.sh
  artifacts:
    reports:
      performance: benchmark_results.json
```

### Environment Reproducibility
- **Docker**: Containerized test environment
- **Infrastructure**: Infrastructure-as-code for test setup
- **Data**: Deterministic test data generation
- **Configuration**: Version-controlled benchmark configurations

This comprehensive benchmark specification ensures consistent, reproducible performance validation of load balancer implementations across different feature sets and deployment scenarios.
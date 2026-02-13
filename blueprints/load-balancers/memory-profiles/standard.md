# Standard Memory Profile for Load Balancers

## Overview
This document provides comprehensive memory management guidelines for load balancer implementations. Efficient memory usage is critical for handling thousands of concurrent connections while maintaining predictable performance and avoiding memory-related failures.

## Memory Architecture Principles

### 1. Object Lifecycle Management
**Connection Objects**: The primary memory consumer in load balancers
- **Creation**: Allocate minimal initial state
- **Growth**: Expand buffers on-demand
- **Reuse**: Pool connection objects between requests
- **Cleanup**: Immediate deallocation on connection close

### 2. Buffer Management Strategy
**Buffer Pools**: Pre-allocated buffer pools for different sizes
```rust
// Example buffer pool structure
struct BufferPool {
    small_buffers: Vec<Buffer>,    // 4KB buffers
    medium_buffers: Vec<Buffer>,   // 16KB buffers
    large_buffers: Vec<Buffer>,    // 64KB buffers
    giant_buffers: Vec<Buffer>,    // 256KB buffers
}
```

**Buffer Selection Logic**:
- **Small (4KB)**: HTTP headers, small requests
- **Medium (16KB)**: Typical HTTP requests/responses
- **Large (64KB)**: Large POST requests, file uploads
- **Giant (256KB)**: Bulk data transfers, streaming

### 3. Zero-Copy Techniques
**Splice Operations**: Use `splice()`, `sendfile()`, or equivalent
```c
// Linux example: zero-copy proxy
ssize_t bytes = splice(client_fd, NULL, backend_fd, NULL, 
                      SPLICE_SIZE, SPLICE_F_MOVE | SPLICE_F_MORE);
```

**Memory Mapping**: For static content serving
```c
// Memory map static files
void* mapped = mmap(NULL, file_size, PROT_READ, MAP_SHARED, fd, 0);
```

**Buffer Chaining**: Avoid copying between buffers
```rust
struct BufferChain {
    buffers: Vec<Buffer>,
    total_size: usize,
    read_pos: usize,
}
```

## Memory Allocation Strategies

### 1. Pre-allocation Patterns

#### Connection Pool Pre-allocation
```rust
struct ConnectionPool {
    free_connections: Vec<Connection>,
    active_connections: HashMap<ConnectionId, Connection>,
    max_connections: usize,
}

impl ConnectionPool {
    fn new(max_connections: usize) -> Self {
        let mut pool = ConnectionPool {
            free_connections: Vec::with_capacity(max_connections),
            active_connections: HashMap::with_capacity(max_connections),
            max_connections,
        };
        
        // Pre-allocate connection objects
        for _ in 0..max_connections {
            pool.free_connections.push(Connection::new());
        }
        
        pool
    }
}
```

#### Buffer Pool Implementation
```rust
struct BufferManager {
    pools: [VecDeque<Box<[u8]>>; 4], // Different buffer sizes
    pool_sizes: [usize; 4],          // 4KB, 16KB, 64KB, 256KB
    allocation_counts: [AtomicU64; 4],
    deallocation_counts: [AtomicU64; 4],
}

impl BufferManager {
    fn get_buffer(&self, min_size: usize) -> Box<[u8]> {
        let pool_idx = self.select_pool(min_size);
        
        if let Some(buffer) = self.pools[pool_idx].pop_front() {
            self.allocation_counts[pool_idx].fetch_add(1, Ordering::Relaxed);
            buffer
        } else {
            // Pool empty, allocate new buffer
            self.allocate_new_buffer(pool_idx)
        }
    }
    
    fn return_buffer(&self, buffer: Box<[u8]>) {
        let pool_idx = self.classify_buffer(&buffer);
        
        // Clear buffer contents for security
        buffer.fill(0);
        
        // Return to pool if pool not full
        if self.pools[pool_idx].len() < self.max_pool_size(pool_idx) {
            self.pools[pool_idx].push_back(buffer);
        }
        // Otherwise let it be deallocated
        
        self.deallocation_counts[pool_idx].fetch_add(1, Ordering::Relaxed);
    }
}
```

### 2. Adaptive Allocation

#### Dynamic Pool Sizing
```rust
struct AdaptiveBufferPool {
    current_pool_size: AtomicUsize,
    max_pool_size: usize,
    min_pool_size: usize,
    usage_stats: RollingStats,
}

impl AdaptiveBufferPool {
    fn adjust_pool_size(&self) {
        let current_usage = self.usage_stats.average();
        let current_size = self.current_pool_size.load(Ordering::Acquire);
        
        if current_usage > 0.8 && current_size < self.max_pool_size {
            // High usage, grow pool
            let new_size = (current_size * 120 / 100).min(self.max_pool_size);
            self.current_pool_size.store(new_size, Ordering::Release);
            self.grow_pool(new_size - current_size);
        } else if current_usage < 0.3 && current_size > self.min_pool_size {
            // Low usage, shrink pool
            let new_size = (current_size * 80 / 100).max(self.min_pool_size);
            self.current_pool_size.store(new_size, Ordering::Release);
            self.shrink_pool(current_size - new_size);
        }
    }
}
```

### 3. Memory Limits and Backpressure

#### Global Memory Limits
```rust
struct MemoryLimitManager {
    max_memory_bytes: usize,
    current_memory_bytes: AtomicUsize,
    warning_threshold: usize,    // 80% of max
    critical_threshold: usize,   // 95% of max
}

impl MemoryLimitManager {
    fn can_allocate(&self, size: usize) -> bool {
        let current = self.current_memory_bytes.load(Ordering::Acquire);
        current + size <= self.max_memory_bytes
    }
    
    fn check_pressure(&self) -> MemoryPressure {
        let current = self.current_memory_bytes.load(Ordering::Acquire);
        let percentage = (current * 100) / self.max_memory_bytes;
        
        match percentage {
            0..=79 => MemoryPressure::Normal,
            80..=94 => MemoryPressure::Warning,
            95..=100 => MemoryPressure::Critical,
            _ => MemoryPressure::Critical,
        }
    }
}
```

#### Backpressure Implementation
```rust
enum BackpressureAction {
    Accept,
    Defer,
    Reject,
}

fn handle_new_connection(memory_manager: &MemoryLimitManager) -> BackpressureAction {
    match memory_manager.check_pressure() {
        MemoryPressure::Normal => BackpressureAction::Accept,
        MemoryPressure::Warning => {
            // Start applying gentle backpressure
            if random_chance(0.1) {
                BackpressureAction::Defer
            } else {
                BackpressureAction::Accept
            }
        },
        MemoryPressure::Critical => {
            // Aggressive backpressure
            if random_chance(0.7) {
                BackpressureAction::Reject
            } else {
                BackpressureAction::Defer
            }
        }
    }
}
```

## Connection Memory Management

### 1. Connection Object Structure
```rust
struct Connection {
    // Fixed-size fields (allocated once)
    id: ConnectionId,
    client_addr: SocketAddr,
    backend_addr: Option<SocketAddr>,
    state: ConnectionState,
    created_at: Timestamp,
    
    // Variable-size fields (allocated on-demand)
    client_buffer: Option<Box<[u8]>>,
    backend_buffer: Option<Box<[u8]>>,
    http_context: Option<Box<HttpContext>>,
    ssl_context: Option<Box<SslContext>>,
    
    // Statistics (minimal overhead)
    bytes_sent: u64,
    bytes_received: u64,
    requests_count: u32,
}

impl Connection {
    fn new(id: ConnectionId, client_addr: SocketAddr) -> Self {
        Connection {
            id,
            client_addr,
            backend_addr: None,
            state: ConnectionState::New,
            created_at: Timestamp::now(),
            
            // Defer allocation until needed
            client_buffer: None,
            backend_buffer: None,
            http_context: None,
            ssl_context: None,
            
            bytes_sent: 0,
            bytes_received: 0,
            requests_count: 0,
        }
    }
    
    fn ensure_client_buffer(&mut self, buffer_manager: &BufferManager) {
        if self.client_buffer.is_none() {
            self.client_buffer = Some(buffer_manager.get_buffer(16384)); // 16KB
        }
    }
    
    fn release_buffers(&mut self, buffer_manager: &BufferManager) {
        if let Some(buffer) = self.client_buffer.take() {
            buffer_manager.return_buffer(buffer);
        }
        if let Some(buffer) = self.backend_buffer.take() {
            buffer_manager.return_buffer(buffer);
        }
    }
}
```

### 2. Buffer Growth Strategy
```rust
impl Connection {
    fn grow_buffer_if_needed(&mut self, buffer_type: BufferType, required_size: usize, 
                            buffer_manager: &BufferManager) -> Result<(), OutOfMemoryError> {
        let current_buffer = match buffer_type {
            BufferType::Client => &mut self.client_buffer,
            BufferType::Backend => &mut self.backend_buffer,
        };
        
        let needs_growth = match current_buffer {
            None => true,
            Some(buffer) => buffer.len() < required_size,
        };
        
        if needs_growth {
            // Return current buffer to pool
            if let Some(old_buffer) = current_buffer.take() {
                buffer_manager.return_buffer(old_buffer);
            }
            
            // Get appropriately sized buffer
            *current_buffer = Some(buffer_manager.get_buffer(required_size));
        }
        
        Ok(())
    }
}
```

### 3. Connection Cleanup
```rust
impl Drop for Connection {
    fn drop(&mut self) {
        // Ensure all buffers are returned to pools
        if let Some(buffer) = self.client_buffer.take() {
            // Note: In real implementation, need access to buffer manager
            // This would typically be handled by connection manager
        }
        
        // Clear sensitive data
        self.zero_sensitive_data();
    }
}

impl Connection {
    fn zero_sensitive_data(&mut self) {
        // Clear any sensitive information from memory
        if let Some(ref mut http_context) = self.http_context {
            http_context.clear_sensitive_headers();
        }
    }
}
```

## HTTP Context Memory Management

### 1. HTTP Parsing Buffer Strategy
```rust
struct HttpContext {
    // Reusable parsing state
    parser_state: HttpParserState,
    
    // Header storage (pre-allocated for common case)
    headers: SmallVec<[Header; 16]>, // Inline storage for 16 headers
    
    // URL components (allocated on-demand)
    parsed_url: Option<ParsedUrl>,
    
    // Body handling
    body_buffer: Option<Box<[u8]>>,
    content_length: Option<usize>,
    
    // Response context
    response_headers: SmallVec<[Header; 8]>,
    response_buffer: Option<Box<[u8]>>,
}

impl HttpContext {
    fn reset_for_new_request(&mut self) {
        // Clear previous request data but keep allocated buffers
        self.headers.clear(); // Don't deallocate
        self.parsed_url = None;
        self.content_length = None;
        self.response_headers.clear();
        
        // Reset parser state
        self.parser_state.reset();
    }
    
    fn clear_sensitive_headers(&mut self) {
        for header in &mut self.headers {
            if header.name.eq_ignore_ascii_case("authorization") ||
               header.name.eq_ignore_ascii_case("cookie") {
                header.value.fill(0); // Zero out sensitive data
            }
        }
    }
}
```

### 2. Header Storage Optimization
```rust
// Efficient header representation
struct Header {
    name: CompactString,   // Interned string for common headers
    value: Vec<u8>,        // Raw bytes to avoid UTF-8 validation
}

// Common header names are interned
static COMMON_HEADERS: &[&str] = &[
    "host", "user-agent", "accept", "content-type", "content-length",
    "authorization", "cookie", "x-forwarded-for", "x-real-ip",
];

struct HeaderInterner {
    interned: HashMap<&'static str, u32>,
}

impl HeaderInterner {
    fn intern_or_copy(&self, name: &str) -> CompactString {
        if let Some(&id) = self.interned.get(name) {
            CompactString::Interned(id)
        } else {
            CompactString::Owned(name.to_string())
        }
    }
}
```

## SSL/TLS Memory Management

### 1. SSL Context Pooling
```rust
struct SslContextPool {
    available_contexts: VecDeque<Box<SslContext>>,
    max_pool_size: usize,
    context_factory: SslContextFactory,
}

impl SslContextPool {
    fn get_context(&mut self) -> Box<SslContext> {
        self.available_contexts.pop_front()
            .unwrap_or_else(|| self.context_factory.create_context())
    }
    
    fn return_context(&mut self, mut context: Box<SslContext>) {
        // Reset context state
        context.reset();
        
        // Return to pool if not full
        if self.available_contexts.len() < self.max_pool_size {
            self.available_contexts.push_back(context);
        }
        // Otherwise drop it (automatic deallocation)
    }
}
```

### 2. Certificate Memory Management
```rust
struct CertificateCache {
    certificates: HashMap<String, Arc<Certificate>>, // Shared certificates
    private_keys: HashMap<String, Arc<PrivateKey>>,
    max_cache_size: usize,
    lru_tracker: LruCache<String>,
}

impl CertificateCache {
    fn get_certificate(&mut self, domain: &str) -> Option<Arc<Certificate>> {
        if let Some(cert) = self.certificates.get(domain) {
            self.lru_tracker.touch(domain);
            Some(cert.clone()) // Cheap Arc clone
        } else {
            None
        }
    }
    
    fn store_certificate(&mut self, domain: String, cert: Certificate, key: PrivateKey) {
        // Evict old certificates if cache full
        while self.certificates.len() >= self.max_cache_size {
            if let Some(old_domain) = self.lru_tracker.evict_oldest() {
                self.certificates.remove(&old_domain);
                self.private_keys.remove(&old_domain);
            }
        }
        
        self.certificates.insert(domain.clone(), Arc::new(cert));
        self.private_keys.insert(domain.clone(), Arc::new(key));
        self.lru_tracker.insert(domain);
    }
}
```

## Memory Monitoring and Diagnostics

### 1. Memory Usage Tracking
```rust
struct MemoryStats {
    total_allocated: AtomicU64,
    peak_allocated: AtomicU64,
    allocation_count: AtomicU64,
    deallocation_count: AtomicU64,
    
    // Per-component tracking
    connection_memory: AtomicU64,
    buffer_memory: AtomicU64,
    ssl_memory: AtomicU64,
    cache_memory: AtomicU64,
}

impl MemoryStats {
    fn record_allocation(&self, size: usize, component: MemoryComponent) {
        let size = size as u64;
        self.total_allocated.fetch_add(size, Ordering::Relaxed);
        self.allocation_count.fetch_add(1, Ordering::Relaxed);
        
        // Update peak if necessary
        let current = self.total_allocated.load(Ordering::Relaxed);
        self.peak_allocated.fetch_max(current, Ordering::Relaxed);
        
        // Update component tracking
        match component {
            MemoryComponent::Connection => 
                self.connection_memory.fetch_add(size, Ordering::Relaxed),
            MemoryComponent::Buffer => 
                self.buffer_memory.fetch_add(size, Ordering::Relaxed),
            MemoryComponent::Ssl => 
                self.ssl_memory.fetch_add(size, Ordering::Relaxed),
            MemoryComponent::Cache => 
                self.cache_memory.fetch_add(size, Ordering::Relaxed),
        }
    }
    
    fn record_deallocation(&self, size: usize, component: MemoryComponent) {
        let size = size as u64;
        self.total_allocated.fetch_sub(size, Ordering::Relaxed);
        self.deallocation_count.fetch_add(1, Ordering::Relaxed);
        
        // Update component tracking
        match component {
            MemoryComponent::Connection => 
                self.connection_memory.fetch_sub(size, Ordering::Relaxed),
            MemoryComponent::Buffer => 
                self.buffer_memory.fetch_sub(size, Ordering::Relaxed),
            MemoryComponent::Ssl => 
                self.ssl_memory.fetch_sub(size, Ordering::Relaxed),
            MemoryComponent::Cache => 
                self.cache_memory.fetch_sub(size, Ordering::Relaxed),
        }
    }
}
```

### 2. Memory Leak Detection
```rust
struct MemoryLeakDetector {
    allocation_tracker: HashMap<*const u8, AllocationInfo>,
    check_interval: Duration,
    last_check: Instant,
}

struct AllocationInfo {
    size: usize,
    timestamp: Instant,
    component: MemoryComponent,
    stack_trace: Option<Vec<String>>, // Debug builds only
}

impl MemoryLeakDetector {
    fn track_allocation(&mut self, ptr: *const u8, size: usize, component: MemoryComponent) {
        if cfg!(debug_assertions) {
            let info = AllocationInfo {
                size,
                timestamp: Instant::now(),
                component,
                stack_trace: Some(capture_stack_trace()),
            };
            self.allocation_tracker.insert(ptr, info);
        }
    }
    
    fn track_deallocation(&mut self, ptr: *const u8) {
        if cfg!(debug_assertions) {
            self.allocation_tracker.remove(&ptr);
        }
    }
    
    fn check_for_leaks(&mut self) -> Vec<LeakReport> {
        let now = Instant::now();
        if now.duration_since(self.last_check) < self.check_interval {
            return vec![];
        }
        
        let mut leaks = Vec::new();
        let leak_threshold = Duration::from_secs(300); // 5 minutes
        
        for (ptr, info) in &self.allocation_tracker {
            if now.duration_since(info.timestamp) > leak_threshold {
                leaks.push(LeakReport {
                    ptr: *ptr,
                    size: info.size,
                    age: now.duration_since(info.timestamp),
                    component: info.component,
                    stack_trace: info.stack_trace.clone(),
                });
            }
        }
        
        self.last_check = now;
        leaks
    }
}
```

## Performance Optimizations

### 1. Memory Locality Optimization
```rust
// Structure of Arrays for better cache locality
struct ConnectionArray {
    ids: Vec<ConnectionId>,
    states: Vec<ConnectionState>,
    client_addrs: Vec<SocketAddr>,
    backend_addrs: Vec<Option<SocketAddr>>,
    timestamps: Vec<Timestamp>,
    
    // Separate storage for less frequently accessed data
    extended_data: Vec<Option<Box<ConnectionExtendedData>>>,
}

struct ConnectionExtendedData {
    http_context: HttpContext,
    ssl_context: Option<SslContext>,
    statistics: ConnectionStats,
}
```

### 2. NUMA-Aware Allocation
```rust
struct NumaAwareAllocator {
    node_allocators: Vec<Box<dyn Allocator>>,
    current_node: AtomicUsize,
}

impl NumaAwareAllocator {
    fn allocate_on_local_node(&self, size: usize) -> *mut u8 {
        let cpu_id = get_current_cpu();
        let numa_node = cpu_to_numa_node(cpu_id);
        self.node_allocators[numa_node].allocate(size)
    }
}
```

### 3. Lock-Free Memory Management
```rust
use crossbeam::epoch;

struct LockFreeBufferPool {
    buffers: [crossbeam::queue::SegQueue<Buffer>; 4], // Per size class
}

impl LockFreeBufferPool {
    fn get_buffer(&self, size_class: usize) -> Option<Buffer> {
        self.buffers[size_class].pop()
    }
    
    fn return_buffer(&self, buffer: Buffer, size_class: usize) {
        // Clear buffer before returning
        buffer.clear();
        self.buffers[size_class].push(buffer);
    }
}
```

## Memory Configuration Guidelines

### 1. Sizing Recommendations

#### Buffer Pool Sizes
```yaml
buffer_pools:
  small_buffers:    # 4KB
    initial_count: 1000
    max_count: 10000
    growth_factor: 1.5
  
  medium_buffers:   # 16KB  
    initial_count: 500
    max_count: 5000
    growth_factor: 1.3
  
  large_buffers:    # 64KB
    initial_count: 100
    max_count: 1000
    growth_factor: 1.2
  
  giant_buffers:    # 256KB
    initial_count: 10
    max_count: 100
    growth_factor: 1.1
```

#### Memory Limits by Deployment Size
```yaml
# Small deployment (< 1000 concurrent connections)
memory_limits:
  max_total_memory: "512MB"
  buffer_pool_memory: "256MB"
  connection_memory: "128MB"
  ssl_context_memory: "64MB"
  cache_memory: "64MB"

# Medium deployment (< 10000 concurrent connections)
memory_limits:
  max_total_memory: "4GB"
  buffer_pool_memory: "2GB"
  connection_memory: "1GB"
  ssl_context_memory: "512MB"
  cache_memory: "512MB"

# Large deployment (< 100000 concurrent connections)
memory_limits:
  max_total_memory: "32GB"
  buffer_pool_memory: "16GB"
  connection_memory: "8GB"
  ssl_context_memory: "4GB"
  cache_memory: "4GB"
```

### 2. Tuning Parameters
```yaml
memory_tuning:
  # Buffer pool tuning
  pool_growth_threshold: 0.8    # Grow when 80% utilized
  pool_shrink_threshold: 0.3    # Shrink when 30% utilized
  pool_check_interval: "30s"    # How often to check pool sizes
  
  # Connection memory tuning
  initial_buffer_size: "16KB"   # Initial buffer allocation
  max_buffer_size: "256KB"      # Maximum buffer per connection
  buffer_growth_factor: 2.0     # Double buffer size when growing
  
  # Pressure handling
  warning_threshold: 0.8        # 80% of max memory
  critical_threshold: 0.95      # 95% of max memory
  backpressure_start: 0.85      # Start applying backpressure
  
  # Cleanup intervals
  idle_connection_timeout: "300s"
  memory_cleanup_interval: "60s"
  leak_check_interval: "600s"
```

This memory profile provides the foundation for implementing memory-efficient, scalable load balancers that can handle high connection loads while maintaining predictable performance characteristics.
# Load Balancer Architecture Guide

## Overview
This document provides in-depth architectural guidance for implementing production-grade load balancers. It covers fundamental design decisions, implementation patterns, and system interactions that determine scalability, performance, and reliability characteristics.

## Architectural Foundations

### 1. Core Architecture Patterns

#### Event-Driven Architecture (Recommended)
**Single-threaded, non-blocking I/O with event loop**

```rust
struct EventLoop {
    epoll_fd: i32,
    event_buffer: Vec<EpollEvent>,
    connection_manager: ConnectionManager,
    timer_manager: TimerManager,
    signal_manager: SignalManager,
}

impl EventLoop {
    fn run(&mut self) -> Result<(), EventLoopError> {
        loop {
            // Wait for events with timeout for timer processing
            let num_events = epoll_wait(
                self.epoll_fd,
                &mut self.event_buffer,
                TIMER_RESOLUTION_MS
            )?;
            
            // Process I/O events
            for i in 0..num_events {
                let event = &self.event_buffer[i];
                match event.data.u64 {
                    fd if fd == self.listen_fd => self.handle_accept()?,
                    fd => self.handle_connection_event(fd as i32, event.events)?,
                }
            }
            
            // Process timers (health checks, cleanup, etc.)
            self.timer_manager.process_expired_timers();
            
            // Process signals (config reload, graceful shutdown)
            self.signal_manager.process_signals();
            
            // Cleanup and maintenance
            if should_perform_cleanup() {
                self.connection_manager.cleanup_idle_connections();
            }
        }
    }
}
```

**Benefits:**
- **High concurrency**: Handle thousands of connections with single thread
- **Low memory overhead**: No thread stack allocation per connection
- **Predictable performance**: No context switching overhead
- **Simple debugging**: Single execution context

**Considerations:**
- **CPU-bound tasks**: Can block the event loop
- **Single point of failure**: One thread handles everything
- **Complex state management**: Requires careful state machine design

#### Multi-threaded Architecture
**Worker thread pool with connection distribution**

```rust
struct LoadBalancer {
    listener: TcpListener,
    worker_pool: ThreadPool,
    connection_distributor: ConnectionDistributor,
    shared_state: Arc<SharedState>,
}

struct WorkerThread {
    id: WorkerId,
    event_loop: EventLoop,
    connection_queue: mpsc::Receiver<NewConnection>,
    shared_state: Arc<SharedState>,
}

impl LoadBalancer {
    fn run(&self) -> Result<(), Error> {
        // Accept connections on main thread
        loop {
            let (stream, addr) = self.listener.accept()?;
            let connection = Connection::new(stream, addr);
            
            // Distribute to worker thread
            let worker_id = self.connection_distributor.select_worker(&connection);
            self.worker_pool.send_connection(worker_id, connection)?;
        }
    }
}
```

**Benefits:**
- **CPU utilization**: Can use multiple CPU cores
- **Fault isolation**: Worker thread failure doesn't affect others
- **Blocking operations**: Workers can handle blocking I/O
- **Scalability**: Add workers based on CPU cores

**Considerations:**
- **Memory overhead**: Thread stacks and synchronization structures
- **Complexity**: Thread synchronization and data sharing
- **Context switching**: Overhead from thread scheduling

#### Hybrid Architecture (Advanced)
**Event loops on multiple threads with work stealing**

```rust
struct HybridLoadBalancer {
    event_loops: Vec<EventLoopWorker>,
    work_stealing_queue: WorkStealingQueue<Task>,
    shared_state: Arc<SharedState>,
}

struct EventLoopWorker {
    thread_id: usize,
    event_loop: EventLoop,
    local_queue: VecDeque<Task>,
    steal_handle: StealHandle,
}

impl EventLoopWorker {
    fn run(&mut self) {
        loop {
            // Process local events first
            self.process_local_events();
            
            // Process local tasks
            while let Some(task) = self.local_queue.pop_front() {
                self.execute_task(task);
            }
            
            // Steal work from other workers if idle
            if self.is_idle() {
                if let Some(stolen_task) = self.steal_handle.steal() {
                    self.execute_task(stolen_task);
                }
            }
            
            // Process timers and cleanup
            self.process_maintenance();
        }
    }
}
```

**Benefits:**
- **Best of both worlds**: Event-driven performance + multi-core utilization
- **Dynamic load balancing**: Work stealing balances load automatically
- **High throughput**: Minimal contention and maximal CPU utilization

**Considerations:**
- **Implementation complexity**: Sophisticated synchronization required
- **Debugging difficulty**: Complex interaction patterns
- **Memory model**: Requires careful attention to memory ordering

### 2. Connection State Machines

#### Connection Lifecycle States
```rust
#[derive(Debug, Clone, Copy, PartialEq)]
enum ConnectionState {
    // Initial states
    Accepting,          // Accepting new client connection
    SslHandshaking,     // Performing SSL/TLS handshake
    
    // Active states  
    ReadingRequest,     // Reading HTTP request from client
    ParsingRequest,     // Parsing HTTP request headers/body
    SelectingBackend,   // Choosing backend server
    ConnectingBackend,  // Establishing backend connection
    SendingRequest,     // Forwarding request to backend
    ReadingResponse,    // Reading response from backend
    SendingResponse,    // Sending response to client
    
    // Persistent connection states
    KeepAlive,         // HTTP keep-alive, waiting for next request
    WebSocket,         // Upgraded to WebSocket connection
    
    // Cleanup states
    Draining,          // Graceful connection close
    Closing,           // Actively closing connection
    Closed,            // Connection fully closed
    
    // Error states
    Error,             // Error occurred, cleanup needed
}

impl ConnectionState {
    fn can_transition_to(&self, new_state: ConnectionState) -> bool {
        use ConnectionState::*;
        
        match (self, new_state) {
            // Valid transitions from Accepting
            (Accepting, SslHandshaking) => true,
            (Accepting, ReadingRequest) => true,
            (Accepting, Error) => true,
            (Accepting, Closing) => true,
            
            // SSL handshake transitions
            (SslHandshaking, ReadingRequest) => true,
            (SslHandshaking, Error) => true,
            (SslHandshaking, Closing) => true,
            
            // Request processing flow
            (ReadingRequest, ParsingRequest) => true,
            (ParsingRequest, SelectingBackend) => true,
            (SelectingBackend, ConnectingBackend) => true,
            (ConnectingBackend, SendingRequest) => true,
            (SendingRequest, ReadingResponse) => true,
            (ReadingResponse, SendingResponse) => true,
            
            // Keep-alive handling
            (SendingResponse, KeepAlive) => true,
            (SendingResponse, Closing) => true,
            (KeepAlive, ReadingRequest) => true,
            
            // WebSocket upgrade
            (SendingResponse, WebSocket) => true,
            
            // Error transitions (from any state)
            (_, Error) => true,
            (_, Closing) => true,
            
            // Cleanup transitions
            (Draining, Closing) => true,
            (Closing, Closed) => true,
            
            _ => false,
        }
    }
}
```

#### State Machine Implementation
```rust
struct ConnectionStateMachine {
    current_state: ConnectionState,
    context: ConnectionContext,
    event_handlers: HashMap<ConnectionState, Box<dyn StateHandler>>,
}

trait StateHandler {
    fn handle_event(&mut self, 
                   event: ConnectionEvent, 
                   context: &mut ConnectionContext) -> StateTransition;
}

struct StateTransition {
    new_state: ConnectionState,
    actions: Vec<Action>,
}

impl ConnectionStateMachine {
    fn process_event(&mut self, event: ConnectionEvent) -> Result<Vec<Action>, StateMachineError> {
        let handler = self.event_handlers.get_mut(&self.current_state)
            .ok_or(StateMachineError::NoHandler)?;
            
        let transition = handler.handle_event(event, &mut self.context);
        
        // Validate transition
        if !self.current_state.can_transition_to(transition.new_state) {
            return Err(StateMachineError::InvalidTransition {
                from: self.current_state,
                to: transition.new_state,
            });
        }
        
        // Perform transition
        self.current_state = transition.new_state;
        
        Ok(transition.actions)
    }
}
```

### 3. Backend Pool Management

#### Backend Pool Architecture
```rust
struct BackendPool {
    name: String,
    backends: Vec<Backend>,
    algorithm: Box<dyn LoadBalancingAlgorithm>,
    health_checker: HealthChecker,
    connection_pools: HashMap<BackendId, ConnectionPool>,
    circuit_breaker: CircuitBreaker,
    metrics: BackendPoolMetrics,
}

struct Backend {
    id: BackendId,
    address: SocketAddr,
    weight: u32,
    max_connections: u32,
    current_connections: AtomicU32,
    health_status: AtomicU32, // Packed health status
    failure_count: AtomicU32,
    last_failure: AtomicU64,  // Timestamp
    response_times: RollingStats,
}

impl Backend {
    fn is_healthy(&self) -> bool {
        let status = self.health_status.load(Ordering::Acquire);
        HealthStatus::from_u32(status) == HealthStatus::Healthy
    }
    
    fn can_accept_connection(&self) -> bool {
        self.is_healthy() && 
        self.current_connections.load(Ordering::Acquire) < self.max_connections
    }
    
    fn record_request(&self, response_time: Duration, success: bool) {
        self.response_times.record(response_time);
        
        if !success {
            self.failure_count.fetch_add(1, Ordering::Release);
            self.last_failure.store(timestamp_now(), Ordering::Release);
        }
    }
}
```

#### Backend Selection Algorithms
```rust
trait LoadBalancingAlgorithm: Send + Sync {
    fn select_backend(&self, 
                     backends: &[Backend], 
                     request: &Request) -> Option<BackendId>;
    
    fn on_backend_response(&self, 
                          backend_id: BackendId, 
                          response_time: Duration, 
                          success: bool);
}

// Round Robin Implementation
struct RoundRobinAlgorithm {
    current_index: AtomicUsize,
}

impl LoadBalancingAlgorithm for RoundRobinAlgorithm {
    fn select_backend(&self, backends: &[Backend], _request: &Request) -> Option<BackendId> {
        let healthy_backends: Vec<_> = backends.iter()
            .filter(|b| b.can_accept_connection())
            .collect();
            
        if healthy_backends.is_empty() {
            return None;
        }
        
        let index = self.current_index.fetch_add(1, Ordering::Relaxed) % healthy_backends.len();
        Some(healthy_backends[index].id)
    }
    
    fn on_backend_response(&self, _backend_id: BackendId, _response_time: Duration, _success: bool) {
        // Round robin doesn't need response feedback
    }
}

// Least Connections Implementation
struct LeastConnectionsAlgorithm;

impl LoadBalancingAlgorithm for LeastConnectionsAlgorithm {
    fn select_backend(&self, backends: &[Backend], _request: &Request) -> Option<BackendId> {
        backends.iter()
            .filter(|b| b.can_accept_connection())
            .min_by_key(|b| b.current_connections.load(Ordering::Acquire))
            .map(|b| b.id)
    }
    
    fn on_backend_response(&self, _backend_id: BackendId, _response_time: Duration, _success: bool) {
        // Connection count is tracked separately
    }
}

// Weighted Least Response Time Algorithm
struct WeightedLeastResponseTimeAlgorithm;

impl LoadBalancingAlgorithm for WeightedLeastResponseTimeAlgorithm {
    fn select_backend(&self, backends: &[Backend], _request: &Request) -> Option<BackendId> {
        backends.iter()
            .filter(|b| b.can_accept_connection())
            .min_by(|a, b| {
                let a_score = a.response_times.mean() / a.weight as f64;
                let b_score = b.response_times.mean() / b.weight as f64;
                a_score.partial_cmp(&b_score).unwrap_or(std::cmp::Ordering::Equal)
            })
            .map(|b| b.id)
    }
    
    fn on_backend_response(&self, backend_id: BackendId, response_time: Duration, success: bool) {
        // Response times are recorded in Backend::record_request
    }
}
```

### 4. Health Check Scheduling

#### Health Check Manager
```rust
struct HealthCheckManager {
    health_checkers: HashMap<BackendId, HealthChecker>,
    scheduler: TimerScheduler,
    executor: HealthCheckExecutor,
    results_channel: mpsc::Receiver<HealthCheckResult>,
}

struct HealthChecker {
    backend_id: BackendId,
    config: HealthCheckConfig,
    state: HealthCheckState,
    consecutive_failures: u32,
    consecutive_successes: u32,
}

#[derive(Clone)]
struct HealthCheckConfig {
    check_type: HealthCheckType,
    interval: Duration,
    timeout: Duration,
    failure_threshold: u32,    // Failures before marking unhealthy
    success_threshold: u32,    // Successes before marking healthy
    path: Option<String>,      // For HTTP checks
    expected_codes: Vec<u16>,  // Expected HTTP response codes
}

impl HealthCheckManager {
    fn schedule_check(&mut self, backend_id: BackendId) {
        let checker = &self.health_checkers[&backend_id];
        let next_check_time = Instant::now() + checker.config.interval;
        
        self.scheduler.schedule_at(next_check_time, HealthCheckTask {
            backend_id,
            config: checker.config.clone(),
        });
    }
    
    fn process_results(&mut self) {
        while let Ok(result) = self.results_channel.try_recv() {
            self.handle_health_check_result(result);
        }
    }
    
    fn handle_health_check_result(&mut self, result: HealthCheckResult) {
        let checker = self.health_checkers.get_mut(&result.backend_id).unwrap();
        
        match result.status {
            HealthCheckStatus::Success => {
                checker.consecutive_failures = 0;
                checker.consecutive_successes += 1;
                
                if checker.state == HealthCheckState::Unhealthy &&
                   checker.consecutive_successes >= checker.config.success_threshold {
                    checker.state = HealthCheckState::Healthy;
                    self.notify_backend_healthy(result.backend_id);
                }
            },
            
            HealthCheckStatus::Failure => {
                checker.consecutive_successes = 0;
                checker.consecutive_failures += 1;
                
                if checker.state == HealthCheckState::Healthy &&
                   checker.consecutive_failures >= checker.config.failure_threshold {
                    checker.state = HealthCheckState::Unhealthy;
                    self.notify_backend_unhealthy(result.backend_id);
                }
            },
        }
        
        // Schedule next check
        self.schedule_check(result.backend_id);
    }
}
```

#### Health Check Implementations
```rust
trait HealthCheckExecutor {
    fn execute_check(&self, backend: &Backend, config: &HealthCheckConfig) -> HealthCheckFuture;
}

struct TcpHealthCheckExecutor;

impl HealthCheckExecutor for TcpHealthCheckExecutor {
    fn execute_check(&self, backend: &Backend, config: &HealthCheckConfig) -> HealthCheckFuture {
        let address = backend.address;
        let timeout = config.timeout;
        
        Box::pin(async move {
            match timeout_after(timeout, TcpStream::connect(address)).await {
                Ok(Ok(_stream)) => HealthCheckStatus::Success,
                _ => HealthCheckStatus::Failure,
            }
        })
    }
}

struct HttpHealthCheckExecutor {
    client: HttpClient,
}

impl HealthCheckExecutor for HttpHealthCheckExecutor {
    fn execute_check(&self, backend: &Backend, config: &HealthCheckConfig) -> HealthCheckFuture {
        let url = format!("http://{}:{}{}", 
                         backend.address.ip(), 
                         backend.address.port(),
                         config.path.as_deref().unwrap_or("/"));
        
        let expected_codes = config.expected_codes.clone();
        let timeout = config.timeout;
        let client = self.client.clone();
        
        Box::pin(async move {
            match timeout_after(timeout, client.get(&url)).await {
                Ok(Ok(response)) => {
                    if expected_codes.is_empty() || expected_codes.contains(&response.status().as_u16()) {
                        HealthCheckStatus::Success
                    } else {
                        HealthCheckStatus::Failure
                    }
                },
                _ => HealthCheckStatus::Failure,
            }
        })
    }
}
```

### 5. Configuration Hot-Reload Mechanism

#### Configuration Management System
```rust
struct ConfigurationManager {
    current_config: Arc<LoadBalancerConfig>,
    config_watcher: ConfigWatcher,
    reload_channel: mpsc::Receiver<ConfigReloadRequest>,
    validation_engine: ConfigValidator,
    migration_engine: ConfigMigrator,
}

struct ConfigReloadRequest {
    new_config: LoadBalancerConfig,
    rollback_config: Option<LoadBalancerConfig>,
    reload_id: ReloadId,
}

impl ConfigurationManager {
    fn start_reload_loop(&mut self) {
        loop {
            match self.reload_channel.recv() {
                Ok(request) => {
                    match self.perform_hot_reload(request) {
                        Ok(_) => log::info!("Configuration reload successful"),
                        Err(e) => log::error!("Configuration reload failed: {}", e),
                    }
                },
                Err(_) => break, // Channel closed
            }
        }
    }
    
    fn perform_hot_reload(&mut self, request: ConfigReloadRequest) -> Result<(), ReloadError> {
        // 1. Validate new configuration
        self.validation_engine.validate(&request.new_config)?;
        
        // 2. Create migration plan
        let migration_plan = self.migration_engine.create_migration_plan(
            &self.current_config,
            &request.new_config
        )?;
        
        // 3. Execute migration with rollback capability
        match self.execute_migration_plan(migration_plan) {
            Ok(_) => {
                // 4. Update current config
                self.current_config = Arc::new(request.new_config);
                Ok(())
            },
            Err(e) => {
                // 5. Rollback on failure
                if let Some(rollback_config) = request.rollback_config {
                    self.emergency_rollback(rollback_config)?;
                }
                Err(e)
            }
        }
    }
}
```

#### Graceful Migration Strategy
```rust
struct ConfigMigrator {
    connection_manager: Arc<ConnectionManager>,
    backend_manager: Arc<BackendManager>,
    listener_manager: Arc<ListenerManager>,
}

#[derive(Debug)]
struct MigrationPlan {
    steps: Vec<MigrationStep>,
    rollback_steps: Vec<MigrationStep>,
}

#[derive(Debug)]
enum MigrationStep {
    AddListener { config: ListenerConfig },
    RemoveListener { listener_id: ListenerId },
    AddBackend { pool_id: PoolId, backend: BackendConfig },
    RemoveBackend { backend_id: BackendId },
    UpdateBackend { backend_id: BackendId, new_config: BackendConfig },
    DrainConnections { backend_id: BackendId, timeout: Duration },
    UpdateAlgorithm { pool_id: PoolId, algorithm: AlgorithmConfig },
}

impl ConfigMigrator {
    fn create_migration_plan(&self, 
                            current: &LoadBalancerConfig,
                            target: &LoadBalancerConfig) -> Result<MigrationPlan, MigrationError> {
        let mut steps = Vec::new();
        let mut rollback_steps = Vec::new();
        
        // Compare listeners
        for (listener_id, new_listener) in &target.listeners {
            match current.listeners.get(listener_id) {
                None => {
                    // New listener - add it
                    steps.push(MigrationStep::AddListener { 
                        config: new_listener.clone() 
                    });
                    rollback_steps.insert(0, MigrationStep::RemoveListener { 
                        listener_id: *listener_id 
                    });
                },
                Some(current_listener) if current_listener != new_listener => {
                    // Modified listener - recreate
                    steps.push(MigrationStep::RemoveListener { 
                        listener_id: *listener_id 
                    });
                    steps.push(MigrationStep::AddListener { 
                        config: new_listener.clone() 
                    });
                    rollback_steps.insert(0, MigrationStep::AddListener { 
                        config: current_listener.clone() 
                    });
                },
                Some(_) => {
                    // Unchanged listener - no action needed
                }
            }
        }
        
        // Remove deleted listeners
        for (listener_id, current_listener) in &current.listeners {
            if !target.listeners.contains_key(listener_id) {
                steps.push(MigrationStep::RemoveListener { 
                    listener_id: *listener_id 
                });
                rollback_steps.insert(0, MigrationStep::AddListener { 
                    config: current_listener.clone() 
                });
            }
        }
        
        // Similar logic for backends...
        self.plan_backend_changes(current, target, &mut steps, &mut rollback_steps)?;
        
        Ok(MigrationPlan { steps, rollback_steps })
    }
    
    fn execute_migration_plan(&self, plan: MigrationPlan) -> Result<(), MigrationError> {
        for step in plan.steps {
            self.execute_migration_step(step)?;
        }
        Ok(())
    }
    
    fn execute_migration_step(&self, step: MigrationStep) -> Result<(), MigrationError> {
        match step {
            MigrationStep::AddListener { config } => {
                self.listener_manager.add_listener(config)?;
            },
            
            MigrationStep::RemoveListener { listener_id } => {
                // Gracefully close listener without dropping existing connections
                self.listener_manager.close_listener(listener_id)?;
            },
            
            MigrationStep::AddBackend { pool_id, backend } => {
                self.backend_manager.add_backend_to_pool(pool_id, backend)?;
            },
            
            MigrationStep::RemoveBackend { backend_id } => {
                // Drain connections before removing
                self.backend_manager.drain_backend(backend_id, Duration::from_secs(30))?;
                self.backend_manager.remove_backend(backend_id)?;
            },
            
            MigrationStep::DrainConnections { backend_id, timeout } => {
                self.backend_manager.drain_backend(backend_id, timeout)?;
            },
            
            // ... other steps
        }
        Ok(())
    }
}
```

### 6. Event-Driven Request Processing

#### Request Processing Pipeline
```rust
struct RequestProcessor {
    pipeline: Vec<Box<dyn RequestMiddleware>>,
    backend_selector: BackendSelector,
    connection_pool: ConnectionPool,
    metrics_collector: MetricsCollector,
}

trait RequestMiddleware: Send + Sync {
    fn process_request(&self, 
                      request: &mut Request, 
                      context: &mut RequestContext) -> MiddlewareResult;
                      
    fn process_response(&self, 
                       response: &mut Response, 
                       context: &mut RequestContext) -> MiddlewareResult;
}

enum MiddlewareResult {
    Continue,
    Stop,
    Error(Box<dyn std::error::Error>),
}

impl RequestProcessor {
    async fn process_request(&self, mut request: Request) -> Result<Response, ProcessingError> {
        let mut context = RequestContext::new(&request);
        
        // Process request through middleware pipeline
        for middleware in &self.pipeline {
            match middleware.process_request(&mut request, &mut context) {
                MiddlewareResult::Continue => continue,
                MiddlewareResult::Stop => return Ok(context.take_response().unwrap()),
                MiddlewareResult::Error(e) => return Err(ProcessingError::Middleware(e)),
            }
        }
        
        // Select backend
        let backend = self.backend_selector.select_backend(&request, &context)?;
        
        // Forward request to backend
        let response = self.forward_to_backend(request, backend).await?;
        
        // Process response through middleware pipeline (in reverse order)
        let mut response = response;
        for middleware in self.pipeline.iter().rev() {
            match middleware.process_response(&mut response, &mut context) {
                MiddlewareResult::Continue => continue,
                MiddlewareResult::Stop => break,
                MiddlewareResult::Error(e) => return Err(ProcessingError::Middleware(e)),
            }
        }
        
        Ok(response)
    }
    
    async fn forward_to_backend(&self, 
                               request: Request, 
                               backend: Backend) -> Result<Response, BackendError> {
        let start_time = Instant::now();
        
        // Get connection from pool
        let mut connection = self.connection_pool.get_connection(&backend).await?;
        
        // Send request
        connection.send_request(&request).await?;
        
        // Read response
        let response = connection.read_response().await?;
        
        // Record metrics
        let duration = start_time.elapsed();
        self.metrics_collector.record_backend_request(
            backend.id,
            duration,
            response.status().is_success()
        );
        
        // Return connection to pool
        self.connection_pool.return_connection(connection);
        
        Ok(response)
    }
}
```

### 7. Error Handling and Recovery

#### Error Recovery Strategies
```rust
#[derive(Debug)]
enum LoadBalancerError {
    // Connection-level errors
    ConnectionTimeout,
    ConnectionRefused,
    ConnectionReset,
    
    // Backend-level errors
    AllBackendsDown,
    BackendTimeout,
    BackendOverloaded,
    
    // Protocol-level errors
    InvalidHttpRequest,
    InvalidHttpResponse,
    SslHandshakeFailure,
    
    // System-level errors
    OutOfMemory,
    OutOfFileDescriptors,
    ConfigurationError,
}

struct ErrorRecoveryManager {
    circuit_breakers: HashMap<BackendId, CircuitBreaker>,
    retry_policies: HashMap<ErrorType, RetryPolicy>,
    fallback_responses: HashMap<ErrorType, Response>,
}

impl ErrorRecoveryManager {
    fn handle_error(&mut self, 
                   error: LoadBalancerError, 
                   context: &RequestContext) -> ErrorHandlingResult {
        match error {
            LoadBalancerError::BackendTimeout => {
                // Check if we should retry with different backend
                if context.retry_count < 2 {
                    ErrorHandlingResult::RetryWithDifferentBackend
                } else {
                    ErrorHandlingResult::SendErrorResponse(504) // Gateway Timeout
                }
            },
            
            LoadBalancerError::AllBackendsDown => {
                ErrorHandlingResult::SendErrorResponse(503) // Service Unavailable
            },
            
            LoadBalancerError::InvalidHttpRequest => {
                ErrorHandlingResult::SendErrorResponse(400) // Bad Request
            },
            
            LoadBalancerError::OutOfMemory => {
                // Aggressive cleanup and connection shedding
                ErrorHandlingResult::EmergencyCleanup
            },
            
            // ... other error types
        }
    }
}

// Circuit Breaker Implementation
struct CircuitBreaker {
    state: CircuitBreakerState,
    failure_count: u32,
    failure_threshold: u32,
    timeout: Duration,
    last_failure_time: Option<Instant>,
    success_count: u32,
    success_threshold: u32,
}

#[derive(Debug, PartialEq)]
enum CircuitBreakerState {
    Closed,      // Normal operation
    Open,        // Failing fast
    HalfOpen,    // Testing recovery
}

impl CircuitBreaker {
    fn can_execute(&mut self) -> bool {
        match self.state {
            CircuitBreakerState::Closed => true,
            CircuitBreakerState::Open => {
                // Check if timeout has passed
                if let Some(last_failure) = self.last_failure_time {
                    if last_failure.elapsed() > self.timeout {
                        self.state = CircuitBreakerState::HalfOpen;
                        self.success_count = 0;
                        true
                    } else {
                        false
                    }
                } else {
                    false
                }
            },
            CircuitBreakerState::HalfOpen => true,
        }
    }
    
    fn record_success(&mut self) {
        match self.state {
            CircuitBreakerState::Closed => {
                self.failure_count = 0;
            },
            CircuitBreakerState::HalfOpen => {
                self.success_count += 1;
                if self.success_count >= self.success_threshold {
                    self.state = CircuitBreakerState::Closed;
                    self.failure_count = 0;
                }
            },
            _ => {}
        }
    }
    
    fn record_failure(&mut self) {
        self.last_failure_time = Some(Instant::now());
        
        match self.state {
            CircuitBreakerState::Closed => {
                self.failure_count += 1;
                if self.failure_count >= self.failure_threshold {
                    self.state = CircuitBreakerState::Open;
                }
            },
            CircuitBreakerState::HalfOpen => {
                self.state = CircuitBreakerState::Open;
                self.success_count = 0;
            },
            _ => {}
        }
    }
}
```

## Performance Optimization Strategies

### 1. Memory Pool Management

#### Buffer Pool Optimization
```rust
struct OptimizedBufferPool {
    pools: [LockFreeQueue<Buffer>; 8], // Different size classes
    size_classes: [usize; 8],
    allocation_counters: [AtomicU64; 8],
    total_allocations: AtomicU64,
    peak_memory_usage: AtomicUsize,
}

impl OptimizedBufferPool {
    fn get_buffer_optimized(&self, required_size: usize) -> Option<Buffer> {
        let size_class = self.find_size_class(required_size);
        
        // Try to get from appropriate pool first
        if let Some(buffer) = self.pools[size_class].pop() {
            self.allocation_counters[size_class].fetch_add(1, Ordering::Relaxed);
            return Some(buffer);
        }
        
        // Try larger size classes
        for i in (size_class + 1)..self.pools.len() {
            if let Some(buffer) = self.pools[i].pop() {
                self.allocation_counters[i].fetch_add(1, Ordering::Relaxed);
                return Some(buffer);
            }
        }
        
        None // Pool exhausted
    }
}
```

### 2. CPU Cache Optimization

#### Data Structure Layout
```rust
// Cache-friendly connection representation
#[repr(C)]
struct CacheFriendlyConnection {
    // Hot data (frequently accessed) - first cache line
    state: ConnectionState,
    client_fd: i32,
    backend_fd: i32,
    last_activity: u64,
    
    // Warm data - second cache line
    bytes_sent: u64,
    bytes_received: u64,
    request_count: u32,
    error_count: u32,
    
    // Cold data - separate allocation
    extended_data: *mut ConnectionExtendedData,
}

// Keep frequently accessed data together
struct ConnectionArray {
    // Structure of Arrays for better cache utilization
    states: Vec<ConnectionState>,
    client_fds: Vec<i32>,
    backend_fds: Vec<i32>,
    last_activities: Vec<u64>,
    
    // Less frequently accessed data
    extended_data: Vec<Option<Box<ConnectionExtendedData>>>,
}
```

### 3. Network I/O Optimization

#### Zero-Copy Techniques
```rust
struct ZeroCopyProxy {
    splice_buffers: Vec<SpliceBuffer>,
    sendfile_cache: LruCache<PathBuf, FileDescriptor>,
}

impl ZeroCopyProxy {
    async fn proxy_data(&self, 
                       client_fd: i32, 
                       backend_fd: i32) -> Result<usize, IoError> {
        // Use splice for zero-copy data transfer
        let bytes_transferred = unsafe {
            libc::splice(
                client_fd,
                ptr::null_mut(),
                backend_fd,
                ptr::null_mut(),
                SPLICE_BUFFER_SIZE,
                libc::SPLICE_F_MOVE | libc::SPLICE_F_MORE
            )
        };
        
        if bytes_transferred < 0 {
            Err(IoError::last_os_error())
        } else {
            Ok(bytes_transferred as usize)
        }
    }
    
    async fn serve_static_file(&self, 
                              client_fd: i32, 
                              file_path: &Path) -> Result<usize, IoError> {
        let file_fd = self.sendfile_cache.get_or_insert(file_path, || {
            std::fs::File::open(file_path)?.into_raw_fd()
        })?;
        
        let bytes_sent = unsafe {
            libc::sendfile(client_fd, file_fd, ptr::null_mut(), file_size)
        };
        
        if bytes_sent < 0 {
            Err(IoError::last_os_error())
        } else {
            Ok(bytes_sent as usize)
        }
    }
}
```

### 4. Lock-Free Data Structures

#### Lock-Free Connection Tracking
```rust
use crossbeam::atomic::AtomicCell;
use crossbeam::queue::SegQueue;

struct LockFreeConnectionManager {
    active_connections: SegQueue<ConnectionId>,
    connection_states: Vec<AtomicCell<ConnectionState>>,
    connection_data: Vec<AtomicPtr<ConnectionData>>,
    free_connection_ids: SegQueue<ConnectionId>,
}

impl LockFreeConnectionManager {
    fn add_connection(&self, client_fd: i32, client_addr: SocketAddr) -> Option<ConnectionId> {
        if let Some(conn_id) = self.free_connection_ids.pop() {
            let connection_data = Box::new(ConnectionData::new(client_fd, client_addr));
            
            self.connection_data[conn_id.0 as usize]
                .store(Box::into_raw(connection_data), Ordering::Release);
            
            self.connection_states[conn_id.0 as usize]
                .store(ConnectionState::Accepting);
                
            self.active_connections.push(conn_id);
            
            Some(conn_id)
        } else {
            None // No free connection slots
        }
    }
    
    fn remove_connection(&self, conn_id: ConnectionId) {
        self.connection_states[conn_id.0 as usize]
            .store(ConnectionState::Closed);
            
        // Safely deallocate connection data
        let ptr = self.connection_data[conn_id.0 as usize]
            .swap(ptr::null_mut(), Ordering::AcqRel);
            
        if !ptr.is_null() {
            unsafe {
                Box::from_raw(ptr);
            }
        }
        
        self.free_connection_ids.push(conn_id);
    }
}
```

## Deployment Architecture Patterns

### 1. Single Instance Deployment
```yaml
# Single instance configuration
deployment:
  type: single_instance
  resources:
    cpu_cores: 4
    memory: "8GB"
    max_connections: 10000
  
  features:
    - http_proxy
    - https_termination
    - health_checks
    - basic_metrics
  
  limits:
    request_rate: "50000/sec"
    connection_timeout: "60s"
    backend_timeout: "30s"
```

### 2. High Availability Deployment
```yaml
# HA deployment with multiple instances
deployment:
  type: high_availability
  instances: 3
  
  load_balancer:
    type: keepalived  # VIP failover
    vip: "192.168.1.100"
    
  instance_config:
    resources:
      cpu_cores: 8
      memory: "16GB"
      max_connections: 25000
      
    clustering:
      enabled: true
      consensus_protocol: "raft"
      
  failover:
    detection_timeout: "3s"
    promotion_timeout: "5s"
    split_brain_protection: true
```

### 3. Horizontally Scaled Deployment
```yaml
# Auto-scaling deployment
deployment:
  type: auto_scaling
  min_instances: 2
  max_instances: 20
  
  scaling_triggers:
    - metric: "cpu_usage"
      threshold: 70
      duration: "60s"
      
    - metric: "active_connections"
      threshold: 20000
      duration: "30s"
      
  load_distribution:
    method: "consistent_hashing"
    session_affinity: true
    
  rolling_updates:
    max_unavailable: 1
    max_surge: 2
    health_check_grace_period: "30s"
```

## Security Architecture

### 1. Multi-Layer Security Model
```rust
struct SecurityManager {
    // Layer 1: Network filtering
    ip_filter: IpFilterEngine,
    geo_filter: GeoLocationFilter,
    
    // Layer 2: Protocol security
    tls_manager: TlsManager,
    certificate_validator: CertificateValidator,
    
    // Layer 3: Application security
    waf_engine: WebApplicationFirewall,
    rate_limiter: RateLimiter,
    
    // Layer 4: Authentication/Authorization
    auth_manager: AuthenticationManager,
    authz_engine: AuthorizationEngine,
}

impl SecurityManager {
    fn evaluate_request(&self, request: &Request) -> SecurityDecision {
        // Layer 1: Network-level filtering
        if !self.ip_filter.is_allowed(&request.client_ip) {
            return SecurityDecision::Block(BlockReason::IpBlacklist);
        }
        
        if !self.geo_filter.is_allowed(&request.client_ip) {
            return SecurityDecision::Block(BlockReason::GeoBlocked);
        }
        
        // Layer 2: Protocol-level security
        if request.is_https() && !self.validate_tls_context(&request.tls_context) {
            return SecurityDecision::Block(BlockReason::InvalidTls);
        }
        
        // Layer 3: Application-level security
        if let Some(waf_violation) = self.waf_engine.evaluate(request) {
            return SecurityDecision::Block(BlockReason::WafViolation(waf_violation));
        }
        
        if !self.rate_limiter.is_allowed(&request.client_ip) {
            return SecurityDecision::RateLimit;
        }
        
        // Layer 4: Authentication/Authorization
        if let Some(auth_result) = self.auth_manager.authenticate(request) {
            if !self.authz_engine.is_authorized(&auth_result, request) {
                return SecurityDecision::Block(BlockReason::Unauthorized);
            }
        }
        
        SecurityDecision::Allow
    }
}
```

### 2. TLS/SSL Architecture
```rust
struct TlsManager {
    certificate_store: CertificateStore,
    cipher_suites: Vec<CipherSuite>,
    protocols: Vec<TlsVersion>,
    session_cache: TlsSessionCache,
    ocsp_stapler: OcspStapler,
}

impl TlsManager {
    fn create_tls_context(&self, sni_hostname: Option<&str>) -> Result<TlsContext, TlsError> {
        // Select appropriate certificate
        let cert_chain = self.certificate_store
            .get_certificate_chain(sni_hostname)
            .ok_or(TlsError::NoCertificate)?;
        
        // Configure TLS context
        let mut ctx = TlsContext::new()?;
        ctx.set_certificate_chain(cert_chain)?;
        ctx.set_cipher_suites(&self.cipher_suites)?;
        ctx.set_protocols(&self.protocols)?;
        
        // Enable session resumption
        ctx.set_session_cache(&self.session_cache)?;
        
        // Configure OCSP stapling
        if let Some(ocsp_response) = self.ocsp_stapler.get_response(sni_hostname) {
            ctx.set_ocsp_response(ocsp_response)?;
        }
        
        Ok(ctx)
    }
}
```

This comprehensive architecture guide provides the foundation for implementing scalable, performant, and secure load balancers that can handle production workloads effectively.
# Grafana Dashboards Analysis

## Overview

**Total Dashboards:** 20
**Location:** `monitoring/grafana/dashboard-files/`

The monitoring stack provides comprehensive observability across 6 major categories:
1. **System & Resource Monitoring** (4 dashboards)
2. **Consumer Health & Performance** (5 dashboards)
3. **Data Refresh Monitoring** (4 dashboards)
4. **Storage & Disk Health** (2 dashboards)
5. **Business & SLA Metrics** (3 dashboards)
6. **Broker Core Metrics** (2 dashboards)

---

## Category 1: System & Resource Monitoring

### 1.1 Broker Bottleneck - CPU / Memory / Disk
**File:** `broker-bottleneck.json` (20KB, 12 panels)

**Purpose:** Identify performance bottlenecks in broker system resources

**Key Metrics:**
- **Heap Usage %** - Heap utilization against max (-Xmx)
- **Container Memory %** - Total container memory usage
- **CPU Usage %** - Process CPU utilization
- **GC Pause Rate** - Garbage collection pause time (ms/s)
- **Disk Read/Write p99** - 99th percentile I/O latency
- **Open File Descriptors** - Track file descriptor leaks
- **Disk I/O Time** - Time spent in I/O (should be < 0.1s/s)

**Panels:**
1. Stat: Heap Usage %
2. Stat: Container Memory %
3. Stat: CPU Usage %
4. Stat: GC Pause (ms/s)
5. Stat: Disk Read p99 (ms)
6. Stat: Disk Write p99 (ms)
7. Stat: Disk I/O Time (s/s)
8. Stat: Open File Descriptors
9. Timeseries: Heap vs Max (MB)
10. Timeseries: Container Memory (MB)
11. Timeseries: GC Pause Rate (ms/s)
12. Timeseries: Storage Read/Write Latency p99 (ms)

**Use Case:**
- Debug OOM issues (B11-6 investigation)
- Identify CPU saturation
- Track GC pressure
- Monitor disk I/O bottlenecks

---

### 1.2 Broker System Metrics - JVM & Resources
**File:** `broker-system-metrics.json` (21KB, 15 panels)

**Purpose:** Detailed JVM and resource monitoring

**Key Metrics:**
- **Container CPU/Memory** - Docker container resource usage
- **Active Threads** - Thread count (should match thread pool sizes)
- **Disk I/O Rate** - Read/write bytes per second
- **Heap vs Non-Heap** - Breakdown of JVM memory regions
- **GC Activity** - Pause time, frequency, and type
- **Memory Pool Breakdown** - Eden, Survivor, Old Gen, Metaspace

**Panels:**
1. Stat: Container CPU Usage
2. Gauge: Container Memory Usage
3. Stat: Active Threads
4. Stat: Disk I/O Rate
5. Stat: Memory Breakdown (Container vs JVM)
6. Timeseries: Container CPU Trend
7. Timeseries: Container Memory Trend
8. Timeseries: Disk I/O Trend
9. Timeseries: Thread Count Trend
10. Stat: Heap vs Non-Heap Memory
11. Stat: GC Activity Summary
12. Stat: Memory Pool Breakdown
13. Timeseries: Heap Memory Usage Trend
14. Timeseries: Garbage Collection Activity
15. Timeseries: Memory Pools Trend

**Use Case:**
- JVM tuning (G1GC settings)
- Memory leak detection
- Thread pool sizing

---

### 1.3 Container Metrics
**File:** `container-metrics.json` (7.3KB, 9 panels)

**Purpose:** cAdvisor-based container resource monitoring

**Key Metrics:**
- **Disk Read/Write Bytes/sec** - Container-level I/O
- **Network RX/TX Bytes/sec** - Network throughput
- **Container CPU/Memory** - Resource usage from Docker

**Panels:**
1. Timeseries: Disk Read Bytes/sec
2. Timeseries: Disk Write Bytes/sec
3. Timeseries: Network Receive Bytes/sec
4. Timeseries: Network Transmit Bytes/sec
5. Timeseries: Container CPU Usage
6. Timeseries: Container Memory Usage
7. Stat: Disk I/O Summary
8. Stat: Network RX Summary
9. Stat: Network TX Summary

**Use Case:**
- Docker resource limits validation
- Network saturation detection

---

### 1.4 Thread Monitoring Dashboard
**File:** `thread-monitoring-dashboard.json` (17KB, 9 panels)

**Purpose:** Thread-level resource consumption analysis

**Key Metrics:**
- **Total Threads** - Current thread count
- **Blocked/Waiting Threads** - Contention indicators
- **Deadlocked Threads** - Critical issue detection
- **CPU Time by Category** - Per-thread-group CPU usage
- **Memory Allocation Rate** - Which threads allocate most memory

**Panels:**
1. Stat: Total Threads
2. Stat: Blocked Threads
3. Stat: Waiting Threads
4. Stat: Deadlocked Threads
5. Timeseries: Thread Count by Category
6. Timeseries: CPU Time by Category (Rate)
7. Timeseries: Memory Allocation Rate by Thread Category (MB/sec)
8. Piechart: Thread Distribution by Category
9. Table: Thread Resources by Category

**Use Case:**
- TopicFairScheduler thread pool sizing
- Netty thread pool optimization
- Deadlock detection

---

## Category 2: Consumer Health & Performance

### 2.1 Messaging Broker - Multi-Consumer Dashboard
**File:** `messaging-broker-dashboard.json` (30KB, 15 panels)

**Purpose:** Primary operational dashboard for broker-consumer system

**Key Metrics:**
- **Active Subscriptions** - Total consumer-topic registrations
- **Msgs In/Out per sec** - Ingress from cloud, egress to consumers
- **Bytes In/Out per sec** - Data throughput
- **Avg E2E Latency** - Cloud → Broker → Consumer
- **Component Latency Breakdown** - Storage, network, delivery
- **Consumer Connection Status** - Connected/disconnected

**Panels:**
1. Stat: Active Subscriptions
2. Stat: Msgs In/sec
3. Stat: Msgs Out/sec
4. Stat: Avg E2E Latency
5. Stat: Bytes In/sec
6. Stat: Bytes Out/sec
7. Stat: Total Stored
8. Timeseries: End-to-End Latency (Cloud → Consumer)
9. Timeseries: Component Latency Breakdown
10. Timeseries: Data Throughput (Bytes/sec)
11. Timeseries: Message Throughput (Msgs/sec)
12. Timeseries: Consumer Connection Status
13. Timeseries: Message Size Distribution
14. Timeseries: Storage Operations
15. Timeseries: Consumer Batch Metrics

**Use Case:**
- Primary operations dashboard
- Real-time health monitoring
- SLA compliance tracking

---

### 2.2 Per-Consumer Metrics - Detailed View
**File:** `per-consumer-dashboard.json` (23KB, 16 panels)

**Purpose:** Drill-down view per consumer group

**Key Metrics:**
- **Consumer Offset** - Current read position per topic
- **Consumer Lag** - Messages behind latest
- **Delivery Latency** - Avg/Max latency per consumer
- **Transfer Success Rate** - Failed vs successful bytes
- **Consumer Health** - Overall health indicator

**Panels:**
1. Table: Active Consumer Groups by Topic
2. Stat: Successful Messages Sent
3. Stat: Successful Data Sent (GB)
4. Stat: Current Offset
5. Stat: Consumer Lag
6. Timeseries: Consumer Offset Over Time
7. Timeseries: Consumer Lag Over Time
8. Timeseries: Message Throughput (Msgs/sec)
9. Timeseries: Data Throughput (Bytes/sec)
10. Timeseries: Delivery Latency (Avg)
11. Timeseries: Delivery Latency (Max)
12. Table: Consumer Metrics Table (Grouped by Topic and Group)
13. Stat: Failed Bytes (MB)
14. Stat: Transfer Success Rate (%)
15. Stat: Consumer Health
16. [Additional panel]

**Use Case:**
- Per-consumer troubleshooting
- Consumer-specific performance analysis
- Lag investigation

---

### 2.3 Consumer Health & Performance
**File:** `consumer-health-performance.json` (16KB, 12 panels)

**Purpose:** Health status and performance overview for all consumers

**Key Metrics:**
- **Active Consumer Groups** - Total registered groups
- **Avg Consumer Lag** - Overall lag across all consumers
- **Avg Delivery Latency (p99)** - 99th percentile latency
- **Failed Transfer Rate %** - Error rate
- **Stuck Consumers** - No ACK for >10 minutes

**Panels:**
1. Stat: Active Consumer Groups
2. Stat: Active Consumer Subscriptions
3. Stat: Avg Consumer Lag
4. Stat: Avg Delivery Latency (p99)
5. Table: Consumer Group Overview
6. Timeseries: Message Rate by Consumer Group
7. Timeseries: Consumer Lag Trend
8. Timeseries: Delivery Latency (p99) by Consumer Group
9. Stat: Failed Transfer Rate (%)
10. Stat: Stuck Consumers (>10min no ACK)
11. Timeseries: Time Since Last ACK by Consumer
12. Timeseries: Failed Messages by Consumer Group

**Use Case:**
- Overall consumer health check
- Identify stuck/disconnected consumers
- SLA monitoring

---

### 2.4 Consumer Delivery Diagnosis
**File:** `consumer-delivery-diagnosis.json` (17KB, 9 panels)

**Purpose:** Diagnose delivery failures and stuck consumers

**Key Metrics:**
- **Disconnected Consumers (5m)** - Recent disconnects
- **Stuck Consumers (>10m)** - No ACK in 10 minutes
- **Delivery Paused** - Lag > 0 but no sends
- **Failed Bytes Rate** - Data transfer failure rate
- **Time Since Last ACK/Delivery** - Staleness indicators

**Panels:**
1. Stat: Disconnected Consumers (5m)
2. Stat: Stuck Consumers (>10m)
3. Stat: Delivery Paused (lag>0, no sends)
4. Stat: Failed Bytes Rate (MB/s)
5. Timeseries: Consumer Lag by Group
6. Timeseries: Send Rate by Group (msgs/s)
7. Timeseries: Time Since Last ACK (s)
8. Timeseries: Time Since Last Delivery (s)
9. Timeseries: Failed Bytes Rate by Group (MB/s)

**Use Case:**
- Troubleshoot consumer not receiving data
- Identify Gate 2 BLOCKED scenarios (B11-6)
- Detect consumer application hangs

---

### 2.5 Consumer Error Dashboard
**File:** `consumer-error-dashboard.json` (14KB, 8 panels)

**Purpose:** Focus on error rates and failure modes

**Key Metrics:**
- **Failed Messages Rate** - Errors per second
- **Failed Bytes Rate** - Data loss rate
- **Disconnect Rate** - Connection churn
- **Decode Errors** - Protocol mismatch errors

**Panels:**
1. Stat: Failed Messages Rate (msgs/s)
2. Stat: Failed Bytes Rate (MB/s)
3. Stat: Stuck Consumers (>10m)
4. Stat: Disconnect Rate (5m)
5. Timeseries: Failed Messages by Topic/Group
6. Timeseries: Failed Bytes by Topic/Group (MB/s)
7. Timeseries: Time Since Last ACK (s)
8. Timeseries: Consumer Decode Errors (if exposed)

**Use Case:**
- Monitor error rates
- Detect protocol issues (like message type -100)
- Alert on high failure rates

---

## Category 3: Data Refresh Monitoring

### 3.1 Data Refresh - Overview
**File:** `data-refresh-overview.json` (23KB, 4 panels)

**Purpose:** High-level refresh batch tracking

**Key Metrics:**
- **Total Batches Completed** - Historical count
- **Active Batches** - Currently running refreshes
- **Refresh History Table** - Clickable rows for drill-down
- **Batch Statistics** - By refresh type (LOCAL/GLOBAL)

**Panels:**
1. Stat: Total Batches Completed
2. Stat: Active Batches
3. Table: Refresh History - Click Row for Details
4. Table: Batch Statistics by Refresh Type

**Use Case:**
- Track refresh batch completion
- Identify long-running refreshes
- Historical refresh analysis

---

### 3.2 Data Refresh Monitoring
**File:** `data-refresh-monitoring.json` (14KB, 6 panels)

**Purpose:** Per-topic refresh progress and performance

**Key Metrics:**
- **In Progress Topics** - Topics currently refreshing
- **Topic Details by Batch** - Status per topic in batch
- **Data Transferred** - Bytes replayed per consumer
- **Transfer Rate** - Throughput during refresh
- **RESET ACK Duration** - Time to receive RESET_ACK
- **READY ACK Duration** - Time for replay to complete

**Panels:**
1. Table: ⚠️ In Progress Topics (Not Yet Completed)
2. Table: Topic Details by Batch
3. Table: Data Transferred by Consumer
4. Table: Transfer Rate by Consumer
5. Table: RESET ACK Duration by Consumer
6. Table: READY ACK (Replay) Duration by Consumer

**Use Case:**
- Monitor refresh progress in real-time
- Identify slow RESET_ACK responses (B11-6)
- Track replay throughput

---

### 3.3 Refresh Reliability
**File:** `refresh-reliability.json` (12KB, 7 panels)

**Purpose:** Refresh success/failure tracking

**Key Metrics:**
- **Refreshes Completed (24h)** - Success count
- **Refresh Failures (24h)** - Failure count
- **Avg Refresh Duration** - Time to complete
- **RESET ACK Duration** - Avg time for RESET_ACK
- **READY ACK Duration** - Avg time for READY_ACK

**Panels:**
1. Stat: Refreshes Completed (24h)
2. Stat: Refresh Failures (24h)
3. Stat: Active Refresh Batches
4. Stat: Avg Refresh Duration (s)
5. Table: Recent Refresh Runs
6. Timeseries: RESET ACK Duration (avg ms)
7. Timeseries: READY ACK Duration (avg ms)

**Use Case:**
- SLA compliance for refresh operations
- Detect refresh failures
- Optimize refresh timing

---

### 3.4 Data Refresh Tables
**File:** `data-refresh-tables.json` (8.7KB, 0 panels)

**Purpose:** Empty/template dashboard

**Status:** No panels configured

---

## Category 4: Storage & Disk Health

### 4.1 Storage & Disk Health
**File:** `storage-disk-health.json` (12KB, 11 panels)

**Purpose:** Comprehensive storage performance monitoring

**Key Metrics:**
- **Read/Write IOPS** - Operations per second
- **Read/Write Latency (p99)** - 99th percentile
- **Active Segments** - Number of open segment files
- **Disk I/O Time** - Time spent in I/O operations
- **Read vs Write Distribution** - Operation mix

**Panels:**
1. Stat: Read IOPS
2. Stat: Write IOPS
3. Stat: Read Latency (p99)
4. Stat: Write Latency (p99)
5. Timeseries: Storage Read/Write IOPS
6. Timeseries: Container Disk I/O (cAdvisor)
7. Timeseries: Read Latency Percentiles
8. Timeseries: Write Latency Percentiles
9. Timeseries: Active Storage Segments
10. Timeseries: Read vs Write Distribution
11. Timeseries: Disk I/O Time

**Use Case:**
- Detect storage bottlenecks
- Monitor segment file growth
- Optimize mmap performance

---

### 4.2 Storage Health Detail
**File:** `storage-health-detail.json` (15KB, 8 panels)

**Purpose:** Detailed storage operation metrics

**Key Metrics:**
- **Read/Write p99** - Latency percentiles
- **Disk I/O (bytes/s)** - Throughput
- **Storage Reads/Writes (ops/s)** - Operation rate
- **Disk I/O Time** - I/O wait time

**Panels:**
1. Stat: Read p99 (ms)
2. Stat: Write p99 (ms)
3. Stat: Read IOPS
4. Stat: Write IOPS
5. Timeseries: Read/Write Latency p99 (ms)
6. Timeseries: Disk I/O (bytes/s)
7. Timeseries: Storage Reads/Writes (ops/s)
8. Timeseries: Disk I/O Time (s/s)

**Use Case:**
- Deep dive into storage performance
- Correlate latency spikes with operations

---

## Category 5: Business & SLA Metrics

### 5.1 Business KPI - Messaging
**File:** `business-kpi.json` (13KB, 10 panels)

**Purpose:** Executive-level KPIs for messaging system

**Key Metrics:**
- **Messages Delivered (24h)** - Total throughput
- **Bytes Delivered (24h)** - Data volume
- **Delivery Success %** - Overall success rate
- **Active Consumer Groups** - Service count
- **Stuck Consumers** - Health indicator
- **Avg E2E Latency p95** - Performance metric
- **Refreshes Completed (24h)** - Operational metric

**Panels:**
1. Stat: Messages Delivered (24h)
2. Stat: Bytes Delivered (24h)
3. Stat: Delivery Success % (5m)
4. Stat: Active Consumer Groups
5. Stat: Stuck Consumers (>10m)
6. Stat: Avg E2E Latency p95 (ms)
7. Stat: Refreshes Completed (24h)
8. Stat: Active Refresh Batches
9. Table: Top Topics by Bytes (24h)
10. Table: Top Topics by Messages (24h)

**Use Case:**
- Executive reporting
- SLA compliance tracking
- Capacity planning

---

### 5.2 Data Freshness SLA
**File:** `data-freshness-sla.json` (9KB, 6 panels)

**Purpose:** Track data freshness SLA compliance

**Key Metrics:**
- **Topics Stale >5m** - SLA violation count
- **Freshness SLA % (<5m)** - Compliance percentage
- **Worst Staleness** - Maximum lag time
- **Avg Staleness** - Average lag across topics
- **Staleness by Topic** - Per-topic lag

**Panels:**
1. Stat: Topics Stale >5m
2. Stat: Freshness SLA % (<5m)
3. Stat: Worst Staleness (s)
4. Stat: Avg Staleness (s)
5. Timeseries: Staleness by Topic (s)
6. Table: Top 10 Stale Topics

**Use Case:**
- SLA monitoring (<5 minute freshness)
- Identify stale data issues
- Consumer lag alerting

---

### 5.3 Producer vs Consumer Gap
**File:** `producer-consumer-gap.json` (12KB, 7 panels)

**Purpose:** Track producer-consumer balance

**Key Metrics:**
- **Ingress Rate** - Messages from cloud-server
- **Egress Rate** - Messages to consumers
- **Delivery Ratio %** - Egress / Ingress ratio
- **Total Lag** - Accumulated backlog
- **Backlog Growth** - Increasing/decreasing trend

**Panels:**
1. Stat: Ingress Rate (msgs/s)
2. Stat: Egress Rate (msgs/s)
3. Stat: Delivery Ratio %
4. Stat: Total Lag (all topics)
5. Timeseries: Ingress vs Egress (msgs/s)
6. Timeseries: Backlog Growth (msgs/s)
7. Timeseries: Lag by Topic

**Use Case:**
- Detect consumer saturation
- Capacity planning
- Backlog alerting

---

## Category 6: Broker Core Metrics

### 6.1 Topic Performance
**File:** `topic-performance.json` (15KB, 12 panels)

**Purpose:** Per-topic performance analysis

**Key Metrics:**
- **Active Topics** - Total topic count
- **Successful Throughput** - Messages per second
- **Avg Message Size** - Batch sizing
- **Delivery Latency (p99)** - Per-topic latency
- **Failed Transfer Rate** - Error rate by topic

**Panels:**
1. Stat: Active Topics
2. Stat: Successful Throughput
3. Stat: Total Successful Bytes (MB)
4. Stat: Avg Message Size
5. Table: Topic Performance Overview
6. Timeseries: Message Rate by Topic
7. Timeseries: Bytes Throughput by Topic
8. Timeseries: Delivery Latency (p99) by Topic
9. Timeseries: Total Messages Sent by Topic
10. Stat: Total Failed Bytes (MB)
11. Stat: Overall Success Rate (%)
12. Timeseries: Failed Transfer Rate by Topic (bytes/s)

**Use Case:**
- Identify hot topics (prices-v1)
- Per-topic performance tuning
- Topic-level alerting

---

### 6.2 Pipe Performance Dashboard
**File:** `pipe-performance.json` (13KB, 6 panels)

**Purpose:** Monitor parent-broker HTTP pipe connection

**Key Metrics:**
- **Pipe Fetch Latency** - HTTP poll latency (target: <200ms)
- **Current P95 Latency** - 95th percentile
- **Total Messages Received** - Ingress from parent
- **Fetch Status** - Success/failure indicator
- **Pipe Throughput** - Messages per second

**Panels:**
1. Timeseries: Pipe Fetch Latency (Target: < 200ms)
2. Stat: Current P95 Latency
3. Stat: Total Messages Received
4. Stat: Fetch Status
5. Timeseries: Pipe Throughput
6. Timeseries: Consumer Message Rate

**Use Case:**
- Monitor parent broker connection
- Detect pipe connection issues
- Optimize poll interval

---

## Prometheus Configuration

### Datasource Config
**File:** `grafana/provisioning/datasources/prometheus.yml`

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

### Dashboard Provisioning
**File:** `grafana/provisioning/dashboards/dashboard-provisioning.yml`

```yaml
apiVersion: 1

providers:
  - name: 'Messaging Dashboards'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
```

---

## Key Metrics Summary

### Critical Metrics for OOM Investigation (B11-6)

**Heap & Memory:**
- `jvm_memory_used_bytes{area="heap"}` - Heap usage
- `container_memory_working_set_bytes` - Container memory
- `broker_consumer_offset` - Consumer offset tracking
- `broker_consumer_lag` - Consumer lag

**Delivery Storm Indicators:**
- `broker_consumer_messages_sent_total` - Delivery attempts
- `broker_consumer_failures_total` - Failed deliveries
- `broker_consumer_delivery_latency_seconds` - Delivery latency

**Data Refresh Metrics:**
- `data_refresh_started_total` - Refresh initiation
- `data_refresh_reset_ack_duration_seconds` - RESET ACK time
- `data_refresh_ready_ack_duration_seconds` - READY ACK time
- `data_refresh_state` - Current refresh state (RESET_SENT, REPLAYING, etc.)

**Thread & Resource:**
- `jvm_threads_current` - Thread count
- `jvm_threads_blocked` - Blocked thread count
- `process_cpu_usage` - CPU utilization
- `broker_storage_read_seconds` - Storage read latency
- `broker_storage_write_seconds` - Storage write latency

### Alert-Worthy Metrics

**Critical:**
- Heap usage > 85%
- Container memory > 90%
- Stuck consumers > 0 for 10 minutes
- Refresh failures > 0
- Deadlocked threads > 0

**Warning:**
- Consumer lag > 10,000 messages
- Delivery latency p99 > 500ms
- Failed transfer rate > 5%
- GC pause time > 100ms/s
- Disk I/O latency p99 > 50ms

---

## Dashboard Usage Recommendations

### Daily Operations
1. **Messaging Broker - Multi-Consumer Dashboard** - Primary view
2. **Consumer Health & Performance** - Consumer status
3. **Broker Bottleneck** - Resource monitoring

### Troubleshooting OOM
1. **Broker Bottleneck** - Check heap/memory/CPU
2. **Thread Monitoring Dashboard** - Check thread explosion
3. **Consumer Delivery Diagnosis** - Check delivery storm
4. **Data Refresh Monitoring** - Check if refresh stuck

### Data Refresh Operations
1. **Data Refresh - Overview** - Track batches
2. **Data Refresh Monitoring** - Monitor progress
3. **Refresh Reliability** - Check duration/failures

### Performance Tuning
1. **Storage & Disk Health** - I/O optimization
2. **Topic Performance** - Per-topic analysis
3. **Per-Consumer Dashboard** - Consumer-specific tuning

---

## Next Steps

1. **Add OOM-specific dashboard** for B11-6 monitoring:
   - Panel: "Gate 2 BLOCKED" attempts per minute
   - Panel: Adaptive delivery skip rate (B11-6a fix)
   - Panel: Refresh state transitions
   - Panel: Heap growth rate during DataRefresh

2. **Configure alerts**:
   - Alert when stuck consumers > 0 for 10 min
   - Alert when heap > 85%
   - Alert when refresh duration > 5 min
   - Alert when "Gate 2 BLOCKED" rate > 10/min

3. **Add missing metrics**:
   - `broker_adaptive_delivery_skipped_total{reason="RESET_SENT"}` (B11-6a)
   - `broker_force_refresh_cleanup_total` (B11-6b)
   - `broker_fileregion_send_failures_total`


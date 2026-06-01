# Memory Panel Fix - Broker System Metrics Dashboard

## Issue Summary

The "Container Memory Usage" panel in the "Broker System Metrics - JVM & Resources" dashboard was showing **391.9 MiB**, while `docker stats` showed **287.1 MiB** for the messaging-broker container.

## Root Cause

The dashboard was using the wrong cAdvisor metric:
- **Previous (incorrect):** `container_memory_usage_bytes`
  - Includes total memory including page cache, buffers, and other cached memory
  - Value: 391.9 MiB

- **New (correct):** `container_memory_working_set_bytes`
  - Shows active working memory (what Docker actually considers "in use")
  - Value: 287.1 MiB ✅
  - **Matches `docker stats` exactly**

## Understanding the Metrics

### cAdvisor Memory Metrics Comparison

| Metric | Value | Description | Used By |
|--------|-------|-------------|---------|
| `container_memory_usage_bytes` | 391.9 MiB | Total memory including cache | ❌ Old dashboard |
| `container_memory_working_set_bytes` | 287.1 MiB | Active working memory | ✅ Docker stats, Fixed dashboard |
| `container_memory_rss` | 277.3 MiB | Resident set size (physical RAM) | - |
| `container_spec_memory_limit_bytes` | 500 MiB | Container memory limit | Both |

### Why the Discrepancy?

Docker (and Kubernetes) use `container_memory_working_set_bytes` because:
1. **Excludes cache**: Page cache can be reclaimed instantly by the kernel
2. **Represents actual pressure**: Shows memory that cannot be easily freed
3. **OOM decisions**: Container gets killed based on working set, not total usage
4. **Industry standard**: Kubernetes uses working_set for resource limits

## Changes Made

### Files Updated

1. **broker-system-metrics.json** (3 panels updated):
   - Panel 2: "Container Memory Usage" (gauge) - line 75
   - Panel 4: "Memory Breakdown (Container vs JVM)" (stat) - line 187
   - Panel 6: "Container Memory Trend" (timeseries) - line 318

2. **container-metrics.json** (1 panel updated):
   - Panel 6: "Container Memory Usage" (timeseries) - line 211

### Queries Changed

**Before:**
```promql
# Percentage gauge
container_memory_usage_bytes{id=~".*/50b37ebce75b.*"} / container_spec_memory_limit_bytes{id=~".*/50b37ebce75b.*"} * 100

# Absolute value (MB)
container_memory_usage_bytes{id=~".*/50b37ebce75b.*"} / 1024 / 1024
```

**After:**
```promql
# Percentage gauge
container_memory_working_set_bytes{id=~".*/50b37ebce75b.*"} / container_spec_memory_limit_bytes{id=~".*/50b37ebce75b.*"} * 100

# Absolute value (MB)
container_memory_working_set_bytes{id=~".*/50b37ebce75b.*"} / 1024 / 1024
```

## Verification

### Before Fix
```bash
$ docker stats messaging-broker
NAME               MEM USAGE / LIMIT     MEM %
messaging-broker   287.1MiB / 500MiB     57.40%

$ curl "http://localhost:9090/api/v1/query?query=container_memory_usage_bytes{...}"
# Result: 391.9 MiB  ❌ MISMATCH
```

### After Fix
```bash
$ docker stats messaging-broker
NAME               MEM USAGE / LIMIT     MEM %
messaging-broker   287.1MiB / 500MiB     57.40%

$ curl "http://localhost:9090/api/v1/query?query=container_memory_working_set_bytes{...}"
# Result: 287.1 MiB  ✅ MATCH
```

## Memory Breakdown (Current State)

### Container Memory: 287.1 MiB
Breakdown:
- **JVM Heap:** ~75.5 MiB
  - G1 Eden Space: 36.7 MiB
  - G1 Old Gen: 38.0 MiB
  - G1 Survivor Space: 0.8 MiB

- **JVM Non-Heap:** ~81.4 MiB
  - Metaspace: 48.7 MiB
  - CodeHeap (profiled nmethods): 14.9 MiB
  - CodeHeap (non-profiled nmethods): 7.9 MiB
  - Compressed Class Space: 8.5 MiB
  - CodeHeap (non-nmethods): 1.4 MiB

- **JVM Total:** ~157 MiB (54.6% of container memory)
- **Other (Native, buffers, etc.):** ~130 MiB (45.4%)

## Impact

### Dashboards Affected
1. ✅ **Broker System Metrics - JVM & Resources** - FIXED
   - Container Memory Usage gauge now shows 57.4% (was showing ~78%)
   - Memory Breakdown panel now matches docker stats
   - Container Memory Trend graph adjusted

2. ✅ **Container Metrics** - FIXED
   - System memory panel updated to use working set

### Dashboards NOT Affected
- Consumer Health & Performance (uses broker-side metrics)
- Topic Performance (uses broker-side metrics)
- Storage & Disk Health (uses storage metrics)
- Data Refresh Monitoring (uses refresh-specific metrics)

## Testing

After applying the fix:

1. **Grafana restarted** to reload dashboards ✅
2. **Metrics verified** via Prometheus API ✅
3. **Values match** docker stats exactly ✅

## Best Practices Going Forward

### Use the Right Metric for the Job

- **For container memory monitoring:** Use `container_memory_working_set_bytes`
  - Matches Docker/Kubernetes behavior
  - Reflects actual memory pressure
  - Used for OOM kill decisions

- **For JVM monitoring:** Continue using JVM-specific metrics
  - `jvm_memory_used_bytes{area="heap"}`
  - `jvm_memory_used_bytes{area="nonheap"}`
  - More accurate for Java application tuning

- **For debugging cache behavior:** Use `container_memory_usage_bytes`
  - Shows total including cache
  - Useful for understanding page cache usage
  - Not recommended for standard monitoring

## References

- [Kubernetes Memory Metrics](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/)
- [cAdvisor Metrics](https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md)
- [Understanding Linux Memory](https://www.kernel.org/doc/Documentation/cgroup-v1/memory.txt)

## Date
Fixed: 2025-12-28
Author: Claude Code Analysis

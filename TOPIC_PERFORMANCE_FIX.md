# Topic Performance Dashboard Fix

## Issue Summary

The "Topic Performance" dashboard had **6 broken queries** using metrics that either:
1. Don't have topic labels (can't aggregate by topic)
2. Have incorrect metric names
3. Have no data (values are 0 or metric doesn't exist)

## Root Cause Analysis

### Metrics Investigation

| Metric Used (BEFORE) | Issue | Available Topic Label? |
|---------------------|-------|----------------------|
| `broker_messages_sent_total` | Only has `type="all"`, no topic | ❌ NO |
| `broker_storage_size_bytes` | No topic label, value = 0 | ❌ NO |
| `broker_message_size_bytes{quantile="0.5"}` | All values = 0 (not recording) | ❌ NO |
| `broker_message_e2e_latency_seconds{quantile="0.99"}` | No topic label | ❌ NO |
| `broker_consumer_active` | Metric doesn't exist | ❌ NO |
| `broker_consumer_bytes_sent_total` | Wrong name (missing `_bytes`) | ❌ WRONG NAME |

### Available Working Metrics

| Metric | Labels | Description |
|--------|--------|-------------|
| `broker_consumer_messages_sent_total` | consumer_id, group, **topic** | ✅ Messages sent per topic |
| `broker_consumer_bytes_sent_bytes_total` | consumer_id, group, **topic** | ✅ Bytes sent per topic |
| `broker_consumer_delivery_latency_seconds` | consumer_id, group, **topic**, quantile | ✅ Delivery latency per topic |

## Changes Made

### Panel 1: Active Topics
**Before:**
```promql
count(count by(topic) (broker_messages_sent_total))
```
**Issue:** `broker_messages_sent_total` has no topic label

**After:**
```promql
count(count by(topic) (broker_consumer_messages_sent_total))
```
**Result:** ✅ 24 topics detected

---

### Panel 2: Total Throughput
**Before:**
```promql
sum(rate(broker_messages_sent_total[1m]))
```
**Issue:** Using wrong metric without topic aggregation

**After:**
```promql
sum(rate(broker_consumer_messages_sent_total[1m]))
```
**Result:** ✅ Correct total throughput

---

### Panel 3: Total Storage Size → Total Bytes Sent
**Before:**
```promql
sum(broker_storage_size_bytes) / 1024 / 1024
```
**Issue:** Metric has no topic data and value = 0

**After:**
```promql
sum(broker_consumer_bytes_sent_bytes_total) / 1024 / 1024
```
**Change:** Replaced "Storage Size" with "Total Bytes Sent" (more useful metric)
**Result:** ✅ Shows actual bytes sent to consumers

---

### Panel 4: Avg Message Size
**Before:**
```promql
avg(broker_message_size_bytes{quantile="0.5"})
```
**Issue:** Metric exists but all values = 0 (not being recorded)

**After:**
```promql
sum(broker_consumer_bytes_sent_bytes_total) / sum(broker_consumer_messages_sent_total)
```
**Change:** Calculate average from total bytes / total messages
**Result:** ✅ 45,860 bytes average message size

---

### Panel 5: Topic Performance Overview Table

**Query A - Broker Msg Rate:**
- **Before:** `sum by(topic) (rate(broker_messages_sent_total[5m]))`
- **After:** `sum by(topic) (rate(broker_consumer_messages_sent_total[5m]))`
- **Result:** ✅ Per-topic message rates

**Query B - Consumer Msg Rate → Total Bytes Sent:**
- **Before:** `sum by(topic) (rate(broker_consumer_messages_sent_total[5m]))`
- **After:** `sum by(topic) (broker_consumer_bytes_sent_bytes_total) / 1024 / 1024`
- **Change:** Shows total bytes sent (MB) instead of duplicate message rate
- **Result:** ✅ Cumulative bytes per topic

**Query C - Storage Size → Avg Msg Size:**
- **Before:** `broker_storage_size_bytes / 1024 / 1024`
- **After:** `sum by(topic) (broker_consumer_bytes_sent_bytes_total) / sum by(topic) (broker_consumer_messages_sent_total)`
- **Change:** Calculate average message size per topic
- **Result:** ✅ Per-topic average message size

**Query D - Avg Msg Size → Active Consumers:**
- **Before:** `broker_message_size_bytes{quantile="0.5"}`
- **After:** `count by(topic) (count by(topic, consumer_id) (broker_consumer_messages_sent_total))`
- **Change:** Count unique consumers per topic
- **Result:** ✅ Number of consumers per topic

**Query E - Active Consumers → Delivery Latency p99:**
- **Before:** `count by(topic) (broker_consumer_active == 1)`
- **After:** `avg by(topic) (broker_consumer_delivery_latency_seconds{quantile="0.99"}) * 1000`
- **Change:** Show p99 delivery latency in milliseconds
- **Result:** ✅ Per-topic latency metrics

**Query F - E2E Latency p99:**
- **Before:** `broker_message_e2e_latency_seconds{quantile="0.99"}`
- **After:** ❌ REMOVED (no per-topic data)

### Table Column Changes

| Before | After | Reason |
|--------|-------|--------|
| Broker Msg Rate (msg/s) | Msg Rate (msg/s) | Simplified name |
| Consumer Msg Rate (msg/s) | Total Bytes Sent (MB) | Changed to cumulative bytes |
| Storage Size (MB) | Avg Msg Size (bytes) | No storage data available |
| Avg Msg Size (bytes) | Active Consumers | Moved metric |
| Active Consumers | Delivery Latency p99 (ms) | Added latency metric |
| E2E Latency p99 (s) | ❌ REMOVED | No per-topic data |

---

### Panel 6: Message Rate by Topic
**Before:**
```promql
sum by(topic) (rate(broker_messages_sent_total[1m]))
```
**Issue:** No topic label in source metric

**After:**
```promql
sum by(topic) (rate(broker_consumer_messages_sent_total[1m]))
```
**Result:** ✅ Per-topic timeseries

---

### Panel 7: Bytes Throughput by Topic
**Before:**
```promql
sum by(topic) (rate(broker_consumer_bytes_sent_total[1m]))
```
**Issue:** Wrong metric name (missing `_bytes`)

**After:**
```promql
sum by(topic) (rate(broker_consumer_bytes_sent_bytes_total[1m]))
```
**Result:** ✅ Correct metric name

---

### Panel 8: End-to-End Latency → Delivery Latency
**Before:**
```promql
broker_message_e2e_latency_seconds{quantile="0.99"}
```
**Issue:** No topic label

**After:**
```promql
avg by(topic) (broker_consumer_delivery_latency_seconds{quantile="0.99"}) * 1000
```
**Changes:**
- Metric: `broker_consumer_delivery_latency_seconds` (has topic label)
- Multiply by 1000 for milliseconds
- Unit: Changed from `s` to `ms`
- Decimals: Changed from 3 to 2
**Result:** ✅ Per-topic delivery latency in ms

---

### Panel 9: Storage Size Growth → Total Messages Sent
**Before:**
```promql
broker_storage_size_bytes / 1024 / 1024
```
**Issue:** No topic label, value = 0

**After:**
```promql
sum by(topic) (broker_consumer_messages_sent_total)
```
**Change:** Shows cumulative messages sent per topic (more useful)
**Result:** ✅ Message count trend per topic

---

## Verification

### Test Queries (at 2025-12-28T07:02:59.580Z)

```bash
# Active Topics
curl "http://localhost:9090/api/v1/query?query=count(count%20by(topic)%20(broker_consumer_messages_sent_total))"
Result: 24 topics ✅

# Total Throughput (current)
curl "http://localhost:9090/api/v1/query?query=sum(rate(broker_consumer_messages_sent_total[1m]))"
Result: Varies based on current activity ✅

# Avg Message Size
curl "http://localhost:9090/api/v1/query?query=sum(broker_consumer_bytes_sent_bytes_total)%20%2F%20sum(broker_consumer_messages_sent_total)"
Result: 45,860 bytes ✅

# Per-topic Message Rate
curl "http://localhost:9090/api/v1/query?query=sum%20by(topic)%20(rate(broker_consumer_messages_sent_total[5m]))"
Result: 24 topics with individual rates ✅
```

## Summary of All Fixes

### ✅ Fixed Panels (9 total)
1. **Active Topics** - Changed to use `broker_consumer_messages_sent_total`
2. **Total Throughput** - Changed to use `broker_consumer_messages_sent_total`
3. **Total Bytes Sent** - Replaced storage size with bytes sent
4. **Avg Message Size** - Calculate from bytes/messages ratio
5. **Topic Performance Overview Table** - Fixed all 5 queries (removed 1)
6. **Message Rate by Topic** - Fixed metric name
7. **Bytes Throughput by Topic** - Fixed metric name (added `_bytes`)
8. **Delivery Latency by Topic** - Changed to consumer delivery latency (ms)
9. **Total Messages Sent by Topic** - Replaced storage growth

### 📊 Dashboard Now Shows

**Top Stats:**
- Active Topics: 24
- Total Throughput: Real-time msg/s
- Total Bytes Sent: Cumulative MB
- Avg Message Size: Calculated from data

**Table Columns:**
- Topic name
- Message rate (msg/s)
- Total bytes sent (MB)
- Average message size (bytes)
- Active consumers count
- Delivery latency p99 (ms)

**Time Series Graphs:**
- Message rate trend per topic
- Bytes throughput trend per topic
- Delivery latency trend per topic
- Total messages sent trend per topic

## Metrics That Need Broker Code Changes

If you want these metrics in the future, the broker code needs to be updated:

1. **`broker_storage_size_bytes{topic}`** - Add topic label
   - Track storage size per topic
   - Update metric in storage layer

2. **`broker_message_size_bytes{topic, quantile}`** - Add topic label and record data
   - Currently all values are 0
   - Need to instrument message size tracking

3. **`broker_message_e2e_latency_seconds{topic, quantile}`** - Add topic label
   - Currently only aggregated
   - Track per-topic end-to-end latency

4. **`broker_consumer_active{topic}`** - Create new metric
   - Track active consumers per topic
   - Alternative: Use existing `broker_consumer_lag` or `broker_consumer_offset`

## Files Modified

- `/Users/anuragmishra/Desktop/workspace/messaging/monitoring/grafana/dashboard-files/topic-performance.json`
  - 9 panels updated
  - 15 query changes
  - 6 column name changes in table
  - 5 field config overrides updated

## Testing Recommendations

1. **Open Grafana**: http://localhost:3000
2. **Navigate to**: Dashboards → Topic Performance
3. **Verify**:
   - ✅ Active Topics shows 24
   - ✅ Table shows all 24 topics with data
   - ✅ All graphs display data
   - ✅ No "No Data" panels
   - ✅ Time range selector works
4. **Test with time range**: 2025-12-28T06:35:39.976Z to 2025-12-28T07:02:59.580Z

## Date
Fixed: 2025-12-28
Author: Claude Code Analysis

# Dashboard Update Plan - Failed Transfer & Stuck Detection Metrics

## Analysis Summary

### Dashboards Analyzed (12 total):

1. **broker-system-metrics.json** (19 panels) - System resources, JVM, container metrics
2. **consumer-health-performance.json** (8 panels) - Consumer health and performance ✅ **NEEDS UPDATE**
3. **container-metrics.json** (9 panels) - Container-level metrics
4. **data-refresh-monitoring.json** (6 panels) - Data refresh workflow
5. **data-refresh-overview.json** (4 panels) - Data refresh overview
6. **data-refresh-tables.json** - Broken/empty
7. **messaging-broker-dashboard.json** (15 panels) - Main broker overview ✅ **NEEDS UPDATE**
8. **per-consumer-dashboard.json** (12 panels) - Per-consumer detailed view ✅ **NEEDS UPDATE**
9. **pipe-performance.json** (6 panels) - Parent pipe metrics
10. **storage-disk-health.json** (11 panels) - Storage metrics
11. **thread-monitoring-dashboard.json** (9 panels) - Thread monitoring
12. **topic-performance.json** (9 panels) - Topic performance ✅ **NEEDS UPDATE**

### Dashboards Using bytes_sent/messages_sent:
- ✅ **consumer-health-performance.json** - Uses messages_sent
- ✅ **per-consumer-dashboard.json** - Uses both bytes_sent and messages_sent
- ✅ **topic-performance.json** - Uses both bytes_sent and messages_sent
- ✅ **pipe-performance.json** - Uses messages_sent
- ✅ **messaging-broker-dashboard.json** - Main overview

---

## Update Plan by Dashboard

### 1. consumer-health-performance.json ⭐ HIGH PRIORITY

**Current Panels (8)**:
1. Active Consumer Groups (stat)
2. Active Consumer Subscriptions (stat)
3. Avg Consumer Lag (stat)
4. Avg Delivery Latency p99 (stat)
5. Consumer Group Overview (table)
6. Message Rate by Consumer Group (timeseries)
7. Consumer Lag Trend (timeseries)
8. Delivery Latency p99 (timeseries)

**Updates Needed**:

**Add Panel 9 - Failed Transfer Rate (stat)**:
```json
{
  "title": "Failed Transfer Rate (%)",
  "type": "stat",
  "targets": [{
    "expr": "avg(\n  rate(broker_consumer_bytes_failed_total[5m])\n  /\n  rate(broker_consumer_bytes_sent_total[5m])\n) * 100"
  }],
  "thresholds": {
    "steps": [
      {"value": 0, "color": "green"},
      {"value": 0.1, "color": "yellow"},
      {"value": 1, "color": "red"}
    ]
  }
}
```

**Add Panel 10 - Stuck Consumers Count (stat)**:
```json
{
  "title": "Stuck Consumers (>10min no ACK)",
  "type": "stat",
  "targets": [{
    "expr": "count(\n  (time() * 1000 - broker_consumer_last_ack_time_ms) / 1000 > 600\n)"
  }],
  "thresholds": {
    "steps": [
      {"value": 0, "color": "green"},
      {"value": 1, "color": "red"}
    ]
  }
}
```

**Add Panel 11 - Time Since Last ACK (timeseries)**:
```json
{
  "title": "Time Since Last ACK by Consumer",
  "type": "timeseries",
  "targets": [{
    "expr": "(time() * 1000 - broker_consumer_last_ack_time_ms) / 1000",
    "legendFormat": "{{group}}:{{topic}}"
  }],
  "fieldConfig": {
    "defaults": {
      "unit": "s",
      "thresholds": {
        "steps": [
          {"value": 0, "color": "green"},
          {"value": 300, "color": "yellow"},
          {"value": 600, "color": "red"}
        ]
      }
    }
  }
}
```

**Update Panel 5 - Consumer Group Overview Table**:
Add columns:
- Failed Bytes (MB)
- Success Rate (%)
- Time Since Last ACK (s)

---

### 2. per-consumer-dashboard.json ⭐ HIGH PRIORITY

**Current Panels (12)**:
0. Active Consumer Groups by Topic (table)
1. Messages Sent per Consumer (stat)
2. Data Sent Bytes (stat)
3. Current Offset (stat)
4. Consumer Lag (stat)
5. Consumer Offset Over Time (timeseries)
6. Consumer Lag Over Time (timeseries)
7. Message Throughput (timeseries)
8. Data Throughput Bytes/sec (timeseries)
9. Delivery Latency Avg (timeseries)
10. Delivery Latency Max (timeseries)
11. Consumer Metrics Table (table)

**Updates Needed**:

**Update Panel 2 - Data Sent (stat)** - Change to Successful Bytes:
```json
{
  "title": "Successful Data Sent (MB)",
  "targets": [{
    "expr": "sum(\n  broker_consumer_bytes_sent_total{group=~\"$consumer_group\", topic=~\"$topic\"}\n  -\n  broker_consumer_bytes_failed_total{group=~\"$consumer_group\", topic=~\"$topic\"}\n) / 1024 / 1024"
  }]
}
```

**Add Panel 12 - Failed Bytes (stat)**:
```json
{
  "title": "Failed Bytes (MB)",
  "type": "stat",
  "targets": [{
    "expr": "sum(broker_consumer_bytes_failed_total{group=~\"$consumer_group\", topic=~\"$topic\"}) / 1024 / 1024"
  }],
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "thresholds"},
      "thresholds": {
        "steps": [
          {"value": 0, "color": "green"},
          {"value": 1, "color": "yellow"},
          {"value": 100, "color": "red"}
        ]
      }
    }
  }
}
```

**Add Panel 13 - Success Rate % (stat)**:
```json
{
  "title": "Transfer Success Rate (%)",
  "type": "stat",
  "targets": [{
    "expr": "(\n  sum(broker_consumer_bytes_sent_total{group=~\"$consumer_group\", topic=~\"$topic\"} - broker_consumer_bytes_failed_total{group=~\"$consumer_group\", topic=~\"$topic\"})\n  /\n  sum(broker_consumer_bytes_sent_total{group=~\"$consumer_group\", topic=~\"$topic\"})\n) * 100"
  }],
  "fieldConfig": {
    "defaults": {
      "unit": "percent",
      "thresholds": {
        "steps": [
          {"value": 0, "color": "red"},
          {"value": 95, "color": "yellow"},
          {"value": 99, "color": "green"}
        ]
      }
    }
  }
}
```

**Add Panel 14 - Consumer Health Status (stat)**:
```json
{
  "title": "Consumer Health",
  "type": "stat",
  "targets": [{
    "expr": "(time() * 1000 - broker_consumer_last_ack_time_ms{group=~\"$consumer_group\", topic=~\"$topic\"}) / 1000"
  }],
  "fieldConfig": {
    "defaults": {
      "unit": "s",
      "mappings": [
        {"type": "range", "options": {"from": 0, "to": 60, "result": {"text": "Healthy", "color": "green"}}},
        {"type": "range", "options": {"from": 60, "to": 300, "result": {"text": "Warning", "color": "yellow"}}},
        {"type": "range", "options": {"from": 300, "to": 999999, "result": {"text": "STUCK", "color": "red"}}}
      ]
    }
  }
}
```

**Add Panel 15 - Time Since Last Delivery/ACK (timeseries)**:
```json
{
  "title": "Consumer Activity Timeline",
  "type": "timeseries",
  "targets": [
    {
      "expr": "(time() * 1000 - broker_consumer_last_delivery_time_ms{group=~\"$consumer_group\", topic=~\"$topic\"}) / 1000",
      "legendFormat": "Seconds since last delivery"
    },
    {
      "expr": "(time() * 1000 - broker_consumer_last_ack_time_ms{group=~\"$consumer_group\", topic=~\"$topic\"}) / 1000",
      "legendFormat": "Seconds since last ACK"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "s",
      "custom": {
        "lineWidth": 2,
        "fillOpacity": 10
      }
    }
  }
}
```

**Update Panel 11 - Consumer Metrics Table**:
Add columns:
- Failed Bytes (MB): `sum by(group, topic) (broker_consumer_bytes_failed_total) / 1024 / 1024`
- Success Rate %: `(sum by(group, topic) (broker_consumer_bytes_sent_total - broker_consumer_bytes_failed_total) / sum by(group, topic) (broker_consumer_bytes_sent_total)) * 100`
- Last ACK (sec ago): `(time() * 1000 - broker_consumer_last_ack_time_ms) / 1000`
- Health Status: Derived from Last ACK

---

### 3. topic-performance.json ⭐ HIGH PRIORITY

**Current Panels (9)**:
1. Active Topics (stat)
2. Total Throughput (stat)
3. Total Bytes Sent (stat)
4. Avg Message Size (stat)
5. Topic Performance Overview (table)
6. Message Rate by Topic (timeseries)
7. Bytes Throughput by Topic (timeseries)
8. Delivery Latency p99 (timeseries)
9. Total Messages Sent by Topic (timeseries)

**Updates Needed**:

**Update Panel 3 - Total Bytes Sent (stat)** - Change to Successful Bytes:
```json
{
  "title": "Total Successful Bytes (MB)",
  "targets": [{
    "expr": "sum(\n  broker_consumer_bytes_sent_total - broker_consumer_bytes_failed_total\n) / 1024 / 1024"
  }]
}
```

**Add Panel 10 - Total Failed Bytes (stat)**:
```json
{
  "title": "Total Failed Bytes (MB)",
  "type": "stat",
  "targets": [{
    "expr": "sum(broker_consumer_bytes_failed_total) / 1024 / 1024"
  }],
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "palette-classic"},
      "thresholds": {
        "steps": [
          {"value": 0, "color": "green"},
          {"value": 100, "color": "yellow"},
          {"value": 1000, "color": "red"}
        ]
      }
    }
  }
}
```

**Update Panel 5 - Topic Performance Overview Table**:
Current columns:
- Topic
- Msg Rate (msg/s)
- Total Bytes Sent (MB)
- Avg Msg Size (bytes)
- Active Consumers
- Delivery Latency p99 (ms)

Add/Update:
- **Total Bytes Sent (MB)** → Keep but rename to "Total Attempted (MB)"
- **Add: Successful Bytes (MB)**: `sum by(topic) (broker_consumer_bytes_sent_total - broker_consumer_bytes_failed_total) / 1024 / 1024`
- **Add: Failed Bytes (MB)**: `sum by(topic) (broker_consumer_bytes_failed_total) / 1024 / 1024`
- **Add: Success Rate (%)**: `(sum by(topic) (broker_consumer_bytes_sent_total - broker_consumer_bytes_failed_total) / sum by(topic) (broker_consumer_bytes_sent_total)) * 100`

**Add Panel 11 - Failed Transfer Rate by Topic (timeseries)**:
```json
{
  "title": "Failed Transfer Rate by Topic (bytes/s)",
  "type": "timeseries",
  "targets": [{
    "expr": "sum by(topic) (rate(broker_consumer_bytes_failed_total[1m]))",
    "legendFormat": "{{topic}}"
  }]
}
```

---

### 4. messaging-broker-dashboard.json

**Current Panels (15)** - Main overview dashboard

**Updates Needed**:

**Update Panel 6 - Bytes Out/sec (stat)**:
Change to show successful bytes only:
```json
{
  "title": "Successful Bytes Out/sec",
  "targets": [{
    "expr": "sum(rate(broker_consumer_bytes_sent_total[1m]) - rate(broker_consumer_bytes_failed_total[1m]))"
  }]
}
```

**Add Panel 16 - Failed Bytes/sec (stat)**:
```json
{
  "title": "Failed Bytes/sec",
  "type": "stat",
  "targets": [{
    "expr": "sum(rate(broker_consumer_bytes_failed_total[1m]))"
  }],
  "fieldConfig": {
    "defaults": {
      "unit": "Bps",
      "color": {"mode": "thresholds"},
      "thresholds": {
        "steps": [
          {"value": 0, "color": "green"},
          {"value": 1000, "color": "yellow"},
          {"value": 10000, "color": "red"}
        ]
      }
    }
  }
}
```

**Add Panel 17 - Consumer Health Overview (table)**:
```json
{
  "title": "Consumer Health Status",
  "type": "table",
  "targets": [
    {
      "expr": "count by(topic, group) (broker_consumer_last_ack_time_ms)",
      "format": "table",
      "refId": "A"
    },
    {
      "expr": "(time() * 1000 - broker_consumer_last_ack_time_ms) / 1000",
      "format": "table",
      "refId": "B"
    }
  ],
  "transformations": [
    {
      "id": "merge",
      "options": {}
    }
  ],
  "overrides": [
    {
      "matcher": {"id": "byName", "options": "Time Since Last ACK"},
      "properties": [
        {
          "id": "custom.cellOptions",
          "value": {
            "type": "color-background",
            "mode": "gradient"
          }
        },
        {
          "id": "thresholds",
          "value": {
            "steps": [
              {"value": 0, "color": "green"},
              {"value": 300, "color": "yellow"},
              {"value": 600, "color": "red"}
            ]
          }
        }
      ]
    }
  ]
}
```

---

### 5. pipe-performance.json

**Current Panels (6)** - Parent pipe metrics

**Updates Needed**:
- This dashboard focuses on pipe (parent broker) metrics
- Less critical for failed transfer/stuck detection
- **Decision**: Low priority, update if time permits

---

## Implementation Order

### Phase 1: High Priority Dashboards ⭐
1. **consumer-health-performance.json** - Add 3 new panels (failed rate, stuck count, time since ACK)
2. **per-consumer-dashboard.json** - Add 4 new panels + update table
3. **topic-performance.json** - Add 2 new panels + update table

### Phase 2: Medium Priority
4. **messaging-broker-dashboard.json** - Add 2 new panels

### Phase 3: Low Priority (Optional)
5. **pipe-performance.json** - If needed

---

## Testing Checklist

After each dashboard update:

1. ✅ Verify dashboard loads without errors
2. ✅ Check all new panels render data
3. ✅ Verify queries return results (use Prometheus /query API)
4. ✅ Check threshold colors work correctly
5. ✅ Test variable selectors ($consumer_group, $topic)
6. ✅ Verify table columns align properly
7. ✅ Check time range selector works
8. ✅ Test refresh rate (5s, 10s, 30s)

---

## Rollback Plan

Before making changes:
```bash
# Backup all dashboards
cd monitoring/grafana/dashboard-files
mkdir -p backups/$(date +%Y%m%d)
cp *.json backups/$(date +%Y%m%d)/
```

If issues occur:
```bash
# Restore from backup
cp backups/YYYYMMDD/*.json .
docker compose restart grafana
```

---

## Metrics Validation

Before updating dashboards, verify metrics exist:

```bash
# Test failed transfer metrics
curl -s "http://localhost:9090/api/v1/query?query=broker_consumer_bytes_failed_total" | jq .

# Test stuck detection metrics
curl -s "http://localhost:9090/api/v1/query?query=broker_consumer_last_ack_time_ms" | jq .

# Test calculation
curl -s "http://localhost:9090/api/v1/query?query=(time()*1000-broker_consumer_last_ack_time_ms)/1000" | jq .
```

Expected: All queries return status "success"

---

## Dashboard JSON Structure Reference

Each panel follows this structure:
```json
{
  "id": <unique_int>,
  "type": "stat|timeseries|table",
  "title": "Panel Title",
  "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
  "targets": [
    {
      "expr": "prometheus_query",
      "legendFormat": "{{label}}",
      "refId": "A"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "unit": "bytes|s|percent",
      "thresholds": {
        "mode": "absolute",
        "steps": [
          {"value": 0, "color": "green"},
          {"value": 80, "color": "yellow"},
          {"value": 100, "color": "red"}
        ]
      }
    }
  }
}
```

---

## Date
Created: 2025-02-16
Author: Claude Code
Task: Dashboard update plan for failed transfer and stuck detection metrics

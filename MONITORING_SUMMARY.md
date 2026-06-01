# Monitoring Stack Summary

## Dashboard Set

- 21 provisioned dashboards
- Role-based entry point: **Observability Home - Support & Engineering**
- Support-first dashboards for triage, with engineering deep-dive dashboards for root-cause analysis

## Dashboard Categories

### Support Dashboards
1. **Support - Broker Overview**: primary incident dashboard for traffic, latency, subscriptions, and connectivity
2. **Support - Delivery Diagnosis**: consumer stuck, lagging, disconnected, or not ACKing
3. **Support - Consumer Health**: group-level lag, latency, and failed transfer view
4. **Support - Broker Resources**: broker CPU, heap, GC, open files, and storage hot spots
5. **Support - Refresh Overview**: refresh status, completion, and history
6. **Support - Storage Health**: storage latency, IOPS, active segments, and Docker host disk I/O
7. **Support - Producer vs Consumer Gap**: ingress, egress, and backlog growth
8. **Support - Data Freshness SLA**: stale topics and freshness compliance
9. **Support - Service KPIs**: high-level service health and delivery KPIs

### Engineering Dashboards
1. **Engineering - Per-Consumer Deep Dive**
2. **Engineering - JVM & Process Detail**
3. **Engineering - Thread Deep Dive**
4. **Engineering - Topic Performance**
5. **Engineering - Pipe / Replication**
6. **Engineering - ACK Reconciliation**
7. **Engineering - Storage Detail**
8. **Engineering - Refresh Topic Detail**
9. **Engineering - Refresh Reliability**
10. **Engineering - Consumer Error Signals**

### Platform / Navigation Dashboards
1. **Observability Home - Support & Engineering**
2. **Platform - Container Metrics**

## Notes for Support

- Start every incident from **Observability Home - Support & Engineering** or **Support - Broker Overview**.
- Use support dashboards first to decide whether the fault is delivery, resource pressure, storage, refresh, or replication.
- Escalate to the engineering dashboards only after the failure domain is known.
- Some refresh dashboards are intentionally empty until a refresh runs in the selected time range.
- Consumer decode error panels depend on the consumer applications exposing and being scraped for `consumer_decode_errors_total`.

## Metric Notes

- Broker resource dashboards now prefer stable broker process/JVM metrics where possible instead of hardcoded container IDs.
- Consumer byte metrics use `broker_consumer_bytes_sent_bytes_total` and `broker_consumer_bytes_failed_bytes_total`.
- Broker latency and message-size dashboards use summary/percentile series instead of nonexistent histogram buckets.

# Grafana Dashboard Configuration

## Directory Structure

```
grafana/
├── dashboard-files/              # Dashboard JSON files
│   ├── messaging-broker-dashboard.json
│   └── per-consumer-dashboard.json
├── provisioning/
│   ├── dashboards/              # Dashboard provisioning config
│   │   └── dashboard-provisioning.yml
│   └── datasources/             # Datasource provisioning config
│       └── prometheus.yml
├── dashboards/                  # OLD structure (kept for reference, can be deleted)
└── datasources/                 # OLD structure (kept for reference, can be deleted)
```

## How Grafana Provisioning Works

### 1. Volume Mounts in docker-compose.yml

```yaml
volumes:
  # Provisioning configs tell Grafana where to find dashboards/datasources
  - .../grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards
  - .../grafana/provisioning/datasources:/etc/grafana/provisioning/datasources

  # Actual dashboard JSON files
  - .../grafana/dashboard-files:/var/lib/grafana/dashboards

  # Persistent data (user changes, etc.)
  - grafana-data:/var/lib/grafana
```

### 2. Datasource Provisioning

File: `provisioning/datasources/prometheus.yml`

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    isDefault: true
```

This creates a Prometheus datasource automatically on Grafana startup.

### 3. Dashboard Provisioning

File: `provisioning/dashboards/dashboard-provisioning.yml`

```yaml
apiVersion: 1
providers:
  - name: 'Messaging Dashboards'
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards  # Points to mounted dashboard-files/
```

This tells Grafana to load all JSON files from `/var/lib/grafana/dashboards` as dashboards.

### 4. Dashboard Files

Files in `dashboard-files/`:
- `messaging-broker-dashboard.json` - Multi-consumer overview dashboard
- `per-consumer-dashboard.json` - Per-consumer detailed metrics

These are mounted to `/var/lib/grafana/dashboards` inside the container.

## Dashboard URLs

After starting Grafana:

1. **Login**: http://localhost:3000
   - Username: `admin`
   - Password: `admin`

2. **Multi-Consumer Dashboard**:
   - UID: `messaging-broker-multi-consumer`
   - URL: http://localhost:3000/d/messaging-broker-multi-consumer

3. **Per-Consumer Dashboard**:
   - UID: `per-consumer-metrics`
   - URL: http://localhost:3000/d/per-consumer-metrics

## Troubleshooting

### Dashboards Not Appearing

**Check Grafana logs:**
```bash
docker compose logs grafana | grep -i provision
```

Look for:
```
logger=provisioning.dashboard Successfully provisioned X dashboards
```

**Verify files are mounted correctly:**
```bash
# Check provisioning config
docker compose exec grafana ls -la /etc/grafana/provisioning/dashboards/

# Check dashboard files
docker compose exec grafana ls -la /var/lib/grafana/dashboards/

# Should show:
# messaging-broker-dashboard.json
# per-consumer-dashboard.json
```

**Restart Grafana:**
```bash
docker compose restart grafana
```

Wait 10 seconds and check: http://localhost:3000/dashboards

### Dashboards Appear But Show No Data

**Check Prometheus datasource:**
1. Go to http://localhost:3000/connections/datasources
2. Click on "Prometheus"
3. Scroll down and click "Save & Test"
4. Should show: "Successfully queried the Prometheus API"

**If test fails:**
```bash
# Check Prometheus is running
docker compose ps prometheus

# Check Prometheus is accessible from Grafana
docker compose exec grafana curl -s http://prometheus:9090/api/v1/status/config | jq .status
# Should show: "success"
```

### Wrong Dashboard Version

If you updated dashboard JSON files but see old version:

```bash
# Restart Grafana to reload provisioned dashboards
docker compose restart grafana

# OR delete Grafana data volume and restart (loses user changes!)
docker compose down
docker volume rm messaging_grafana-data
docker compose up -d grafana
```

## Adding New Dashboards

### Option 1: Via Grafana UI (Temporary)

1. Go to http://localhost:3000
2. Create dashboard manually
3. **Note**: This will be lost if `grafana-data` volume is deleted

### Option 2: Via Provisioning (Permanent)

1. Create dashboard in Grafana UI
2. Export dashboard JSON:
   - Dashboard → Share → Export → Save to file
3. Save to `dashboard-files/your-new-dashboard.json`
4. Restart Grafana: `docker compose restart grafana`

Dashboard will appear automatically.

## Modifying Existing Dashboards

### Make Changes Persistent

1. Edit dashboard in Grafana UI
2. Export updated JSON
3. Replace file in `dashboard-files/`
4. Restart Grafana

**Or edit JSON directly:**
```bash
# Edit JSON file
vim dashboard-files/messaging-broker-dashboard.json

# Restart Grafana
docker compose restart grafana
```

## Dashboard Configuration

### Multi-Consumer Dashboard

Shows aggregate metrics across all 13 consumers:
- Total messages consumed
- Consumer lag
- Active connections
- Topics subscribed (24 total)
- Message rate per consumer

### Per-Consumer Dashboard

Detailed metrics for individual consumers with variables:
- **Variable**: `consumer_id` (dropdown to select consumer)
- Metrics:
  - Messages consumed over time
  - Consumer lag
  - Topic subscriptions
  - Connection status
  - Processing rate

## Grafana Configuration Files

### dashboard-provisioning.yml

```yaml
apiVersion: 1
providers:
  - name: 'Messaging Dashboards'
    orgId: 1
    folder: ''                    # Root folder (no subfolder)
    type: file
    disableDeletion: false       # Allow deletion via UI
    updateIntervalSeconds: 10    # Check for updates every 10 seconds
    allowUiUpdates: true         # Allow editing via UI
    options:
      path: /var/lib/grafana/dashboards
```

### prometheus.yml (Datasource)

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

## Migration from Old Structure

The old structure had dashboards and datasources in separate directories at the root level. The new structure organizes everything under `provisioning/`:

```
OLD:
grafana/
├── dashboards/
│   ├── *.json
│   └── dashboard-provisioning.yml
└── datasources/
    └── prometheus.yml

NEW:
grafana/
├── dashboard-files/           # Dashboard JSON only
│   └── *.json
└── provisioning/             # Provisioning configs
    ├── dashboards/
    │   └── dashboard-provisioning.yml
    └── datasources/
        └── prometheus.yml
```

The old directories are kept for reference but can be safely deleted.

## Cleanup

To remove old directories after verifying new structure works:

```bash
cd monitoring/grafana
rm -rf dashboards/
rm -rf datasources/
```

Make sure Grafana is working correctly before deleting!

#!/bin/bash

################################################################################
# Phase 3: Deploy Dashboard
#
# Deploys the monitoring dashboard for the Agentic SOC.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Deploying monitoring dashboard..."
    
    # Create dashboard directory
    ensure_directory "$DEPLOY_DIR/dashboard"
    
    # Install Node.js if needed
    check_nodejs
    
    # Deploy Grafana for metrics
    deploy_grafana
    
    # Create simple web dashboard
    create_web_dashboard
    
    log_success "Dashboard deployment completed"
    log_info "Dashboard will be available at http://localhost:3000"
    log_info "Grafana will be available at http://localhost:3001"
}

check_nodejs() {
    if ! command_exists node; then
        log_info "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        install_package nodejs
    fi
    
    log_success "Node.js installed: $(node --version)"
}

deploy_grafana() {
    log_info "Deploying Grafana..."
    
    cat > "$DEPLOY_DIR/docker-compose.monitoring.yml" << 'EOF'
version: '3.8'

services:
  grafana:
    image: grafana/grafana:latest
    container_name: agentic-soc-grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=
    volumes:
      - grafana_data:/var/lib/grafana
      - ./config/grafana:/etc/grafana/provisioning
    restart: unless-stopped
  
  prometheus:
    image: prom/prometheus:latest
    container_name: agentic-soc-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    restart: unless-stopped

volumes:
  grafana_data:
  prometheus_data:
EOF
    
    # Create Prometheus config
    ensure_directory "$DEPLOY_DIR/config/prometheus"
    cat > "$DEPLOY_DIR/config/prometheus/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'agentic-soc'
    static_configs:
      - targets: ['localhost:9090']
EOF
    
    # Start monitoring stack
    cd "$DEPLOY_DIR"
    docker-compose -f docker-compose.monitoring.yml up -d
    
    log_success "Grafana and Prometheus deployed"
}

create_web_dashboard() {
    log_info "Creating web dashboard..."
    
    cat > "$DEPLOY_DIR/dashboard/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AI Agentic SOC Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #0f172a;
            color: #e2e8f0;
            padding: 20px;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .subtitle { opacity: 0.9; }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .card {
            background: #1e293b;
            padding: 25px;
            border-radius: 10px;
            border: 1px solid #334155;
        }
        .card h2 {
            font-size: 1.2rem;
            margin-bottom: 15px;
            color: #94a3b8;
        }
        .metric {
            font-size: 3rem;
            font-weight: bold;
            margin-bottom: 10px;
        }
        .metric.green { color: #10b981; }
        .metric.yellow { color: #f59e0b; }
        .metric.red { color: #ef4444; }
        .label { color: #64748b; font-size: 0.9rem; }
        .status {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 0.9rem;
            margin-top: 10px;
        }
        .status.active { background: #10b98133; color: #10b981; }
        .status.idle { background: #f59e0b33; color: #f59e0b; }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #334155;
        }
        th { color: #94a3b8; font-weight: 600; }
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.85rem;
        }
        .badge.critical { background: #ef444433; color: #ef4444; }
        .badge.high { background: #f59e0b33; color: #f59e0b; }
        .badge.medium { background: #3b82f633; color: #3b82f6; }
        .badge.low { background: #10b98133; color: #10b981; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🤖 AI Agentic SOC</h1>
        <p class="subtitle">Real-time Security Operations Dashboard</p>
    </div>
    
    <div class="grid">
        <div class="card">
            <h2>Active Alerts</h2>
            <div class="metric green">0</div>
            <div class="label">Alerts in last 24 hours</div>
            <div class="status active">System Active</div>
        </div>
        
        <div class="card">
            <h2>Agent Status</h2>
            <div class="metric green">3</div>
            <div class="label">Agents online</div>
            <div class="status active">All Systems Go</div>
        </div>
        
        <div class="card">
            <h2>Mean Time to Triage</h2>
            <div class="metric yellow">2.5m</div>
            <div class="label">Average response time</div>
        </div>
        
        <div class="card">
            <h2>Automation Rate</h2>
            <div class="metric green">85%</div>
            <div class="label">Alerts auto-triaged</div>
        </div>
    </div>
    
    <div class="card">
        <h2>Recent Alerts</h2>
        <table>
            <thead>
                <tr>
                    <th>Alert ID</th>
                    <th>Type</th>
                    <th>Severity</th>
                    <th>Status</th>
                    <th>Time</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>ALERT-001</td>
                    <td>Suspicious Login</td>
                    <td><span class="badge high">High</span></td>
                    <td>Triaged</td>
                    <td>2 min ago</td>
                </tr>
                <tr>
                    <td>ALERT-002</td>
                    <td>Port Scan</td>
                    <td><span class="badge medium">Medium</span></td>
                    <td>In Progress</td>
                    <td>15 min ago</td>
                </tr>
                <tr>
                    <td>ALERT-003</td>
                    <td>Phishing Email</td>
                    <td><span class="badge low">Low</span></td>
                    <td>Resolved</td>
                    <td>1 hour ago</td>
                </tr>
            </tbody>
        </table>
    </div>
    
    <div class="card" style="margin-top: 20px;">
        <h2>Quick Links</h2>
        <p><a href="http://localhost:3001" style="color: #60a5fa;">📊 Grafana Metrics</a></p>
        <p><a href="http://localhost:5555" style="color: #60a5fa;">🌸 Celery Flower (Task Monitor)</a></p>
        <p><a href="../README.md" style="color: #60a5fa;">📖 Documentation</a></p>
    </div>
</body>
</html>
EOF
    
    # Create simple HTTP server script
    cat > "$DEPLOY_DIR/dashboard/serve.sh" << 'EOF'
#!/bin/bash
echo "Starting dashboard on http://localhost:3000"
cd "$(dirname "$0")"
python3 -m http.server 3000
EOF
    
    chmod +x "$DEPLOY_DIR/dashboard/serve.sh"
    
    log_success "Web dashboard created"
    log_info "Start dashboard with: cd dashboard && ./serve.sh"
}

main "$@"

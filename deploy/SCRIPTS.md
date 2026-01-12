# Deployment Scripts Overview

This document provides a high-level overview of all deployment scripts for the AI Agentic SOC implementation.

## Directory Structure

```
deploy/
├── README.md                          # Main documentation
├── QUICKSTART.md                      # Quick start guide
├── SCRIPTS.md                         # This file
├── validate.sh                        # Validation script
├── backup.sh                          # Backup script (created by phase4)
│
├── common/                            # Shared utilities
│   └── utils.sh                       # Common bash functions
│
├── config/                            # Configuration files
│   ├── .env.example                   # Environment variables template
│   ├── agent_config.yaml             # Agent configuration (created by phase1)
│   ├── governance_config.yaml        # Governance settings (created by phase3)
│   ├── orchestration_config.yaml     # Orchestration config (created by phase3)
│   ├── alerting_rules.yaml           # Alerting rules (created by phase4)
│   ├── production.yaml               # Production settings (created by phase4)
│   ├── integrations/                 # Integration configs (created by phase1)
│   │   ├── siem_config.yaml
│   │   └── edr_config.yaml
│   ├── grafana/                      # Grafana configs (created by phase3)
│   └── prometheus/                   # Prometheus configs (created by phase3)
│
├── phase1/                            # Foundation Building
│   ├── setup.sh                      # Main orchestrator
│   ├── install_core_deps.sh          # Core dependencies
│   ├── install_ai_frameworks.sh      # AI/ML frameworks
│   ├── install_siem_edr.sh          # SIEM/EDR integration
│   └── prepare_data.sh               # Data environment setup
│
├── phase2/                            # Agent Development
│   ├── setup.sh                      # Main orchestrator
│   ├── setup_agent_env.sh            # Development environment
│   ├── install_langchain.sh          # LangChain/CrewAI
│   ├── deploy_triage_agent.py        # Triage agent implementation
│   ├── test_triage_agent.py          # Agent tests
│   └── setup_sandbox.sh              # Testing sandbox
│
├── phase3/                            # Integration & Orchestration
│   ├── setup.sh                      # Main orchestrator
│   ├── setup_orchestration.sh        # Multi-agent orchestration
│   ├── deploy_dashboard.sh           # Dashboard deployment
│   └── configure_governance.sh       # Governance controls
│
├── phase4/                            # Deployment & Optimization
│   ├── setup.sh                      # Main orchestrator
│   ├── deploy_production.sh          # Production config
│   ├── setup_monitoring.sh           # Monitoring & KPIs
│   └── continuous_improvement.sh     # CI/CD pipeline
│
├── agents/                            # Agent modules (created during deployment)
│   ├── orchestrator.py               # Multi-agent orchestrator
│   ├── celeryconfig.py              # Celery configuration
│   ├── hitl.py                       # Human-in-the-loop
│   ├── audit_logger.py              # Audit logging
│   ├── compliance_reporter.py        # Compliance reports
│   ├── kpi_tracker.py               # KPI tracking
│   ├── continuous_improvement.py     # Improvement pipeline
│   ├── feedback_collector.py         # Feedback collection
│   ├── multi_agent_example.py        # Example multi-agent setup
│   ├── common/                       # Common agent utilities
│   │   ├── __init__.py
│   │   ├── base_agent.py
│   │   ├── logger.py
│   │   └── config.py
│   ├── triage/                       # Triage agent files
│   ├── investigation/                # Investigation agent files
│   └── response/                     # Response agent files
│
├── dashboard/                         # Web dashboard (created by phase3)
│   ├── index.html                    # Main dashboard
│   └── serve.sh                      # Dashboard server
│
├── data/                              # Data directories (created by phase1)
│   ├── alerts/                       # Alert data
│   ├── investigations/               # Investigation data
│   ├── models/                       # AI models
│   ├── logs/                         # Application logs
│   │   ├── audit_YYYYMMDD.jsonl     # Audit logs
│   │   └── reports/                  # Generated reports
│   ├── exports/                      # Data exports
│   └── backup/                       # Backups
│
├── sandbox/                           # Testing sandbox (created by phase2)
│   ├── test_scenarios.json           # Test scenarios
│   └── docker-compose.sandbox.yml    # Sandbox Docker config
│
├── backups/                           # Backup storage (created by phase4)
│
├── docker-compose.db.yml             # Database services (created by phase1)
└── docker-compose.monitoring.yml     # Monitoring services (created by phase3)
```

## Script Execution Flow

### Phase 1: Foundation Building

```bash
phase1/setup.sh
├─> install_core_deps.sh
│   ├─ Install Python, Docker, Git
│   ├─ Create virtual environment
│   └─ Install base packages
│
├─> install_ai_frameworks.sh
│   ├─ Install OpenAI SDK
│   ├─ Install LangChain
│   ├─ Install CrewAI
│   └─ Save requirements.txt
│
├─> install_siem_edr.sh
│   ├─ Install SIEM clients (Elastic, Splunk)
│   ├─ Install EDR clients (CrowdStrike, etc.)
│   ├─ Create integration configs
│   └─ Test API connections
│
└─> prepare_data.sh
    ├─ Create directory structure
    ├─ Generate sample data
    ├─ Set up PostgreSQL + Redis
    └─ Create database schema
```

### Phase 2: Agent Development

```bash
phase2/setup.sh
├─> setup_agent_env.sh
│   ├─ Install development tools
│   ├─ Create agent directories
│   ├─ Create common utilities
│   └─ Create base agent class
│
├─> install_langchain.sh
│   ├─ Install LangChain ecosystem
│   ├─ Install CrewAI
│   ├─ Create multi-agent example
│   └─ Verify installations
│
├─> deploy_triage_agent.py
│   ├─ Initialize TriageAgent class
│   ├─ Load sample alerts
│   ├─ Run triage demo
│   └─ Log audit trail
│
├─> setup_sandbox.sh
│   ├─ Set up Atomic Red Team
│   ├─ Create test scenarios
│   └─ Configure sandbox network
│
└─> test_triage_agent.py
    ├─ Load test scenarios
    ├─ Run agent tests
    └─ Validate results
```

### Phase 3: Integration & Orchestration

```bash
phase3/setup.sh
├─> setup_orchestration.sh
│   ├─ Install Celery + Redis
│   ├─ Create orchestration config
│   ├─ Create orchestrator service
│   └─ Set up message queue
│
├─> deploy_dashboard.sh
│   ├─ Check Node.js installation
│   ├─ Deploy Grafana + Prometheus
│   ├─ Create web dashboard
│   └─ Start services
│
└─> configure_governance.sh
    ├─ Create governance config
    ├─ Implement HITL workflow
    ├─ Set up audit logging
    └─ Create compliance reporters
```

### Phase 4: Deployment & Optimization

```bash
phase4/setup.sh
├─> deploy_production.sh
│   ├─ Create production config
│   ├─ Create systemd services
│   ├─ Configure nginx
│   └─ Set up backup script
│
├─> setup_monitoring.sh
│   ├─ Install monitoring tools
│   ├─ Create KPI tracker
│   ├─ Set up alerting
│   └─ Create Grafana dashboards
│
└─> continuous_improvement.sh
    ├─ Create improvement pipeline
    ├─ Set up feedback loop
    └─ Create retraining schedule
```

## Key Scripts Reference

### Validation & Testing

- **validate.sh** - Comprehensive validation of all components
- **phase2/test_triage_agent.py** - Test triage agent functionality
- **agents/kpi_tracker.py** - Generate KPI reports
- **agents/continuous_improvement.py** - Run improvement analysis

### Operational Scripts

- **backup.sh** - Create system backup
- **retrain.sh** - Retrain AI models (created by phase4)
- **dashboard/serve.sh** - Start web dashboard
- **agents/orchestrator.py** - Run multi-agent orchestrator

### Configuration Files

- **.env** - Main environment configuration (copy from .env.example)
- **config/agent_config.yaml** - Agent behavior settings
- **config/governance_config.yaml** - Governance and compliance
- **config/orchestration_config.yaml** - Workflow configuration
- **config/production.yaml** - Production settings

## Common Tasks

### Start All Services

```bash
cd deploy

# Start databases
docker-compose -f docker-compose.db.yml up -d

# Start monitoring
docker-compose -f docker-compose.monitoring.yml up -d

# Start dashboard
cd dashboard && ./serve.sh &

# Start Celery worker
source .venv/bin/activate
celery -A agents.orchestrator worker --loglevel=info &
```

### Stop All Services

```bash
cd deploy

# Stop Docker services
docker-compose -f docker-compose.db.yml down
docker-compose -f docker-compose.monitoring.yml down

# Stop background processes
pkill -f "serve.sh"
pkill -f "celery"
```

### Run Daily Maintenance

```bash
cd deploy
source .venv/bin/activate

# Generate KPI report
python agents/kpi_tracker.py

# Run improvement analysis
python agents/continuous_improvement.py

# Create backup
./backup.sh
```

### Update Dependencies

```bash
cd deploy
source .venv/bin/activate

# Update Python packages
pip install --upgrade openai langchain crewai

# Save updated requirements
pip freeze > requirements.txt
```

## Troubleshooting

### Check System Status

```bash
cd deploy
./validate.sh
```

### View Logs

```bash
# Application logs
tail -f /var/log/agentic-soc/phase*.log

# Docker logs
docker logs agentic-soc-db
docker logs agentic-soc-redis
docker logs agentic-soc-grafana

# Agent audit logs
tail -f data/logs/audit_*.jsonl
```

### Reset Installation

```bash
# WARNING: This will delete all data

cd deploy

# Stop services
docker-compose -f docker-compose.db.yml down -v
docker-compose -f docker-compose.monitoring.yml down -v

# Remove data
rm -rf .venv data backups sandbox

# Restart from Phase 1
cd phase1
./setup.sh
```

## Dependencies Between Phases

- **Phase 2** requires Phase 1 completion (virtual environment, databases)
- **Phase 3** requires Phase 2 completion (agents, orchestrator)
- **Phase 4** requires Phase 3 completion (dashboard, monitoring)

Each phase validates prerequisites before execution.

## Estimated Resource Usage

### Disk Space
- Phase 1: ~5GB (dependencies, databases)
- Phase 2: ~2GB (agents, models)
- Phase 3: ~3GB (monitoring, dashboards)
- Phase 4: ~1GB (configs, scripts)
- **Total: ~15GB** (excluding logs and backups)

### Memory
- Base system: ~4GB
- PostgreSQL: ~512MB
- Redis: ~256MB
- Grafana: ~256MB
- Python processes: ~2GB
- **Total: ~8GB minimum, 16GB recommended**

### Network
- Initial setup: ~2GB download
- Ongoing: Depends on API usage

---

For detailed information on each component, see the main [README.md](README.md) and [QUICKSTART.md](QUICKSTART.md).

# AI Agentic SOC Deployment Scripts

This directory contains comprehensive automation scripts for implementing an AI Agentic Security Operations Center (SOC) based on the [AI Agentic SOC Implementation Guide](/posts/ai-agentic-soc-implementation-guide.mdx).

## Overview

The deployment is organized into four phases, each with dedicated scripts that automate installation, configuration, and setup of required components:

- **Phase 1:** Foundation Building (Weeks 1-4)
- **Phase 2:** Agent Development & Automation (Weeks 5-12)
- **Phase 3:** Integration & Orchestration (Weeks 13-20)
- **Phase 4:** Deployment & Optimization (Weeks 21+)

## Directory Structure

```
deploy/
├── README.md                    # This file
├── phase1/                      # Foundation Building scripts
│   ├── setup.sh                # Main setup script
│   ├── install_siem_edr.sh     # SIEM/EDR platform setup
│   ├── install_ai_frameworks.sh # AI framework installation
│   └── prepare_data.sh         # Data preparation utilities
├── phase2/                      # Agent Development scripts
│   ├── setup.sh                # Main setup script
│   ├── setup_agent_env.sh      # Agent development environment
│   ├── deploy_triage_agent.py  # Example triage agent
│   ├── install_langchain.sh    # LangChain integration
│   └── setup_sandbox.sh        # Testing sandbox
├── phase3/                      # Integration & Orchestration scripts
│   ├── setup.sh                # Main setup script
│   ├── setup_orchestration.sh  # Multi-agent orchestration
│   ├── deploy_dashboard.sh     # Dashboard deployment
│   └── configure_governance.sh # Governance controls
├── phase4/                      # Deployment & Optimization scripts
│   ├── setup.sh                # Main setup script
│   ├── deploy_production.sh    # Production deployment
│   ├── setup_monitoring.sh     # Monitoring and KPIs
│   └── continuous_improvement.sh # CI/CD and retraining
├── common/                      # Shared utilities
│   ├── utils.sh                # Common shell functions
│   ├── logger.sh               # Logging utilities
│   └── validator.sh            # Input validation
└── config/                      # Configuration templates
    ├── .env.example            # Environment variables template
    ├── siem_config.yaml        # SIEM configuration
    ├── agent_config.yaml       # Agent configuration
    └── dashboard_config.yaml   # Dashboard configuration
```

## Prerequisites

### System Requirements

- **Operating System:** Linux (Ubuntu 20.04+, Debian 11+, or RHEL 8+)
- **Python:** 3.9 or higher
- **Node.js:** 18.x or higher (for dashboard)
- **RAM:** Minimum 16GB (32GB+ recommended)
- **Storage:** 100GB+ available space
- **Network:** Stable internet connection

### Access Requirements

- API keys for:
  - OpenAI (GPT-4o or similar)
  - SIEM platform (Splunk, Elastic, etc.)
  - EDR platform (CrowdStrike Falcon, etc.)
- Administrative access to target systems
- Valid licenses for commercial tools

## Quick Start

### 1. Initial Setup

Clone the repository and navigate to the deploy directory:

```bash
cd /path/to/B0LK13/deploy
```

### 2. Configure Environment

Copy and customize the environment configuration:

```bash
cp config/.env.example .env
# Edit .env with your API keys and configuration
nano .env
```

### 3. Run Phase Scripts

Execute each phase in order. Each phase is modular and can be run independently if prerequisites are met.

#### Phase 1: Foundation Building

```bash
cd phase1
chmod +x setup.sh
./setup.sh
```

**What this does:**
- Installs core dependencies (Python, Docker, etc.)
- Sets up SIEM/EDR platform connections
- Installs AI frameworks (OpenAI SDK, CrewAI)
- Prepares data directories and initial datasets

**Expected output:**
- AI-ready environment
- Basic agent prototype
- Configured SIEM/EDR API connections

**Duration:** ~30-60 minutes

#### Phase 2: Agent Development & Automation

```bash
cd ../phase2
chmod +x setup.sh
./setup.sh
```

**What this does:**
- Creates Python virtual environment for agent development
- Installs LangChain, CrewAI, and dependencies
- Deploys example triage agent
- Sets up testing sandbox with Atomic Red Team
- Integrates SOAR capabilities

**Expected output:**
- Functional triage agent
- Testing environment
- 50% automation of alert handling

**Duration:** ~1-2 hours

#### Phase 3: Integration & Orchestration

```bash
cd ../phase3
chmod +x setup.sh
./setup.sh
```

**What this does:**
- Configures multi-agent orchestration
- Deploys monitoring dashboard (React + Grafana)
- Implements governance controls and audit trails
- Sets up human-in-the-loop workflows

**Expected output:**
- Collaborative multi-agent system
- Real-time dashboard
- MTTI under 5 minutes in tests

**Duration:** ~2-3 hours

#### Phase 4: Deployment & Optimization

```bash
cd ../phase4
chmod +x setup.sh
./setup.sh
```

**What this does:**
- Configures production deployment
- Sets up monitoring and KPI tracking
- Implements continuous improvement pipelines
- Configures automated retraining

**Expected output:**
- Production-ready SOC
- 24/7 autonomous operations
- Monitoring dashboards

**Duration:** ~1-2 hours

## Modular Execution

Each phase is designed to be executed independently. If you need to re-run a specific component:

```bash
# Example: Re-install AI frameworks only
cd phase1
./install_ai_frameworks.sh

# Example: Redeploy triage agent
cd phase2
python deploy_triage_agent.py
```

## Configuration

### Environment Variables

All scripts use environment variables defined in `.env`. Key variables include:

```bash
# API Keys
OPENAI_API_KEY=your_openai_key
SIEM_API_KEY=your_siem_key
EDR_API_KEY=your_edr_key

# SIEM/EDR Configuration
SIEM_TYPE=elastic|splunk|qradar
SIEM_HOST=your_siem_host
EDR_TYPE=crowdstrike|sentinelone|defender

# Agent Configuration
AGENT_MODEL=gpt-4o
AGENT_TEMPERATURE=0.2
MAX_ITERATIONS=5

# Dashboard
DASHBOARD_PORT=3000
GRAFANA_PORT=3001
```

See `config/.env.example` for the complete list.

### Custom Configurations

Each component has its own YAML configuration file in the `config/` directory:

- `siem_config.yaml`: SIEM platform settings
- `agent_config.yaml`: Agent behavior and limits
- `dashboard_config.yaml`: Dashboard preferences

## Logging and Auditing

All scripts log to `/var/log/agentic-soc/` by default. Each phase creates its own log file:

```bash
/var/log/agentic-soc/
├── phase1_foundation.log
├── phase2_agents.log
├── phase3_orchestration.log
└── phase4_deployment.log
```

Audit trails for agent actions are stored in the database and can be queried via the dashboard.

## Troubleshooting

### Common Issues

**Issue:** Script fails with "Permission denied"
```bash
# Solution: Ensure scripts are executable
chmod +x setup.sh
```

**Issue:** Python dependencies fail to install
```bash
# Solution: Upgrade pip and setuptools
python3 -m pip install --upgrade pip setuptools wheel
```

**Issue:** API connection errors
```bash
# Solution: Verify API keys in .env and network connectivity
source .env
curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
```

**Issue:** SIEM/EDR connection fails
```bash
# Solution: Check firewall rules and API endpoints
# Verify credentials and network access
```

### Getting Help

1. Check logs in `/var/log/agentic-soc/`
2. Review error messages and stack traces
3. Consult the [AI Agentic SOC Implementation Guide](/posts/ai-agentic-soc-implementation-guide.mdx)
4. Open an issue on GitHub with logs and error details

## Security Considerations

### Best Practices

1. **API Keys:** Never commit `.env` to version control
2. **Sandboxing:** Always test agents in isolated environments first
3. **Human Oversight:** Keep human-in-the-loop for critical actions
4. **Audit Trails:** Enable comprehensive logging
5. **Access Control:** Use RBAC for dashboard and agent management
6. **Data Protection:** Encrypt sensitive data at rest and in transit

### Compliance

Scripts implement governance controls to support:

- **GDPR:** Data logging and retention policies
- **SOC 2:** Audit trails and access controls
- **EU AI Act:** Transparency and explainability requirements
- **NIST CSF:** Security framework alignment

## Testing

Each phase includes validation checks. To verify installation:

```bash
# Test Phase 1
cd phase1
./test_installation.sh

# Test Phase 2 agents
cd ../phase2
python test_triage_agent.py

# Test Phase 3 orchestration
cd ../phase3
./test_orchestration.sh

# Test Phase 4 monitoring
cd ../phase4
./test_monitoring.sh
```

## Cost Estimates

Based on the implementation guide:

- **Phase 1:** ~€50K (licenses, consulting)
- **Phase 2:** ~€150K (development, APIs)
- **Phase 3:** ~€100K (testing, UI development)
- **Phase 4:** ~€100K/year (maintenance)

**Total:** €200K-€500K for full implementation

## Timeline

- **Phase 1:** Weeks 1-4 (Foundation)
- **Phase 2:** Weeks 5-12 (Agent Development)
- **Phase 3:** Weeks 13-20 (Integration)
- **Phase 4:** Weeks 21+ (Deployment & Optimization)

**Total:** 3-6 months for full rollout

## Support

For questions or issues:

1. Review documentation in this README
2. Check the [AI Agentic SOC Implementation Guide](/posts/ai-agentic-soc-implementation-guide.mdx)
3. Open a GitHub issue with detailed information
4. Contact your cybersecurity team lead

## License

MIT License - See LICENSE file in the repository root

## Contributing

Contributions are welcome! Please:

1. Test changes thoroughly
2. Update documentation
3. Follow existing code style
4. Submit pull requests with clear descriptions

## Acknowledgments

Based on frameworks from:
- CrowdStrike Agentic SOC Guide
- Google Cloud AI for Security
- Prophet Security AI SOC Platform
- Red Canary Threat Detection
- NIST Cybersecurity Framework

---

**Note:** These scripts are provided as a starting point. Customize them for your specific environment, security requirements, and organizational policies. Always test in a non-production environment first.

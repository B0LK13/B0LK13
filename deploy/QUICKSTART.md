# Quick Start Guide - AI Agentic SOC

This guide will help you quickly get started with the AI Agentic SOC deployment scripts.

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Linux system (Ubuntu 20.04+, Debian 11+, or RHEL 8+)
- [ ] 16GB+ RAM (32GB recommended)
- [ ] 100GB+ free disk space
- [ ] Sudo privileges
- [ ] Internet connectivity
- [ ] OpenAI API key (for GPT-4o)
- [ ] SIEM/EDR access (optional for Phase 1, required for production)

## 5-Minute Quick Start

### 1. Clone and Navigate

```bash
cd /path/to/B0LK13
cd deploy
```

### 2. Configure Environment

```bash
# Copy environment template
cp config/.env.example .env

# Edit with your API keys (minimum required: OPENAI_API_KEY)
nano .env
```

**Required at minimum:**
```bash
OPENAI_API_KEY=sk-your-actual-key-here
```

### 3. Run Phase 1 (Foundation)

```bash
cd phase1
chmod +x setup.sh
./setup.sh
```

**What happens:**
- Installs Python, Docker, and dependencies
- Creates virtual environment
- Installs AI frameworks (OpenAI, LangChain, CrewAI)
- Sets up database containers
- Prepares data directories

**Duration:** ~30-60 minutes

**Verify:**
```bash
# Check Docker containers
docker ps | grep agentic-soc

# Check Python environment
source ../.venv/bin/activate
python -c "import openai, langchain, crewai; print('✓ All packages installed')"
```

### 4. Run Phase 2 (Agents)

```bash
cd ../phase2
./setup.sh
```

**What happens:**
- Deploys triage agent
- Sets up multi-agent orchestration
- Creates testing sandbox
- Runs initial tests

**Duration:** ~1-2 hours

**Verify:**
```bash
# Test the triage agent
source ../.venv/bin/activate
python test_triage_agent.py
```

### 5. Run Phase 3 (Integration)

```bash
cd ../phase3
./setup.sh
```

**What happens:**
- Configures multi-agent orchestration
- Deploys web dashboard
- Sets up governance controls
- Starts monitoring services

**Duration:** ~2-3 hours

**Verify:**
```bash
# Access dashboard
# Open browser to: http://localhost:3000

# Check Grafana
# Open browser to: http://localhost:3001
```

### 6. Run Phase 4 (Production)

```bash
cd ../phase4
./setup.sh
```

**What happens:**
- Configures production settings
- Sets up monitoring and KPIs
- Creates backup scripts
- Enables continuous improvement

**Duration:** ~1-2 hours

**Verify:**
```bash
# Generate KPI report
source ../.venv/bin/activate
python ../agents/kpi_tracker.py
```

## Using Individual Components

### Deploy Triage Agent Only

```bash
cd deploy
source .venv/bin/activate
python phase2/deploy_triage_agent.py
```

### Start Dashboard Only

```bash
cd deploy/dashboard
./serve.sh
# Visit http://localhost:3000
```

### Run Orchestrator

```bash
cd deploy
source .venv/bin/activate
celery -A agents.orchestrator worker --loglevel=info
```

### Generate KPI Report

```bash
cd deploy
source .venv/bin/activate
python agents/kpi_tracker.py
```

## Common Issues and Solutions

### Issue: Docker permission denied

```bash
# Solution: Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Issue: Python package installation fails

```bash
# Solution: Upgrade pip
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
```

### Issue: OpenAI API errors

```bash
# Solution: Verify API key
source .env
curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
```

### Issue: Database connection fails

```bash
# Solution: Restart database container
docker-compose -f docker-compose.db.yml restart postgres
```

## Testing Your Setup

### Run Full Test Suite

```bash
cd deploy
source .venv/bin/activate

# Test triage agent
python phase2/test_triage_agent.py

# Test KPI tracker
python agents/kpi_tracker.py

# Test improvement pipeline
python agents/continuous_improvement.py
```

### Verify All Services

```bash
# Check Docker services
docker ps

# Expected output should show:
# - agentic-soc-db (PostgreSQL)
# - agentic-soc-redis (Redis)
# - agentic-soc-grafana (Grafana)
# - agentic-soc-prometheus (Prometheus)
```

### Check Logs

```bash
# Application logs
tail -f /var/log/agentic-soc/phase*

# Docker logs
docker logs agentic-soc-db
docker logs agentic-soc-redis
```

## Next Steps

1. **Configure Production API Keys**
   - Add SIEM API credentials to `.env`
   - Add EDR API credentials to `.env`
   - Configure threat intelligence feeds

2. **Customize Agents**
   - Review `config/agent_config.yaml`
   - Adjust prompts and parameters
   - Test with real alerts

3. **Set Up Monitoring**
   - Configure Grafana dashboards
   - Set up alerting rules
   - Configure notification channels

4. **Enable Automation**
   - Start with read-only mode
   - Gradually enable automated actions
   - Maintain human-in-the-loop for critical actions

5. **Train Your Team**
   - Review the main README
   - Understand agent capabilities
   - Practice incident response workflows

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     AI Agentic SOC                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │   Triage     │   │ Investigation│   │   Response   │  │
│  │    Agent     │──▶│    Agent     │──▶│    Agent     │  │
│  └──────────────┘   └──────────────┘   └──────────────┘  │
│         │                  │                    │          │
│         └──────────────────┼────────────────────┘          │
│                            ▼                                │
│                   ┌────────────────┐                       │
│                   │  Orchestrator  │                       │
│                   └────────────────┘                       │
│                            │                                │
│         ┌──────────────────┼──────────────────┐           │
│         ▼                  ▼                   ▼           │
│  ┌──────────┐      ┌──────────┐       ┌──────────┐       │
│  │  SIEM    │      │   EDR    │       │ Dashboard│       │
│  └──────────┘      └──────────┘       └──────────┘       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Support

- **Documentation:** See [deploy/README.md](README.md)
- **Implementation Guide:** [posts/ai-agentic-soc-implementation-guide.mdx](/posts/ai-agentic-soc-implementation-guide.mdx)
- **Issues:** Open a GitHub issue with logs and error details

## Security Notes

⚠️ **Important Security Considerations:**

1. **Never commit `.env` with real credentials**
2. **Start with automated actions disabled**
3. **Enable human-in-the-loop for all critical actions**
4. **Test in sandbox before production**
5. **Monitor agent decisions closely**
6. **Maintain comprehensive audit logs**
7. **Rotate API keys regularly**
8. **Keep systems updated**

---

**Ready to deploy?** Start with Phase 1 and work your way through each phase. Each phase builds on the previous one, so follow them in order for best results.

Good luck with your AI Agentic SOC deployment! 🚀🔒

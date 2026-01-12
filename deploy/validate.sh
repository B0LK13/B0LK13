#!/bin/bash

################################################################################
# Validation Script for AI Agentic SOC Deployment
#
# This script validates that all components are properly installed and
# configured across all deployment phases.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common/utils.sh"

print_header "AI AGENTIC SOC - DEPLOYMENT VALIDATION"

# Initialize counters
total_checks=0
passed_checks=0
failed_checks=0
warnings=0

# Check function
check() {
    local description=$1
    local command=$2
    
    total_checks=$((total_checks + 1))
    echo -n "  [$total_checks] $description... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e "${RED}✗${NC}"
        failed_checks=$((failed_checks + 1))
        return 1
    fi
}

warn() {
    local description=$1
    local command=$2
    
    total_checks=$((total_checks + 1))
    echo -n "  [$total_checks] $description... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${YELLOW}⚠${NC}"
        warnings=$((warnings + 1))
    fi
}

# Phase 1 Checks
print_header "Phase 1: Foundation Building"

check "Python 3.9+ installed" "command -v python3 && python3 --version | grep -E 'Python 3\.(9|1[0-9])'"
check "Docker installed" "command -v docker"
check "Docker Compose installed" "command -v docker-compose"
check "Virtual environment exists" "[ -d '$SCRIPT_DIR/.venv' ]"
check "Git installed" "command -v git"

warn "PostgreSQL container running" "docker ps | grep -q agentic-soc-db"
warn "Redis container running" "docker ps | grep -q agentic-soc-redis"

# Activate venv for Python checks
if [ -d "$SCRIPT_DIR/.venv" ]; then
    source "$SCRIPT_DIR/.venv/bin/activate"
    
    check "OpenAI package installed" "python -c 'import openai'"
    check "LangChain package installed" "python -c 'import langchain'"
    check "CrewAI package installed" "python -c 'import crewai'"
    check "Elasticsearch package installed" "python -c 'import elasticsearch'"
else
    failed_checks=$((failed_checks + 4))
    echo "  [SKIP] Python package checks (no virtual environment)"
fi

# Phase 2 Checks
print_header "Phase 2: Agent Development"

check "Agents directory exists" "[ -d '$SCRIPT_DIR/agents' ]"
check "Triage agent exists" "[ -f '$SCRIPT_DIR/phase2/deploy_triage_agent.py' ]"
check "Test agent exists" "[ -f '$SCRIPT_DIR/phase2/test_triage_agent.py' ]"
check "Multi-agent example exists" "[ -f '$SCRIPT_DIR/agents/multi_agent_example.py' ]"

warn "Sample alerts data exists" "[ -f '$SCRIPT_DIR/data/alerts/sample_alerts.json' ]"
warn "Sandbox configured" "[ -f '$SCRIPT_DIR/sandbox/test_scenarios.json' ]"

# Phase 3 Checks
print_header "Phase 3: Integration & Orchestration"

check "Orchestrator exists" "[ -f '$SCRIPT_DIR/agents/orchestrator.py' ]"
check "Dashboard exists" "[ -f '$SCRIPT_DIR/dashboard/index.html' ]"
check "Governance config exists" "[ -f '$SCRIPT_DIR/config/governance_config.yaml' ]"
check "HITL module exists" "[ -f '$SCRIPT_DIR/agents/hitl.py' ]"

warn "Grafana container running" "docker ps | grep -q agentic-soc-grafana"
warn "Prometheus container running" "docker ps | grep -q agentic-soc-prometheus"

# Phase 4 Checks
print_header "Phase 4: Deployment & Optimization"

check "KPI tracker exists" "[ -f '$SCRIPT_DIR/agents/kpi_tracker.py' ]"
check "Improvement pipeline exists" "[ -f '$SCRIPT_DIR/agents/continuous_improvement.py' ]"
check "Backup script exists" "[ -f '$SCRIPT_DIR/backup.sh' ]"
check "Production config exists" "[ -f '$SCRIPT_DIR/config/production.yaml' ]"

# Configuration Checks
print_header "Configuration Validation"

check "Config directory exists" "[ -d '$SCRIPT_DIR/config' ]"
check "Environment example exists" "[ -f '$SCRIPT_DIR/config/.env.example' ]"

warn "Environment file configured" "[ -f '$SCRIPT_DIR/.env' ]"

if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
    
    warn "OpenAI API key set" "[ -n '$OPENAI_API_KEY' ] && [ '$OPENAI_API_KEY' != 'sk-your-openai-api-key-here' ]"
    warn "SIEM type configured" "[ -n '$SIEM_TYPE' ]"
    warn "Database URL configured" "[ -n '$DATABASE_URL' ]"
fi

# System Checks
print_header "System Resources"

total_ram=$(free -g | awk '/^Mem:/{print $2}')
if [ $total_ram -ge 16 ]; then
    echo -e "  RAM: ${GREEN}${total_ram}GB (✓ Sufficient)${NC}"
    passed_checks=$((passed_checks + 1))
elif [ $total_ram -ge 8 ]; then
    echo -e "  RAM: ${YELLOW}${total_ram}GB (⚠ Low, 16GB recommended)${NC}"
    warnings=$((warnings + 1))
else
    echo -e "  RAM: ${RED}${total_ram}GB (✗ Insufficient)${NC}"
    failed_checks=$((failed_checks + 1))
fi
total_checks=$((total_checks + 1))

available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ $available_space -ge 100 ]; then
    echo -e "  Disk Space: ${GREEN}${available_space}GB (✓ Sufficient)${NC}"
    passed_checks=$((passed_checks + 1))
elif [ $available_space -ge 50 ]; then
    echo -e "  Disk Space: ${YELLOW}${available_space}GB (⚠ Low, 100GB recommended)${NC}"
    warnings=$((warnings + 1))
else
    echo -e "  Disk Space: ${RED}${available_space}GB (✗ Insufficient)${NC}"
    failed_checks=$((failed_checks + 1))
fi
total_checks=$((total_checks + 1))

# Network Check
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo -e "  Network: ${GREEN}✓ Connected${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "  Network: ${RED}✗ No connectivity${NC}"
    failed_checks=$((failed_checks + 1))
fi
total_checks=$((total_checks + 1))

# Summary
print_header "VALIDATION SUMMARY"

echo
echo "  Total Checks: $total_checks"
echo -e "  ${GREEN}Passed: $passed_checks${NC}"
echo -e "  ${YELLOW}Warnings: $warnings${NC}"
echo -e "  ${RED}Failed: $failed_checks${NC}"
echo

# Calculate percentage
success_rate=$(( (passed_checks * 100) / total_checks ))

if [ $failed_checks -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo
    echo "  Your AI Agentic SOC deployment is ready."
    echo "  Success rate: ${success_rate}%"
    
    if [ $warnings -gt 0 ]; then
        echo
        echo -e "${YELLOW}Note: $warnings optional component(s) not configured.${NC}"
        echo "  These are optional and won't prevent the system from running."
    fi
    
    echo
    echo "Next steps:"
    echo "  1. Review configuration in .env"
    echo "  2. Test the triage agent: python phase2/test_triage_agent.py"
    echo "  3. Access dashboard at http://localhost:3000"
    echo "  4. View logs at /var/log/agentic-soc/"
    echo
    exit 0
else
    echo -e "${RED}✗ $failed_checks critical check(s) failed.${NC}"
    echo
    echo "  Please address the failed checks before proceeding."
    echo "  Success rate: ${success_rate}%"
    echo
    echo "Common fixes:"
    echo "  - Run phase setup scripts: cd phaseN && ./setup.sh"
    echo "  - Check system requirements in README.md"
    echo "  - Ensure Docker is running: sudo systemctl start docker"
    echo "  - Verify network connectivity"
    echo
    exit 1
fi

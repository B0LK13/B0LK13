#!/bin/bash

################################################################################
# Phase 2: Install LangChain and CrewAI
#
# Installs and configures LangChain and CrewAI for multi-agent orchestration.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Installing LangChain and CrewAI..."
    
    # Activate virtual environment
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Ensure latest versions
    log_info "Installing/upgrading LangChain ecosystem..."
    pip install --upgrade langchain langchain-openai langchain-community
    pip install langchain-experimental
    pip install langsmith  # For tracing and monitoring
    
    # CrewAI
    log_info "Installing/upgrading CrewAI..."
    pip install --upgrade crewai crewai-tools
    
    # Additional agent frameworks
    log_info "Installing additional agent tools..."
    pip install autogen-agentchat  # Microsoft AutoGen
    
    # Orchestration tools
    log_info "Installing orchestration utilities..."
    pip install celery  # Task queue
    pip install redis  # Backend for Celery
    
    # Create example multi-agent setup
    create_multi_agent_example
    
    # Verify installations
    log_info "Verifying installations..."
    python -c "import langchain; print(f'LangChain {langchain.__version__}')"
    python -c "import crewai; print('CrewAI installed')"
    python -c "import langsmith; print('LangSmith installed')"
    
    log_success "LangChain and CrewAI installed successfully"
}

create_multi_agent_example() {
    log_info "Creating multi-agent orchestration example..."
    
    cat > "$DEPLOY_DIR/agents/multi_agent_example.py" << 'EOF'
#!/usr/bin/env python3
"""
Multi-Agent Orchestration Example

Demonstrates how multiple AI agents work together to handle a security incident.
Uses CrewAI for orchestration.
"""

import os
from crewai import Agent, Task, Crew, Process
from langchain_openai import ChatOpenAI

def create_security_crew():
    """Create a crew of security agents"""
    
    # Initialize LLM
    llm = ChatOpenAI(
        model="gpt-4o",
        api_key=os.getenv("OPENAI_API_KEY"),
        temperature=0.2
    )
    
    # Define agents
    triage_agent = Agent(
        role='Security Triage Specialist',
        goal='Quickly assess and prioritize security alerts',
        backstory='Expert in rapidly evaluating security threats',
        llm=llm,
        verbose=True
    )
    
    investigation_agent = Agent(
        role='Security Investigator',
        goal='Conduct deep analysis of security incidents',
        backstory='Senior security analyst with deep forensics experience',
        llm=llm,
        verbose=True
    )
    
    response_agent = Agent(
        role='Incident Responder',
        goal='Recommend and coordinate response actions',
        backstory='Incident response expert focused on containment',
        llm=llm,
        verbose=True
    )
    
    # Define tasks
    triage_task = Task(
        description='Analyze this security alert and determine priority: {alert}',
        agent=triage_agent,
        expected_output='Priority assessment and initial analysis'
    )
    
    investigation_task = Task(
        description='Investigate the alert in detail, gather context and evidence',
        agent=investigation_agent,
        expected_output='Detailed investigation report'
    )
    
    response_task = Task(
        description='Based on the investigation, recommend response actions',
        agent=response_agent,
        expected_output='Response action plan'
    )
    
    # Create crew
    crew = Crew(
        agents=[triage_agent, investigation_agent, response_agent],
        tasks=[triage_task, investigation_task, response_task],
        process=Process.sequential,  # Tasks executed in sequence
        verbose=True
    )
    
    return crew

if __name__ == "__main__":
    print("Multi-Agent Orchestration Example")
    print("=" * 80)
    
    # Example alert
    sample_alert = """
    Alert: Suspicious Login Detected
    User: admin@company.com
    Source IP: 185.220.101.45
    Time: 2026-01-12 23:00:00 UTC
    Location: Russia
    Failed Attempts: 15
    Successful: Yes
    """
    
    crew = create_security_crew()
    
    # Process alert
    result = crew.kickoff(inputs={'alert': sample_alert})
    
    print("\nCrew Result:")
    print("=" * 80)
    print(result)
EOF
    
    chmod +x "$DEPLOY_DIR/agents/multi_agent_example.py"
    log_success "Multi-agent example created"
}

main "$@"

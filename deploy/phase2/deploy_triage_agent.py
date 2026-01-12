#!/usr/bin/env python3
"""
AI Agentic SOC - Triage Agent

This is the example triage agent from the AI Agentic SOC Implementation Guide.
It analyzes security alerts and prioritizes them based on severity and context.

Based on the example code from the guide with enhancements for production use.
"""

import os
import sys
import json
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from langchain_openai import ChatOpenAI
    from langchain.agents import initialize_agent, Tool, AgentType
    from langchain.prompts import PromptTemplate
    from langchain.memory import ConversationBufferMemory
except ImportError as e:
    print(f"Error: Required packages not installed. Run Phase 2 setup first.")
    print(f"Details: {e}")
    sys.exit(1)

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class TriageAgent:
    """
    AI-powered security alert triage agent.
    
    This agent:
    1. Receives security alerts from SIEM/EDR
    2. Analyzes severity, context, and potential impact
    3. Prioritizes alerts and recommends actions
    4. Logs all decisions for audit trail
    """
    
    def __init__(self, api_key: Optional[str] = None, model: str = "gpt-4o"):
        """
        Initialize the triage agent.
        
        Args:
            api_key: OpenAI API key (defaults to OPENAI_API_KEY env var)
            model: LLM model to use
        """
        self.api_key = api_key or os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OpenAI API key not found. Set OPENAI_API_KEY environment variable.")
        
        self.model = model
        self.llm = ChatOpenAI(
            model=self.model,
            api_key=self.api_key,
            temperature=0.2  # Lower temperature for more consistent responses
        )
        
        # Initialize tools
        self.tools = self._create_tools()
        
        # Initialize memory for context
        self.memory = ConversationBufferMemory(
            memory_key="chat_history",
            return_messages=True
        )
        
        # Initialize agent
        self.agent = initialize_agent(
            self.tools,
            self.llm,
            agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION,
            verbose=True,
            memory=self.memory,
            max_iterations=5
        )
        
        logger.info(f"Triage agent initialized with model: {self.model}")
    
    def _create_tools(self) -> List[Tool]:
        """Create tools for the agent to use."""
        
        tools = [
            Tool(
                name="SIEM_Query",
                func=self._query_siem,
                description="Query SIEM for alert details and related events. Input should be an alert ID or query string."
            ),
            Tool(
                name="Threat_Intel_Lookup",
                func=self._lookup_threat_intel,
                description="Look up threat intelligence for IPs, domains, or file hashes. Input should be an IP address, domain, or hash."
            ),
            Tool(
                name="User_Context",
                func=self._get_user_context,
                description="Get context about a user account (role, department, recent activity). Input should be a username."
            ),
            Tool(
                name="Asset_Info",
                func=self._get_asset_info,
                description="Get information about an asset (criticality, services, location). Input should be an IP address or hostname."
            ),
        ]
        
        return tools
    
    def _query_siem(self, query: str) -> str:
        """
        Query SIEM for alert details.
        
        In production, this would connect to actual SIEM.
        For now, it returns mock data for demonstration.
        """
        logger.info(f"Querying SIEM: {query}")
        
        # Mock response - in production, integrate with actual SIEM API
        return json.dumps({
            "alert_id": query,
            "related_events": 3,
            "timeline": "Last seen 15 minutes ago",
            "frequency": "First occurrence"
        })
    
    def _lookup_threat_intel(self, indicator: str) -> str:
        """
        Look up threat intelligence for an indicator.
        
        In production, this would query VirusTotal, AbuseIPDB, etc.
        """
        logger.info(f"Looking up threat intel: {indicator}")
        
        # Mock response - in production, integrate with threat intel APIs
        if "." in indicator and len(indicator.split(".")) == 4:
            # Looks like an IP
            return json.dumps({
                "indicator": indicator,
                "reputation": "suspicious",
                "categories": ["scanning", "brute-force"],
                "last_seen": "2 hours ago",
                "threat_score": 65
            })
        
        return json.dumps({
            "indicator": indicator,
            "reputation": "unknown",
            "threat_score": 0
        })
    
    def _get_user_context(self, username: str) -> str:
        """Get context about a user."""
        logger.info(f"Getting user context: {username}")
        
        # Mock response
        return json.dumps({
            "username": username,
            "role": "standard_user",
            "department": "Engineering",
            "risk_level": "normal",
            "recent_alerts": 0
        })
    
    def _get_asset_info(self, asset: str) -> str:
        """Get information about an asset."""
        logger.info(f"Getting asset info: {asset}")
        
        # Mock response
        return json.dumps({
            "asset": asset,
            "criticality": "medium",
            "services": ["web", "ssh"],
            "location": "datacenter-1",
            "os": "Linux"
        })
    
    def triage_alert(self, alert_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Triage a security alert.
        
        Args:
            alert_data: Dictionary containing alert information
            
        Returns:
            Dictionary with triage results
        """
        logger.info(f"Triaging alert: {alert_data.get('id', 'unknown')}")
        
        # Create prompt for the agent
        prompt = self._create_triage_prompt(alert_data)
        
        try:
            # Run the agent
            start_time = datetime.now()
            response = self.agent.run(prompt)
            execution_time = (datetime.now() - start_time).total_seconds()
            
            # Parse and structure the response
            result = {
                "alert_id": alert_data.get("id"),
                "triage_timestamp": datetime.now().isoformat(),
                "priority": self._extract_priority(response),
                "recommendation": response,
                "execution_time_seconds": execution_time,
                "status": "completed"
            }
            
            logger.info(f"Triage completed for alert {alert_data.get('id')}")
            
            # Log to audit trail
            self._log_audit_trail(alert_data, result)
            
            return result
            
        except Exception as e:
            logger.error(f"Error triaging alert: {e}")
            return {
                "alert_id": alert_data.get("id"),
                "status": "error",
                "error": str(e),
                "triage_timestamp": datetime.now().isoformat()
            }
    
    def _create_triage_prompt(self, alert_data: Dict[str, Any]) -> str:
        """Create a detailed prompt for alert triage."""
        
        template = """
You are a security analyst performing alert triage. Analyze the following security alert and provide:

1. PRIORITY ASSESSMENT (Critical/High/Medium/Low)
2. THREAT ANALYSIS (What is the threat? Is it legitimate?)
3. IMPACT ASSESSMENT (What systems/data are at risk?)
4. RECOMMENDED ACTIONS (What should be done next?)
5. FALSE POSITIVE LIKELIHOOD (High/Medium/Low and why)

Alert Details:
- Alert ID: {alert_id}
- Type: {alert_type}
- Severity: {severity}
- Source: {source}
- Description: {description}
- Source IP: {source_ip}
- Destination IP: {dest_ip}
- User: {user}
- Timestamp: {timestamp}

Use the available tools to gather additional context:
- Query SIEM for related events
- Look up threat intelligence for the source IP
- Get user and asset context

Provide your analysis in a clear, structured format.
"""
        
        return template.format(
            alert_id=alert_data.get("id", "N/A"),
            alert_type=alert_data.get("type", "N/A"),
            severity=alert_data.get("severity", "N/A"),
            source=alert_data.get("source", "N/A"),
            description=alert_data.get("description", "N/A"),
            source_ip=alert_data.get("source_ip", "N/A"),
            dest_ip=alert_data.get("destination_ip", "N/A"),
            user=alert_data.get("user", "N/A"),
            timestamp=alert_data.get("timestamp", "N/A")
        )
    
    def _extract_priority(self, response: str) -> str:
        """Extract priority from agent response."""
        response_lower = response.lower()
        
        if "critical" in response_lower:
            return "critical"
        elif "high" in response_lower:
            return "high"
        elif "medium" in response_lower:
            return "medium"
        else:
            return "low"
    
    def _log_audit_trail(self, alert_data: Dict[str, Any], result: Dict[str, Any]):
        """Log triage decision to audit trail."""
        
        audit_entry = {
            "timestamp": datetime.now().isoformat(),
            "agent": "triage_agent",
            "alert_id": alert_data.get("id"),
            "action": "triage",
            "input": alert_data,
            "output": result
        }
        
        # In production, save to database
        # For now, save to file
        audit_dir = Path(__file__).parent.parent / "data" / "logs"
        audit_dir.mkdir(parents=True, exist_ok=True)
        
        audit_file = audit_dir / f"audit_{datetime.now().strftime('%Y%m%d')}.jsonl"
        with open(audit_file, "a") as f:
            f.write(json.dumps(audit_entry) + "\n")
        
        logger.info(f"Audit trail logged to {audit_file}")


def main():
    """Main function for standalone execution."""
    
    print("=" * 80)
    print("AI Agentic SOC - Triage Agent Deployment")
    print("=" * 80)
    print()
    
    # Check for API key
    if not os.getenv("OPENAI_API_KEY"):
        print("Error: OPENAI_API_KEY environment variable not set")
        print("Please configure your .env file")
        sys.exit(1)
    
    try:
        # Initialize agent
        print("Initializing triage agent...")
        agent = TriageAgent()
        print("✓ Triage agent initialized successfully")
        print()
        
        # Load sample alert for testing
        sample_alert_file = Path(__file__).parent.parent / "data" / "alerts" / "sample_alerts.json"
        
        if sample_alert_file.exists():
            print(f"Loading sample alerts from {sample_alert_file}")
            with open(sample_alert_file) as f:
                alerts = json.load(f)
            
            # Triage first alert as demo
            if alerts:
                print(f"\nTriaging sample alert: {alerts[0]['id']}")
                print("-" * 80)
                
                result = agent.triage_alert(alerts[0])
                
                print("\nTriage Result:")
                print(json.dumps(result, indent=2))
                print("-" * 80)
                print()
        
        print("✓ Triage agent deployment completed successfully")
        print()
        print("The agent is ready to triage alerts.")
        print("See data/logs/ for audit trails.")
        
    except Exception as e:
        print(f"✗ Error deploying triage agent: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

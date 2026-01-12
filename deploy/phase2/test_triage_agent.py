#!/usr/bin/env python3
"""
Test Triage Agent

Runs automated tests on the triage agent using sample scenarios.
"""

import sys
import json
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from phase2.deploy_triage_agent import TriageAgent
except ImportError:
    print("Error: Cannot import TriageAgent. Make sure deploy_triage_agent.py is present.")
    sys.exit(1)


def load_test_scenarios():
    """Load test scenarios from sandbox"""
    scenarios_file = Path(__file__).parent.parent / "sandbox" / "test_scenarios.json"
    
    if not scenarios_file.exists():
        print(f"Warning: Test scenarios file not found: {scenarios_file}")
        return []
    
    with open(scenarios_file) as f:
        data = json.load(f)
        return data.get("scenarios", [])


def test_agent_with_scenario(agent, scenario):
    """Test agent with a specific scenario"""
    print(f"\n{'='*80}")
    print(f"Testing Scenario: {scenario['name']}")
    print(f"Description: {scenario['description']}")
    print(f"{'='*80}\n")
    
    results = []
    
    for alert in scenario['alerts']:
        print(f"Processing alert: {alert['id']}")
        result = agent.triage_alert(alert)
        results.append(result)
        
        print(f"  Priority: {result.get('priority', 'unknown')}")
        print(f"  Status: {result.get('status', 'unknown')}")
        print(f"  Execution time: {result.get('execution_time_seconds', 0):.2f}s")
    
    return results


def main():
    """Run tests"""
    print("="*80)
    print("Triage Agent Test Suite")
    print("="*80)
    
    # Check for API key
    import os
    if not os.getenv("OPENAI_API_KEY"):
        print("\nWarning: OPENAI_API_KEY not set. Some tests will be skipped.")
        print("Set OPENAI_API_KEY in .env to run full tests.\n")
        return
    
    try:
        # Initialize agent
        print("\nInitializing triage agent...")
        agent = TriageAgent()
        print("✓ Agent initialized\n")
        
        # Load test scenarios
        scenarios = load_test_scenarios()
        
        if not scenarios:
            print("No test scenarios found. Creating a basic test...")
            test_alert = {
                "id": "TEST-BASIC",
                "type": "Test Alert",
                "severity": "medium",
                "source": "Test",
                "source_ip": "192.168.1.1",
                "destination_ip": "10.0.0.1",
                "user": "testuser",
                "description": "Basic test alert",
                "timestamp": "2026-01-12T12:00:00Z"
            }
            
            print("Testing with basic alert...")
            result = agent.triage_alert(test_alert)
            print(f"\nResult: {json.dumps(result, indent=2)}")
        else:
            # Run all scenarios
            print(f"Found {len(scenarios)} test scenario(s)\n")
            
            for scenario in scenarios:
                test_agent_with_scenario(agent, scenario)
        
        print("\n" + "="*80)
        print("✓ Test suite completed")
        print("="*80)
        
    except Exception as e:
        print(f"\n✗ Test failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()

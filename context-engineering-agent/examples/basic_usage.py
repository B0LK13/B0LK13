"""
Example: Basic Usage of Context Engineering Agent

This example demonstrates:
1. Initializing the CEA
2. Processing a query with context optimization
3. Accessing audit trails and explanations
"""

import asyncio
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from src.main import ContextEngineeringAgent


async def basic_example():
    """Basic query processing example"""
    print("=" * 60)
    print("Example 1: Basic Query Processing")
    print("=" * 60)
    
    # Initialize CEA
    cea = ContextEngineeringAgent(
        llm_provider="openai",
        knowledge_base="./data/knowledge"
    )
    
    # Process a query
    result = await cea.process(
        query="What are the main applications of quantum computing?",
        context={
            "domain": "technology",
            "timeframe": "2024-2026",
            "user_expertise": "intermediate"
        },
        llm_options={
            "model": "gpt-4-turbo",
            "temperature": 0.7,
            "max_tokens": 500
        },
        optimization={
            "compressionEnabled": True,
            "graphAugmentation": False
        }
    )
    
    # Display results
    print(f"\nRequest ID: {result.request_id}")
    print(f"Processing Time: {result.processing_time_ms:.2f}ms\n")
    
    print("LLM Response:")
    print("-" * 60)
    print(result.llm_response)
    print()
    
    print("Context Summary:")
    print("-" * 60)
    print(f"Total contexts retrieved: {result.optimized_context['total_retrieved']}")
    print(f"Contexts used: {result.optimized_context['contexts_used']}")
    print()
    
    print("Audit Trail:")
    print("-" * 60)
    for step in result.audit_trail:
        print(f"  [{step['step']}] {step['action']}: {step['details']}")
    print()


async def graph_augmentation_example():
    """Example with knowledge graph augmentation"""
    print("=" * 60)
    print("Example 2: Query with Graph Augmentation")
    print("=" * 60)
    
    cea = ContextEngineeringAgent(
        llm_provider="openai",
        graph_database="neo4j://localhost:7687"
    )
    
    result = await cea.process(
        query="How does quantum entanglement relate to quantum computing?",
        context={
            "domain": "physics",
            "require_technical_depth": True
        },
        llm_options={
            "model": "gpt-4-turbo",
            "temperature": 0.5
        },
        optimization={
            "compressionEnabled": True,
            "graphAugmentation": True  # Enable graph augmentation
        }
    )
    
    print(f"\nRequest ID: {result.request_id}")
    print(f"Processing Time: {result.processing_time_ms:.2f}ms\n")
    
    print("LLM Response:")
    print("-" * 60)
    print(result.llm_response)
    print()
    
    # In a full implementation, this would show actual graph traversal data
    print("Graph Augmentation:")
    print("-" * 60)
    print("  Entities extracted: [quantum entanglement, quantum computing, qubit]")
    print("  Relationships traversed: 12")
    print("  Additional contexts from graph: 3")
    print()


async def multi_turn_conversation_example():
    """Example of multi-turn conversation with drift detection"""
    print("=" * 60)
    print("Example 3: Multi-Turn Conversation (Simulated)")
    print("=" * 60)
    
    cea = ContextEngineeringAgent(llm_provider="openai")
    
    # Simulate multiple turns
    turns = [
        "What is quantum computing?",
        "What are its main applications?",
        "Tell me about quantum algorithms",
    ]
    
    for i, query in enumerate(turns, 1):
        print(f"\nTurn {i}: {query}")
        print("-" * 60)
        
        result = await cea.process(
            query=query,
            context={
                "conversation_turn": i,
                "maintain_coherence": True
            },
            optimization={
                "driftDetection": True  # Enable drift detection
            }
        )
        
        print(f"Response: {result.llm_response}")
        
        # In full implementation, show drift analysis
        if i > 1:
            print(f"  Drift score: 0.02 (coherent)")
        print()


async def compression_example():
    """Example demonstrating context compression"""
    print("=" * 60)
    print("Example 4: Context Compression")
    print("=" * 60)
    
    cea = ContextEngineeringAgent(llm_provider="openai")
    
    # Simulate a query that would retrieve many contexts
    result = await cea.process(
        query="Comprehensive overview of machine learning techniques",
        context={
            "domain": "AI",
            "depth": "comprehensive"
        },
        llm_options={
            "model": "gpt-4-turbo",
            "max_tokens": 500  # Limited output
        },
        optimization={
            "compressionEnabled": True,
            "compressionMethod": "extractive"
        }
    )
    
    print(f"\nRequest ID: {result.request_id}")
    print()
    
    print("Compression Statistics:")
    print("-" * 60)
    print(f"  Original contexts: {result.optimized_context['total_retrieved']}")
    print(f"  After compression: {result.optimized_context['contexts_used']}")
    print(f"  Compression ratio: {(result.optimized_context['contexts_used'] / result.optimized_context['total_retrieved']):.2%}")
    print()
    
    print("LLM Response:")
    print("-" * 60)
    print(result.llm_response)
    print()


async def main():
    """Run all examples"""
    try:
        await basic_example()
        await graph_augmentation_example()
        await multi_turn_conversation_example()
        await compression_example()
        
        print("=" * 60)
        print("All examples completed successfully!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\nError running examples: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("Context Engineering Agent - Usage Examples")
    print("=" * 60)
    print("\nNote: This is a proof-of-concept with simulated responses.")
    print("Full implementation requires LLM API keys and database setup.\n")
    
    asyncio.run(main())

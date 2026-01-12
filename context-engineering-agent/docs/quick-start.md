# Quick Start Guide - Context Engineering Agent

This guide will help you get started with the Context Engineering Agent (CEA) proof-of-concept implementation.

## Prerequisites

Before you begin, ensure you have:

- **Python 3.10+** or **Node.js 18+**
- **Neo4j** (for knowledge graph) - Optional for initial testing
- **Redis** (for caching) - Optional for initial testing
- **LLM API Keys** (OpenAI, Anthropic, etc.)

## Installation

### Option 1: Python Implementation

```bash
# Navigate to the CEA directory
cd context-engineering-agent

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp config/env.example .env

# Edit .env and add your API keys
nano .env  # or your preferred editor
```

### Option 2: Node.js Implementation

```bash
# Navigate to the CEA directory
cd context-engineering-agent

# Install dependencies
npm install

# Copy environment template
cp config/env.example .env

# Edit .env and add your API keys
nano .env
```

## Configuration

Edit the `.env` file with your credentials:

```bash
# Required for basic functionality
OPENAI_API_KEY=sk-...your-key-here

# Optional for full features
NEO4J_URI=neo4j://localhost:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=your-password

PINECONE_API_KEY=your-pinecone-key
REDIS_HOST=localhost
```

## Running Examples

### Python Examples

```bash
# Run basic usage examples
python examples/basic_usage.py

# The examples demonstrate:
# 1. Basic query processing
# 2. Graph augmentation
# 3. Multi-turn conversation
# 4. Context compression
```

### Quick Test

```python
import asyncio
from src.main import ContextEngineeringAgent

async def quick_test():
    cea = ContextEngineeringAgent(llm_provider="openai")
    
    result = await cea.process(
        query="What is machine learning?",
        context={"domain": "AI"},
        llm_options={"model": "gpt-4-turbo"}
    )
    
    print(result.llm_response)
    print(f"Processing time: {result.processing_time_ms:.2f}ms")

asyncio.run(quick_test())
```

## Setting Up Services (Optional)

### Neo4j (Knowledge Graph)

**Using Docker:**
```bash
docker run -d \
  --name neo4j \
  -p 7474:7474 -p 7687:7687 \
  -e NEO4J_AUTH=neo4j/your-password \
  neo4j:latest
```

**Access Neo4j Browser:** http://localhost:7474

### Redis (Caching)

**Using Docker:**
```bash
docker run -d \
  --name redis \
  -p 6379:6379 \
  redis:latest
```

### Pinecone (Vector Database)

1. Sign up at https://www.pinecone.io/
2. Create a new index:
   - Name: `cea-contexts`
   - Dimensions: `1536` (for OpenAI embeddings)
   - Metric: `cosine`
3. Copy API key to `.env`

## Development Workflow

### 1. Start with Minimal Setup

For initial testing, you only need:
- OpenAI API key
- Python/Node.js environment

The system will work without Neo4j, Redis, or Pinecone (with reduced functionality).

### 2. Add Graph Database

Once you want to test graph augmentation:
```bash
# Start Neo4j
docker-compose up -d neo4j

# Verify connection
python -c "from neo4j import GraphDatabase; print('Neo4j OK')"
```

### 3. Add Vector Database

For production-quality semantic search:
```bash
# Configure Pinecone in .env
PINECONE_API_KEY=your-key
PINECONE_ENVIRONMENT=us-west1-gcp
PINECONE_INDEX_NAME=cea-contexts
```

## Testing

### Run Unit Tests

```bash
# Python
pytest tests/ -v

# Node.js
npm test
```

### Manual Testing

Use the provided examples:

```bash
# Test contextualizer module
python -m src.contextualizer.contextualizer

# Test knowledge graph engine
python -m src.knowledge-graph.graph_engine

# Test LLM integration
python -m src.llm-integration.llm_layer
```

## API Server (Coming Soon)

Start the API server:

```bash
# Python (FastAPI)
uvicorn src.api.server:app --reload --port 8000

# Node.js (Express)
npm run dev
```

Access API documentation: http://localhost:8000/docs

## Monitoring

### View Logs

```bash
# Application logs
tail -f logs/cea.log

# Development debug logs
export CEA_LOG_LEVEL=DEBUG
python examples/basic_usage.py
```

### Metrics (if enabled)

- Prometheus metrics: http://localhost:9090
- Grafana dashboards: http://localhost:3000

## Common Issues

### Issue: "Module not found"

```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

### Issue: "Connection refused" (Neo4j/Redis)

```bash
# Check if services are running
docker ps

# Restart services
docker-compose restart
```

### Issue: "Invalid API key"

- Verify `.env` file has correct keys
- Ensure no extra spaces around keys
- Check API key hasn't expired

### Issue: "Rate limit exceeded"

- CEA respects LLM provider rate limits
- Add delays between requests
- Consider upgrading API tier

## Next Steps

1. **Explore Documentation**: Read `/docs/architecture/overview.md`
2. **Review Phase 1 Research**: See `/docs/phase1/research-findings.md`
3. **Customize Configuration**: Modify settings in `config/`
4. **Add Knowledge**: Populate knowledge base with domain data
5. **Extend Modules**: Implement custom context extractors

## Getting Help

- **Documentation**: `/docs/`
- **Examples**: `/examples/`
- **API Reference**: `/docs/api-reference.md`
- **Development Plan**: `/docs/context-engineering-agent-development-plan.md`

## Production Checklist

Before deploying to production:

- [ ] Set up proper authentication
- [ ] Configure rate limiting
- [ ] Enable monitoring and alerting
- [ ] Set up backup for graph database
- [ ] Implement request queuing
- [ ] Add comprehensive error handling
- [ ] Security audit completed
- [ ] Load testing performed
- [ ] Documentation updated
- [ ] Team training completed

---

**Ready to start?** Run `python examples/basic_usage.py` to see CEA in action!

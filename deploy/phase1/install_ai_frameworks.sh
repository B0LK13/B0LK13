#!/bin/bash

################################################################################
# Phase 1: Install AI Frameworks
#
# Installs AI/ML frameworks and libraries required for agent development.
# - OpenAI SDK
# - LangChain
# - CrewAI
# - Supporting libraries
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Installing AI frameworks and libraries..."
    
    # Activate virtual environment
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Core AI frameworks
    log_info "Installing OpenAI SDK..."
    pip install openai>=1.0.0
    
    log_info "Installing LangChain..."
    pip install langchain>=0.1.0
    pip install langchain-openai
    pip install langchain-community
    
    log_info "Installing CrewAI..."
    pip install crewai>=0.1.0
    pip install crewai-tools
    
    # Additional LLM providers (optional)
    log_info "Installing additional LLM providers..."
    pip install anthropic  # Claude
    pip install google-generativeai  # Gemini
    
    # Agent frameworks and tools
    log_info "Installing agent development tools..."
    pip install langchain-experimental
    pip install tiktoken  # Token counting
    pip install chromadb  # Vector database
    pip install faiss-cpu  # Vector search
    
    # Prompt engineering and validation
    log_info "Installing prompt engineering tools..."
    pip install guidance
    pip install jsonschema
    
    # Data processing
    log_info "Installing data processing libraries..."
    pip install pandas
    pip install numpy
    pip install scikit-learn
    
    # API and web frameworks
    log_info "Installing API frameworks..."
    pip install fastapi
    pip install uvicorn
    pip install pydantic
    pip install httpx
    
    # Async processing
    log_info "Installing async processing libraries..."
    pip install aiohttp
    pip install asyncio
    
    # Save requirements
    log_info "Saving installed packages to requirements.txt..."
    pip freeze > "$DEPLOY_DIR/requirements.txt"
    
    # Verify installations
    log_info "Verifying AI framework installations..."
    python -c "import openai; print(f'OpenAI version: {openai.__version__}')" || log_error "OpenAI import failed"
    python -c "import langchain; print(f'LangChain version: {langchain.__version__}')" || log_error "LangChain import failed"
    python -c "import crewai; print('CrewAI installed successfully')" || log_error "CrewAI import failed"
    
    log_success "AI frameworks installed successfully"
    log_info "Requirements saved to: $DEPLOY_DIR/requirements.txt"
}

main "$@"

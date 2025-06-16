# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Redmine AI Helper Plugin, a Ruby on Rails plugin that adds AI-powered chat functionality to Redmine project management software. It uses a multi-agent architecture with various specialized agents for different tasks like issue management, repository analysis, and wiki content processing.

## Architecture

### Multi-Agent System
The plugin implements a multi-agent architecture where different agents handle specific domains:
- **BaseAgent** (`lib/redmine_ai_helper/base_agent.rb`) - Base class for all agents
- **IssueAgent** - Handles issue-related queries and operations
- **RepositoryAgent** - Manages repository and source code analysis
- **WikiAgent** - Processes wiki content and queries
- **LeaderAgent** - Coordinates multi-step tasks across agents
- **BoardAgent**, **ProjectAgent**, **SystemAgent**, **UserAgent**, **VersionAgent** - Handle their respective domains

### Key Components
- **LLM Providers** (`lib/redmine_ai_helper/llm_client/`) - Abstracts different AI services (OpenAI, Anthropic, Gemini, Azure OpenAI)
- **Tools** (`lib/redmine_ai_helper/tools/`) - Each agent has associated tools for specific operations
- **Vector Search** (`lib/redmine_ai_helper/vector/`) - Qdrant-based vector search for issues and wiki content
- **Chat Room** (`lib/redmine_ai_helper/chat_room.rb`) - Manages conversation state and agent coordination

### Models
- `AiHelperConversation` - Stores chat conversations
- `AiHelperMessage` - Individual messages in conversations
- `AiHelperModelProfile` - AI model configurations
- `AiHelperSetting` - Global plugin settings
- `AiHelperProjectSetting` - Project-specific settings
- `AiHelperVectorData` - Vector embeddings for search
- `AiHelperSummaryCache` - Cached AI-generated summaries

## Development Commands

### Testing
```bash
# Setup test environment
bundle exec rake redmine:plugins:migrate RAILS_ENV=test
bundle exec rake redmine:plugins:ai_helper:setup_scm

# Run all tests
bundle exec rake redmine:plugins:test NAME=redmine_ai_helper
```

### Database
```bash
# Run migrations
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

### Vector Search Setup
```bash
# Generate vector index
bundle exec rake redmine:plugins:ai_helper:vector:generate RAILS_ENV=production

# Register data in vector database
bundle exec rake redmine:plugins:ai_helper:vector:regist RAILS_ENV=production

# Destroy vector data
bundle exec rake redmine:plugins:ai_helper:vector:destroy RAILS_ENV=production
```

## Configuration

### Plugin Configuration
- Main settings managed through `AiHelperSetting` model
- Model profiles configured via `AiHelperModelProfile`
- MCP server config in `config/ai_helper/config.json`
- Langfuse integration config in `config/ai_helper/config.yml`

### Prompt Templates
Agent prompts are stored in YAML files under `assets/prompt_templates/` with support for internationalization (English and Japanese).

## Custom Agent Development

To create custom agents:
1. Inherit from `RedmineAiHelper::BaseAgent`
2. Create associated tools inheriting from `RedmineAiHelper::BaseTools`
3. Place files anywhere in Redmine and require them
4. See `example/redmine_fortune/` for a complete example

## Key Files for Development

- `init.rb` - Plugin initialization and registration
- `lib/redmine_ai_helper/` - Core plugin logic
- `app/controllers/ai_helper_controller.rb` - Main chat interface controller
- `app/views/ai_helper/` - Chat UI templates
- `assets/javascripts/ai_helper.js` - Frontend JavaScript
- `config/routes.rb` - Plugin routes

## Development Guidelines

### Code Style(Ruby)
- Follow Ruby on Rails conventions
- Write comments in English

### Code Style(Javascript)
- Use `let` and `const` instead of `var`
- Don't use jQuery, use vanilla JavaScript
- Write comments in English

### test
- Always add tests for any new features you implement
- Write tests using shoulda
- Use mocks only when absolutely necessary, such as when connecting to external servers

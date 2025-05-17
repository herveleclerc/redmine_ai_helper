# Redmine AI Helper Plugin

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)
[![build](https://github.com/haru/redmine_ai_helper/actions/workflows/build.yml/badge.svg)](https://github.com/haru/redmine_ai_helper/actions/workflows/build.yml)
[![Maintainability](https://qlty.sh/badges/a0cabed6-3c2d-4eb2-a7b0-2cd58e6fdf72/maintainability.svg)](https://qlty.sh/gh/haru/projects/redmine_ai_helper)
[![codecov](https://codecov.io/gh/haru/redmine_ai_helper/graph/badge.svg?token=1HOSGRHVM9)](https://codecov.io/gh/haru/redmine_ai_helper)


- [Redmine AI Helper Plugin](#redmine-ai-helper-plugin)
- [Features](#features)
- [Installation](#installation)
- [Basic Configuration](#basic-configuration)
  - [Plugin Settings](#plugin-settings)
  - [Role and Permission Settings](#role-and-permission-settings)
  - [Project-specific Settings](#project-specific-settings)
- [Advanced Configuration](#advanced-configuration)
  - [MCP Server Settings](#mcp-server-settings)
  - [Vector Search Settings](#vector-search-settings)
    - [AI Helper Settings Page](#ai-helper-settings-page)
    - [Creating the Index](#creating-the-index)
    - [Recreating the Index](#recreating-the-index)
- [Build your own Agent](#build-your-own-agent)
- [Langfuse integration](#langfuse-integration)
- [Important Notice](#important-notice)
- [Contributing](#contributing)
- [Support](#support)
- [Credits](#credits)

The Redmine AI Helper Plugin adds AI chat functionality to Redmine, enhancing project management efficiency through AI-powered support.

# Features

- Adds an AI chat sidebar to the right side of your Redmine interface
- Enables various AI-assisted queries including:
  - Issue search
  - Issue and Wiki content summarization
  - Repository source code explanation
  - Other project and Redmine-related inquiries
- Supports multiple AI models and services
- MCP server integration
- Vector search using Qdrant

![Image](https://github.com/user-attachments/assets/39f61008-45a3-4807-9c1c-57fba4e06835)

# Installation

1. Extract the plugin to your Redmine plugins folder:
   ```bash
   cd {REDMINE_ROOT}/plugins/
   git clone https://github.com/haru/redmine_ai_helper.git
   ```

2. Install required dependencies:
   ```bash
   bundle install
   ```

3. Run database migrations:
   ```bash
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```

4. Restart Redmine:


# Basic Configuration

## Plugin Settings

1. Open the AI Helper settings page from the Administration menu.
2. Create a model profile and fill in the following fields:
   - Type: Choose the AI model type (e.g., OpenAI, Anthropic. Strongly recommend using OpenAI)
   - Name: Enter a name for the model profile
   - Access Key: Enter the API key for the AI service
   - Model name: Specify the AI model name (e.g., gpt-4.1-mini)
3. Select the model profile you created from the dropdown menu and save the settings.


## Role and Permission Settings

1. Go to "Roles and permissions" in the administration menu
2. Configure the AI Helper permissions for each role as needed

## Project-specific Settings

1. Open the settings page for each project where you want to use the plugin
2. Go to the "Modules" tab
3. Enable "AI Helper" by checking the box
4. Click "Save" to apply the changes

# Advanced Configuration

## MCP Server Settings

The "Model Context Protocol (MCP)" is an open standard protocol proposed by Anthropic that allows AI models to interact with external systems such as files, databases, tools, and APIs.
Reference: https://github.com/modelcontextprotocol/servers

The AI Helper Plugin can use the MCP Server to perform tasks, such as sending issue summaries to Slack.

1. Create `config/ai_helper/config.json` under the root directory of Redmine.
2. Configure the MCP server as follows (example for Slack):
   ```json
   {
      "mcpServers": {
         "slack": {
            "command": "npx",
            "args": [
            "-y",
            "@modelcontextprotocol/server-slack"
            ],
            "env": {
            "SLACK_BOT_TOKEN": "xoxb-your-bot-token",
            "SLACK_TEAM_ID": "T01234567"
            }
         }
      }
   }
   ```
3. Restart Redmine.

## Vector Search Settings

Configure settings to perform vector searches for issues using Qdrant.

### AI Helper Settings Page

1. Navigate to the AI Helper settings page.
2. Enable "Enable vector search."
3. Configure Qdrant settings:
   - **URI**: Specify the URL of the Qdrant instance.
   - **API Key**: Provide the API key for Qdrant. Leave this field blank if using a locally hosted Qdrant instance.
   - **Embedding Model**: Specify the embedding model to use, e.g., `text-embedding-3-large`.

### Creating the Index

Run the following command to create the index.

```bash
bundle exec rake redmine:plugins:ai_helper:vector:generate RAILS_ENV=production
```

Registers ticket data into the index. The initial run may take some time.

```bash
bundle exec rake redmine:plugins:ai_helper:vector:regist RAILS_ENV=production
```

Please execute the above commands periodically using cron or a similar tool to reflect ticket updates.

This completes the configuration.

### Recreating the Index

If you change the embedding model, delete the index and recreate it using the following commands.

```bash
bundle exec rake redmine:plugins:ai_helper:vector:destroy RAILS_ENV=production
```

# Build your own Agent

The AI Helper plugin adopts a multi-agent model. You can create your own agent and integrate it into the AI Helper plugin.

To create your own agent, you need to create the following two files:

- **Agent Implementation**
   - A class that inherits from `RedmineAiHelper::BaseAgent`
   - Defines the agent's behavior
- **Tools**
   - A class that inherits from `RedmineAiHelper::BaseTools`
   - Implements the tools used by the agent

Place these files in any location within Redmine and load them.

As an example, there is a plugin called `redmine_fortune` under the `example` directory. Place this plugin in the `plugins` folder of Redmine. This will add a fortune-telling feature to the AI Helper plugin. When you ask, "Tell me my fortune for today," it will return a fortune-telling result.

# Langfuse integration
By integrating with Langfuse, you can track the usage of the AI Helper Plugin. This allows you to monitor the cost of LLM queries and improve prompts effectively.


![Image](https://github.com/user-attachments/assets/35904911-db39-4da7-baf6-a90fe05d9115)

To configure the integration, add the following to `{REDMINE_ROOT}/config/ai_helper/config.yml`:

```yaml
langfuse:
  public_key: "pk-lf-************"
  secret_key: "sk-lf-************"
  endpoint: https://us.cloud.langfuse.com # Change this to match your environment
```

# Important Notice

⚠️ Please note that AI responses may not always be 100% accurate. Users should verify and validate AI-provided information at their own discretion.


# Contributing

I welcome bug reports and feature improvement suggestions through GitHub Issues. Pull requests are also appreciated.

# Support

If you encounter any issues or have questions, please open an issue on GitHub.


# Credits

Developed and maintained by [Haru Iida](https://github.com/haru).

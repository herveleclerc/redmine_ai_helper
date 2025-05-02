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
- Call MCP server
- Vactor search using Qdrant

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
   - Model name: Specify the AI model name (e.g., gpt-3.1-mini)
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

# Important Notice

⚠️ Please note that AI responses may not always be 100% accurate. Users should verify and validate AI-provided information at their own discretion.


# Contributing

I welcome bug reports and feature improvement suggestions through GitHub Issues. Pull requests are also appreciated.

# Support

If you encounter any issues or have questions, please open an issue on GitHub.


# Credits

Developed and maintained by [Haru Iida](https://github.com/haru).

# Redmine AI Helper Plugin

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.md)
[![Maintainability](https://qlty.sh/badges/a0cabed6-3c2d-4eb2-a7b0-2cd58e6fdf72/maintainability.svg)](https://qlty.sh/gh/haru/projects/redmine_ai_helper)
[![codecov](https://codecov.io/gh/haru/redmine_ai_helper/graph/badge.svg?token=1HOSGRHVM9)](https://codecov.io/gh/haru/redmine_ai_helper)


The Redmine AI Helper Plugin adds AI chat functionality to Redmine, enhancing project management efficiency through AI-powered support.

## Features

- Adds an AI chat sidebar to the right side of your Redmine interface
- Enables various AI-assisted queries including:
  - Issue search
  - Issue and Wiki content summarization
  - Repository source code explanation
  - Other project and Redmine-related inquiries

## Installation

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


## Configuration

### Plugin Settings

1. Navigate to the Plugin settings in Redmine administration
2. Open the configuration page for "Redmine AI Helper Plugin"
3. Configure the following settings:
   - API Key: Your AI service API key
   - Organization: Your organization ID
   - Model: The AI model to use
   - URI Base: Base URI for API endpoints

### Role and Permission Settings

1. Go to "Roles and permissions" in the administration menu
2. Configure the AI Helper permissions for each role as needed

### Project-specific Settings

1. Open the settings page for each project where you want to use the plugin
2. Go to the "Modules" tab
3. Enable "AI Helper" by checking the box
4. Click "Save" to apply the changes

## Important Notice

⚠️ Please note that AI responses may not always be 100% accurate. Users should verify and validate AI-provided information at their own discretion.


## Contributing

I welcome bug reports and feature improvement suggestions through GitHub Issues. Pull requests are also appreciated.

## Support

If you encounter any issues or have questions, please open an issue on GitHub.


## Credits

Developed and maintained by [Haru Iida](https://github.com/haru).

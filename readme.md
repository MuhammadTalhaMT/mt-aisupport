
# AI Support
An intelligent AI-powered support system for FiveM servers using Google's Gemini API.

## Features
- 🤖 AI-powered responses using Gemini Pro
- 🐛 Structured bug reporting system
- 📍 Interactive location marking
- 💬 Natural conversation handling
- 🌙 Dark/Light theme support
- 📋 Copy-to-clipboard functionality
- ⚡ Quick action buttons
- 🔄 Context-aware responses
- 📝 Markdown support
- 💾 Chat history persistence

## Installation

1. Download the resource
2. Add to your resources folder
3. Add to server.cfg:
```
ensure mt-support
```
4. Configure your `config.lua`
5. Get a FREE Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

## Configuration

### Essential Settings
```lua
Config.GeminiApiKey = 'YOUR_API_KEY' -- Required
Config.DiscordWebhook = 'YOUR_WEBHOOK' -- Optional, for bug reports
```

### Basic Settings
```lua
Config.Command = 'support'    -- Command to open support menu
Config.Key = 'F9'            -- Keybind to open menu
Config.Title = 'AI Support'  -- Window title
Config.EnableKeyMapping = true
```

### Server Information
Configure your server details in `config.lua`:
- Server name, description, and max slots
- Important locations with coordinates
- Server rules and features
- FAQ entries
- Restricted information

## Usage

### Opening the Menu
- Use the configured command (`/support` by default)
- Press the keybind (`F9` by default)

### Features

#### Bug Reporting
The system guides users through structured bug reports:
1. Category selection
2. Bug description
3. Steps to reproduce
4. Additional information
5. Confirmation

#### Location Marking
AI can mark locations on the map when users ask for directions:
```
User: "Where is the hospital?"
AI: "The hospital is located downtown. I'll mark it for you!"
```

#### FAQ System
Configure common questions and answers in `config.lua`:
```lua
Config.FAQ = {
    {
        question = "How do I get a job?",
        answer = "Visit the job center at Legion Square..."
    }
}
```

## Customization

### Themes
- Supports dark and light themes
- User preference is saved
- Customizable colors in `style.css`

### Quick Action Buttons
Configure quick action buttons in `index.html`:
```html
<button class="quick-prompt-btn" data-prompt="report bug">
    <i class="fas fa-bug"></i>
    Report Bug
</button>
```

### API Integration
The system uses Google's Gemini API for natural language processing:
- Requests are rate-limited
- Responses are context-aware
- System prompts guide AI behavior

## Dependencies
- FiveM server
- Google Gemini API key
- Discord webhook (optional)

## License
MIT License - Feel free to modify and distribute as needed.

## Support
For issues and feature requests, please use the GitHub issue tracker.

## Credits
- Google Gemini API for natural language processing
- FontAwesome for icons
- FiveM community for inspiration and support
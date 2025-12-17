
# make-ai-project-container

A PowerShell utility to instantly "AI-Enable" any project. It generates a VS Code Dev Container configured with the CLI tools of your choice (GitHub Copilot, Google Gemini, Claude Code, or OpenAI Codex).

## Prerequisites

- **Windows 10/11** (with PowerShell)
    
- **WSL**
    
- **VS Code** with the _Dev Containers_ extension installed.
    

## Installation

1. Download or save the script `make-ai-project-container.ps1`.
    
2. Open PowerShell in the folder containing the script.
    
3. Allow script execution (if not already enabled):
    
    PowerShell
    
    ```
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```
    

## Usage

### 1. Create a New Project

To start a fresh project from scratch:

PowerShell

```
.\make-ai-project-container.ps1 my-new-app
```

_Creates a folder named `my-new-app` and sets up the container inside it._

### 2. Enable Current Directory

To add AI tools to the folder you are currently in:

PowerShell

```
.\make-ai-project-container.ps1 .
```

### 3. Enable Existing Project

To target a specific legacy project elsewhere on your drive:

PowerShell

```
.\make-ai-project-container.ps1 C:\path\to\existing-app
```

---

## The Interactive Menu

Once the script runs, you will see a toggle menu:

Plaintext

```
==========================================
   CONFIGURE AI DEVELOPMENT ENVIRONMENT   
==========================================
Instructions:
 • Press number keys (1-4) to toggle tools.
 • Press ENTER to confirm and build.

 [1] [x] GitHub Copilot CLI
 [2] [ ] Google Gemini CLI
 [3] [ ] Claude Code CLI
 [4] [ ] OpenAI Codex (CLI)
```

- **Press `1`, `2`, `3`, or `4`** on your keyboard to instantly toggle a tool on or off.
    
- **Press `ENTER`** when you are happy with the selection.
    

## Post-Installation Steps

1. Open the project folder in VS Code (`code .`).
    
2. When prompted by the popup **"Folder contains a Dev Container configuration file..."**, click **Reopen in Container**.
    
3. Once the container builds and the terminal opens, **authenticate your tools**:
    

|**Tool**|**Command**|**Notes**|
|---|---|---|
|**GitHub Copilot**|`gh auth login`|Followed by `gh extension install github/gh-copilot`|
|**Google Gemini**|`gemini login`|Requires Google account|
|**Claude**|`claude login`|Requires Anthropic account|
|**Codex**|`openai api key set`|Requires OpenAI API Key|

## Troubleshooting

"Script cannot be loaded because running scripts is disabled..."

Run the Set-ExecutionPolicy command listed in the Installation section above.

"dpkg not found" error

Ensure you are using the latest version of this script. Older versions had issues with variable expansion; the current version strictly handles Linux commands inside the Dockerfile generation.

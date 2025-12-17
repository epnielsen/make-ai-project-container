<#
.SYNOPSIS
Generates a VS Code Dev Container configured with selectable AI CLI tools.
Features an interactive menu to toggle Gemini, Copilot, Claude, and Codex.

.EXAMPLE
.\make-ai-project-container.ps1 my-new-bot
.\make-ai-project-container.ps1 .
.\make-ai-project-container.ps1 C:\Projects\LegacyApp
#>

param (
    [Parameter(Position=0, Mandatory=$true, HelpMessage="Enter project path (or '.' for current dir)")]
    [string]$Target
)

# --- 1. Define Available AI Tools ---
$tools = @(
    @{ Name = "GitHub Copilot CLI";   Id = "copilot"; Selected = $true;  InstallCmd = "npm install -g @github/copilot";                                    AuthCmd = "gh auth login && gh extension install github/gh-copilot" }
    @{ Name = "Google Gemini CLI";    Id = "gemini";  Selected = $false; InstallCmd = "npm install -g @google/gemini-cli";                                 AuthCmd = "gemini login" }
    @{ Name = "Claude Code CLI";      Id = "claude";  Selected = $false; InstallCmd = "npm install -g @anthropic-ai/claude-code";                          AuthCmd = "claude login" }
    @{ Name = "OpenAI Codex (CLI)";   Id = "codex";   Selected = $false; InstallCmd = "npm install -g openai";                                             AuthCmd = "openai api key set ..." }
)

# --- 2. Interactive Menu Logic ---
function Show-Menu {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "   CONFIGURE AI DEVELOPMENT ENVIRONMENT   " -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "`nInstructions:" -ForegroundColor Gray
    Write-Host " • Press number keys (1-4) to toggle tools."
    Write-Host " • Press ENTER to confirm and build."
    Write-Host " • (Mouse clicks are not supported)" -ForegroundColor DarkGray
    Write-Host "`n------------------------------------------"
    
    for ($i = 0; $i -lt $tools.Count; $i++) {
        $num = $i + 1
        $tool = $tools[$i]
        
        if ($tool.Selected) {
            Write-Host " [$num] [x] $($tool.Name)" -ForegroundColor Green
        } else {
            Write-Host " [$num] [ ] $($tool.Name)" -ForegroundColor Gray
        }
    }
    Write-Host "------------------------------------------"
    Write-Host "`nReady? Press [ENTER] to build." -ForegroundColor Cyan
}

# The Interactive Loop
$finished = $false
while (-not $finished) {
    Show-Menu
    
    # Read a single key press
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    switch ($key.VirtualKeyCode) {
        13 { $finished = $true } # Enter Key
        49 { $tools[0].Selected = -not $tools[0].Selected } # Key '1'
        50 { $tools[1].Selected = -not $tools[1].Selected } # Key '2'
        51 { $tools[2].Selected = -not $tools[2].Selected } # Key '3'
        52 { $tools[3].Selected = -not $tools[3].Selected } # Key '4'
        # Numpad support
        97 { $tools[0].Selected = -not $tools[0].Selected } 
        98 { $tools[1].Selected = -not $tools[1].Selected } 
        99 { $tools[2].Selected = -not $tools[2].Selected } 
        100 { $tools[3].Selected = -not $tools[3].Selected }
    }
}

# Filter down to selection
$selectedTools = $tools | Where-Object { $_.Selected }
if ($selectedTools.Count -eq 0) {
    Write-Host "`nNo tools selected. Exiting." -ForegroundColor Red
    exit
}

# --- 3. Resolve Path & Create Directory ---
$targetPath = $null
$isNewProject = $false

if (Test-Path -Path $Target) {
    $targetPath = Resolve-Path $Target
    Write-Host "`nTargeting existing directory: $targetPath" -ForegroundColor Cyan
} else {
    Write-Host "`nCreating new project directory: '$Target'..." -ForegroundColor Green
    $newItem = New-Item -ItemType Directory -Force -Path $Target
    $targetPath = $newItem.FullName
    $isNewProject = $true
}

# --- 4. Conflict Check ---
$devContainerPath = Join-Path -Path $targetPath -ChildPath ".devcontainer"
if ((Test-Path -Path $devContainerPath) -and (-not $isNewProject)) {
    Write-Host "WARNING: A .devcontainer already exists." -ForegroundColor Yellow
    $choice = Read-Host "[A]bort, [O]verwrite, or [B]ackup?"
    switch ($choice.ToUpper()) {
        "A" { exit }
        "O" { Remove-Item -Path $devContainerPath -Recurse -Force }
        "B" { Rename-Item -Path $devContainerPath -NewName ".devcontainer.bak.$(Get-Date -Format 'yyyyMMdd-HHmm')" }
    }
}
if (-not (Test-Path -Path $devContainerPath)) { New-Item -ItemType Directory -Force -Path $devContainerPath | Out-Null }

# --- 5. Build Dockerfile ---
$installCommands = ""
foreach ($tool in $selectedTools) {
    $installCommands += "`n# Install $($tool.Name)`nRUN $($tool.InstallCmd)"
}

# GitHub CLI Requirement Block (Only if Copilot is chosen)
$ghInstallBlock = ""
if ($selectedTools.Id -contains "copilot") {
    $ghInstallBlock = @"
# Install GitHub CLI (Required for Copilot)
RUN type -p curl >/dev/null || (apt update && apt install curl -y) \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=`$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y
"@
}

$dockerfileContent = @"
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Base Setup
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs python3-pip
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

$ghInstallBlock

$installCommands

# User Setup
USER vscode
RUN uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
ENV PATH="/home/vscode/.local/bin:`$PATH"
"@

# --- 6. Build DevContainer JSON ---
$postCreateCmd = "echo '--- AUTHENTICATION ---' && " + (($selectedTools.AuthCmd) -join " && ")

# Dynamic extensions
$extensions = @("ms-python.python")
if ($selectedTools.Id -contains "copilot") { $extensions += "GitHub.copilot"; $extensions += "GitHub.copilot-chat" }
if ($selectedTools.Id -contains "gemini")  { $extensions += "Google.gemini-code-assist" }

$extensionsJson = $extensions | ConvertTo-Json -Compress

$defaultName = Split-Path -Path $targetPath -Leaf
$userContainerName = Read-Host "`nEnter Container Name [Default: $defaultName]"
if ([string]::IsNullOrWhiteSpace($userContainerName)) { $userContainerName = $defaultName }

$devcontainerContent = @"
{
  "name": "$userContainerName (AI)",
  "build": { "dockerfile": "Dockerfile" },
  "remoteUser": "vscode",
  "features": { "ghcr.io/devcontainers/features/git:1": {} },
  "customizations": {
    "vscode": { "extensions": $extensionsJson }
  },
  "postCreateCommand": "$postCreateCmd"
}
"@

# --- 7. Write Files ---
Set-Content -Path "$devContainerPath\Dockerfile" -Value $dockerfileContent
Set-Content -Path "$devContainerPath\devcontainer.json" -Value $devcontainerContent

Write-Host "`nSuccess! Configured '$userContainerName' with:" -ForegroundColor Green
$selectedTools | ForEach-Object { Write-Host " - $($_.Name)" }

param (
    [string]$Manager,
    [string]$AgentName
)

# Set paths and URLs
$installerUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.12.0-1.msi"
$installerPath = "$env:TEMP\wazuh-agent.msi"

# Download the Wazuh agent installer
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Install the agent silently with parameters
Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /q WAZUH_MANAGER=$Manager WAZUH_AGENT_NAME=$AgentName" -Wait

# Start the Wazuh agent service
Start-Service -Name WazuhSvc

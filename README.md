# BGInfo Configurations

This folder contains the BGInfo configuration files used by BGInfo AutoDeploy.

Planned configurations:

- Workstation.bgi - Windows 10/11 workstations
- Server.bgi - Windows Server systems

The deployment script automatically selects the appropriate configuration according to the detected operating system.


to used this script in powershell:

irm "https://raw.githubusercontent.com/Ldmat673/bginfo-autodeploy/main/Install.ps1" | iex

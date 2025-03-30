# 📖 Microsoft Graph Console GUI Search Tool

Welcome to the **Microsoft Graph Console GUI Search Tool**! This interactive PowerShell function allows you to search and view detailed information for various Microsoft 365 and Azure AD objects through a friendly console-based GUI.

## 🚀 Overview

![Demo](https://raw.githubusercontent.com/Jorgeasaurus/MgConsoleGuiGraphSearch/main/MgConsoleGuiGraphSearchDemo.gif)

Quickly search and explore Microsoft 365 and Azure AD objects using an intuitive console-based GUI interface. The tool simplifies the process of finding and viewing detailed information about various Microsoft Graph resources.


This tool provides an interactive console-based GUI using **Out-ConsoleGridView** that enables you to search for and display full details of Microsoft Graph objects such as:

- 👤 **Users**
- 👥 **Groups**
- 💻 **Devices**
- 📱 **Mobile Apps**
- 🔐 **Service Principals**
- ⚙️ **Settings Catalog Policies**
- 📄 **Configuration Profiles**

It leverages the Microsoft Graph Beta API endpoints and requires appropriate permissions for each object type.

## 🔧 Prerequisites

Before using this tool, please ensure you have the following installed:

- **Microsoft.Graph.Beta** PowerShell module  
  (Install using: `Install-Module Microsoft.Graph.Beta`)
- **Microsoft.PowerShell.ConsoleGuiTools** module  
  (Install using: `Install-Module Microsoft.PowerShell.ConsoleGuiTools`)
- PowerShell version 6.0 or later

Also, ensure you have connected to Microsoft Graph with the required scopes/permissions, for example:

- **User:** `User.Read.All`
- **Group:** `Group.Read.All`
- **Device:** `Device.Read.All`
- **MobileApp:** `DeviceManagementApps.Read.All`
- **ServicePrincipal:** `Application.Read.All`
- **SettingsCatalog / ConfigProfile:** `DeviceManagementConfiguration.Read.All`

## ⚙️ How It Works
1. **Import the Function**
   ```powershell
   . .\Invoke-MgConsoleGuiGraphSearch.ps1
   # Or with full path
   . "C:\Path\To\Invoke-MgConsoleGuiGraphSearch.ps1"
   ```

2. **Connect to Microsoft Graph:**
   Before running the search tool, connect to Microsoft Graph using:
   ```powershell
   Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Device.Read.All", "DeviceManagementApps.Read.All", "Application.Read.All", "DeviceManagementConfiguration.Read.All"
   ```
3. **Select an Object Type:**
   Use the `-ObjectType` parameter to specify the type of object you want to search for. Valid values include:
   - `User`
   - `Group`
   - `Device`
   - `MobileApp`
   - `ServicePrincipal`
   - `SettingsCatalog`
   - `ConfigProfile`

4. **Optional Search:**
   Provide a search string using the `-Search` parameter to filter results. If no search string is provided, the function retrieves all items for the selected object type.

5. **Interactive Selection:**
   A grid view appears, showing a subset of common properties for quick selection. Once you select one or more items, the tool retrieves and displays the full details of the selected objects.

## 📚 Usage Examples

### List All Users
```powershell
Invoke-MgConsoleGuiGraphSearch -ObjectType User
```

### Search for Groups Containing "IT"
```powershell
Invoke-MgConsoleGuiGraphSearch -ObjectType Group -Search "IT"
```

### Search for Devices Running Windows
```powershell
Invoke-MgConsoleGuiGraphSearch -ObjectType Device -Search "Windows"
```

### List All Mobile Apps
```powershell
Invoke-MgConsoleGuiGraphSearch -ObjectType MobileApp
```

### Search for Service Principals with "Microsoft"
```powershell
Invoke-MgConsoleGuiGraphSearch -ObjectType ServicePrincipal -Search "Microsoft"
```

### List Settings Catalog Policies
```powershell
Invoke-MgConsoleGuiGraphSearch -ObjectType SettingsCatalog
```

### Search Configuration Profiles (e.g., for macOS)
```powershell
Invoke-MgConsoleGuiGraphSearch -ObjectType ConfigProfile -Search "MacOS"
```

## 🔗 Useful Links

- [Microsoft Graph API Overview (Beta)](https://learn.microsoft.com/graph/api/overview?view=graph-rest-beta) 🌐
- [ConsoleGuiTools GitHub Repository](https://github.com/PowerShell/ConsoleGuiTools) 🚀

## 🎉 Conclusion

This tool simplifies searching through Microsoft Graph objects with an interactive and user-friendly console GUI. Enjoy exploring your Microsoft 365 and Azure AD data! 😄

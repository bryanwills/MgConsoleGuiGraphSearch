<#
.SYNOPSIS
    Interactive Microsoft Graph search tool using console GUI for various Microsoft 365 and Azure AD object types.

.DESCRIPTION
    This function provides an interactive console-based GUI interface to search and view details of various Microsoft Graph objects.
    It supports different object types including Users, Groups, Devices, Mobile Apps, Service Principals, Settings Catalog policies,
    and Configuration Profiles. The function utilizes Microsoft Graph Beta API endpoints and requires appropriate permissions.

.PARAMETER ObjectType
    Specifies the type of object to search for. Valid values include:
    - "User": Microsoft 365 users
    - "Group": Microsoft 365 groups
    - "Device": Devices managed in Microsoft Endpoint Manager
    - "MobileApp": Mobile apps managed in Microsoft Endpoint Manager
    - "ServicePrincipal": Service principals in Azure AD
    - "SettingsCatalog": Settings catalog policies in Microsoft Endpoint Manager
    - "ConfigProfile": Configuration profiles in Microsoft Endpoint Manager

.PARAMETER Search
    Optional search string to filter results. Search behavior varies by object type:
    - Users/Groups: Supports server-side search
    - Devices: Supports server-side search
    - MobileApps/ServicePrincipals: Uses client-side filtering
    - SettingsCatalog/ConfigProfile: Uses OData filtering

.EXAMPLE
    Invoke-MgConsoleGuiGraphSearch -ObjectType User
    Shows all users in an interactive grid view

.EXAMPLE
    Invoke-MgConsoleGuiGraphSearch -ObjectType Group -Search "IT"
    Shows groups containing "IT" in their display name

.NOTES
    Prerequisites:
    - Microsoft.Graph PowerShell SDK (Beta profile)
    - Microsoft.PowerShell.ConsoleGuiTools module
    - Appropriate Microsoft Graph permissions based on object type
    
    Required Permissions:
    - User: User.Read.All
    - Group: Group.Read.All
    - Device: Device.Read.All
    - MobileApp: DeviceManagementApps.Read.All
    - ServicePrincipal: Application.Read.All
    - SettingsCatalog: DeviceManagementConfiguration.Read.All
    - ConfigProfile: DeviceManagementConfiguration.Read.All

.LINK
    https://learn.microsoft.com/graph/api/overview?view=graph-rest-beta
    https://github.com/PowerShell/ConsoleGuiTools
#>

#requires -modules Microsoft.PowerShell.ConsoleGuiTools
#requires -version 6.0

Function Invoke-MgConsoleGuiGraphSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        # Object types and their purposes:
        # "User" - Represents Microsoft 365 users.
        # "Group" - Represents Microsoft 365 groups.
        # "Device" - Represents devices managed in Microsoft Endpoint Manager.
        # "MobileApp" - Represents mobile apps managed in Microsoft Endpoint Manager.
        # "ServicePrincipal" - Represents service principals in Azure AD.
        # "SettingsCatalog" - Represents settings catalog policies in Microsoft Endpoint Manager.
        # "ConfigProfile" - Represents configuration profiles in Microsoft Endpoint Manager.
        [ValidateSet("User", "Group", "Device", "MobileApp", "ServicePrincipal", "SettingsCatalog", "ConfigProfile")]
        [string]$ObjectType,

        [Parameter(Mandatory = $false)]
        [string]$Search  # Search string is optional
    )

    Function IsNullOrWhitespace {
        param([string]$InputString)
        return [string]::IsNullOrEmpty($InputString) -or $InputString.Trim() -eq ""
    }

    $noSearch = IsNullOrWhitespace $Search

    # Check if the required Microsoft Graph module is loaded
    $requiredCommand = switch ($ObjectType) {
        "User" { "Get-MgBetaUser" }
        "Group" { "Get-MgBetaGroup" }
        "Device" { "Get-MgBetaDevice" }
        "MobileApp" { "Get-MgBetaDeviceAppManagementMobileApp" }
        "ServicePrincipal" { "Get-MgBetaServicePrincipal" }
        "SettingsCatalog" { "Get-MgBetaDeviceManagementConfigurationPolicy" }
        "ConfigProfile" { "Get-MgBetaDeviceManagementDeviceConfiguration" }
    }

    if (-not (Get-Command $requiredCommand -ErrorAction SilentlyContinue)) {
        Write-Error "The required command '$requiredCommand' for object type '$ObjectType' is not available. Please ensure the Microsoft Graph module is installed and imported."
        return
    }
    if (-not (Get-Command Out-ConsoleGridView -ErrorAction SilentlyContinue)) {
        Write-Error "The required command 'Out-ConsoleGridView' is not available. Please ensure the Microsoft.PowerShell.ConsoleGuiTools module is installed and imported."
        return
    }
    # Check if the user has the required permissions to access the specified object type
    $permissions = switch ($ObjectType) {
        "User" { "User.Read.All" }
        "Group" { "Group.Read.All" }
        "Device" { "Device.Read.All" }
        "MobileApp" { "DeviceManagementApps.Read.All" }
        "ServicePrincipal" { "Application.Read.All" }
        "SettingsCatalog" { "DeviceManagementConfiguration.Read.All" }
        "ConfigProfile" { "DeviceManagementConfiguration.Read.All" }
    }
    
    $context = Get-MgContext
    if (-not $context) {
        Write-Error "Not connected to Microsoft Graph. Please connect using Connect-MgGraph."
        return
    }
    
    if (-not $context.Scopes.Contains($permissions)) {
        Write-Error "You do not have the required permission: $permissions. Current scopes: $($context.Scopes -join ', ')"
        return
    }

    # Retrieve data from Microsoft Graph based on object type and search input
    switch ($ObjectType) {
        "User" {
            if ( $noSearch ) {
                # No search term provided – retrieve all users
                $items = Get-MgBetaUser -All
            } else {
                # Use server-side search to find matching users (reduces API payload)
                $items = Get-MgBetaUser -Search "displayName:$Search" -All -ConsistencyLevel eventual
            }
        }
        "Group" {
            if ( $noSearch ) {
                $items = Get-MgBetaGroup -All
            } else {
                $items = Get-MgBetaGroup -Search "displayName:$Search" -All -ConsistencyLevel eventual

            }
        }
        "Device" {
            if ( $noSearch ) {
                $items = Get-MgBetaDevice -All -Select "DisplayName,Id,OperatingSystem,OperatingSystemVersion,Model,Manufacturer" | Select-Object -Property DisplayName, Id, OperatingSystem, OperatingSystemVersion, Model, Manufacturer
            } else {
                $items = Get-MgBetaDevice -Search "displayName:$search" -ConsistencyLevel eventual | Select-Object -Property DisplayName, Id, OperatingSystem, OperatingSystemVersion, Model, Manufacturer
            }
        }
        "MobileApp" {
            if ( $noSearch ) {
                $items = Get-MgBetaDeviceAppManagementMobileApp -All

            } else {
                # Applications don't support -Search; use filter or client-side filtering
                $items = Get-MgBetaDeviceAppManagementMobileApp -Search "displayName:$search" -ConsistencyLevel eventual
                # Alternatively, use an OData filter for startsWith if available:
                # $items = Get-MgBetaDeviceAppManagementMobileApp -Filter "startsWith(displayName,'$Search')" -All
            }
        }
        "ServicePrincipal" {
            if ( $noSearch ) {
                $items = Get-MgBetaServicePrincipal -All 
            } else {
                # Service principals also don't support direct -Search in Graph API
                $items = Get-MgBetaServicePrincipal -Search "displayName:$search" -ConsistencyLevel eventual
            }
        }
        "SettingsCatalog" {
            if ( $noSearch ) {
                $items = Get-MgBetaDeviceManagementConfigurationPolicy -All

            } else {
                # Use an OData filter to search within settings catalog items if supported
                $items = Get-MgBetaDeviceManagementConfigurationPolicy -All | ? Name -like "*$search*"
            }
        }
        "ConfigProfile" {
            if ( $noSearch ) {
                $items = Get-MgBetaDeviceManagementDeviceConfiguration -All
            } else {
                # Use an OData filter to search within configuration profiles
                $items = Get-MgBetaDeviceManagementDeviceConfiguration -All | ?  DisplayName -like "*$search*"
            }
        }    
    }
    # Define common properties to show in the grid view for each object type
    $commonProperties = switch ($ObjectType) {
        "User" { "DisplayName", "Id", "Mail", "accountEnabled", "UserPrincipalName", "UserType" }
        "Group" { "DisplayName", "Id", "MailEnabled", "MailNickname", "SecurityEnabled" }
        "Device" { "DisplayName", "Id", "OperatingSystem", "OperatingSystemVersion", "Model", "Manufacturer" }
        "MobileApp" { "DisplayName", "Id", "Publisher", "AppType", "IsFeatured", "IsAssigned" }
        "ServicePrincipal" { "DisplayName", "Id", "AppId" }
        "SettingsCatalog" { "Name", "Id", "Description" }
        "ConfigProfile" { "displayName", "Id", "Description", "Version" }
        default { "*" }
    }

    # Limit the items shown in the grid view to common properties
    $gridItems = $items | Select-Object -Property $commonProperties

    $title = "Select a $ObjectType" + $(if (-not $noSearch) { " matching '$Search'" } else { "" })
    $selections = $gridItems | Out-ConsoleGridView -Title $title -OutputMode "Multiple"

    # Helper function to retrieve the full object details
    function Get-FullObject {
        param(
            [string]$Type,
            [string]$Id
        )
        switch ($Type) {
            "User" { return Get-MgBetaUser -UserId $Id }
            "Group" { return Get-MgBetaGroup -GroupId $Id }
            "Device" { return Get-MgBetaDevice -DeviceId $Id }
            "MobileApp" { return Get-MgBetaDeviceAppManagementMobileApp -MobileAppId $Id }
            "ServicePrincipal" { return Get-MgBetaServicePrincipal -ServicePrincipalId $Id }
            "SettingsCatalog" { return Get-MgBetaDeviceManagementConfigurationPolicy -DeviceManagementConfigurationPolicyId $Id }
            "ConfigProfile" { return Get-MgBetaDeviceManagementDeviceConfiguration -DeviceConfigurationId $Id }
            default { return $null }
        }
    }

    if ($selections) {
        if ($selections -is [System.Collections.IEnumerable] -and $selections.Count -gt 1) {
            foreach ($selection in $selections) {
                if (-not $selection.PSObject.Properties["Id"]) {
                    Write-Warning "Selected $ObjectType object does not contain an 'Id' property."
                    continue
                }
                $result = Get-FullObject -Type $ObjectType -Id $selection.Id
                $result | Format-List -Property * -Force
            }
        } else {
            $selection = $selections
            if (-not $selection.PSObject.Properties["Id"]) {
                Write-Warning "Selected $ObjectType object does not contain an 'Id' property."
                return
            }
            $selection = Get-FullObject -Type $ObjectType -Id $selection.Id
            $selection | Format-List -Property * -Force
        }
    }
} 

# Prevent execution if the script is run directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Write-Host "This script is intended to be used as a function. Please import it into your PowerShell session."
    Write-Host "Usage: .\Invoke-MgConsoleGuiGraphSearch.ps1"
    Write-Host "Then call the function with appropriate parameters."
    Write-Host "Example: Invoke-MgConsoleGuiGraphSearch -ObjectType User -Search 'Jorge'"
    Write-Host "Exiting script."
}
Exit 0

# Sample commands:
# Connect to Microsoft Graph with required permissions
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Device.Read.All", "DeviceManagementApps.Read.All", "Application.Read.All", "DeviceManagementConfiguration.Read.All"

# Search for users
Invoke-MgConsoleGuiGraphSearch -ObjectType User -Search "Jorge"

# List all groups
Invoke-MgConsoleGuiGraphSearch -ObjectType Group

# Search for devices running Windows
Invoke-MgConsoleGuiGraphSearch -ObjectType Device -Search "JORGEASAURUS-28"

# List all mobile apps
Invoke-MgConsoleGuiGraphSearch -ObjectType MobileApp

# Search for service principals
Invoke-MgConsoleGuiGraphSearch -ObjectType ServicePrincipal -Search "Microsoft"

# List settings catalog policies
Invoke-MgConsoleGuiGraphSearch -ObjectType SettingsCatalog

# Search configuration profiles
Invoke-MgConsoleGuiGraphSearch -ObjectType ConfigProfile -Search "MacOS"
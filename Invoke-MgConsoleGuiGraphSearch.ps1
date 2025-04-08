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
    - AppProtection: DeviceManagementApps.Read.All
    - CompliancePolicy: DeviceManagementConfiguration.Read.All
    - DiscoveredApps: DeviceManagementManagedDevices.Read.All
    - Note: The script checks for the required permissions and prompts the user if they are missing.
.VERSION
    0.1.0
    Initial version of the script.
.LINK
    https://learn.microsoft.com/graph/api/overview?view=graph-rest-beta
    https://github.com/PowerShell/ConsoleGuiTools
#>

#requires -modules Microsoft.PowerShell.ConsoleGuiTools
#requires -version 6.0

Function Invoke-MgConsoleGuiGraphSearch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        # Object types and their purposes:
        # "User" - Represents Microsoft 365 users.
        # "Group" - Represents Microsoft 365 groups.
        # "Device" - Represents devices managed in Microsoft Endpoint Manager.
        # "MobileApp" - Represents mobile apps managed in Microsoft Endpoint Manager.
        # "ServicePrincipal" - Represents service principals in Azure AD.
        # "SettingsCatalog" - Represents settings catalog policies in Microsoft Endpoint Manager.
        # "ConfigProfile" - Represents configuration profiles in Microsoft Endpoint Manager.
        # "AppProtection" - Represents app protection policies in Microsoft Endpoint Manager.
        # "CompliancePolicy" - Represents compliance policies in Microsoft Endpoint Manager.
        [ValidateSet(
            "User",
            "Group", 
            "Device", 
            "MobileApp", 
            "ServicePrincipal", 
            "SettingsCatalog", 
            "ConfigProfile", 
            "AppProtection", 
            "CompliancePolicy",
            "DiscoveredApps"
        )]
        [string]$ObjectType,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$Search , # Search string is optional
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("JSON", "Grid", "List", "Table", "System.Object")]
        [string]$OutputType = "System.Object" # Default output type
    )

    # Begin block to initialize resources
    begin {

        # The helper function remains local
        Function IsNullOrWhitespace {
            param([string]$InputString)
            return [string]::IsNullOrEmpty($InputString) -or $InputString.Trim() -eq ""
        }
        function Get-GraphItemsForType {
            param(
                [Parameter(Mandatory = $true)]
                [string]$ObjectType,
                [string]$Search
            )
            
            # Determine whether a search term is provided.
            $noSearch = [string]::IsNullOrWhiteSpace($Search)
            $splat = @{ All = $true }
            if ($ObjectType -match "User|Group|Device|ServicePrincipal" -and (-not $noSearch)) {
                $splat += @{ Search = "displayName:$Search"; ConsistencyLevel = "eventual" }
            }
            $items = $null
            switch ($ObjectType) {
                "User" {
                    return Get-MgBetaUser @splat
                }
                "Group" {
                    return Get-MgBetaGroup @splat
                }
                "Device" {
                    return Get-MgBetaDevice @splat
                }
                "ServicePrincipal" {
                    return Get-MgBetaServicePrincipal @splat
                }
                "SettingsCatalog" {
                    $items = Get-MgBetaDeviceManagementConfigurationPolicy -All
                    if (-not $noSearch) {
                        return $items | Where-Object { $_.Name -like "*$Search*" }
                    }
                    return $items
                }
                "MobileApp" {
                    $items = Get-MgBetaDeviceAppManagementMobileApp @splat
                }
                "ConfigProfile" {
                    $items = Get-MgBetaDeviceManagementDeviceConfiguration @splat
                }
                "AppProtection" {
                    $items = Get-MgBetaDeviceAppManagementManagedAppPolicy @splat
                }
                "CompliancePolicy" {
                    $items = Get-MgBetaDeviceManagementDeviceCompliancePolicy @splat
                }
                "DiscoveredApps" {
                    $items = Get-MgBetaDeviceManagementDetectedApp @splat
                }
                default {
                    throw "Unsupported ObjectType: $ObjectType"
                }
            }
            if (-not $noSearch) {
                return $items | Where-Object { $_.DisplayName -like "*$Search*" }
            }
            return $items
        }
    }

    # Process block: Runs once for each piped input
    process {
        $noSearch = IsNullOrWhitespace $Search

        # Check required Microsoft Graph and Console GUI commands.
        $requiredCommand = switch ($ObjectType) {
            "User" { "Get-MgBetaUser" }
            "Group" { "Get-MgBetaGroup" }
            "Device" { "Get-MgBetaDevice" }
            "MobileApp" { "Get-MgBetaDeviceAppManagementMobileApp" }
            "ServicePrincipal" { "Get-MgBetaServicePrincipal" }
            "SettingsCatalog" { "Get-MgBetaDeviceManagementConfigurationPolicy" }
            "ConfigProfile" { "Get-MgBetaDeviceManagementDeviceConfiguration" }
            "AppProtection" { "Get-MgBetaDeviceAppManagementManagedAppPolicy" }
            "CompliancePolicy" { "Get-MgBetaDeviceManagementDeviceCompliancePolicy" }
            "DiscoveredApps" { "Get-MgBetaDeviceManagementManagedDeviceDetectedApp" }
        }

        if (-not (Get-Command $requiredCommand -ErrorAction SilentlyContinue)) {
            Write-Error "The required command '$requiredCommand' for object type '$ObjectType' is not available. Please ensure the Microsoft Graph module is installed and imported."
            return
        }
        if (-not (Get-Command Out-ConsoleGridView -ErrorAction SilentlyContinue)) {
            Write-Error "The required command 'Out-ConsoleGridView' is not available. Please ensure the Microsoft.PowerShell.ConsoleGuiTools module is installed and imported."
            return
        }

        # Check if the user has the required permissions
        $permissions = switch ($ObjectType) {
            "User" {
                "User.Read.All"
            }
            "Group" {
                "Group.Read.All"
            }
            "Device" {
                "Device.Read.All"
            }
            "MobileApp" { 
                "DeviceManagementApps.Read.All" 
            }
            "ServicePrincipal" {
                "Application.Read.All"
            }
            "SettingsCatalog" { 
                "DeviceManagementConfiguration.Read.All" 
            }
            "ConfigProfile" { 
                "DeviceManagementConfiguration.Read.All" 
            }
            "AppProtection" { 
                "DeviceManagementApps.Read.All"
            }
            "CompliancePolicy" {
                "DeviceManagementConfiguration.Read.All"
            }
            "DiscoveredApps" {
                "DeviceManagementManagedDevices.Read.All"
            }

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
        # Retrieve data from Microsoft Graph based on object type and search input.
        $items = Get-GraphItemsForType -ObjectType $ObjectType -Search $Search
        # Define common properties for the grid view.
        $commonProperties = switch ($ObjectType) {
            "User" { "DisplayName", "Id", "Mail", "accountEnabled", "UserPrincipalName", "UserType" }
            "Group" { "DisplayName", "Id", "MailEnabled", "MailNickname", "SecurityEnabled" }
            "Device" { "DisplayName", "Id", "OperatingSystem", "OperatingSystemVersion", "Model", "Manufacturer" }
            "MobileApp" { "DisplayName", "Id", "Publisher", "AppType", "IsFeatured", "IsAssigned" }
            "ServicePrincipal" { "DisplayName", "Id", "AppId" }
            "SettingsCatalog" { "Name", "Id", "Description" }
            "ConfigProfile" { "DisplayName", "Id", "Description", "Version" }
            "AppProtection" { "DisplayName", "Id", "Description", "CreatedDateTime", "LastModifiedDateTime" }
            "CompliancePolicy" { "DisplayName", "Id", "Description", "CreatedDateTime", "LastModifiedDateTime" }
            "DiscoveredApps" { "DisplayName", "Platform", "Version", "DeviceCount", "Id" }
            default { "*" }
        }

        $gridItems = $items | Select-Object -Property $commonProperties
        $title = "Select a $ObjectType" + $(if (-not $noSearch) { " matching '$Search'" } else { "" })
        $selections = $gridItems | Out-ConsoleGridView -Title $title -OutputMode "Multiple"

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
                "AppProtection" { return Get-MgBetaDeviceAppManagementManagedAppPolicy -ManagedAppPolicyId $Id }
                "CompliancePolicy" { return Get-MgBetaDeviceManagementDeviceCompliancePolicy -DeviceCompliancePolicyId $Id }
                "DiscoveredApps" { return Get-MgBetaDeviceManagementDetectedApp -DetectedAppId $Id }
                default { return $null }
            }
        }

        if ($selections) {
            # Initialize $Output as an array
            $Output = @()
            
            if ($selections -is [System.Collections.IEnumerable] -and $selections.Count -gt 1) {
                foreach ($selection in $selections) {
                    if (-not $selection.PSObject.Properties["Id"]) {
                        Write-Warning "Selected $ObjectType object does not contain an 'Id' property."
                        continue
                    }
                    $result = Get-FullObject -Type $ObjectType -Id $selection.Id
                    # Add the current result to the $Output array
                    $Output += $result
                }
            } else {
                $selection = $selections
                if (-not $selection.PSObject.Properties["Id"]) {
                    Write-Warning "Selected $ObjectType object does not contain an 'Id' property."
                    return
                }
                $Output = Get-FullObject -Type $ObjectType -Id $selection.Id
            }
        
            switch ($OutputType) {
                "JSON" {
                    $Output | ConvertTo-Json -Depth 10
                }
                "Grid" {
                    $Output | Out-ConsoleGridView -Title "Selected $ObjectType Details"
                }
                "Table" {
                    $Output | Format-Table -Property * -Force
                }
                default {
                    $Output | Format-List -Property * -Force
                }
            }
        } else {
            Write-Warning "No items selected."
        }
    }

    # End block (if any cleanup is required)
    end {
        # Optionally, perform any final actions.
    }
}

# Prevent execution if the script is run directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Write-Host "`nThis script is intended to be used as a function. Please import it into your PowerShell session."
    Write-Host "`nUsage:"
    Write-Host "`n. .\Invoke-MgConsoleGuiGraphSearch.ps1`n" -ForegroundColor Yellow
    Write-Host "Then call the function with appropriate parameters."
    Write-Host "`nExample:"
    Write-Host "`nInvoke-MgConsoleGuiGraphSearch -ObjectType User -Search 'Jorge'`n" -ForegroundColor Yellow
    Write-Host "Exiting script."
}
Exit 0

# Sample commands:
# Connect to Microsoft Graph with required permissions
$mgParams = @{
    Scopes = @(
        "User.Read.All"
        "Group.Read.All"
        "Device.Read.All"
        "DeviceManagementApps.Read.All"
        "Application.Read.All"
        "DeviceManagementConfiguration.Read.All"
    )
}
Connect-MgGraph @mgParams

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

# Retrieve App Protection policies with "iOS" in their name and output the result in JSON format.
Invoke-MgConsoleGuiGraphSearch -ObjectType AppProtection -Search "iOS" -OutputType JSON

# Retrieve Compliance policies
Invoke-MgConsoleGuiGraphSearch -ObjectType CompliancePolicy

# Retrieve discovered apps
Invoke-MgConsoleGuiGraphSearch -ObjectType DiscoveredApps -Search "Zune"
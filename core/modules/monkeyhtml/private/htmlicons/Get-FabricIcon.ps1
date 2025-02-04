# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Function Get-FabricIcon{
    <#
        .SYNOPSIS
        Get M365 fabric icon

        .DESCRIPTION
        Get M365 fabric icon

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-FabricIcon
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, HelpMessage="Icon Name")]
        [String]$Icon
    )
    Begin{
        $fabric_icons = @{
            'Microsoft Entra ID' = 'AADLogo'
            'IAM' = 'AccountManagement'
            'Hosted Services' = 'WebComponents'
            'AppIcon' = 'AppIconDefault'
            'AzureIcon' = 'AzureIcon'
            'AzureApiManagement' = 'AzureAPIManagement'
            'Microsoft 365' = 'OfficeLogo'
            'Databases' = 'Database'
            'Database Configuration' = 'DatabaseSource'
            'Network' = 'NetworkDeviceScanning'
            'Storage' = 'StorageAcount'
            'Compute' = 'Devices2'
            'Subscription' = 'AzureIcon'
        }
    }
    Process{
        #Try to get icon
        $myIcon = $fabric_icons.GetEnumerator() | Where-Object {$_.Name -like ('{0}' -f $Icon)} | Select-Object -ExpandProperty Value -ErrorAction Ignore
        if($null -eq $myIcon){
            $myIcon = 'bi bi-box-arrow-down-right nav-icon'
        }
        else{
            $myIcon = ("ms-Icon ms-Icon--{0}" -f $myIcon)
        }
        #return icon
        return $myIcon
    }
    End{
        #Nothing to do here
    }
}



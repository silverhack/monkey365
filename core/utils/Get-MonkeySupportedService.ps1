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

Function Get-MonkeySupportedService{
    <#
        .SYNOPSIS
        Get supported services from installed plugins
        .DESCRIPTION
        Get supported services from installed plugins
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySupportedServices
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Azure supported services")]
		[Switch]$Azure,

        [Parameter(Mandatory = $false,HelpMessage = "Microsoft 365 supported services")]
		[Switch]$M365
	)
    Begin{
        $selected_plugins = $null
        $all_plugin_metadata = Get-MetadataFromPlugin
    }
    Process{
        if($null -ne $all_plugin_metadata -and $Azure.IsPresent){
            #Get all supported services based on Azure plugins
            $unsorted_az_plugins = $all_plugin_metadata | Where-Object {$_.Provider -eq 'Azure'}
            $unsorted_az_plugins | Select-Object -ExpandProperty Group | ForEach-Object {$selected_plugins+=$_.Split(',')}
            $selected_plugins = $selected_plugins | Sort-Object -Unique
            $selected_plugins+="All"
            $selected_plugins = $selected_plugins -replace '"', ""
        }
        elseif($null -ne $all_plugin_metadata -and $M365.IsPresent){
            #Get all supported services based on Microsoft 365 plugins
            $unsorted_az_plugins = $all_plugin_metadata | Where-Object {$_.Provider -eq 'Microsoft365'}
            $unsorted_az_plugins | Select-Object -ExpandProperty Group | ForEach-Object {$selected_plugins+=$_.Split(',')}
            $selected_plugins = $selected_plugins | Sort-Object -Unique
            $selected_plugins = $selected_plugins -replace '"', ""
        }
    }
    End{
        return $selected_plugins
    }
}
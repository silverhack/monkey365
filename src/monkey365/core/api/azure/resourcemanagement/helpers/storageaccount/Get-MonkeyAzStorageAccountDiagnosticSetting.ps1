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

Function Get-MonkeyAzStorageAccountDiagnosticSetting {
    <#
        .SYNOPSIS
		Get storage account diagnostic settings

        .DESCRIPTION
		Get storage account diagnostic settings

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzStorageAccountDiagnosticSetting
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Storage account object")]
        [Object]$InputObject,

        [parameter(Mandatory=$True, HelpMessage="Diagnostic Setting Type")]
        [ValidateSet("root","file","queue","blob","table")]
        [String]$Type
    )
    Process{
        Try{
            $objectId = $InputObject | Select-Object -ExpandProperty id -ErrorAction Ignore
            IF($null -ne $objectId){
                Switch($Type.ToLower()){
                    'root'{
                        $diag = $objectId | Get-MonkeyAzDiagnosticSettingsById
                        If($null -ne $diag){
                            $diag | New-MonkeyDiagnosticSettingObject
                        }
                    }
                    'blob'{
                        $blobEndpoint = ("{0}/blobServices/default" -f $objectId)
                        #Get diagnostic settings
                        $diag = $blobEndpoint | Get-MonkeyAzDiagnosticSettingsById
                        If($null -ne $diag){
                            $diag | New-MonkeyDiagnosticSettingObject
                        }
                    }
                    'queue'{
                        $queueEndpoint = ("{0}/queueServices/default" -f $objectId)
                        #Get diagnostic settings
                        $diag = $queueEndpoint | Get-MonkeyAzDiagnosticSettingsById
                        If($null -ne $diag){
                            $diag | New-MonkeyDiagnosticSettingObject
                        }
                    }
                    'table'{
                        $tableEndpoint = ("{0}/tableServices/default" -f $objectId)
                        #Get diagnostic settings
                        $diag = $tableEndpoint | Get-MonkeyAzDiagnosticSettingsById
                        If($null -ne $diag){
                            $diag | New-MonkeyDiagnosticSettingObject
                        }
                    }
                    'file'{
                        $fileEndpoint = ("{0}/fileServices/default" -f $objectId)
                        #Get diagnostic settings
                        $diag = $fileEndpoint | Get-MonkeyAzDiagnosticSettingsById
                        If($null -ne $diag){
                            $diag | New-MonkeyDiagnosticSettingObject
                        }
                    }
                }
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}

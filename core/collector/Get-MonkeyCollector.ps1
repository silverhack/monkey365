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

Function Get-MonkeyCollector{
    <#
        .SYNOPSIS
        List installed collectors
        .DESCRIPTION
        List installed collectors
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCollector
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraID","Microsoft365")]
        [String]$Provider,

        [Parameter(Mandatory=$false, HelpMessage="Cloud resource")]
        [String[]]$Service,

        [Parameter(Mandatory=$false, HelpMessage="Include Entra ID")]
        [Switch]$IncludeEntraID,

        [parameter(Mandatory=$false,HelpMessage="Pretty table")]
        [Switch]$Pretty
    )
    Try{
        #Set array
        $AllCollectors = [System.Collections.Generic.List[System.Object]]::new()
        $colors = [ordered]@{
            info = 36;
            low = 34;
            medium = 33;
            high = 31;
            critical = 35;
            good = 32;
        }
        $e = [char]27
        #Get metadata from collectors
        $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-MetadataFromCollector")
        $newPsboundParams = [ordered]@{}
        if($null -ne $MetaData){
            $param = $MetaData.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($PSBoundParameters.ContainsKey($p)){
                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                }
            }
        }
        #Add verbose, debug
        $newPsboundParams.Add('Verbose',$O365Object.verbose)
        $newPsboundParams.Add('Debug',$O365Object.debug)
        $newPsboundParams.Add('InformationAction',$O365Object.InformationAction)
        #Get metadata
        $_collectors = Get-MetadataFromCollector @newPsboundParams
        #Add to main array
        If ($_collectors -is [System.Collections.IEnumerable] -and $_collectors -isnot [string]){
            [void]$AllCollectors.AddRange($_collectors)
        }
        ElseIf ($_collectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $_collectors.GetType() -eq [System.Management.Automation.PSObject]) {
            [void]$AllCollectors.Add($_collectors)
        }
        #Check if Entra ID
        If($PSBoundParameters.ContainsKey('IncludeEntraID') -and $PSBoundParameters['IncludeEntraID'].IsPresent){
            $newPsboundParams.Provider = "EntraID"
            #Remove service
            $newPsboundParams.Remove('Service')
            $entraCollectors = Get-MetadataFromCollector @newPsboundParams
            #Add to main array
            If ($entraCollectors -is [System.Collections.IEnumerable] -and $entraCollectors -isnot [string]){
                [void]$AllCollectors.AddRange($entraCollectors)
            }
            ElseIf ($entraCollectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $entraCollectors.GetType() -eq [System.Management.Automation.PSObject]) {
                [void]$AllCollectors.Add($entraCollectors)
            }
        }
        If($AllCollectors.Count -gt 0){
            #Select properties
            $SelectedCollectors = $AllCollectors | Select-Object CollectorName,Id,Description,Enabled | Sort-Object -Property Id -Unique
            #Check if pretty
            If($PSBoundParameters.ContainsKey('Pretty') -and $PSBoundParameters['Pretty'].IsPresent){
                if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
                    $green = $colors.Item('good')
                    $yellow = $colors.Item('medium')
                    $red = $colors.Item('high')
                    foreach($r in $SelectedCollectors){
                        $r.collectorName = "$e[${green}m$($r.collectorName)${e}[0m"
                        $r.Id = "$e[${yellow}m$($r.Id)${e}[0m"
                        If($r.enabled){
                            $r.enabled = "$e[${green}m$($r.enabled)${e}[0m"
                        }
                        Else{
                            $r.enabled = "$e[${red}m$($r.enabled)${e}[0m"
                        }
                    }
                }
                Write-Output $SelectedCollectors
                if($null -eq (Get-Variable -Name psISE -ErrorAction Ignore)){
                    $message = ("There are $e[${yellow}m$(@($SelectedCollectors).Count)${e}[0m available collectors")
                }
                else{
                    $message = ('There are {0} available collectors' -f @($SelectedCollectors).Count)
                }
                Write-Output $message
            }
            Else{
                Write-Output $SelectedCollectors
            }
        }
    }
    Catch{
        Write-Error $_
    }
}


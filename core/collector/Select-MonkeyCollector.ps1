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

Function Select-MonkeyCollector{
    <#
        .SYNOPSIS
        Utility to work with internal collectors
        .DESCRIPTION
        Utility to work with internal collectors
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Select-MonkeyCollector
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
        [String[]]$Service
    )
    Begin{
        #Set empty arrays
        $allCollectors = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        $collectors = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        Try{
            $services = $null;
            If($PSBoundParameters.ContainsKey('Service') -and $PSBoundParameters['Service']){
                If(!$PSBoundParameters['Service'].Contains('All')){
                    $services = $PSBoundParameters['Service']
                }
            }
            #Set params
            $p = @{
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            IF($null -ne $services){
                [void]$p.Add('Service',$services);
            }
            IF($PSBoundParameters.ContainsKey('Provider') -and $PSBoundParameters['Provider']){
                If($PSBoundParameters['Provider'].ToLower() -eq 'entraid'){
                    return
                }
                [void]$p.Add('Provider',$PSBoundParameters['Provider']);
            }
            $allCollectors = Get-MetadataFromCollector @p
            #Remove disabled plugins
            $allCollectors = @($allCollectors).Where({$_.enabled})
        }
        Catch{
            $errorMessage = @{
                Message      = $_.Exception.Message
                Category     = [System.Management.Automation.ErrorCategory]::InvalidData
                ErrorId      = 'Monkey365ConnectorError'
            }
            $msg = @{
                MessageData = $errorMessage;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConnectorError');
            }
            Write-Error @msg
        }
    }
    Process{
        If($allCollectors.Count -gt 0){
            #Remove collectors if connection is not available
            Foreach($resource in $O365Object.onlineServices.GetEnumerator().Where({$_.Value -eq $false})){
                If($resource.Name.ToLower() -eq 'azure' -or $resource.Name.ToLower() -eq 'entraid'){
                    $allCollectors = @($allCollectors).Where({$_.Provider -ne $resource.Name});
                }
                Else{
                    $allCollectors = @($allCollectors).Where({$_.Group -notcontains $resource.Name});
                }
            }
            #Add collectors to main array
            If ($allCollectors -is [System.Collections.IEnumerable] -and $allCollectors -isnot [string]){
                [void]$collectors.AddRange($allCollectors)
            }
            ElseIf ($allCollectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $allCollectors.GetType() -eq [System.Management.Automation.PSObject]) {
                [void]$collectors.Add($allCollectors)
            }
        }
        #Check if EntraID collectors should be added
        If($O365Object.IncludeEntraID -eq $true -and $O365Object.onlineServices.EntraID -eq $true){
            $entraIdCollectors = [System.Collections.Generic.List[System.Object]]::new()
            $msGraphCollectors = Get-MetadataFromCollector -Provider EntraID -ApiType MSGraph
            $apiPortalCollectors = Get-MetadataFromCollector -Provider EntraID -ApiType EntraIDPortal
            #Add Azure collector to get Diagnostic settings for Entra ID
            $eidCollector = Get-MetadataFromCollector -Provider Azure -Service General | Where-Object {$_.Id -eq "az00150"}
            If($null -ne $eidCollector){
                [void]$entraIdCollectors.Add($eidCollector);
            }
            If($O365Object.isConfidentialApp){
                #Only MSGraph is supported for confidential apps
                If ($msGraphCollectors -is [System.Collections.IEnumerable] -and $msGraphCollectors -isnot [string]){
                    [void]$entraIdCollectors.AddRange($msGraphCollectors)
                }
                ElseIf ($msGraphCollectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $msGraphCollectors.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$entraIdCollectors.Add($msGraphCollectors)
                }
            }
            Else{
                #Load MSGraph collectors
                If ($msGraphCollectors -is [System.Collections.IEnumerable] -and $msGraphCollectors -isnot [string]){
                    [void]$entraIdCollectors.AddRange($msGraphCollectors)
                }
                ElseIf ($msGraphCollectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $msGraphCollectors.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$entraIdCollectors.Add($msGraphCollectors)
                }
                #Load Entra ID internal API collectors
                If ($apiPortalCollectors -is [System.Collections.IEnumerable] -and $apiPortalCollectors -isnot [string]){
                    [void]$entraIdCollectors.AddRange($apiPortalCollectors)
                }
                ElseIf ($apiPortalCollectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $apiPortalCollectors.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$entraIdCollectors.Add($apiPortalCollectors)
                }
            }
            #Add discovered collectors
            Foreach($eidCollector in $entraIdCollectors.GetEnumerator()){
                [void]$collectors.Add($eidCollector);
            }
        }
    }
    End{
        #Exclude collectors if present
        if($null -ne $O365Object.excludeCollectors){
            $message = ("The following collectors will be excluded: {0}" -f [string]::join(",", $O365Object.excludeCollectors))
            $msg = @{
                MessageData = $message;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('ExcludingCollectors');
            }
            Write-Verbose @msg
            $collectors = @($collectors).Where({$_.Id -notin $O365Object.excludeCollectors})
        }
        #TODO: Add include option to execute only specific collectors
        return $collectors | Sort-Object -Property id -Unique
    }
}

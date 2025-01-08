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
                Service = $services;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            IF($PSBoundParameters.ContainsKey('Provider') -and $PSBoundParameters['Provider']){
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
            #Set empty array
            $allCollectors = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        }
        #Get Api Type
        Try{
            $useMsGraph = [System.Convert]::ToBoolean($O365Object.internal_config.entraId.useMsGraph)
            $useAADOldAPIForUsers = [System.Convert]::ToBoolean($O365Object.internal_config.entraId.getUsersWithAADInternalAPI)
        }
        Catch{
            $useMsGraph = $true;
            $useAADOldAPIForUsers = $false;
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
            $graphCollectors = Get-MetadataFromCollector -Provider EntraID -ApiType graphlegacy
            $msGraphCollectors = Get-MetadataFromCollector -Provider EntraID -ApiType MSGraph
            $apiPortalCollectors = Get-MetadataFromCollector -Provider EntraID -ApiType EntraIDPortal
            If($O365Object.isConfidentialApp -eq $true){
                #Only MSGraph is supported for confidential apps
                If ($msGraphCollectors -is [System.Collections.IEnumerable] -and $msGraphCollectors -isnot [string]){
                    [void]$entraIdCollectors.AddRange($msGraphCollectors)
                }
                ElseIf ($msGraphCollectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $msGraphCollectors.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$entraIdCollectors.Add($msGraphCollectors)
                }
            }
            ElseIf($useMsGraph -eq $false -and $O365Object.isConfidentialApp -eq $false){
                #Load Old Graph collectors
                If ($graphCollectors -is [System.Collections.IEnumerable] -and $graphCollectors -isnot [string]){
                    [void]$entraIdCollectors.AddRange($graphCollectors)
                }
                ElseIf ($graphCollectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $graphCollectors.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$entraIdCollectors.Add($graphCollectors)
                }
                #Load Entra ID internal API collectors
                If ($apiPortalCollectors -is [System.Collections.IEnumerable] -and $apiPortalCollectors -isnot [string]){
                    [void]$entraIdCollectors.AddRange($apiPortalCollectors)
                }
                ElseIf ($apiPortalCollectors.GetType() -eq [System.Management.Automation.PSCustomObject] -or $apiPortalCollectors.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$entraIdCollectors.Add($apiPortalCollectors)
                }
            }
            ElseIf($useMsGraph -and $O365Object.isConfidentialApp -eq $false){
                Foreach($_collector in $entraIdCollectors.GetEnumerator()){
                    [void]$collectors.Add($eidCollector);
                }
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
                #Check if should load old AAD collector for users
                If($useAADOldAPIForUsers){
                    #Remove MSGraph user collector
                    $entraIdCollectors = $entraIdCollectors.Where({$_.collectorName -ne "Get-MonkeyAADUser"});
                    #Add graph users collector
                    $OlduserCollector = @($graphCollectors).Where({$_.collectorName -eq "Get-MonkeyADUser"});
                    If($OlduserCollector.Count -gt 0){
                        Foreach($_collector in $OlduserCollector){
                            [void]$entraIdCollectors.Add($_collector)
                        }
                    }
                    #Add policies
                    $policiesCollector = @($graphCollectors).Where({$_.collectorName -eq "Get-MonkeyADPolicy"});
                    If($policiesCollector.Count -gt 0){
                        Foreach($_collector in $policiesCollector){
                            [void]$entraIdCollectors.Add($_collector)
                        }
                    }
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

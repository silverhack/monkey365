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

Function Get-MonkeyAzResource{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzResource
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$false,HelpMessage="Resource group names")]
        [String[]]$ResourceGroupNames,

        [parameter(Mandatory=$false,HelpMessage="Check if diagnostic settings is supported")]
        [Switch]$DiagnosticSettingsSupport
    )
    Begin{
        $all_resources = [System.Collections.Generic.List[System.Object]]::new()
        #Get API version
        $apiDetails = $O365Object.internal_config.resourceManager | Where-Object {$_.Name -eq 'resources'} | Select-Object -ExpandProperty resource -ErrorAction Ignore
        if($null -eq $apiDetails){
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
    }
    Process{
        if($null -ne $ResourceGroupNames -and $ResourceGroupNames.Count -gt 0){
            foreach($rg in $ResourceGroupNames.GetEnumerator()){
                #Get Resources
                $p = @{
                    Authentication = $O365Object.auth_tokens.ResourceManager;
                    ObjectType = 'resources';
                    Filter = ("substringof('{0}', resourceGroup)" -f $rg);
                    Environment = $O365Object.Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $apiDetails.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $resources = Get-MonkeyRMObject @p
                if($null -ne $resources){
                    If ($resources -is [System.Collections.IEnumerable] -and $resources -isnot [string]){
                        [void]$all_resources.AddRange($resources)
                    }
                    ElseIf ($resources.GetType() -eq [System.Management.Automation.PSCustomObject] -or $resources.GetType() -eq [System.Management.Automation.PSObject]) {
                        [void]$all_resources.Add($resources)
                    }
                }
            }
        }
        else{
            #Get all resources within subscription
            $params = @{
                Authentication = $O365Object.auth_tokens.ResourceManager;
                ObjectType = 'resources';
                Environment = $O365Object.Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $resources = Get-MonkeyRMObject @params
            if($null -ne $resources){
                If ($resources -is [System.Collections.IEnumerable] -and $resources -isnot [string]){
                    [void]$all_resources.AddRange($resources)
                }
                ElseIf ($resources.GetType() -eq [System.Management.Automation.PSCustomObject] -or $resources.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$all_resources.Add($resources)
                }
            }
        }
    }
    End{
        if($all_resources.Count -gt 0){
            if($PSBoundParameters.ContainsKey('DiagnosticSettingsSupport') -and $PSBoundParameters['DiagnosticSettingsSupport'].isPresent){
                $diagSettings = Get-MonkeyAzProviderOperation
                if($null -ne $diagSettings){
                    foreach($rsrc in $all_resources){
                        $type = $rsrc.type.Split('/')[0]
                        $resourceType = $rsrc.type.Replace(("{0}/" -f $type),'')
                        $ds = ('{0}/providers/Microsoft.Insights/diagnosticSettings' -f $resourceType)
                        #Search provider
                        $resourceMatch = $diagSettings.Where({$_.name -eq $type}).Where({$_.resourceTypes.Where({$_.name -eq $ds},'First')})
                        if($resourceMatch.Count -gt 0){
                            $m = $resourceMatch.resourceTypes.Where({$_.name -eq $ds},'First')
                            if($m.Count -gt 0){
                                $rsrc | Add-Member -Type NoteProperty -name supportsDiagnosticSettings -value $true -Force
                            }
                        }
                        else{
                            $rsrc | Add-Member -Type NoteProperty -name supportsDiagnosticSettings -value $false -Force
                        }
                    }
                }
                return $all_resources
            }
            else{
                return $all_resources
            }
        }
    }
}


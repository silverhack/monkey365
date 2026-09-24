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

        [parameter(Mandatory=$false,HelpMessage="Filter")]
        [String]$Filter,

        [parameter(Mandatory=$false,HelpMessage="Check if diagnostic settings is supported")]
        [Switch]$DiagnosticSettingsSupport,

        [parameter(Mandatory=$false,HelpMessage="Append diagnostic settings is supported")]
        [Switch]$AddDiagnosticSetting
    )
    Begin{
        $tmp_resources = [System.Collections.Generic.List[System.Object]]::new()
        $all_resources = [System.Collections.Generic.List[System.Object]]::new()
        #Get API version
        $apiDetails = @($O365Object.internal_config.resourceManager).Where({$_.Name -eq 'resources'}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        If($null -eq $apiDetails){
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            $apiDetails = $null;
            break
        }
        #Get Diagnostic settings api version
        $config = @($O365Object.internal_config.resourceManager).Where({$_.Name -eq "DiagnosticSettings"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        If($config){
            $diag_settings_api_Version = $config.api_version;
        }
        Else{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            #Fallback
            $diag_settings_api_Version = "2021-05-01-preview"
        }
    }
    Process{
        If($null -ne $ResourceGroupNames -and $ResourceGroupNames.Count -gt 0 -and $null -ne $apiDetails){
            ForEach($rg in $ResourceGroupNames.GetEnumerator()){
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
                If($null -ne $resources){
                    If ($resources -is [System.Collections.IEnumerable] -and $resources -isnot [string]){
                        [void]$tmp_resources.AddRange($resources)
                    }
                    ElseIf ($resources.GetType() -eq [System.Management.Automation.PSCustomObject] -or $resources.GetType() -eq [System.Management.Automation.PSObject]) {
                        [void]$tmp_resources.Add($resources)
                    }
                }
            }
        }
        Else{
            #Get all resources within subscription
            $params = @{
                Authentication = $O365Object.auth_tokens.ResourceManager;
                ObjectType = 'resources';
                Environment = $O365Object.Environment;
                ContentType = 'application/json';
                Filter = $Filter;
                Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $resources = Get-MonkeyRMObject @params
            if($null -ne $resources){
                If ($resources -is [System.Collections.IEnumerable] -and $resources -isnot [string]){
                    [void]$tmp_resources.AddRange($resources)
                }
                ElseIf ($resources.GetType() -eq [System.Management.Automation.PSCustomObject] -or $resources.GetType() -eq [System.Management.Automation.PSObject]) {
                    [void]$tmp_resources.Add($resources)
                }
            }
        }
    }
    End{
        If($tmp_resources.Count -gt 0){
            If($PSBoundParameters.ContainsKey('DiagnosticSettingsSupport') -and $PSBoundParameters['DiagnosticSettingsSupport'].isPresent){
                $diagSettings = Get-MonkeyAzProviderOperation
                If($null -ne $diagSettings){
                    ForEach($rsrc in $tmp_resources){
                        $type = $rsrc.type.Split('/')[0]
                        $resourceType = $rsrc.type.Replace(("{0}/" -f $type),'')
                        $ds = ('{0}/providers/Microsoft.Insights/diagnosticSettings' -f $resourceType)
                        #Search provider
                        $resourceMatch = $diagSettings.Where({$_.name -eq $type}).Where({$_.resourceTypes.Where({$_.name -eq $ds},'First')})
                        If($resourceMatch.Count -gt 0){
                            $m = $resourceMatch.resourceTypes.Where({$_.name -eq $ds},'First')
                            If($m.Count -gt 0){
                                $rsrc | Add-Member -Type NoteProperty -name supportsDiagnosticSettings -value $true -Force
                            }
                        }
                        Else{
                            $rsrc | Add-Member -Type NoteProperty -name supportsDiagnosticSettings -value $false -Force
                        }
                        #Add to list
                        #[void]$all_resources.Add($rsrc);
                    }
                }
                If($PSBoundParameters.ContainsKey('AddDiagnosticSetting') -and $PSBoundParameters['AddDiagnosticSetting'].isPresent){
                    Try{
                        #Get resources that not support diagnostic settings
                        $nonSupportedResources = $tmp_resources.Where({$_.supportsDiagnosticSettings -eq $false})
                        ForEach($resource in $nonSupportedResources.GetEnumerator()){
                            $resource | Add-Member -MemberType NoteProperty -Name diagnosticSettings -Value $null -Force
                            #Add to list
                            [void]$all_resources.Add($resource);
                        }
                        #Get diagnostic settings
                        $supportedResources = $tmp_resources.Where({$_.supportsDiagnosticSettings -eq $true})
                        #Get pool
                        $scans = Initialize-MonkeyScan -Provider Azure -Throttle $O365Object.threads
                        $myscan = $scans | Select-Object -First 1
                        If($null -ne $myscan){
                            #Get all libs
                            $libs = $myscan.libCommands | Select-Object -Unique
                            $nestedParam = @{
                                ImportVariables = $myscan.vars;
                                ImportModules = $myscan.modules;
                                ImportCommands = $libs;
                                ApartmentState = $myscan.apartmentState;
                                Throttle = $myscan.threads;
                                StartUpScripts = $myscan.startUpScripts;
                                ThrowOnRunspaceOpenError = $true;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
                            }
                            #Set a second runspace for nested executions
                            $nestedRunspace = New-RunspacePool @nestedParam
                            If($null -ne $nestedRunspace -and $nestedRunspace -is [System.Management.Automation.Runspaces.RunspacePool]){
                                #Open runspace
                                $nestedRunspace.Open();
                                #Get diagnostic settings
                                $new_arg = @{
				                    APIVersion = $diag_settings_api_Version;
			                    }
                                $jobParam = @{
	                                ScriptBlock = {Get-MonkeyAzDiagnosticSettingForResource -InputObject $_ -AddToObject};
                                    Arguments = $new_arg;
	                                Runspacepool = $nestedRunspace;
	                                ReuseRunspacePool = $true;
	                                Debug = $O365Object.VerboseOptions.Debug;
	                                Verbose = $O365Object.VerboseOptions.Verbose;
	                                MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	                                BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	                                BatchSize = $O365Object.nestedRunspaces.BatchSize;
                                }
		                        $supportedResources = $supportedResources | Invoke-MonkeyJob @jobParam
                                #Add to list
                                ForEach($resource in @($supportedResources).Where({$null -ne $_})){
                                    #Add to list
                                    [void]$all_resources.Add($resource);
                                }
                                #dispose runspace
                                $nestedRunspace.Dispose()
                            }
                        }
                    }
                    Catch{
                        Write-Error $_
                    }
                }
            }
            #return object
            Write-Output $all_resources -NoEnumerate
        }
    }
}


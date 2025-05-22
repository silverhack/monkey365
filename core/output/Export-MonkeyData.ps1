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

Function Export-MonkeyData{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Export-MonkeyData
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $True, HelpMessage = 'Output format')]
        [String]$ExportTo
    )
    Process{
        If($ExportTo.ToLower() -in @('json','csv','clixml')){
            $OutDir = New-MonkeyFolder -destination ('{0}{1}{2}' -f $Script:OutFolder, [System.IO.Path]::DirectorySeparatorChar, $ExportTo.ToLower())
            If($null -ne $OutDir){
                If($O365Object.Instance.ToLower() -eq 'azure'){
                    $p = @{
                        InputObject = $matchedRules;
                        ProductName = 'Monkey365';
                        ProductVersion = Get-MonkeyVersion;
                        ProductVendorName = 'Monkey365';
                        TenantId = $O365Object.executionInfo.Tenant.TenantId;
                        TenantName = $O365Object.executionInfo.Tenant.TenantName;
                        SubscriptionId = $O365Object.executionInfo.subscription.subscriptionId;
                        SubscriptionName = $O365Object.executionInfo.subscription.subscriptionId;
                        Provider = $O365Object.Instance;
                        ExportTo = $ExportTo;
                        OutDir = $OutDir;
                    }
                }
                Else{
                    $p = @{
                        InputObject = $matchedRules;
                        ProductName = 'Monkey365';
                        ProductVersion = Get-MonkeyVersion;
                        ProductVendorName = 'Monkey365';
                        TenantId = $O365Object.executionInfo.Tenant.TenantId;
                        TenantName = $O365Object.executionInfo.Tenant.TenantName;
                        Provider = $O365Object.Instance;
                        ExportTo = $ExportTo;
                        OutDir = $OutDir;
                    }
                }
                #Export Data
                Invoke-MonkeyOutput @p
            }
        }
        ElseIf($ExportTo.ToLower() -eq "html"){
            #Check if local html report should be produced
            Try{
                If($null -ne (Get-Variable -Name monkeyExportObject -ErrorAction Ignore) -and $null -ne (Get-Variable -Name matchedRules -ErrorAction Ignore)){
                    $OutHtmlDir = New-MonkeyFolder -destination ('{0}{1}{2}' -f $Script:OutFolder, [System.IO.Path]::DirectorySeparatorChar, $ExportTo.ToLower())
                    $out = $null;
                    [void][bool]::TryParse($O365Object.internal_config.htmlSettings.localHtmlReport.enabled, [ref]$out);
                    $localHtmlReport = $out;
                    $out = $null;
                    [void][bool]::TryParse($O365Object.internal_config.htmlSettings.htmlReportFromCDN, [ref]$out);
                    $htmlCDNReport = $out;
                    $assetsRepository = $O365Object.internal_config.htmlSettings.assetsRepository;
                    $localAssetsPath = $O365Object.internal_config.htmlSettings.localHtmlReport.assetsPath;
                    #Get all rules
                    $allRules = Get-Rule
                    #Set ruleset Info
                    $rulesetInfo = [ordered]@{
                        Ruleset = (Get-Framework);
                        'Ruleset Description' = (Get-Ruleset -Info).about;
                        'Number of rules' = @($allRules).Count;
                        'Executed Rules' = @($matchedRules).Count;
                        'Scan Date' = $MonkeyExportObject.executionInfo.ScanDate;
                        'Monkey Version' = Get-MonkeyVersion;
                    }
                    #Download assets and produce local report
                    If($localHtmlReport -and $localAssetsPath -and $assetsRepository){
                        If(-NOT [System.IO.Path]::IsPathRooted($O365Object.internal_config.htmlSettings.localHtmlReport.assetsPath)){
                            $localAssetsPath = ("{0}{1}{2}" -f $O365Object.Localpath, [System.IO.Path]::DirectorySeparatorChar, $O365Object.internal_config.htmlSettings.localHtmlReport.assetsPath)
                        }
                        $p = @{
                            Url = $assetsRepository;
                            SHA256 = $true;
                            IncludeVersionId = $true;
                            Output = $localAssetsPath;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
                        }
                        $downloaded = Update-MonkeyAsset @p
                        If($downloaded){
                            #Produce report
                            #Set params
                            $p = @{
                                ConfigFile = ("{0}{1}{2}{3}config.json" -f $localAssetsPath, [System.IO.Path]::DirectorySeparatorChar,"assets",[System.IO.Path]::DirectorySeparatorChar);
                                Report = $matchedRules;
                                ExecutionInfo = $O365Object.executionInfo;
                                Instance = $O365Object.Instance;
                                Rules = $allRules;
                                RulesetInfo = $rulesetInfo;
                                OutDir = $OutHtmlDir;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
                            }
                            New-HtmlReport @p
                        }
                    }
                    If($htmlCDNReport -and $assetsRepository){
                        #Set params
                        $p = @{
                            Repository = $assetsRepository;
                            Report = $matchedRules;
                            ExecutionInfo = $O365Object.executionInfo;
                            Instance = $O365Object.Instance;
                            Rules = $allRules;
                            RulesetInfo = $rulesetInfo;
                            OutDir = $OutHtmlDir;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
                        }
                        New-HtmlReport @p
                    }
                }
            }
            Catch{
                $msg = @{
                    Message = $_.Exception.Message;
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'error';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('Monkey365HTMLError');
                }
                Write-Error @msg
            }
        }
    }
}


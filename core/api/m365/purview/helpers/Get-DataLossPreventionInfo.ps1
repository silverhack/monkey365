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

Function Get-DataLossPreventionInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-DataLossPreventionInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    Begin{
        $DLPStatus = New-Object System.Collections.Generic.List[System.Object]
        $DLPCollection = $Sensitivity_Types = $custom_types = $null
        if($O365Object.onlineServices.Purview -eq $true){
            $DLPCollection = [ordered]@{}
            #Get Security and Compliance Auth token
            $ExoAuth = $O365Object.auth_tokens.ComplianceCenter
            #Get Backend Uri
            $Uri = $O365Object.SecCompBackendUri
            #InitParams
            $p = @{
                Authentication = $ExoAuth;
                EndPoint = $Uri;
                ResponseFormat = 'clixml';
                Command = $null;
                Method = "POST";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $msg = @{
                MessageData = ("Getting Data Loss Prevention Configuration");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('O365DLPInfo');
            }
            Write-Information @msg
            try{
                #Get DLP Compliance Policy
                $p.Command = 'Get-DlpCompliancePolicy';
                $DLPCollection.DLPCompliancePolicy = Get-PSExoAdminApiObject @p
                #Get DLP Compliance Rules
                Start-Sleep -Milliseconds 1000
                $p.Command = 'Get-DlpComplianceRule';
                $DLPCollection.DLPComplianceRules = Get-PSExoAdminApiObject @p
                #Get Custom Sensitivity types
                Start-Sleep -Milliseconds 1000
                $p.Command = 'Get-DlpSensitiveInformationType -ErrorAction Ignore';
                $Sensitivity_Types = Get-PSExoAdminApiObject @p
                if($null -ne $Sensitivity_Types){
                    $custom_types = $Sensitivity_Types | Where-Object { $_.Publisher -ne "Microsoft Corporation" }
                }
                $DLPCollection.DLPCustomType = $custom_types
            }
            catch{
                $msg = @{
                    MessageData = ($_);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('SecComplianceDLPInfoError');
                }
                Write-Verbose @msg
            }
        }
        else{
            $msg = @{
                MessageData = ($message.NotConnectedTo -f "Security and Compliance Manager");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('SecComplianceDLPConnectionError');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($null -ne $DLPCollection -and $DLPCollection.DLPCompliancePolicy){
            foreach($DLPPolicy in @($DLPCollection.DLPCompliancePolicy)){
                $sits = $null;
                $all_sits = [System.Collections.Generic.List[System.Object]]::new()
                $enabled = $DLPPolicy.Enabled;
                $policyName = $DLPPolicy.Name;
                if($null -ne $DLPCollection.DLPComplianceRules){
                    $associated_rule = $DLPCollection.DLPComplianceRules | Where-Object {$_.Policy.Guid -eq $DLPPolicy.Guid.Guid} -ErrorAction Ignore
                }
                else{
                    $associated_rule = $null
                }
                if($null -ne $associated_rule){
                    foreach($rule in @($associated_rule)){
                        #Get Sensitivity information type
                        $p = @{
                            Rule = $rule;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $sits = Get-DLPSensitiveInformation @p
                        if($null -ne $sits){
                            $uniqueSits = $sits | ForEach-Object {$_.sit | Select-Object -ExpandProperty Name -ErrorAction Ignore} | Select-Object -Unique
                            if($uniqueSits){
                                foreach($usit in $uniqueSits){
                                    [void]$all_sits.Add($usit);
                                }
                            }
                        }
                    }
                }
                elseif ($policyName -match "Default") {
                    $enabled = $true;
                }
                #Add to a ndw PsObject
                $DLPObject = New-Object -TypeName PsObject -Property @{
                    policyName = $policyName;
                    isEnabled = $enabled;
                    policy = $DLPPolicy;
                    policyId = $DLPPolicy.ExchangeObjectId.Guid;
                    rule = $associated_rule;
                    ruleName = $associated_rule.Name;
                    ruleId = $associated_rule.ExchangeObjectId.Guid;
                    raw_sits = $sits;
                    sits = $all_sits;
                }
                #Add to array
                [void]$DLPStatus.Add($DLPObject)
            }
        }
    }
    End{
        $DLPStatus
    }
}


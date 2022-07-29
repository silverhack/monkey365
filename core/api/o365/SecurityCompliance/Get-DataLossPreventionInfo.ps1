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
        $msg = @{
            MessageData = ("Getting Data Loss Prevention Configuration");
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $script:InformationAction;
            Tags = @('O365DLPInfo');
        }
        Write-Information @msg
        $DLPCollection = $Sensitivity_Types = $custom_types = $null
        if($null -ne (Get-Command -Name Get-DlpCompliancePolicy -errorAction Ignore)){
            $DLPStatus = New-Object System.Collections.Generic.List[System.Object]
            $DLPCollection = [ordered]@{}
            try{
                #Get DLP Compliance Policy
                $DLPCollection.DLPCompliancePolicy = Get-DlpCompliancePolicy
                #Get DLP Compliance Rules
                $DLPCollection.DLPComplianceRules = Get-DlpComplianceRule
                #Get Custom Sensitivity types
                $Sensitivity_Types = Get-DlpSensitiveInformationType -ErrorAction Ignore
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
                    InformationAction = $InformationAction;
                    Tags = @('O365DLPInfo');
                }
                Write-Verbose @msg
            }
        }
        else{
            $msg = @{
                MessageData = ($message.NoPsSessionWasFound -f "Security and Compliance Manager");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('O365DLPInfo');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($null -ne $DLPCollection -and $DLPCollection.DLPCompliancePolicy){
            foreach($DLPPolicy in @($DLPCollection.DLPCompliancePolicy)){
                $sits = $null;
                $all_sits = @()
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
                        if($rule.ContentContainsSensitiveInformation[0].groups){
                            $sits = Get-DLPSensitiveInformationGroup -sit_groups $rule.ContentContainsSensitiveInformation[0]
                            if($null -ne $sits){
                                $all_sits += $sits | ForEach-Object {$_.sit | Select-Object -ExpandProperty Name} | Select-Object -Unique
                            }
                        }
                        else{
                            $sits = Get-DLPSensitiveInformation -sits $rule.ContentContainsSensitiveInformation[0]
                            if($null -ne $sits){
                                $all_sits += $sits | Select-Object -ExpandProperty Name
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
                    Policy = $DLPPolicy;
                    Rule = $associated_rule;
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

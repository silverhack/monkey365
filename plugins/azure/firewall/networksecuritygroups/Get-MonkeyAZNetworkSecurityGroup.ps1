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


Function Get-MonkeyAZNetworkSecurityGroup{
    <#
        .SYNOPSIS
		Plugin to get Network Security Rules from Azure

        .DESCRIPTION
		Plugin to get Network Security Rules from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZNetworkSecurityGroup
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Config
        $AzureNSGConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureNSG"} | Select-Object -ExpandProperty resource
        #Get Network Security Groups
        $all_nsgs = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Network/networkSecurityGroups'}
        if(-NOT $all_nsgs){continue}
        #Set array
        $all_nsg_rules = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Network Security Groups", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureNSGInfo');
        }
        Write-Information @msg
        if($all_nsgs){
            foreach($my_nsg in $all_nsgs){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $my_nsg.name, "Network Security Group");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureNSGInfo');
                }
                Write-Information @msg
                #construct URI
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$my_nsg.id,$AzureNSGConfig.api_version)
                #launch request
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $nsg = Get-MonkeyRMObject @params
                if($nsg){
                    $msg = @{
                        MessageData = ($message.MonkeyResponseCountMessage -f $nsg.properties.securityrules.count);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $InformationAction;
                        Tags = @('AzureNSGInfo');
                    }
                    Write-Information @msg
                    #iterate over properties
                    foreach ($sr in $nsg.properties.securityrules){
                        $SecurityRule = New-Object -TypeName PSCustomObject
                        $SecurityRule | Add-Member -type NoteProperty -name name -value $nsg.name
                        $SecurityRule | Add-Member -type NoteProperty -name location -value $nsg.location
                        $SecurityRule | Add-Member -type NoteProperty -name ResourceGroupName -value $nsg.id.Split("/")[4]
                        #Getting interfaces names
                        $AllInterfaces =  @()
                        foreach($interface in $nsg.properties.networkinterfaces){
                            $Ifacename = $interface.id.Split("/")[8]
                            $AllInterfaces+=$Ifacename
                        }
                        if($AllInterfaces){
                            $SecurityRule | Add-Member -type NoteProperty -name RulesAppliedOn -value (@($AllInterfaces) -join ',')
                        }
                        $SecurityRule | Add-Member -type NoteProperty -name Rulename -value $sr.name
                        $SecurityRule | Add-Member -type NoteProperty -name RuleDescription -value $sr.properties.description
                        $SecurityRule | Add-Member -type NoteProperty -name Protocol -value $sr.properties.protocol
                        $SecurityRule | Add-Member -type NoteProperty -name SourcePortRange -value $sr.properties.sourcePortRange
                        $SecurityRule | Add-Member -type NoteProperty -name SourcePortRanges -value (@($sr.properties.sourcePortRanges) -join ',')
                        $SecurityRule | Add-Member -type NoteProperty -name DestinationPortRange -value $sr.properties.DestinationPortRange
                        $SecurityRule | Add-Member -type NoteProperty -name DestinationPortRanges -value (@($sr.properties.DestinationPortRanges) -join ',')
                        $SecurityRule | Add-Member -type NoteProperty -name SourceAddressPrefix -value $sr.properties.sourceAddressPrefix
                        $SecurityRule | Add-Member -type NoteProperty -name SourceAddressPrefixes -value (@($sr.properties.sourceAddressPrefixes) -join ',')
                        $SecurityRule | Add-Member -type NoteProperty -name DestinationAddressPrefix -value $sr.properties.DestinationAddressPrefix
                        $SecurityRule | Add-Member -type NoteProperty -name DestinationAddressPrefixes -value (@($sr.properties.DestinationAddressPrefixes) -join ',')
                        $SecurityRule | Add-Member -type NoteProperty -name Access -value $sr.properties.access
                        $SecurityRule | Add-Member -type NoteProperty -name Priority -value $sr.properties.priority
                        $SecurityRule | Add-Member -type NoteProperty -name direction -value $sr.properties.direction
                        $SecurityRule | Add-Member -type NoteProperty -name rawObject -value $sr
                        #Add to array
                        $all_nsg_rules+=$SecurityRule
                    }
                    #Getting all default security rules
                    foreach ($dsr in $nsg.properties.defaultSecurityRules){
                        $DefaultSecurityRule = New-Object -TypeName PSCustomObject
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name name -value $nsg.name
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name location -value $nsg.location
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name ResourceGroupName -value $nsg.id.Split("/")[4]
                        #Getting interfaces names
                        $AllInterfaces =  @()
                        foreach($interface in $nsg.properties.networkinterfaces){
                            $Ifacename = $interface.id.Split("/")[8]
                            $AllInterfaces+=$Ifacename
                        }
                        if($AllInterfaces){
                            $DefaultSecurityRule | Add-Member -type NoteProperty -name RulesAppliedOn -value (@($AllInterfaces) -join ',')
                        }
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name Rulename -value $dsr.name
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name RuleDescription -value $dsr.properties.description
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name Protocol -value $dsr.properties.protocol
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name SourcePortRange -value $dsr.properties.sourcePortRange
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name DestinationPortRange -value $dsr.properties.DestinationPortRange
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name SourceAddressPrefix -value $dsr.properties.sourceAddressPrefix
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name DestinationAddressPrefix -value $dsr.properties.DestinationAddressPrefix
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name Access -value $dsr.properties.access
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name Priority -value $dsr.properties.priority
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name direction -value $dsr.properties.direction
                        $DefaultSecurityRule | Add-Member -type NoteProperty -name rawObject -value $dsr

                        $all_nsg_rules+=$DefaultSecurityRule
                    }
                }
            }
        }
    }
    End{
        if($all_nsg_rules){
            $all_nsg_rules.PSObject.TypeNames.Insert(0,'Monkey365.Azure.NetworkSecurityRules')
            [pscustomobject]$obj = @{
                Data = $all_nsg_rules
            }
            $returnData.az_nsg_rules = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Network Security Rules", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureNSGEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}

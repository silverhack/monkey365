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

Function Get-MonkeyAzSbsPolicySetDefinition {
    <#
        .SYNOPSIS
		Get subscription policy set definition from Azure

        .DESCRIPTION
		Get subscription policy set definition from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSbsPolicySetDefinition
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [parameter(Mandatory=$false, ParameterSetName = 'Category', ValueFromPipeline = $True)]
        [String]$Category,

        [parameter(Mandatory=$false, ParameterSetName = 'PolicyType', ValueFromPipeline = $True)]
        [String]$PolicyType
    )
    Begin{
        #Get resource management Auth
        $rmAuth = $O365Object.auth_tokens.ResourceManager
        #Get API version
        $apiDetails = $O365Object.internal_config.resourceManager | Where-Object {$_.Name -eq 'azureAuthorization'} | Select-Object -ExpandProperty resource -ErrorAction Ignore
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
        #set var
        $policy = $null
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'PolicyType'){
            $msg = @{
                MessageData = ($message.AzureSbsPolicySetDefinition -f $PolicyType);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureSubscriptionInfo');
            }
            Write-Information @msg
            $filter = ("policyType eq '{0}'" -f $PolicyType)
            #Set params
            $p = @{
		        Authentication = $rmAuth;
                Environment = $O365Object.Environment;
                Provider = $apiDetails.provider;
                ObjectType = "policySetDefinitions";
                Filter = $filter;
                APIVersion= '2019-09-01';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $policy = Get-MonkeyRMObject @p
            #return policy
            return $policy
        }
        elseif($PSCmdlet.ParameterSetName -eq 'Category'){
            $msg = @{
                MessageData = ($message.AzureSbsPolicySetDefinition -f $Category);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureSubscriptionInfo');
            }
            Write-Information @msg
            $filter = ("category eq '{0}'" -f $Category)
            #Set params
            $p = @{
		        Authentication = $rmAuth;
                Environment = $O365Object.Environment;
                Provider = $apiDetails.provider;
                ObjectType = "policySetDefinitions";
                Filter = $filter;
                APIVersion= '2019-09-01';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $policy = Get-MonkeyRMObject @p
            #return policy
            return $policy
        }
        else{
            $msg = @{
                MessageData = ($message.AzureSbsPolicySetDefinitionAll);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureSubscriptionInfo');
            }
            Write-Information @msg
            #Set params
            $p = @{
		        Authentication = $rmAuth;
                Environment = $O365Object.Environment;
                Provider = $apiDetails.provider;
                ObjectType = "policySetDefinitions";
                APIVersion= '2019-09-01';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $policy = Get-MonkeyRMObject @p
            #return policy
            return $policy
        }
    }
    End{
        #nothing to do here
    }
}
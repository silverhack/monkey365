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

Function Get-MonkeyAzSubscription {
    <#
        .SYNOPSIS
		Get subscriptions from Azure

        .DESCRIPTION
		Get subscriptions from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzSubscription
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [parameter(Mandatory=$false, ParameterSetName = 'SubscriptionId', ValueFromPipeline = $True)]
        [String]$SubscriptionId
    )
    Begin{
        #Get resource management Auth
        $rmAuth = $O365Object.auth_tokens.ResourceManager
        #Get API version
        $apiDetails = $O365Object.internal_config.resourceManager | Where-Object {$_.Name -eq 'suscriptions'} | Select-Object -ExpandProperty resource -ErrorAction Ignore
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
        $subscription = $null
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'SubscriptionId'){
            $Server = [System.Uri]::new($O365Object.Environment.ResourceManager)
            $uri = [System.Uri]::new($Server,("/subscriptions/{0}?api-version={1}" -f $SubscriptionId, $apiDetails.api_version))
            $final_uri = $uri.ToString()
            $msg = @{
                MessageData = ($message.AzureSubscriptionInfo -f $SubscriptionId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureSubscriptionInfo');
            }
            Write-Information @msg
            #Set params
            $p = @{
		        Authentication = $rmAuth;
                OwnQuery = $final_uri;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $subscription = Get-MonkeyRMObject @p
        }
        else{
            $msg = @{
                MessageData = $message.AzureSubscriptionAllInfo;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureSubscriptionInfo');
            }
            Write-Information @msg
            $Server = [System.Uri]::new($O365Object.Environment.ResourceManager)
            $uri = [System.Uri]::new($Server,"/subscriptions?api-version={0}" -f $apiDetails.api_version)
            $final_uri = $uri.ToString()
            #Set params
            $p = @{
		        Authentication = $rmAuth;
                OwnQuery = $final_uri;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $subscription = Get-MonkeyRMObject @p
        }
        #return subscription
        return $subscription
    }
    End{
        #nothing to do here
    }
}

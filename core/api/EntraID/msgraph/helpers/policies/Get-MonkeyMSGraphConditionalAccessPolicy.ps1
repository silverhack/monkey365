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


Function Get-MonkeyMSGraphConditionalAccessPolicy{
    <#
        .SYNOPSIS
		Get conditional access policies

        .DESCRIPTION
		Get conditional access policies

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphConditionalAccessPolicy
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="Conditional Access Id")]
        [String]$id,

        [Parameter(Mandatory=$false, HelpMessage="Get detailed conditional access policies")]
        [Switch]$detailed,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    try{
        $caps_ = $null
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        if($PSBoundParameters.ContainsKey('id') -and $PSBoundParameters.id){
            $objectType = ('identity/conditionalAccess/policies/{0}' -f $id)
            $params = @{
                Authentication = $graphAuth;
                ObjectType = $objectType;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $caps_ = Get-MonkeyMSGraphObject @params
        }
        else{
            #Get all conditional access policies
            $objectType = 'identity/conditionalAccess/policies'
            $params = @{
                Authentication = $graphAuth;
                ObjectType = $objectType;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $caps_ = Get-MonkeyMSGraphObject @params
            #Check if detailed cap
            if($PSBoundParameters.ContainsKey('detailed') -and $PSBoundParameters.detailed){
                $cap_ = New-Object System.Collections.Generic.List[System.Object]
                foreach($cap in $caps_){
                    $objectType = ('identity/conditionalAccess/policies/{0}' -f $cap.id)
                    $params = @{
                        Authentication = $graphAuth;
                        ObjectType = $objectType;
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                        APIVersion = $APIVersion;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $cap = Get-MonkeyMSGraphObject @params
                    if($cap){
                        #Add to array
                        [void]$cap_.Add($cap);
                    }
                    Start-Sleep -Milliseconds 1000
                }
                $caps_ = $cap_
            }
        }
        if($null -ne $caps_){
            return $caps_
        }
        else{
            $msg = @{
                MessageData = $message.ConditionalAccessEmptyMessage;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                Tags = @('CAPEmptyMessage');
            }
            Write-Verbose @msg
        }
    }
    catch{
        $msg = @{
            MessageData = $message.ConditionalAccessErrorMessage;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $O365Object.InformationAction;
            Tags = @('CAPErrorMessage');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        [void]$msg.Add('verbose',$O365Object.verbose)
        Write-Verbose @msg
    }
}



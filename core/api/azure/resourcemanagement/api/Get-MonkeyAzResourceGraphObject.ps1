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

function Get-MonkeyAzResourceGraphObject{
    <#
        .SYNOPSIS
        Queries the resources managed by Azure Resource Manager within a specified subscription, resource group, etc..

        .DESCRIPTION
        Queries the resources managed by Azure Resource Manager within a specified subscription, resource group, etc..

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzResourceGraphObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage='Query')]
        [String]$query,

        [Parameter(Mandatory=$false, HelpMessage="Subscription Id")]
        [String[]]$SubscriptionId,

        [Parameter(Mandatory=$false, HelpMessage="Management Group")]
        [String[]]$ManagementGroup,

        [parameter(Mandatory=$False, HelpMessage='Top objects')]
        [System.Int32]$Skip,

        [parameter(Mandatory=$False, HelpMessage='Top objects')]
        [System.Int32]$Top,

        [Parameter(Mandatory=$false, HelpMessage="Api version")]
        [String]$ApiVersion = "2024-04-01"
    )
    Begin{
        #Set null
        $final_uri = $null;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Auth object
        $authObject = $O365Object.auth_tokens.ResourceManager
        #Get Authorization Header
        $methods = $authObject | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name
        #Get Authorization Header
        If($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
            $AuthHeader = $authObject.CreateAuthorizationHeader()
        }
        Else{
            $AuthHeader = ("Bearer {0}" -f $authObject.AccessToken)
        }
        #Create dictionary
        $postQuery = @{}
        #Set Dictionary for options
        If(($PSBoundParameters.ContainsKey('Skip') -and $PSBoundParameters['Skip']) -or ($PSBoundParameters.ContainsKey('Top') -and $PSBoundParameters['Top'])){
            #Set options dictionary
            $options = @{}
            If($PSBoundParameters.ContainsKey('Skip') -and $PSBoundParameters['Skip']){
                [void]$options.Add('$skip',$PSBoundParameters['Skip']);
            }
            If($PSBoundParameters.ContainsKey('Top') -and $PSBoundParameters['Top']){
                [void]$options.Add('$top',$PSBoundParameters['Top']);
            }
            #Add to main dictionary
            [void]$postQuery.Add('options',$options);
        }
        If($PSBoundParameters.ContainsKey('ManagementGroup') -and $PSBoundParameters['ManagementGroup']){
            #Set dictionary for management groups
            $allManagementGroups = [System.Collections.Generic.List[System.String]]::new()
            ForEach($mGroup in $PSBoundParameters['ManagementGroup']){
                [void]$allManagementGroups.Add($mGroup);
            }
            #Set property
            [void]$postQuery.Add('managementGroups',$allManagementGroups.ToArray());
        }
        ElseIf($PSBoundParameters.ContainsKey('SubscriptionId') -and $PSBoundParameters['SubscriptionId']){
            #Set dictionary for subscriptions
            $allSubscriptions = [System.Collections.Generic.List[System.String]]::new()
            ForEach($sId in $PSBoundParameters['SubscriptionId']){
                [void]$allSubscriptions.Add($sId);
            }
            #Set property
            [void]$postQuery.Add('subscriptions',$allSubscriptions.ToArray());
        }
        ElseIf($null -ne $authObject.Psobject.Properties.Item('subscriptionId') -and $null -ne $authObject.SubscriptionId){
            #Set dictionary for subscriptions
            $allSubscriptions = [System.Collections.Generic.List[System.String]]::new()
            ForEach($sId in  @($authObject.subscriptionId)){
                [void]$allSubscriptions.Add($sId);
            }
            #Set property
            [void]$postQuery.Add('subscriptions',$allSubscriptions.ToArray());
        }
        Else{
            Write-Warning "Missing SubscriptionId or ManagementGroup"
            #Clear dictionary
            [void]$postQuery.Clear()
        }
        #Set URI
        If($null -ne $Environment){
            $final_uri = ("{0}/providers/Microsoft.ResourceGraph/resources?api-version={1}" -f $Environment.ResourceManager,$ApiVersion)
        }
    }
    Process{
        If($postQuery.Count -ne 0 -and $null -ne $final_uri){
            #Add Query
            [void]$postQuery.Add('query',$PSBoundParameters['Query']);
            #Convert to json
            $jsonQuery = $postQuery | ConvertTo-Json -Depth 10 -Compress | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
            #Set request header
            $requestHeader = @{
                "Authorization" = $AuthHeader
            }
            #Set parameters
            $p = @{
                Url = $final_uri;
                Headers = $requestHeader;
                Method = "POST";
                ContentType = "application/json";
                Data = $jsonQuery;
                UserAgent = $O365Object.UserAgent;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            #Execute query
            $_objects = Invoke-MonkeyWebRequest @p
            #Get objects
            If($null -ne $_objects){
                #return data
                $_objects | Select-Object -ExpandProperty data -ErrorAction Ignore
                #Check for paging objects
                If($null -ne $_objects.PSObject.Properties.Item('$skipToken')){
                    $skipToken = $_objects.'$skipToken';
                    Do{
                        #Get query
                        $jsonQuerySkipToken = $jsonQuery.Clone();
                        #Add skipToken
                        [void]$jsonQuerySkipToken.Add('$skipToken',$skipToken);
                        #Set parameters
                        $p = @{
                            Url = $final_uri;
                            Headers = $requestHeader;
                            Method = "POST";
                            ContentType = "application/json";
                            Data = $jsonQuerySkipToken;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
                        }
                        $_objects = Invoke-MonkeyWebRequest @p
                        #return data
                        $_objects | Select-Object -ExpandProperty data -ErrorAction Ignore
                        $skipToken = $_objects | Select-Object -ExpandProperty '$skipToken' -ErrorAction Ignore
                    }
                    While($null -ne $skipToken)
                }
            }
        }
    }
}
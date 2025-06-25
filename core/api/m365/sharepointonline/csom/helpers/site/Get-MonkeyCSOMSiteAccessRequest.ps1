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


Function Get-MonkeyCSOMSiteAccessRequest{
    <#
        .SYNOPSIS
		Get Sharepoint Online site access request

        .DESCRIPTION
		Get Sharepoint Online site access request

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSiteAccessRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [parameter(Mandatory=$true, ParameterSetName = 'Web', ValueFromPipeline = $true, HelpMessage="Web Object")]
        [Object]$Web,

        [Parameter(Mandatory= $false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$true, ParameterSetName = 'Endpoint', HelpMessage="SharePoint Url")]
        [Object]$Endpoint
    )
    Process{
        try{
            If($PSCmdlet.ParameterSetName -eq "Current" -or $PSCmdlet.ParameterSetName -eq "Endpoint"){
                $p = Set-CommandParameter -Command "Get-MonkeyCSOMWeb" -Params $PSBoundParameters
                $_Web = Get-MonkeyCSOMWeb @p
                if($_Web){
                    #Remove Endpoint if exists
                    [void]$PSBoundParameters.Remove('Endpoint');
                    $_Web | Get-MonkeyCSOMSiteAccessRequest @PSBoundParameters
                    return
                }
            }
            foreach($_Web in @($Web)){
                #Check for objectType
                $objectType = $_Web | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
                if ($null -ne $objectType -and $objectType -eq 'SP.Web'){
                    If(($_Web | Test-HasUniqueRoleAssignment)){
                        #Set command parameters
                        $p = Set-CommandParameter -Command "Get-MonkeyCSOMList" -Params $PSBoundParameters
                        #Add Filter
                        [void]$p.Add('Filter','Access Requests');
                        #Add Web
                        $p.Item('Web') = $_Web
                        #Execute query
                        $arList = Get-MonkeyCSOMList @p
                        if($null -ne $arList){
                            #Set command parameters
                            $p = Set-CommandParameter -Command "Get-MonkeyCSOMListItem" -Params $PSBoundParameters
                            #Add List
                            $p.Item('List') = $arList;
                            $access_requests = Get-MonkeyCSOMListItem @p
                            if($null -ne $access_requests){
                                $access_requests | New-MonkeyCSOMSiteAccesRequestObject
                            }
                        }
                    }
                }
                Else{
                    $msg = @{
                        MessageData = ($message.SPOInvalidWebObjectMessage);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'Warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('MonkeyCSOMInvalidWebObject');
                    }
                    Write-Warning @msg
                }
            }
        }
        Catch{
            Write-Error $_
        }
    }
}


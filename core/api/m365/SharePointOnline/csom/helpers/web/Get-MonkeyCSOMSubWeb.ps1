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

Function Get-MonkeyCSOMSubWeb{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSubWeb
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$true, ParameterSetName = 'Web', ValueFromPipeline = $true, HelpMessage="Web Object")]
        [Object]$Web,

        [parameter(Mandatory=$true, ParameterSetName = 'Endpoint', HelpMessage="SharePoint Url")]
        [Object]$Endpoint,

        [parameter(Mandatory=$false, HelpMessage="Recursive search")]
        [Switch]$Recurse,

        [Parameter(Mandatory=$false, HelpMessage="Subsite depth limit recursion")]
        [int32]$Limit = 10
    )
    Begin{
        $count = 0
        $_Web = $null
        #Xml Post data
        $subsite_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="26" ObjectPathId="3"><Query SelectAllProperties="true"><Properties><Property Name="Webs" SelectAll="true"><Query SelectAllProperties="true"><Properties/></Query></Property></Properties></Query></Query></Actions><ObjectPaths><Identity Id="3" Name="{0}"/></ObjectPaths></Request>'
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq "Endpoint" -or $PSCmdlet.ParameterSetName -eq "Current"){
            #Set command parameters
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMWeb" -Params $PSBoundParameters
            #Remove recurse and limit
            [void]$p.Remove('Recurse');
            [void]$p.Remove('Limit');
            $_Web = Get-MonkeyCSOMWeb @p
            if($null -ne $_Web){
                $p = Set-CommandParameter -Command "Get-MonkeyCSOMSubWeb" -Params $PSBoundParameters
                #Remove Endpoint if exists
                [void]$p.Remove('Endpoint');
                $_Web | Get-MonkeyCSOMSubWeb @p
                return
            }
        }
        Else{
            foreach($_Web in @($PSBoundParameters['Web'])){
                $objectType = $_Web | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
                if ($null -ne $objectType -and $objectType -eq 'SP.Web'){
                    $Webs_Data = $subsite_data.Clone()
                    $Webs_Data = ($Webs_Data -f $_Web._ObjectIdentity_)
                    #Set command parameters
                    $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMRequest" -Params $PSBoundParameters
                    #Add authentication header if missing
                    if(!$p.ContainsKey('Authentication')){
                        if($null -ne $O365Object.auth_tokens.SharePointOnline){
                            [void]$p.Add('Authentication',$O365Object.auth_tokens.SharePointOnline);
                        }
                        Else{
                            Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online")
                            break
                        }
                    }
                    #Add endpoint
                    [void]$p.Add('Endpoint',$_Web.Url);
                    #Add select
                    [void]$p.Add('Select','Webs');
                    #Add post Data
                    [void]$p.Add('Data',$Webs_Data);
                    #Execute query
                    $allWebs = Invoke-MonkeyCSOMRequest @p
                    if($allWebs){
                        #Update count
                        $count+=1
                        Write-Output $allWebs -NoEnumerate
                        if($PSBoundParameters.ContainsKey('Recurse') -and $PSBoundParameters['Recurse'].IsPresent){
                            $queue = [System.Collections.Generic.Queue[object]]::new(2000)
                            @($allWebs).ForEach({[void]$queue.Enqueue($_)});
                            While($queue.Count -gt 0){
                                $_web = $queue.Dequeue()
                                $Webs_Data = $subsite_data.Clone()
                                $Webs_Data =($Webs_Data -f $_web._ObjectIdentity_)
                                #Update parameter
                                $p.Data = $Webs_Data;
                                $p.Endpoint = $_web.Url;
                                #Construct query
                                $my_webs = Invoke-MonkeyCSOMRequest @p
                                if($my_webs){
                                    foreach($_nWeb in @($my_webs)){
                                        #Add count
                                        $count+=1
                                        if($count -ge $Limit){
                                            break;
                                        }
                                        #Add to queue
                                        $queue.Enqueue($_nWeb);
                                        write-output $_nWeb
                                    }
                                }
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
    }
    End{
        #Nothing to do here
    }
}

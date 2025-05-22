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


Function Get-MonkeyCSOMExternalUser{
    <#
        .SYNOPSIS
		Get external users from Sharepoint Online Web

        .DESCRIPTION
		Get external users from Sharepoint Online Web

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMExternalUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(DefaultParameterSetName = 'Current')]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, ParameterSetName = 'Endpoint', HelpMessage="SharePoint Url")]
        [Object]$Endpoint,

        [parameter(Mandatory=$false, ParameterSetName = 'Web',ValueFromPipeline = $true, HelpMessage="SSharePoint Web Object")]
        [Object]$Web
    )
    Begin{
        #Set generic list
        $externalCollection = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        $_Endpoint = $null;
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq "Current"){
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMWeb" -Params $PSBoundParameters
            $_Web = Get-MonkeyCSOMWeb @p
            if($_Web){
                $_Endpoint = $_Web.Url
            }
        }
        ElseIf($PSCmdlet.ParameterSetName -eq "Web"){
            $objectType = $PSBoundParameters['Web'] | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
            #Check for objectType
            if ($null -ne $objectType -and $objectType -eq 'SP.Web'){
                $_Endpoint = $PSBoundParameters['Web'].Url;
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
        Else{
            $_Endpoint = $PSBoundParameters['EndPoint']
        }
    }
    End{
        if($null -ne $_Endpoint){
            $position = 0;
            while ($true){
                $body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="320" ObjectPathId="319" /><Query Id="321" ObjectPathId="319"><Query SelectAllProperties="false"><Properties><Property Name="TotalUserCount" ScalarProperty="true" /><Property Name="UserCollectionPosition" ScalarProperty="true" /><Property Name="ExternalUserCollection"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="DisplayName" ScalarProperty="true" /><Property Name="InvitedAs" ScalarProperty="true" /><Property Name="UniqueId" ScalarProperty="true" /><Property Name="AcceptedAs" ScalarProperty="true" /><Property Name="WhenCreated" ScalarProperty="true" /><Property Name="InvitedBy" ScalarProperty="true" /></Properties></ChildItemQuery></Property></Properties></Query></Query></Actions><ObjectPaths><Method Id="319" ParentId="316" Name="GetExternalUsersForSite"><Parameters><Parameter Type="String">${site}</Parameter><Parameter Type="Int32">${position}</Parameter><Parameter Type="Int32">50</Parameter><Parameter Type="Null" /><Parameter Type="Enum">0</Parameter></Parameters></Method><Constructor Id="316" TypeId="{e45fd516-a408-4ca4-b6dc-268e2f1f0f83}" /></ObjectPaths></Request>' -replace '\${site}',$_Endpoint -replace '\${position}',$position
                #Set command parameters
                $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMRequest" -Params $PSBoundParameters
                #Remove Endpoint
                $p.Remove('Endpoint')
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
                #Add Body
                [void]$p.Add('Data',$body_data);
                #Execute query
                $raw_external = Invoke-MonkeyCSOMRequest @p
                if($null -ne $raw_external -and $null -ne ($raw_external | Select-Object -ExpandProperty ExternalUserCollection -ErrorAction Ignore)){
                    #Get Position
                    $position = $raw_external.UserCollectionPosition
                    #Get users
                    foreach($user in $raw_external.ExternalUserCollection._Child_Items_){
                        $user | Add-Member NoteProperty -Name SiteUrl -Value $_Endpoint
                        #Try to get Date
                        try{
                            if($null -ne $user.PsObject.Properties.Item('WhenCreated') -and $null -ne $user.WhenCreated){
                                $user.WhenCreated = $user.WhenCreated | Convert-SharePointOnlineDateString
                            }
                        }
                        catch{
                            $msg = @{
                                MessageData = ($_);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'verbose';
                                Verbose = $O365Object.verbose;
                                Tags = @('MonkeyCSOMInvalidDateTimeObject');
                            }
                            Write-Verbose @msg
                        }
                        #Add to list
                        [void]$externalCollection.Add($user)
                    }
                    if($position -eq -1 -or $position -eq $raw_external.TotalUserCount){
                        break;
                    }
                }
                Else{
                    break;
                }
            }
        }
        #return object
        if($externalCollection.Count -gt 0){
            Write-Output $externalCollection -NoEnumerate
        }
    }
}


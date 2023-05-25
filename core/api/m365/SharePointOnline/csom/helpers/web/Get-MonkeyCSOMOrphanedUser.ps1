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


Function Get-MonkeyCSOMOrphanedUser{
    <#
        .SYNOPSIS
		Get orphaned users from Sharepoint Online Web

        .DESCRIPTION
		Get orphaned users from Sharepoint Online Web

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMOrphanedUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [Parameter(Mandatory= $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName  = $true, HelpMessage="SharePoint Web Object")]
        [Object]$Web,

        [parameter(Mandatory= $True, HelpMessage="Authentication Object")]
        [Object]$Authentication
    )
    Begin{
        #body data
		[xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="52" ObjectPathId="5"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true"/><Property Name="Title" ScalarProperty="true"/><Property Name="LoginName" ScalarProperty="true"/><Property Name="Email" ScalarProperty="true"/><Property Name="IsShareByEmailGuestUser" ScalarProperty="true"/><Property Name="IsSiteAdmin" ScalarProperty="true"/><Property Name="UserId" ScalarProperty="true"/><Property Name="IsHiddenInUI" ScalarProperty="true"/><Property Name="PrincipalType" ScalarProperty="true"/><Property Name="AadObjectId" ScalarProperty="true"/><Property Name="UserPrincipalName" ScalarProperty="true"/><Property Name="Alerts"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Title" ScalarProperty="true"/><Property Name="Status" ScalarProperty="true"/></Properties></ChildItemQuery></Property><Property Name="Groups"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true"/><Property Name="Title" ScalarProperty="true"/><Property Name="LoginName" ScalarProperty="true"/></Properties></ChildItemQuery></Property></Properties></ChildItemQuery></Query></Actions><ObjectPaths><Property Id="5" ParentId="3" Name="SiteUsers"/><Property Id="3" ParentId="1" Name="Web"/><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current"/></ObjectPaths></Request>'
    }
    Process{
        #Set generic list
        $orphanedCollection = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
        #Check for objectType
        if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            $msg = @{
				MessageData = ($message.SPSCheckSiteForOrphanedObjects -f $Web.url);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'info';
				InformationAction = $InformationAction;
				Tags = @('SPSOrphanedObjectInfo');
			}
			Write-Information @msg
            $p = @{
                Authentication = $Authentication;
                Endpoint = $Web.Url;
                Data = $body_data;
                ChildItems = $true;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            #Construct query
            $all_users = Invoke-MonkeyCSOMRequest @p
            if($all_users){
                $all_users = $all_users | Where-Object {
			        $_.Title.ToLower() -ne "everyone"`
 					    -and $_.Title.ToLower() -ne "everyone except external users"`
 					    -and $_.Title.ToLower() -ne "sharepoint app"`
 					    -and $_.Title.ToLower() -ne "system account"`
 					    -and $_.Title.ToLower() -ne "nt service\spsearch"`
 					    -and $_.Title.ToLower() -ne "sharepoint service administrator"`
 					    -and $_.Title.ToLower() -ne "global administrator"`
                        -and $_.Title.ToLower() -ne "all users (windows)"`
                        -and $_.Title.ToLower() -ne "guest contributor"
			    }
            }
            if($all_users){
                foreach($object in $all_users){
                    if($null -ne $object.AadObjectId -and $object.AadObjectId.PsObject.Properties.Item('NameId')){
                        $objectId = $object.AadObjectId.NameId
                    }
                    else{
                        $objectId = $null
                    }
                    if($null -ne $objectId){
                        if ($object.principalType -eq [principalType]::User){
                            $p = @{
                                UserId = $objectId;
                                Select = "accountEnabled";
                                BypassMFACheck = $true;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $graphUser = Get-MonkeyMSGraphUser @p
                            if ($null -eq $graphUser) {
								$object | Add-Member NoteProperty -Name SiteUrl -Value $Web.Url
								$object | Add-Member NoteProperty -Name orphanedType -Value "deleted"
								#Add to array
								[void]$orphanedCollection.Add($object)
							}
                            elseif ($null -ne $graphUser -and $graphUser.accountEnabled -eq $false) {
							    $object | Add-Member NoteProperty -Name SiteUrl -Value $site.Url
								$object | Add-Member NoteProperty -Name orphanedType -Value "disabled"
								#Add to array
								[void]$orphanedCollection.Add($object)
							}
                        }
                        elseif($object.principalType -eq [principalType]::SecurityGroup){
                            $p = @{
                                GroupId = $objectId;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $graphObject = Get-MonkeyMSGraphGroup @p
                            if ($null -eq $graphObject) {
								$object | Add-Member NoteProperty -Name SiteUrl -Value $Web.Url
								$object | Add-Member NoteProperty -Name orphanedType -Value "deleted"
								#Add to array
								[void]$orphanedCollection.Add($object)
							}
                        }
                    }
                    else{
                        #Potentially deleted user
                        $object | Add-Member NoteProperty -Name SiteUrl -Value $Web.Url
						$object | Add-Member NoteProperty -Name orphanedType -Value "deleted"
                        #Add to array
						[void]$orphanedCollection.Add($object)
                    }
                }
            }
        }
        else{
            $msg = @{
                MessageData = ($message.SPOInvalieWebObjectMessage);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('SPOInvalidWebObject');
            }
            Write-Warning @msg
        }
    }
    End{
        #return orphaned users
        #return , $orphanedCollection
        Write-Output $orphanedCollection -NoEnumerate
    }
}

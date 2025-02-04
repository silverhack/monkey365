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


Function Get-MonkeyCSOMOrphanedIdentity{
    <#
        .SYNOPSIS
		Get orphaned users and groups from Sharepoint Online

        .DESCRIPTION
		Get orphaned users and groups from Sharepoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMOrphanedIdentity
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [Parameter(Mandatory= $false, ParameterSetName = 'Web', ValueFromPipeline = $true, ValueFromPipelineByPropertyName  = $true, HelpMessage="SharePoint Web Object")]
        [Object]$Web,

        [parameter(Mandatory= $false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory= $false, ParameterSetName = 'Endpoint', HelpMessage="SharePoint url")]
        [String]$Endpoint
    )
    Begin{
        #Set null
        $all_users = $orphanedIds = $null;
        #body data
		[xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="52" ObjectPathId="5"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true"/><Property Name="Title" ScalarProperty="true"/><Property Name="LoginName" ScalarProperty="true"/><Property Name="Email" ScalarProperty="true"/><Property Name="IsShareByEmailGuestUser" ScalarProperty="true"/><Property Name="IsSiteAdmin" ScalarProperty="true"/><Property Name="UserId" ScalarProperty="true"/><Property Name="IsHiddenInUI" ScalarProperty="true"/><Property Name="PrincipalType" ScalarProperty="true"/><Property Name="AadObjectId" ScalarProperty="true"/><Property Name="UserPrincipalName" ScalarProperty="true"/><Property Name="Alerts"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Title" ScalarProperty="true"/><Property Name="Status" ScalarProperty="true"/></Properties></ChildItemQuery></Property><Property Name="Groups"><Query SelectAllProperties="false"><Properties/></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true"/><Property Name="Title" ScalarProperty="true"/><Property Name="LoginName" ScalarProperty="true"/></Properties></ChildItemQuery></Property></Properties></ChildItemQuery></Query></Actions><ObjectPaths><Property Id="5" ParentId="3" Name="SiteUsers"/><Property Id="3" ParentId="1" Name="Web"/><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current"/></ObjectPaths></Request>'
    }
    Process{
        try{
            If($O365Object.canRequestGroupsFromMsGraph -and $O365Object.canRequestUsersFromMsGraph){
                If($PSCmdlet.ParameterSetName -eq "Endpoint" -or $PSCmdlet.ParameterSetName -eq "Current"){
                    $_Web = Get-MonkeyCSOMWeb @PSBoundParameters
                    if($null -ne $_Web){
                        #Remove Endpoint if exists
                        [void]$PSBoundParameters.Remove('Endpoint')
                        $_Web | Get-MonkeyCSOMOrphanedIdentity @PSBoundParameters
                        return
                    }
                }
                Foreach($_Web in @($PSBoundParameters['Web'])){
                    #Set array
                    $batchObjects = [System.Collections.Generic.List[System.Object]]::new()
                    #Set generic list
                    $orphanedIdentities = [System.Collections.Generic.List[System.Object]]::new()
                    $msg = @{
				        MessageData = ($message.SPSCheckSiteForOrphanedObjects -f $_Web.Url);
				        callStack = (Get-PSCallStack | Select-Object -First 1);
				        logLevel = 'info';
				        InformationAction = $O365Object.InformationAction;
				        Tags = @('MonkeyCSOMOrphanedObjectInfo');
			        }
			        Write-Information @msg
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
                    #Add post Data
                    [void]$p.Add('Data',$body_data);
                    #Add ChidItems
                    [void]$p.Add('ChildItems',$true);
                    #Execute query
                    $all_users = Invoke-MonkeyCSOMRequest @p
                    $all_users = @($all_users).Where({
			            $_.Title.ToLower() -ne "everyone"`
 					        -and $_.Title.ToLower() -ne "everyone except external users"`
 					        -and $_.Title.ToLower() -ne "sharepoint app"`
 					        -and $_.Title.ToLower() -ne "system account"`
 					        -and $_.Title.ToLower() -ne "nt service\spsearch"`
 					        -and $_.Title.ToLower() -ne "sharepoint service administrator"`
 					        -and $_.Title.ToLower() -ne "global administrator"`
                            -and $_.Title.ToLower() -ne "all users (windows)"`
                            -and $_.Title.ToLower() -ne "guest contributor"
			        });
                    #Filter for all users
                    $all_objects = @($all_users).Where({$_.principalType -eq [principalType]::User -or ($_.loginName -match 'c:0t.c' -or $_.loginName -match 'c:0o.c')})
                    #Get Object Id
                    $_users = $all_objects.Where({$null -ne $_.AadObjectId})
                    $objectIds = $_users.AadObjectId.nameId
                    $objectIds | Split-Array -Elements 1000 | ForEach-Object {
                        $jp = @{
	                        ScriptBlock = { Get-MonkeyMSGraphDirectoryObjectById -Ids $_ -APIVersion beta};
                            InputObject = $_;
	                        Runspacepool = $O365Object.monkey_runspacePool;
	                        ReuseRunspacePool = $true;
	                        Debug = $O365Object.VerboseOptions.Debug;
	                        Verbose = $O365Object.VerboseOptions.Verbose;
	                        MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	                        BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	                        BatchSize = $O365Object.nestedRunspaces.BatchSize;
                        }
                        #Request Entra ID objects
                        $EntraObjects = Invoke-MonkeyJob @jp
                        if($null -eq $EntraObjects){
                            $msg = @{
                                MessageData = "An empty response was received from Entra Id";
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'Verbose';
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Tags = @('Monkey365EnraIdEmptyResponse');
                            }
                            Write-Verbose @msg
                        }
                        ElseIf ($EntraObjects -is [System.Collections.IEnumerable] -and $EntraObjects -isnot [string]){
                            [void]$batchObjects.AddRange($EntraObjects);
                        }
                        ElseIf ($EntraObjects.GetType() -eq [System.Management.Automation.PSCustomObject] -or $EntraObjects.GetType() -eq [System.Management.Automation.PSObject]) {
                            [void]$batchObjects.Add($EntraObjects);
                        }
                        Else{
                            $msg = @{
                                MessageData = "Unable to recognize object from Entra Id";
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'Verbose';
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Tags = @('Monkey365UnrecognizedEnraIdObject');
                            }
                            Write-Verbose @msg
                        }
                    }
                    #Get object Id
                    $entraObjectIds = $batchObjects | Select-Object -ExpandProperty Id -ErrorAction Ignore
                    $disabledUsersIds = $batchObjects.Where({$_."@odata.type" -match '#microsoft.graph.user' -and $_.accountEnabled -eq $false}) | Select-Object -ExpandProperty Id -ErrorAction Ignore
                    #Check if orphaned Ids
                    if($entraObjectIds){
                        $orphanedIds = Compare-Object -ReferenceObject $objectIds -DifferenceObject $entraObjectIds | Select-Object -ExpandProperty InputObject
                    }
                    #Get orphaned users
                    if($null -ne $orphanedIds -and @($orphanedIds).Count -gt 0){
                        @($_users).Where({$_.AadObjectId.nameId -in $orphanedIds}) | ForEach-Object {
                            $_ | Add-Member NoteProperty -Name SiteUrl -Value $_Web.Url -Force
		                    $_ | Add-Member NoteProperty -Name orphanedType -Value "deleted" -Force
                            [void]$orphanedIdentities.Add($_);
                        }
                    }
                    if($null -ne $disabledUsersIds -and @($disabledUsersIds).Count -gt 0){
                        @($_users).Where({$_.AadObjectId.nameId -in $disabledUsersIds}) | ForEach-Object {
                            $_ | Add-Member NoteProperty -Name SiteUrl -Value $_Web.Url -Force
		                    $_ | Add-Member NoteProperty -Name orphanedType -Value "disabled" -Force
                            [void]$orphanedIdentities.Add($_);
                        }
                    }
                    #Check for null nameId
                    $_users = @($all_objects).Where({$null -eq $_.AadObjectId})
                    if($_users.Count -gt 0){
                        $_users.foreach({
                            $_ | Add-Member NoteProperty -Name SiteUrl -Value $_Web.Url -Force
		                    $_ | Add-Member NoteProperty -Name orphanedType -Value "deleted" -Force
                            [void]$orphanedIdentities.Add($_);
                        });
                    }
                }
                Write-Output $orphanedIdentities -NoEnumerate
            }
            Else{
                $msg = @{
                    MessageData = ($message.GraphV2ErrorMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('Monkey365GraphV2Error');
                }
                Write-Warning @msg
            }
        }
        Catch{
            Write-Error $_
        }
    }
    End{
    }
}



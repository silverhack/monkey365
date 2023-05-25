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


Function Get-MonkeyCSOMObjectType{
    <#
        .SYNOPSIS
		Cast Sharepoint Object

        .DESCRIPTION
		Cast Sharepoint Object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMObjectType
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="SharePoint Object: Web, List, Folder or List Item")]
        [Object]$Object
    )
    Begin{
        $regexGuid = '\{?(([0-9a-f]){8}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){12})\}?'
    }
    Process{
        try{
            #Set nulls
            $localPath = $null
            #Set Dictionary
            $obj_dict = [ordered]@{
                ObjectType = $null;
                Title = $null;
                Path = $null;
                Url = $null;
            }
            if($null -ne $Object.PsObject.Properties.Item('_ObjectType_')){
                Switch($Object._ObjectType_.ToString()){
                    "SP.Web"{
                        $obj_dict.ObjectType = "Web";
                        $obj_dict.Title = $Object.Title;
                        $obj_dict.Path = $Object.ServerRelativeUrl;
                        $obj_dict.Url = $Object.Url;
                    }
                    "SP.Site"{
                        $obj_dict.ObjectType = "Site";
                        #Get Title
                        if($null -ne $Object.PsObject.Properties.Item('Id') -and $Object.Id -match $regexGuid){
                            $obj_dict.Title = $Matches[1]
                        }
                        $obj_dict.Path = $Object.ServerRelativeUrl;
                        $obj_dict.Url = $Object.Url;
                    }
                    "SP.ListItem"{
                        if($Object.FileSystemObjectType -eq [FileSystemObjectType]::Folder){
                            $obj_dict.ObjectType = "Folder";
                            if($null -ne $Object.PsObject.Properties.Item('Title') -and $null -ne $Object.Title){
                                $obj_dict.Title = $Object.Title;
                            }
                            elseif($null -ne $Object.PsObject.Properties.Item('FileLeafRef') -and $null -ne $Object.FileLeafRef){
                                $obj_dict.Title = $object.FileLeafRef
                            }
                            if($null -ne $Object.PsObject.Properties.Item('FileRef') -and $null -ne $Object.FileRef){
                                $localPath = $Object.FileRef
                                #Set path
                                $obj_dict.Path = ("{0}" -f $localPath)
                            }
                        }
                        elseif($Object.FileSystemObjectType -eq [FileSystemObjectType]::File){
                            $obj_dict.ObjectType = "File";
                            if($null -ne $Object.PsObject.Properties.Item('Title') -and $null -ne $Object.Title){
                                $obj_dict.Title = $Object.Title;
                            }
                            elseif($null -ne $Object.PsObject.Properties.Item('FileLeafRef') -and $null -ne $object.FileLeafRef){
                                $obj_dict.Title = $object.FileLeafRef
                            }
                            if($null -ne $Object.PsObject.Properties.Item('FileRef') -and $null -ne $object.FileRef){
                                $localPath = $Object.FileRef
                                #Set path
                                $obj_dict.Path = ("{0}" -f $localPath)
                            }
                        }
                        else{
                            $msg = @{
                                MessageData = ("Object not recognized");
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'warning';
                                InformationAction = $O365Object.InformationAction;
                                Tags = @('SPSUnableToGetListItemInfoType');
                            }
                            Write-Warning @msg
                        }
                    }
                    Default{
                        if($null -ne $Object.PsObject.Properties.Item('BaseType')){
                            if([enum]::IsDefined([System.Type]([BaseType]),[System.Int32]$Object.BaseType)){
                                $localPath = [string]::Empty
                                $obj_dict.ObjectType = [BaseType]$Object.BaseType #List, DocumentLibrary, etc
                                if($null -ne $Object.PsObject.Properties.Item('Title') -and $null -ne $Object.Title){
                                    $obj_dict.Title = $Object.Title
                                }
                                #Get Path
                                if($null -ne $Object.PsObject.Properties.Item('ParentWebUrl') -and $null -ne $Object.ParentWebUrl){
                                    $localPath = ("{0}{1}" -f $localPath, $Object.ParentWebUrl)
                                }
                                if($null -ne $Object.PsObject.Properties.Item('FileRef') -and $null -ne $Object.FileRef){
                                    $localPath = ("{0}/{1}" -f $localPath, $Object.FileRef)
                                }
                                elseif($null -ne $Object.PsObject.Properties.Item('EntityTypeName') -and $null -ne $Object.EntityTypeName){
                                    $localPath = ("{0}/{1}" -f $localPath, $Object.EntityTypeName.Replace('OData__x005f','').Replace('_x002f_','/').Replace('_x0020_',' '))
                                }
                                #Remove double slashes
                                $localPath = [regex]::Replace($localPath,"/+","/")
                                #Set Path
                                $obj_dict.Path = ("{0}" -f $localPath)
                            }
                            else{
                                $msg = @{
                                    MessageData = ("Object not recognized");
                                    callStack = (Get-PSCallStack | Select-Object -First 1);
                                    logLevel = 'warning';
                                    InformationAction = $O365Object.InformationAction;
                                    Tags = @('SPSUnableToGetDefaultInfoType');
                                }
                                Write-Warning @msg
                            }
                        }
                        else{
                            $msg = @{
                                MessageData = ("Object not recognized");
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'warning';
                                InformationAction = $O365Object.InformationAction;
                                Tags = @('SPSUnableToGetInfoType');
                            }
                            Write-Warning @msg
                        }
                    }
                }
                #Verbose message
                $msg = @{
                    MessageData = ($message.SPSCastObjectMessage -f $obj_dict.ObjectType);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('SPSObjectTypeInfo');
                }
                Write-Verbose @msg
                #Return Obj
                New-Object PSObject -Property $obj_dict
            }
            else{
                $msg = @{
                    MessageData = ("Unable to cast SharePoint Object");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('SPSUnableToGetInfoType');
                }
                Write-Warning @msg
            }
        }
        catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('SPSUnableToGetInfoType');
            }
            Write-Verbose @msg
        }
    }
}
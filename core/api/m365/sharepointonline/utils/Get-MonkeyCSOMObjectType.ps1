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
        [Object]$InputObject
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
            if($null -ne $InputObject.PsObject.Properties.Item('_ObjectType_')){
                Switch($InputObject._ObjectType_.ToString()){
                    "SP.Web"{
                        $obj_dict.ObjectType = "Web";
                        $obj_dict.Title = $InputObject.Title;
                        $obj_dict.Path = $InputObject.ServerRelativeUrl;
                        $obj_dict.Url = $InputObject.Url;
                    }
                    "SP.Site"{
                        $obj_dict.ObjectType = "Site";
                        #Get Title
                        if($null -ne $InputObject.PsObject.Properties.Item('Id') -and $InputObject.Id -match $regexGuid){
                            $obj_dict.Title = $Matches[1]
                        }
                        $obj_dict.Path = $InputObject.ServerRelativeUrl;
                        $obj_dict.Url = $InputObject.Url;
                    }
                    "SP.ListItem"{
                        if($InputObject.FileSystemObjectType -eq [FileSystemObjectType]::Folder){
                            $obj_dict.ObjectType = "Folder";
                            if($null -ne $InputObject.PsObject.Properties.Item('Title') -and $null -ne $InputObject.Title){
                                $obj_dict.Title = $InputObject.Title;
                            }
                            elseif($null -ne $InputObject.PsObject.Properties.Item('FileLeafRef') -and $null -ne $InputObject.FileLeafRef){
                                $obj_dict.Title = $InputObject.FileLeafRef
                            }
                            if($null -ne $InputObject.PsObject.Properties.Item('FileRef') -and $null -ne $InputObject.FileRef){
                                $localPath = $InputObject.FileRef
                                #Set path
                                $obj_dict.Path = ("{0}" -f $localPath)
                            }
                        }
                        elseif($InputObject.FileSystemObjectType -eq [FileSystemObjectType]::File){
                            $obj_dict.ObjectType = "File";
                            if($null -ne $InputObject.PsObject.Properties.Item('Title') -and $null -ne $InputObject.Title){
                                $obj_dict.Title = $InputObject.Title;
                            }
                            elseif($null -ne $InputObject.PsObject.Properties.Item('FileLeafRef') -and $null -ne $InputObject.FileLeafRef){
                                $obj_dict.Title = $InputObject.FileLeafRef
                            }
                            if($null -ne $InputObject.PsObject.Properties.Item('FileRef') -and $null -ne $InputObject.FileRef){
                                $localPath = $InputObject.FileRef
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
                                Tags = @('MonkeyCSOMUnableToGetListItemInfoType');
                            }
                            Write-Warning @msg
                        }
                    }
                    Default{
                        if($null -ne $InputObject.PsObject.Properties.Item('BaseType')){
                            if([enum]::IsDefined([System.Type]([BaseType]),[System.Int32]$InputObject.BaseType)){
                                $localPath = [string]::Empty
                                $obj_dict.ObjectType = [BaseType]$InputObject.BaseType #List, DocumentLibrary, etc
                                if($null -ne $InputObject.PsObject.Properties.Item('Title') -and $null -ne $InputObject.Title){
                                    $obj_dict.Title = $InputObject.Title
                                }
                                #Get Path
                                if($null -ne $InputObject.PsObject.Properties.Item('ParentWebUrl') -and $null -ne $InputObject.ParentWebUrl){
                                    $localPath = ("{0}{1}" -f $localPath, $InputObject.ParentWebUrl)
                                }
                                if($null -ne $InputObject.PsObject.Properties.Item('FileRef') -and $null -ne $InputObject.FileRef){
                                    $localPath = ("{0}/{1}" -f $localPath, $InputObject.FileRef)
                                }
                                elseif($null -ne $InputObject.PsObject.Properties.Item('EntityTypeName') -and $null -ne $InputObject.EntityTypeName){
                                    $localPath = ("{0}/{1}" -f $localPath, $InputObject.EntityTypeName.Replace('OData__x005f','').Replace('_x002f_','/').Replace('_x0020_',' '))
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
                                    logLevel = 'Warning';
                                    InformationAction = $O365Object.InformationAction;
                                    Tags = @('MonkeyCSOMUnableToGetDefaultInfoType');
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
                                Tags = @('MonkeyCSOMUnableToGetInfoType');
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
                    Tags = @('MonkeyCSOMObjectTypeInfo');
                }
                Write-Verbose @msg
                #Return Obj
                New-Object PSObject -Property $obj_dict
            }
            else{
                $msg = @{
                    MessageData = ("SharePoint Object not recognized");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyCSOMUnableToGetInfoType');
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
                Tags = @('MonkeyCSOMUnableToGetInfoType');
            }
            Write-Verbose @msg
        }
    }
}

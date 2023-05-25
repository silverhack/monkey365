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

Function Get-MonkeyCSOMSharingInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSharingInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, HelpMessage="Endpoint")]
        [String]$Endpoint,

        [parameter(Mandatory=$True, HelpMessage="ObjectId")]
        [String]$ObjectId
    )
    Begin{
        $out_obj = $null
        $body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey 365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="31905" ObjectPathId="32996" /><Query Id="31906" ObjectPathId="32996"><Query SelectAllProperties="true"><Properties /></Query></Query></Actions><ObjectPaths><StaticMethod Id="32996" Name="GetObjectSharingInformation" TypeId="{e7dae9f6-8ca5-4286-92c8-61941d774c44}"><Parameters><Parameter ObjectPathId="20" /><Parameter Type="Boolean">false</Parameter><Parameter Type="Boolean">false</Parameter><Parameter Type="Boolean">false</Parameter><Parameter Type="Boolean">true</Parameter><Parameter Type="Boolean">true</Parameter><Parameter Type="Boolean">true</Parameter><Parameter Type="Boolean">true</Parameter></Parameters></StaticMethod><Identity Id="20" Name="${objectId}" /></ObjectPaths></Request>' -replace '\${objectId}', $ObjectId
        $objectMetadata = @{
            "CheckValue"=1;
            "isEqualTo"=31905;
            "GetValue"=4;
        }
        $param = @{
            Authentication = $Authentication;
            Data = $body_data;
            Endpoint= $Endpoint;
            ObjectMetadata = $objectMetadata;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        #Construct query
        $raw_data = Invoke-MonkeyCSOMDefaultRequest @param
    }
    Process{
        if($raw_data){
            if($null -ne $raw_data.psobject.Properties.Item('_Child_Items_')){
                $out_obj = $raw_data._Child_Items_
            }
            else{
                $out_obj = $raw_data
            }
        }
    }
    End{
        if($null -ne $out_obj){
            return $out_obj
        }
    }
}

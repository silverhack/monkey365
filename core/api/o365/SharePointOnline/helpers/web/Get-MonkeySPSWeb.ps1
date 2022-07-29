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

Function Get-MonkeySPSWeb{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPSWeb
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$endpoint,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [Switch]$recurse,

        [Parameter(Mandatory=$false, HelpMessage="Subsite depth limit recursion")]
        [int32]$limit = 10
    )
    Begin{
        $raw_sps_web = @()
        #Get PNPWeb
        $body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey 365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="2" ObjectPathId="1"/><ObjectPath Id="4" ObjectPathId="3"/><Query Id="5" ObjectPathId="3"><Query SelectAllProperties="true"><Properties/></Query></Query></Actions><ObjectPaths><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current"/><Property Id="3" ParentId="1" Name="Web"/></ObjectPaths></Request>'
        #subsite data
        $subsite_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey 365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="26" ObjectPathId="3"><Query SelectAllProperties="true"><Properties><Property Name="Webs" SelectAll="true"><Query SelectAllProperties="true"><Properties/></Query></Property></Properties></Query></Query></Actions><ObjectPaths><Identity Id="3" Name="{0}"/></ObjectPaths></Request>'
    }
    Process{
        $params = @{
            Authentication = $Authentication;
            Data = $body_data;
            Endpoint = $endpoint;
        }
        #Construct query
        $raw_web = Invoke-MonkeySPSUrlRequest @params
        if($raw_web){
            $raw_sps_web+=$raw_web
        }
        #Check if recurse
        if($recurse.IsPresent -and $raw_web){
            $msg = @{
                MessageData = ($message.SharepointSubSitesMessage -f $raw_web.Url);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                Tags = @('SPSSearchSubsites');
            }
            Write-Information @msg
            #raw xml
            $body_data = $subsite_data.Clone()
            $body_data = ($body_data -f $raw_web._ObjectIdentity_)
            #Object Metadata
            $objectMetadata = @{
                "CheckValue"=1;
                "isEqualTo"=26;
                "GetValue"=2;
                "ChildItems"="Webs";
            }
            #Perform query
            $params = @{
                Authentication = $Authentication;
                Data = $body_data;
                objectMetadata= $objectMetadata;
                Endpoint = $raw_web.Url;
            }
            #Construct query
            $subWebs = Invoke-MonkeySPSDefaultUrlRequest @params
            if($subWebs){
                $raw_sps_web+=$subWebs
            }
            $count = 0
            if($subWebs){
                while($count -ne $limit -or $null -ne $subWebs){
                    foreach($raw_web in $subWebs){
                        $body_data = $subsite_data.Clone()
                        $body_data = ($body_data -f $raw_web._ObjectIdentity_)
                        #Perform query
                        $params = @{
                            Authentication = $Authentication;
                            Data = $body_data;
                            objectMetadata= $objectMetadata;
                            Endpoint = $raw_web.Url;
                        }
                        #Construct query
                        $subWebs = Invoke-MonkeySPSDefaultUrlRequest @params
                        if($subWebs){
                            $raw_sps_web+=$subWebs
                        }
                    }
                    $count+=1
                }
            }
        }
    }
    End{
        if($raw_sps_web){
            return $raw_sps_web
        }
        else{
            Write-Warning "Web not found"
        }
    }
}

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
    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, HelpMessage="Web Object")]
        [Object]$Web,

        [parameter(Mandatory=$false, HelpMessage="Recursive search")]
        [Switch]$Recurse,

        [Parameter(Mandatory=$false, HelpMessage="Subsite depth limit recursion")]
        [int32]$Limit = 1
    )
    Begin{
        $raw_webs = $null
        #set generic list
        $all_subWebs = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
        #Xml Post data
        $subsite_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="26" ObjectPathId="3"><Query SelectAllProperties="true"><Properties><Property Name="Webs" SelectAll="true"><Query SelectAllProperties="true"><Properties/></Query></Property></Properties></Query></Query></Actions><ObjectPaths><Identity Id="3" Name="{0}"/></ObjectPaths></Request>'
    }
    Process{
        if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            $Webs_Data = $subsite_data.Clone()
            $Webs_Data = ($Webs_Data -f $Web._ObjectIdentity_)
            $p = @{
                Authentication = $Authentication;
                Data = $Webs_Data;
                Endpoint = $Web.Url;
                Select = 'Webs';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            #Construct query
            $raw_webs = Invoke-MonkeyCSOMRequest @p
            foreach($web in @($raw_webs)){
                #Add to list
                [void]$all_subWebs.Add($Web)
            }
        }
        else{
            $msg = @{
                MessageData = ($message.SPOInvalieWebObjectMessage);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $InformationAction;
                Tags = @('SPOInvalidWebObject');
            }
            Write-Warning @msg
        }
        if($PSBoundParameters.ContainsKey('Recurse') -and $PSBoundParameters.Recurse -and @($raw_webs).Count -gt 0){
            $count = 0
            for($i=0;$i -lt @($raw_webs).Count;$i++){
                if($count -gt $Limit){
                    break;
                }
                $Webs_Data = $subsite_data.Clone()
                $Webs_Data = ($Webs_Data -f $raw_webs[$i]._ObjectIdentity_)
                $p = @{
                    Authentication = $Authentication;
                    Data = $Webs_Data;
                    Endpoint = $raw_webs[$i].Url;
                    Select = 'Webs';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                #Construct query
                $my_webs = Invoke-MonkeyCSOMRequest @p
                if($my_webs){
                    foreach($Web in @($my_webs)){
                        $count+=1;
                        #Add to list
                        [void]$all_subWebs.Add($Web)
                        #Add to array
                        $raw_webs+=$Web
                    }
                }
                $count+=1;
            }
        }
    }
    End{
        return $all_subWebs
    }
}

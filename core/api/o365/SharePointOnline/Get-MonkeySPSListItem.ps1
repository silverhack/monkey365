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

Function Get-MonkeySPSListItem{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPSListItem
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True, `
                   ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True, `
                   ValueFromPipeLineByPropertyName = $True)]
        [Object]$list,

        [parameter(ValueFromPipeline = $True, `
                   ValueFromPipeLineByPropertyName = $True)]
        [Int]$pagedSize = 2000,

        [parameter(ValueFromPipeline = $True, `
                   ValueFromPipeLineByPropertyName = $True)]
        [string]$endpoint
    )
    Begin{
        $raw_data = $null
        if($null -eq $Authentication){
            Write-Warning -Message ($message.NullAuthenticationDetected -f "Sharepoint Online")
            return
        }
        $objectPathID = Get-Random -Minimum 20000 -Maximum 50000
        $objectPathID_1 = $objectPathID+1
        $objectPathID_2 = $objectPathID_1+1
        #Fill Post data
        $postData = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="${objectPathID1}" ObjectPathId="${objectPathID}" /><Query Id="${objectPathID2}" ObjectPathId="${objectPathID}"><Query SelectAllProperties="true"><Properties /></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Method Id="${objectPathID}" ParentId="11" Name="GetItems"><Parameters><Parameter TypeId="{3d248d7b-fc86-40a3-aa97-02a75d69fb8a}"><Property Name="AllowIncrementalResults" Type="Boolean">false</Property><Property Name="DatesInUtc" Type="Boolean">true</Property><Property Name="FolderServerRelativePath" Type="Null" /><Property Name="FolderServerRelativeUrl" Type="Null" /><Property Name="ListItemCollectionPosition" Type="Null" /><Property Name="ViewXml" Type="String">&lt;View Scope="RecursiveAll"&gt;&#xD; &lt;Query&gt;&lt;/Query&gt;&#xD; &lt;RowLimit Paged="TRUE"&gt;${pagedSize}&lt;/RowLimit&gt;&#xD; &lt;/View&gt;</Property></Parameter></Parameters></Method><Identity Id="11" Name="${ListID}" /></ObjectPaths></Request>' -replace '\${ListID}', $list._ObjectIdentity_ -replace '\${pagedSize}', $pagedSize -replace '\${objectPathID}',$objectPathID -replace '\${objectPathID1}',$objectPathID_1 -replace '\${objectPathID2}',$objectPathID_2
        $all_items = @()
    }
    Process{
        #Construct query
        $param = @{
            Authentication = $Authentication;
            Data = $postData;
            objectMetadata= $null;
            endpoint = $endpoint;
        }
        $tmp_object = Invoke-MonkeySPSDefaultUrlRequest @param
        if($null -ne $tmp_object -and $tmp_object -is [System.Management.Automation.PSCustomObject]){
            if($tmp_object.psobject.properties.Item('ErrorInfo')){
                #Errors found
                $errorData = $tmp_object[0]
                $errorMessage = "[{0}][{1}]:[{2}]" -f $errorData.ErrorInfo.ErrorTypeName, $errorData.ErrorInfo.ErrorCode, $errorData.ErrorInfo.ErrorMessage
                $msg = @{
                    MessageData = ($message.SPSDetailedErrorMessage -f $errorMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $InformationAction;
                    Tags = @('SPSRequestError');
                }
                Write-Verbose @msg
            }
        }
        elseif($null -ne $tmp_object -and $tmp_object -is [System.Object[]] -and $tmp_object.GetValue(1) -eq $objectPathID_1 `
            -and ($tmp_object.GetValue(4)).GetType().Name -eq "PsCustomObject"){
            #Get object
            $raw_data = $tmp_object.GetValue(4)
        }
        else{
            Write-Verbose ("Unable to get list item")
            Write-Debug $tmp_object
        }
        #Check if childitems
        if($null -ne $raw_data -and $raw_data.psobject.Properties.name -match "_Child_Items_"){
            $all_items += $raw_data._Child_Items_
        }
        $nextLink = $raw_data.ListItemCollectionPosition.PagingInfo -replace "&", "&amp;"
        #Sumo al objectpathid el pagedsize
        $objectPathID = $objectPathID + $pagedSize + 4
        $objectPathID_1 = $objectPathID + 1
        $objectPathID_2 = $objectPathID_1 + 1
        #Check for paging objects
        if ($nextLink){
            while ($null -ne $nextLink){
                $postData = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="${objectPathID1}" ObjectPathId="${objectPathID}" /><Query Id="${objectPathID2}" ObjectPathId="${objectPathID}"><Query SelectAllProperties="true"><Properties /></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Method Id="${objectPathID}" ParentId="11" Name="GetItems"><Parameters><Parameter TypeId="{3d248d7b-fc86-40a3-aa97-02a75d69fb8a}"><Property Name="AllowIncrementalResults" Type="Boolean">false</Property><Property Name="DatesInUtc" Type="Boolean">true</Property><Property Name="FolderServerRelativePath" Type="Null" /><Property Name="FolderServerRelativeUrl" Type="Null" /><Property Name="ListItemCollectionPosition" TypeId="{922354eb-c56a-4d88-ad59-67496854efe1}"><Property Name="PagingInfo" Type="String">${PageID}</Property></Property><Property Name="ViewXml" Type="String">&lt;View Scope="RecursiveAll"&gt;&#xD; &lt;Query&gt;&lt;/Query&gt;&#xD; &lt;RowLimit Paged="TRUE"&gt;${pagedSize}&lt;/RowLimit&gt;&#xD; &lt;/View&gt;</Property></Parameter></Parameters></Method><Identity Id="11" Name="${ListID}" /></ObjectPaths></Request>' -replace '\${ListID}', $list._ObjectIdentity_ -replace '\${pagedSize}', $pagedSize -replace '\${PageID}', $nextLink -replace '\${objectPathID}',$objectPathID -replace '\${objectPathID1}',$objectPathID_1 -replace '\${objectPathID2}',$objectPathID_2
                #Make RestAPI call
                $param = @{
                    Authentication = $Authentication;
                    Data = $postData;
                    objectMetadata= $null;
                    endpoint = $endpoint;
                }
                $tmp_object = Invoke-MonkeySPSDefaultUrlRequest @param
                if($tmp_object -is [object] -and $tmp_object.GetValue(1) -eq $objectPathID_1 `
                    -and ($tmp_object.GetValue(4)).GetType().Name -eq "PsCustomObject"){
                    #Get object
                    $raw_data = $tmp_object.GetValue(4)
                }
                #Check if childitems
                if($null -ne $raw_data -and $raw_data.psobject.Properties.name -match "_Child_Items_"){
                    $all_items += $raw_data._Child_Items_
                }
                $nextLink = $raw_data.ListItemCollectionPosition.PagingInfo
                if($null -ne $nextLink){
                    $nextLink = $nextLink -replace "&", "&amp;"
                    $objectPathID = $objectPathID + $pagedSize + 4
                    $objectPathID_1 = $objectPathID + 1
                    $objectPathID_2 = $objectPathID_1 + 1
                }
            }
        }
    }
    End{
        if($all_items){
            $all_clean_objs = @()
            foreach($obj in $all_items){
                #Clean object
                $_object = New-Object -TypeName PSCustomObject
                foreach($elem in $obj.psobject.properties){
                    if($elem.Name.Contains("$")){
                        $_object | Add-Member NoteProperty -name $elem.Name.Split('$')[0] -value $elem.Value -Force
                    }
                    else{
                        $_object | Add-Member NoteProperty -name $elem.Name -value $elem.Value -Force
                    }
                }
                if($_object){
                    $all_clean_objs += $_object
                }
            }
            if($all_clean_objs){
                return $all_clean_objs
            }
            else{
                return $all_items
            }
        }
    }
}

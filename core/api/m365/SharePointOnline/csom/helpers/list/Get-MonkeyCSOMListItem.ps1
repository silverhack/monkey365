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

Function Get-MonkeyCSOMListItem{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMListItem
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $True, ValueFromPipeline = $true, HelpMessage="SharePoint List Object")]
        [Object]$List,

        [Parameter(Mandatory= $false, HelpMessage="Paged Size")]
        [Int]$PagedSize = 500,

        [Parameter(Mandatory= $false, HelpMessage="EndPoint")]
        [string]$Endpoint
    )
    Begin{
        $raw_data = $postData = $null
        $objectPathID = Get-Random -Minimum 20000 -Maximum 50000
        $objectPathID_1 = $objectPathID+1
        $objectPathID_2 = $objectPathID_1+1
        #Set generic list
        $all_items = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
    }
    Process{
        $objectType = $PSBoundParameters['List'] | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
        if ($null -ne $objectType -and $objectType -eq 'SP.List'){
            #Fill Post data
            $postData = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="${objectPathID1}" ObjectPathId="${objectPathID}" /><Query Id="${objectPathID2}" ObjectPathId="${objectPathID}"><Query SelectAllProperties="true"><Properties /></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Method Id="${objectPathID}" ParentId="11" Name="GetItems"><Parameters><Parameter TypeId="{3d248d7b-fc86-40a3-aa97-02a75d69fb8a}"><Property Name="AllowIncrementalResults" Type="Boolean">false</Property><Property Name="DatesInUtc" Type="Boolean">true</Property><Property Name="FolderServerRelativePath" Type="Null" /><Property Name="FolderServerRelativeUrl" Type="Null" /><Property Name="ListItemCollectionPosition" Type="Null" /><Property Name="ViewXml" Type="String">&lt;View Scope="RecursiveAll"&gt;&#xD; &lt;Query&gt;&lt;/Query&gt;&#xD; &lt;RowLimit Paged="TRUE"&gt;${pagedSize}&lt;/RowLimit&gt;&#xD; &lt;/View&gt;</Property></Parameter></Parameters></Method><Identity Id="11" Name="${ListID}" /></ObjectPaths></Request>' -replace '\${ListID}', $PSBoundParameters['List']._ObjectIdentity_ -replace '\${pagedSize}', $pagedSize -replace '\${objectPathID}',$objectPathID -replace '\${objectPathID1}',$objectPathID_1 -replace '\${objectPathID2}',$objectPathID_2
            #Set command parameters
            $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMDefaultRequest" -Params $PSBoundParameters
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
            #Add Post Data
            [void]$p.Add('Data',$postData);
            #Add Object Metadata
            [void]$p.Add('ObjectMetadata',$null);
            #Execute query
            $tmp_object = Invoke-MonkeyCSOMDefaultRequest @p
            if($null -ne $tmp_object -and $tmp_object -is [System.Management.Automation.PSCustomObject]){
                if($null -ne $tmp_object.psobject.properties.Item('ErrorInfo') -and $null -ne $tmp_object.ErrorInfo){
                    #Errors found
                    $errorData = $tmp_object[0]
                    $errorMessage = "[{0}][{1}]:[{2}]" -f $errorData.ErrorInfo.ErrorTypeName, $errorData.ErrorInfo.ErrorCode, $errorData.ErrorInfo.ErrorMessage
                    $msg = @{
                        MessageData = ($message.SPSDetailedErrorMessage -f $errorMessage);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        Verbose = $O365Object.verbose;
                        Tags = @('MonkeyCSOMRequestError');
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
                $msg = @{
                    MessageData = ("Unable to get list item");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Verbose = $O365Object.verbose;
                    Tags = @('MonkeyCSOMRequestError');
                }
                Write-Verbose @msg
            }
            #Check if childitems
            if($null -ne $raw_data -and $null -ne ($raw_data.psobject.Properties.Item('_Child_Items_'))){
                $raw_data._Child_Items_.Foreach({[void]$all_items.Add($_)});
            }
            try{
                $listItemCol = $raw_data | Select-Object -ExpandProperty ListItemCollectionPosition -ErrorAction Ignore
                if($null -ne $listItemCol){
                    $nl = $listItemCol | Select-Object -ExpandProperty PagingInfo -ErrorAction Ignore
                    if($null -ne $nl){
                        $nextLink = $nl -replace "&", "&amp;"
                    }
                    else{
                        $nextLink = $null
                    }
                }
                else{
                    $nextLink = $null;
                }
            }
            catch{
                $nextLink = $null
            }
            #Sum pagedSize and objectpathid
            $objectPathID = $objectPathID + $pagedSize + 4
            $objectPathID_1 = $objectPathID + 1
            $objectPathID_2 = $objectPathID_1 + 1
            #Check for paging objects
            while ($null -ne $nextLink){
                $postData = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="${objectPathID1}" ObjectPathId="${objectPathID}" /><Query Id="${objectPathID2}" ObjectPathId="${objectPathID}"><Query SelectAllProperties="true"><Properties /></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Method Id="${objectPathID}" ParentId="11" Name="GetItems"><Parameters><Parameter TypeId="{3d248d7b-fc86-40a3-aa97-02a75d69fb8a}"><Property Name="AllowIncrementalResults" Type="Boolean">false</Property><Property Name="DatesInUtc" Type="Boolean">true</Property><Property Name="FolderServerRelativePath" Type="Null" /><Property Name="FolderServerRelativeUrl" Type="Null" /><Property Name="ListItemCollectionPosition" TypeId="{922354eb-c56a-4d88-ad59-67496854efe1}"><Property Name="PagingInfo" Type="String">${PageID}</Property></Property><Property Name="ViewXml" Type="String">&lt;View Scope="RecursiveAll"&gt;&#xD; &lt;Query&gt;&lt;/Query&gt;&#xD; &lt;RowLimit Paged="TRUE"&gt;${pagedSize}&lt;/RowLimit&gt;&#xD; &lt;/View&gt;</Property></Parameter></Parameters></Method><Identity Id="11" Name="${ListID}" /></ObjectPaths></Request>' -replace '\${ListID}', $PSBoundParameters['List']._ObjectIdentity_ -replace '\${pagedSize}', $pagedSize -replace '\${PageID}', $nextLink -replace '\${objectPathID}',$objectPathID -replace '\${objectPathID1}',$objectPathID_1 -replace '\${objectPathID2}',$objectPathID_2
                #Update params
                $p.Item('Data') = $postData;
                $tmp_object = Invoke-MonkeyCSOMDefaultRequest @p
                if($tmp_object -is [object] -and $tmp_object.GetValue(1) -eq $objectPathID_1 `
                    -and ($tmp_object.GetValue(4)).GetType().Name -eq "PsCustomObject"){
                    #Get object
                    $raw_data = $tmp_object.GetValue(4)
                }
                #Check if childitems
                if($null -ne $raw_data -and $raw_data.psobject.Properties.name -match "_Child_Items_"){
                    $raw_data._Child_Items_.Foreach({[void]$all_items.Add($_)});
                }
                try{
                    $nextLink = $raw_data.ListItemCollectionPosition.PagingInfo
                }
                catch{
                    $nextLink = $null
                }
                if($null -ne $nextLink){
                    $nextLink = $nextLink -replace "&", "&amp;"
                    $objectPathID = $objectPathID + $pagedSize + 4
                    $objectPathID_1 = $objectPathID + 1
                    $objectPathID_2 = $objectPathID_1 + 1
                }
            }
        }
        Else{
            $msg = @{
                MessageData = "Invalid SharePoint List Object";
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('MonkeyCSOMInvalidListObject');
            }
            Write-Warning @msg
        }
    }
    End{
        if($all_items.Count -gt 0){
            $all_clean_objs = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
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
                    [void]$all_clean_objs.Add($_object);
                }
            }
            if($all_clean_objs.Count -gt 0){
                Write-Output $all_clean_objs -NoEnumerate
            }
            else{
                Write-Output $all_items -NoEnumerate
            }
        }
    }
}


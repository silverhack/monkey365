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

Function Invoke-MonkeyCSOMRequest{
    <#
        .SYNOPSIS
        Send requests using SharePoint client object model (CSOM)

        .DESCRIPTION
        Send requests using SharePoint client object model (CSOM)

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyCSOMRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, HelpMessage="Endpoint")]
        [String]$Endpoint,

        [parameter(Mandatory=$false, HelpMessage="Select Object")]
        [String]$Select,

        [parameter(Mandatory=$false, HelpMessage="ContentType")]
        [String]$Content_Type = "text/xml",

        [parameter(Mandatory=$false, HelpMessage="XML object data")]
        [Xml]$Data,

        [parameter(Mandatory=$false, HelpMessage="Get childitems")]
        [Switch]$ChildItems
    )
    Begin{
        #set null
        $raw_response = $url = $null
        #Set False
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        if($null -eq $Authentication){
            Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online")
            break
        }
        #Get Authorization Header
        $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        #Set Endpoint
        try{
            if($Endpoint){
                $Server = [System.Uri]::new($Endpoint)
            }
            else{
                $Server = [System.Uri]::new($Authentication.resource)
            }
        }
        catch{
            $msg = @{
                MessageData = ($_.Exception.Message);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                Verbose = $Verbose;
                Tags = @('SPSUrlError');
            }
            Write-Verbose @msg
            return
        }
        #Set site path
        if($Server.Segments.Contains('sites/')){
            $sitePath = ("{0}/_vti_bin/client.svc/ProcessQuery" -f $Server.AbsolutePath)
            #Remove double slashes
            $sitePath = [regex]::Replace($sitePath,"/+","/")
        }
        else{
            $sitePath = ("/_vti_bin/client.svc/ProcessQuery")
        }
        #Get Url
        $url = [System.Uri]::new($Server,$sitePath)
        $url = $url.ToString()
        #Construct Request Header
        $requestHeader = @{"Authorization" = $AuthHeader}
        #Set new IDs
        $Id = Get-Random -Minimum 20000 -Maximum 50000
        $opId = Get-Random -Minimum 20000 -Maximum 50000
        #Set Array
        $Ids = New-Object System.Collections.Generic.List[Int32]
        $opIds = New-Object System.Collections.Generic.List[Int32]
        #Set count
        $count = 0
        #Set Ids for Actions
        foreach ($elem in $Data.Request.Actions.GetEnumerator()){
            if($elem.Name -eq 'ObjectPath'){
                #Set Ids
                $elem.id = $Id.ToString()
                $elem.ObjectPathId = $opId.ToString()
                [void]$Ids.Add($Id);
                [void]$opIds.Add($opId);
                #Increment Id
                $Id+=1
                $opId += 1
            }
            if($elem.Name -eq 'Query'){
                if($elem.ParentNode.FirstChild.Name -eq 'ObjectPath'){
                    #Set Ids
                    $elem.id = $Id.ToString()
                    #Add to Array
                    [void]$Ids.Add($Id);
                    try{
                        $opId = $opIds.Item($count-1)
                    }
                    catch{
                        $opId = Get-Random -Minimum 1 -Maximum 10
                    }
                    $elem.ObjectPathId = $opId.ToString();
                    #Add to lopid
                    #[void]$opIds.Add($opId);
                    #Increment ObjectId
                    $Id+=1
                }
                else{
                    #Set Ids
                    $elem.id = $Id.ToString()
                    $elem.ObjectPathId = $opId.ToString()
                    [void]$Ids.Add($Id);
                    #Save OpId
                    [void]$opIds.Add($opId);
                    #Increment Id
                    $Id+=1
                    $opId += 1
                }
            }
            $count+=1
        }
        #Set method
        $count = 0
        #Save last OpId
        if($opIds.Count -eq 0){
            [void]$opIds.Add($opId-1);
        }
        foreach ($elem in $Data.Request.ObjectPaths.GetEnumerator()){
            if($null -ne $elem.PreviousSibling){
                #Get parent Id
                if($null -ne $elem.PreviousSibling.PsObject.Properties.Item('ParentId')){
                    $Id = $elem.PreviousSibling.ParentId
                    $elem.id = $Id.ToString()
                }
                else{
                    try{
                        $Id = $opIds.Item($count)
                    }
                    catch{
                        $Id = Get-Random -Minimum 1 -Maximum 10
                        $opIds.Add($Id)
                    }
                    #Add Id
                    $elem.id = $Id.ToString()
                }
            }
            else{
                #First
                #Get opId
                try{
                    $Id = $opIds.Item($count)
                }
                catch{
                    $Id = Get-Random -Minimum 1 -Maximum 10
                    $opIds.Add($Id)
                }
                #Add Id
                $elem.id = $Id.ToString()
            }
            if($null -ne $elem.Psobject.Properties.Item('ParentId')){
                #Check if Id is in array
                if($elem.Id -in $opIds){
                    <#
                    try{
                        $Id = $elem.PreviousSibling.Id
                    }
                    catch{
                        $Id = Get-Random -Minimum 1 -Maximum 10
                    }
                    #>
                    if($null -ne $elem.PreviousSibling -and $null -ne $elem.PreviousSibling.Psobject.Properties.Item('Id')){
                        $Id = $elem.PreviousSibling.Id
                    }
                    else{
                        $Id = Get-Random -Minimum 1 -Maximum 10
                    }
                }
                else{
                    $Id = Get-Random -Minimum 1 -Maximum 10
                }
                if($Id -ne $elem.Id){
                    try{
                        $elem.ParentId = $Id.ToString()
                    }
                    catch{
                        $Id = Get-Random -Minimum 1 -Maximum 10
                        $elem.ParentId = $Id.ToString()
                    }
                }
                else{
                    $Id = Get-Random -Minimum 1 -Maximum 10
                    $elem.ParentId = $Id.ToString()
                }
                #$opids2+=$Id
            }
            $count+=1
        }
        <#
        foreach ($elem in $Data.Request.ObjectPaths.GetEnumerator()){
            #Get opId
            try{
                $Id = $opIds.Item($count)
            }
            catch{
                $Id = Get-Random -Minimum 1 -Maximum 10
                $opIds.Add($Id)
            }
            $elem.id = $Id.ToString()
            if($null -ne $elem.Psobject.Properties.Item('ParentId')){
                if($null -ne $elem.PreviousSibling -and $elem.PreviousSibling.LocalName -eq 'Property'){
                    #Get parent Id
                    $Id = $elem.PreviousSibling.ParentId
                    $elem.id = $Id.ToString()
                    $opId = Get-Random -Minimum 1 -Maximum 10
                }
                else{
                    #Get opid
                    try{
                        $opId = $elem.PreviousSibling.Id
                    }
                    catch{
                        $opId = (Get-Random -Minimum 1 -Maximum 10)
                    }
                }
                $elem.ParentId = $opId.ToString()
            }
            #Add to array
            if($opId -notin $opIds){
                $opIds.Add($opId)
            }
            $count+=1
        }
        #>
    }
    Process{
        if($null -ne $url){
            #Set servicePoint
            $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($url)
            $ServicePoint.ConnectionLimit = 1000;
            #Get Data
            if($Data){
                $param = @{
                    Url = $url;
                    Headers = $requestHeader;
                    Method = "POST";
                    Content_Type = $Content_Type;
                    Data = $Data.OuterXml;
                    UserAgent = $O365Object.UserAgent;
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
            }
            else{
                $param = @{
                    Url = $url;
                    Headers = $requestHeader;
                    Method = "POST";
                    Content_Type = $Content_Type;
                    UserAgent = $O365Object.UserAgent;
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
            }
            #Execute Query
            $tmp_response = Invoke-UrlRequest @param
            try{
                if($null -ne $tmp_response){
                    if($null -eq $tmp_response.PsObject.Properties.Item('Length') -and $tmp_response -is [object]){
                        $errorData = $tmp_response[0]
                        if($null -ne $errorData -and $null -ne $errorData.psobject.properties.Item('ErrorInfo') -and $null -ne $errorData.ErrorInfo){
                            $errorMessage = "{0} in {1}. {2} {3}" -f $errorData.ErrorInfo.ErrorTypeName, $Server.AbsoluteUri, $errorData.ErrorInfo.ErrorCode, $errorData.ErrorInfo.ErrorMessage
                            $msg = @{
                                MessageData = ($message.SPSDetailedErrorMessage -f $errorMessage);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'verbose';
                                Verbose = $Verbose;
                                Tags = @('SPSRequestError');
                            }
                            Write-Verbose @msg
                        }
                    }
                    else{
                        for($i=1;$i -lt $tmp_response.Length;$i++){
                            if($tmp_response[$i] -is [psobject]){
                                #Get object
                                $raw_response = $tmp_response[$i]
                                #check if childItems
                                if($ChildItems){
                                    if($null -ne $raw_response.PSObject.Properties.Item('_Child_Items_')){
                                        $raw_response = $raw_response._Child_Items_
                                    }
                                }
                                elseif($PSBoundParameters.ContainsKey('Select') -and $PSBoundParameters['Select']){
                                    if($null -ne ($raw_response | Select-Object -ExpandProperty $PSBoundParameters['Select'] -ErrorAction Ignore)){
                                        $raw_response = $raw_response.$($PSBoundParameters['Select'])
                                        #Check if child items
                                        if($null -ne $raw_response.PSObject.Properties.Item('_Child_Items_')){
                                            $raw_response = $raw_response._Child_Items_
                                        }
                                    }
                                    else{
                                        $msg = @{
                                            MessageData = ("Property {0} does not exist" -f $PSBoundParameters['Select']);
                                            callStack = (Get-PSCallStack | Select-Object -First 1);
                                            logLevel = 'verbose';
                                            Verbose = $Verbose;
                                            Tags = @('SPSRequestError');
                                        }
                                        Write-Verbose @msg
                                    }
                                }
                            }
                            elseif($tmp_response[$i] -is [string]){
                                #Get object
                                $raw_response = $tmp_response[$i]
                            }
                        }
                    }
                }
                ####close all the connections made to the host####
                [void]$ServicePoint.CloseConnectionGroup("")
            }
            catch{
                $msg = @{
                    MessageData = ($message.UnableToProcessQuery -f $url);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $InformationAction;
                    Tags = @('SPSRequestError');
                }
                Write-Warning @msg
                $msg = @{
                    MessageData = ($_);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Verbose = $Verbose;
                    Tags = @('SPSRequestError');
                }
                Write-Verbose @msg
                if($tmp_response -is [object]){
                    $errorData = $tmp_response[0]
                    if($null -ne $errorData -and $null -ne $errorData.psobject.properties.Item('ErrorInfo') -and $null -ne $errorData.ErrorInfo){
                        $errorMessage = "[{0}][{1}]:[{2}]" -f $errorData.ErrorInfo.ErrorTypeName, $errorData.ErrorInfo.ErrorCode, $errorData.ErrorInfo.ErrorMessage
                        $msg = @{
                            MessageData = ($message.SPSDetailedErrorMessage -f $errorMessage);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            Verbose = $Verbose;
                            Tags = @('SPSRequestError');
                        }
                        Write-Verbose @msg
                    }
                }
                ####close all the connections made to the host####
                [void]$ServicePoint.CloseConnectionGroup("")
            }
        }
    }
    End{
        if($raw_response){
            return $raw_response
        }
    }
}

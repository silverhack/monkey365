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

Function Get-MonkeyM365AdminObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyM365AdminObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Environment,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("settings", "appsettings", "recommendations","identitysecurity","billing","users")]
        [String]$InternalPath = 'settings',

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectType,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$RawQuery,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$useExpect
    )
    Begin{
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
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Microsoft 365 admin portal")
             break
        }
        #Get Authorization Header
        $AuthHeader = $Authentication.CreateAuthorizationHeader()
        #Get internal Path
        switch ($InternalPath) {
            'settings'{$base_uri = 'settings'}
            'appsettings'{$base_uri = 'settings/apps'}
            'recommendations'{$base_uri = 'recommendations'}
            'identitysecurity'{$base_uri = 'identitysecurity'}
            'billing'{$base_uri = 'billing'}
            'users'{$base_uri = 'users'}
        }
        $base_uri = ("/admin/api/{0}" -f $base_uri)
        if($ObjectType){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectType)
        }
        if($ObjectId){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectId)
        }
        #construct final URI
        if($RawQuery){
            $base_uri = ("{0}" -f $RawQuery)
        }
        #Remove double slashes
        $base_uri = [regex]::Replace($base_uri,"/+","/")
        $Server = [System.Uri]::new($Environment.OfficeAdminPortal)
        $final_uri = [System.Uri]::new($Server,$base_uri)
        $final_uri = $final_uri.ToString()
    }
    Process{
        if($final_uri -and $AuthHeader){
            #Create Request Header
            $requestHeader = @{
                Authorization = $AuthHeader
            }
            #Set Expect 100 continue
            if($useExpect){
                [void]$requestHeader.Add('Expect','100-continue');
            }
            #Perform query
            $AllObjects = @()
            try{
                switch ($Method) {
                    'GET'
                    {
                        $param = @{
                            Url = $final_uri;
                            Headers = $requestHeader;
                            Method = $Method;
                            ContentType = $ContentType;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $Objects = Invoke-MonkeyWebRequest @param
                    }
                }
                if($ObjectType){
                    Write-Verbose ("Getting {0} from microsoft PowerBI" -f $ObjectType)
                }
                else{
                    Write-Verbose $final_uri
                }
                if($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -gt 0){
                    $Objects.value
                }
                elseif($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -eq 0){
                    #empty response
                    $Objects.value
                }
                else{
                    $Objects
                }
                #Search for nextLink paging objects
                if ($Objects.PsObject.Properties.Item('@odata.nextLink')){
                    $nextLink = $Objects.'@odata.nextLink'
                    while ($null -ne $nextLink){
                        #Make RestAPI call
                        $param = @{
                            Url = $nextLink;
                            Method = "Get";
                            Headers = $requestHeader;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $NextPage = Invoke-MonkeyWebRequest @param
                        $NextPage.value
                        $nextLink = $nextPage.'@odata.nextLink'
                    }
                }
                #Search for odata.count objects
                elseif ($Objects.PsObject.Properties.Item('@odata.count')){
                    $maxObjects = $Objects.'@odata.count'
                    while($maxObjects -gt @($AllObjects).Count){
                        $uri = [System.Uri]$final_uri
                        $TokenizedQueryString = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                        $new_filter = $null
                        if($null -ne $TokenizedQueryString.Item('$top')){
                            $oldTop = $TokenizedQueryString.Item('$top')
                            $newTop = 4000+[int]$TokenizedQueryString.Item('$top');
                            if($newTop -gt 5000){
                                $newTop = 5000;
                            }
                            $TokenizedQueryString.Item('$top') = $newTop
                        }
                        else{
                            $oldTop = 100;
                        }
                        if($null -ne $TokenizedQueryString.Item('$skip')){
                            $newSkip = [int]$oldTop +[int]$TokenizedQueryString.Item('$skip')
                            $TokenizedQueryString.Item('$skip') = $newSkip;
                        }
                        else{
                            $TokenizedQueryString.Add('$skip',$oldTop)
                        }
                        foreach($key in $TokenizedQueryString.AllKeys){
                            if($null -ne $new_filter){
                                $new_filter = ('{0}&{1}={2}' -f $new_filter, $key,$TokenizedQueryString[$key])
                            }
                            else{
                                $new_filter = ('?{0}={1}' -f $key,$TokenizedQueryString[$key])
                            }
                        }
                        #Construct new query
                        $final_uri = ('https://{0}{1}{2}' -f $uri.Authority,$uri.AbsolutePath,$new_filter)
                        #Make RestAPI call
                        $param = @{
                            Url = $final_uri;
                            Method = "Get";
                            Headers = $requestHeader;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $NextPage = Invoke-MonkeyWebRequest @param
                        $NextPage.value
                    }
                }
            }
            catch{
                Write-Verbose $_
            }
        }
    }
    End{
        #Nothing to do here
    }
}

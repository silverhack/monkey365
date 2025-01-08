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

Function Invoke-MonkeySPOAdminRestQuery{
    <#
        .SYNOPSIS
        Utility to get information from SharePoint Admin REST API

        .DESCRIPTION
        Utility to get information from SharePoint Admin REST API

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeySPOAdminRestQuery
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, HelpMessage="SiteId")]
        [String]$SiteId,

        [parameter(Mandatory=$false, HelpMessage="Get Site User Groups")]
        [Switch]$GetSiteUserGroups,

        [parameter(Mandatory=$True, HelpMessage="Object Path")]
        [ValidateSet("SPO.Tenant")]
        [String]$ObjectPath,

        [parameter(Mandatory=$false, HelpMessage="Method")]
        [ValidateSet("GET","POST")]
        [String]$Method = "GET",

        [parameter(Mandatory=$false, HelpMessage="Post Data")]
        [Object]$Data,

        [parameter(Mandatory=$false, HelpMessage="ContentType")]
        [String]$ContentType = 'application/json;odata.metadata=minimal',

        [parameter(Mandatory=$false, HelpMessage="ContentType")]
        [String]$Accept = 'application/json'
    )
    dynamicparam{
        # set a new dynamic parameter
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        #Add parameters for SiteProperties
        if($null -ne (Get-Variable -Name ObjectPath -ErrorAction Ignore) -and $ObjectPath -eq 'SPO.Tenant'){
            #Create the -Site parameter
            $attrCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $param_attr = New-Object System.Management.Automation.ParameterAttribute
            $param_attr.Mandatory = $True
            $arrSet = @('RenderAdminListData','sites','GetSiteAdministrators')
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
            $attrCollection.Add($param_attr)
            $attrCollection.Add($ValidateSetAttribute)
            $attr_pname = 'ObjectType'
            $param_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($attr_pname,
            [String], $attrCollection)
            $paramDictionary.Add($attr_pname, $param_type_dynParam)
        }
        # return the collection of dynamic parameters
        $paramDictionary
    }
    Begin{
        $URL = $null
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
             Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online Admin API")
             break
        }
        #Get Authorization Header
        $methods = $Authentication | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name
        #Get Authorization Header
        if($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
            $AuthHeader = $Authentication.CreateAuthorizationHeader()
        }
        else{
            $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        }
        #Set server
        $Server = [System.Uri]::new($Authentication.resource)
        $baseUrl = ("_api/{0}/{1}" -f $PSBoundParameters['ObjectPath'], $PSBoundParameters['ObjectType'])
        if($PSBoundParameters.ContainsKey('SiteId') -and $PSBoundParameters['SiteId'] -and $PSBoundParameters['ObjectType'] -eq "sites"){
            if($PSBoundParameters.ContainsKey('GetSiteUserGroups') -and $PSBoundParameters['GetSiteUserGroups'].IsPresent){
                $sid = [uri]::EscapeDataString(("'{0}'" -f $PSBoundParameters['SiteId']))
                $baseUrl = ("{0}/GetSiteUserGroups?siteId={1}&userGroupIds=[0,1,2]" -f $baseUrl, $sid)
            }
            else{
                $baseUrl = ("{0}('{1}')" -f $baseUrl, $PSBoundParameters['SiteId'])
            }
        }
        Elseif($PSBoundParameters.ContainsKey('SiteId') -and $PSBoundParameters['SiteId'] -and $PSBoundParameters['ObjectType'] -eq "GetSiteAdministrators"){
            $sid = [uri]::EscapeDataString(("'{0}'" -f $PSBoundParameters['SiteId']))
            $baseUrl = ("{0}?siteId={1}" -f $baseUrl, $sid)
        }
        #Set Final url
        $URL = [System.Uri]::new($Server,$baseUrl)
        $URL = $URL.ToString()
        #Create new Session Id
        $SessionID = (New-Guid).ToString().Replace("-","")
    }
    Process{
        if($null -ne $URL){
            $requestHeader = @{
                "client-request-id" = $SessionID
                "Authorization" = $AuthHeader
            }
            #Perform query
            try{
                switch ($Method) {
                    'GET'
                    {
                        $param = @{
                            Url = $URL;
                            Headers = $requestHeader;
                            Method = $Method;
                            Accept = $Accept;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        Invoke-MonkeyWebRequest @param
                    }
                    'POST'
                    {
                        if($Data){
                            $param = @{
                                Url = $URL;
                                Headers = $requestHeader;
                                Method = $Method;
                                Accept = $Accept;
                                ContentType = $ContentType;
                                Data = $Data;
                                UserAgent = $O365Object.UserAgent;
                                Verbose = $Verbose;
                                Debug = $Debug;
                                InformationAction = $InformationAction;
                            }
                        }
                        else{
                            $param = @{
                                Url = $URL;
                                Headers = $requestHeader;
                                Accept = $Accept;
                                Method = $Method;
                                ContentType = $ContentType;
                                UserAgent = $O365Object.UserAgent;
                                Verbose = $Verbose;
                                Debug = $Debug;
                                InformationAction = $InformationAction;
                            }
                        }
                        #Execute Query request
                        Invoke-MonkeyWebRequest @param
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


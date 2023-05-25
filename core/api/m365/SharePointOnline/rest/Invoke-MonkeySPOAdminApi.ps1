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

Function Invoke-MonkeySPOAdminApi{
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
            File Name	: Invoke-MonkeySPOAdminApi
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, HelpMessage="Endpoint to execute query")]
        [String]$Endpoint,

        [parameter(Mandatory=$false, HelpMessage="Object Path")]
        [ValidateSet("Tenant","SiteProperties","TenantAdminSettingsService","Office365Tenant")]
        [String]$ObjectPath = "Tenant",

        [parameter(Mandatory=$false, HelpMessage="Method")]
        [ValidateSet("GET")]
        [String]$Method = "GET",

        [parameter(Mandatory=$false, HelpMessage="ContentType")]
        [String]$ContentType = "application/json, text/plain, */*"
    )
    dynamicparam{
        # set a new dynamic parameter
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
        #Add parameters for SiteProperties
        if($null -ne (Get-Variable -Name ObjectPath -ErrorAction Ignore) -and $ObjectPath -eq 'SiteProperties'){
            #Create the -Site parameter
            $attrCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
            # define a new parameter attribute
            $site_attr = New-Object System.Management.Automation.ParameterAttribute
            $site_attr.Mandatory = $false
            $attrCollection.Add($site_attr)
            $attr_pname = 'Site'
            $site_type_dynParam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter($attr_pname,
            [String], $attrCollection)
            $paramDictionary.Add($attr_pname, $site_type_dynParam)
        }
        # return the collection of dynamic parameters
        $paramDictionary
    }
    Begin{
        $URL = $Objects = $null
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
        $AuthHeader = $Authentication.CreateAuthorizationHeader()
        #Set server
        if($PSBoundParameters.ContainsKey('Endpoint') -and $PSBoundParameters.Endpoint){
            $Server = [System.Uri]::new($PSBoundParameters['Endpoint'])
        }
        else{
            $Server = [System.Uri]::new($Authentication.resource)
        }
        #Set base url
        if($PSBoundParameters.ContainsKey('ObjectPath') -and $PSBoundParameters.ObjectPath -eq "Office365Tenant"){
            if($Server.Segments.Contains('sites/')){
                $baseUrl = ("{0}/{1}" -f $Server.AbsolutePath,"/_api/Microsoft.Online.SharePoint.TenantManagement.Office365Tenant")
                #Remove double slashes
                $baseUrl = [regex]::Replace($baseUrl,"/+","/")
            }
            else{
                $baseUrl = "/_api/Microsoft.Online.SharePoint.TenantManagement.Office365Tenant"
            }
        }
        else{
            $baseUrl = ("/_api/Microsoft.Online.SharePoint.TenantAdministration")
            #Set site path
            if($Server.Segments.Contains('sites/')){
                $baseUrl = ("{0}/{1}" -f $Server.AbsolutePath,$baseUrl)
                #Remove double slashes
                $baseUrl = [regex]::Replace($baseUrl,"/+","/")
            }
            #Check if Site Properties
            if($PSBoundParameters.ContainsKey('Site') -and $PSBoundParameters['ObjectPath'] -eq 'SiteProperties'){
                $baseUrl = ("{0}.SiteProperties('{1}')" -f $baseUrl, $PSBoundParameters['Site'])
            }
            else{
                $baseUrl = ("{0}.{1}" -f $baseUrl, $PSBoundParameters.ObjectPath)
            }
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
            $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($URL)
            $ServicePoint.ConnectionLimit = 1000;
            try{
                switch ($Method) {
                        'GET'
                        {
                            $param = @{
                                Url = $URL;
                                Headers = $requestHeader;
                                Method = $Method;
                                Content_Type = $ContentType;
                                Encoding = $ContentType;
                                UserAgent = $O365Object.UserAgent;
                                Verbose = $Verbose;
                                Debug = $Debug;
                                InformationAction = $InformationAction;
                            }
                            $Objects = Invoke-UrlRequest @param
                        }
                }
                ####close all the connections made to the host####
                [void]$ServicePoint.CloseConnectionGroup("")
            }
            catch {
                Write-Verbose $_
                ####close all the connections made to the host####
                [void]$ServicePoint.CloseConnectionGroup("")
            }
        }
    }
    End{
        if($null -ne $Objects){
            return $Objects
        }
    }
}

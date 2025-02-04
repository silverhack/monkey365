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

Function Initialize-AuthenticationParam{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-AuthenticationParam
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    Begin{
        #Set new clients
        $O365Object.msal_public_applications = [System.Collections.Generic.List[Microsoft.Identity.Client.IPublicClientApplication]]::new()
        $O365Object.msal_confidential_applications = [System.Collections.Generic.List[Microsoft.Identity.Client.IConfidentialClientApplication]]::new()
    }
    Process{
        $msalAppMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-MonkeyMsalApplication")
        #Set new dict
        $newPsboundParams = [ordered]@{}
        $param = $msalAppMetadata.Parameters.Keys
        foreach($p in $param.GetEnumerator()){
            if($O365Object.initParams.ContainsKey($p) -and $O365Object.initParams.Item($p)){
                if ($p -eq 'Instance') { continue }
                $newPsboundParams.Add($p,$O365Object.initParams.Item($p))
            }
        }
        #Check if TenantId
        if($null -ne $O365Object.TenantId){
            $newPsboundParams.Item('TenantId') = $O365Object.TenantId;
        }
        #Add auth params
        $O365Object.application_args = $newPsboundParams;
    }
    End{
        if($O365Object.application_args){
            $app_param = $O365Object.application_args;
            $newApplication = New-MonkeyMsalApplication @app_param
            $O365Object.isConfidentialApp = -NOT $newApplication.isPublicApp;
            #$O365Object.msalapplication = New-MonkeyMsalApplication @app_param
            #$O365Object.isConfidentialApp = -NOT $O365Object.msalapplication.isPublicApp;
            #Get Auth params
            $msalAppMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-MonkeyMSALToken")
            #Set new dict
            $newPsboundParams = @{}
            $param = $msalAppMetadata.Parameters.Keys
            foreach($p in $param.GetEnumerator()){
                if($O365Object.initParams.ContainsKey($p) -and $O365Object.initParams.Item($p)){
                    if ($p -in $app_param.keys) {continue }
                    $newPsboundParams.Add($p,$O365Object.initParams.Item($p))
                }
            }
            if($O365Object.isConfidentialApp){
                #Add confidential application
                $O365Object.msalapplication = $newApplication;
                [void]$O365Object.msal_confidential_applications.Add($O365Object.msalapplication)
                [ref]$null = $newPsboundParams.Add('confidentialApp',$O365Object.msalapplication);
            }
            else{
                #Add public client
                #[void]$O365Object.msal_public_applications.Add($O365Object.msalapplication)
                #[ref]$null = $newPsboundParams.Add('publicApp',$O365Object.msalapplication);
                [ref]$null = $newPsboundParams.Add('publicApp',$null);
            }
            #Add Verbose, informationAction and Debug parameters
            [ref]$null = $newPsboundParams.Add('InformationAction',$O365Object.InformationAction);
            [ref]$null = $newPsboundParams.Add('Verbose',$O365Object.verbose);
            [ref]$null = $newPsboundParams.Add('Debug',$O365Object.debug);
            #Update msal application args. These parameters will contain current MSAL application
            $O365Object.msal_application_args = $newPsboundParams
            #Set initial backup application args
            $new_params = @{}
            foreach ($param in $newPsboundParams.GetEnumerator()){
                $new_params.add($param.Key, $param.Value)
            }
            $O365Object.msalAuthArgs = $new_params
        }
    }
}



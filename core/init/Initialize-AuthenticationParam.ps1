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

    Begin{
        #Confidential params
        $confidentialParams=@(
            'ClientAssertionCertificate',
            'certificate_credentials',
            'ClientSecret',
            'Certificate',
            'certfilepassword',
            'client_credentials'
        )
        #Public Implicit Params
        $publicParams=@(
            'Silent',
            'DeviceCode',
            'PromptBehavior',
            'ForceAuth',
            'user_credentials'
        )
        #parameters to skip in auth
        $skip=@(
            'outDir','SaveProject','resourcegroups','IncludeAzureActiveDirectory',
            'Analysis','ExportTo','Threads','Instance',
            'ClearCache','WriteLog','cache_token_file',
            'AuditorName', 'saveProject','ResolveTenantDomainName',
            'reportType','profileName','ResolveTenantUserName',
            'ClearCache','subscriptions','all_subscriptions','RuleSet',
            'ImportJob'
        )
        #Set isPublicApp var
        $isPublicApp = $true
    }
    Process{
        #Check if public application (Interactive, devicecode,etc..)
        foreach ($param in $O365Object.initParams.GetEnumerator()){
            if ($param.key -in $confidentialParams) { $isPublicApp = $false }
        }
        #Remove common params
        $body_params = @{}
        foreach ($param in $O365Object.initParams.GetEnumerator()){
            if ($param.key -in $skip) { continue }
            #Remove additional params if is confidential app
            if($isPublicApp -eq $false -and $param.key -in $publicParams){ continue }
            $body_params.add($param.Key, $param.Value)
        }
        #Set confidentialApp in Object
        if($isPublicApp){
            $O365Object.isConfidentialApp = $false
        }
        else{
            $O365Object.isConfidentialApp = $true
        }
        #Remove implicit args if confidential app
        if($O365Object.isConfidentialApp){
            $new_params = @{}
            foreach ($param in $body_params.GetEnumerator()){
                if ($param.key -in $publicParams) { continue }
                $new_params.add($param.Key, $param.Value)
            }
            $body_params = $new_params
        }
        else{
            #Public app detected. Remove confidential params if exists
            $new_params = @{}
            foreach ($param in $body_params.GetEnumerator()){
                if ($param.key -in $confidentialParams) { continue }
                $new_params.add($param.Key, $param.Value)
            }
            $body_params = $new_params
        }
        #Remove ClientId if null value
        if($body_params.ContainsKey('ClientId') -and $null -eq $body_params.ClientId){
            [ref]$null = $body_params.Remove('ClientId')
        }
        #Remove TenantId if null value
        if($body_params.ContainsKey('TenantId') -and $null -eq $body_params.TenantId){
            [ref]$null = $body_params.Remove('TenantId')
        }
    }
    End{
        #Initialize authentication params
        $O365Object.application_args = $body_params
        if($O365Object.isUsingAdalLib){
            if($O365Object.isConfidentialApp){
                $adal_confidential_params = $confidentialParams
                #Add ClientId
                $adal_confidential_params+='ClientId'
                $client_params = @{}
                foreach ($param in $O365Object.application_args.GetEnumerator()){
                    if ($param.key -in $adal_confidential_params){
                        $client_params.add($param.Key, $param.Value)
                    }
                }
                $O365Object.adal_credentials = New-MonkeyADALClientCredential @client_params
            }
        }
        else{
            #Using MSAL
            if($O365Object.isConfidentialApp){
                $app_param = $O365Object.application_args
                $O365Object.msalapplication = New-MonkeyMsalApplication @app_param
                #Remove confidential params and add msal application
                $new_params = @{}
                foreach ($param in $app_param.GetEnumerator()){
                    if ($param.key -in $confidentialParams) { continue }
                    $new_params.add($param.Key, $param.Value)
                }
                $O365Object.msal_application_args = $new_params
            }
            else{
                #Public application
                $app_param = $O365Object.application_args
                #Remove extra parameters
                $new_params = @{}
                foreach ($param in $app_param.GetEnumerator()){
                    if ($param.key -in $publicParams) { continue }
                    $new_params.add($param.Key, $param.Value)
                }
                #Create public application
                $O365Object.msalapplication = New-MonkeyMsalApplication @new_params
                #Update application args
                $O365Object.application_args = $new_params
                $O365Object.msal_application_args = $app_param
            }
        }
    }
}

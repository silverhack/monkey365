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

Function Get-MonkeyGraphAADUser {
    <#
        .SYNOPSIS
        Get detailed user from Entra ID

        .DESCRIPTION
        Get detailed user from Entra ID

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphAADUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'UserId', ValueFromPipeline = $True)]
        [String]$UserId,

        [Parameter(Mandatory=$false, HelpMessage="Bypass MFA check")]
        [Switch]$BypassMFACheck
    )
    Begin{
        $allUsers = $null;
        #Get instance
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        #Get Config
        try{
            $aadConf = $O365Object.internal_config.entraId.provider.graph
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'UserId'){
            $uri = ("{0}/myorganization/users('{1}')?api-version={2}" `
                    -f $Environment.Graph, $UserId,$aadConf.internal_api_version)

            $params = @{
                Authentication = $AADAuth;
                OwnQuery = $uri;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $allUsers = Get-MonkeyGraphObject @params
        }
        else{
            #Get users
		    $params = @{
			    Authentication = $AADAuth;
			    ObjectType = "users";
			    Environment = $Environment;
			    ContentType = 'application/json';
                Top = '999';
			    Method = "GET";
			    APIVersion = $aadConf.internal_api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
		    $allUsers = Get-MonkeyGraphObject @params
        }
        if($allUsers -and $BypassMFACheck.IsPresent -eq $false){
            #Create new id property
            foreach($User in @($allUsers)){
                $mfaStatus = $mfaenabled = $null
                $methods = New-Object System.Collections.Generic.List[System.Object]
                $weak_methods = New-Object System.Collections.Generic.List[System.Object]
                #Get StrongAuthDetails
                $strong_auth = $User.strongAuthenticationDetail
                #Get Methods
                $mfa_methods = $User.strongAuthenticationDetail.methods
                #Get PhoneApp Details
                $phoneAppDetails = $User.strongAuthenticationDetail.phoneAppDetails
                #Get Office phone authentication method
                $office_phone_mfa = $strong_auth | Where-Object {$null -ne $_.verificationDetail -and $_.verificationDetail.voiceOnlyPhoneNumber}
                #Get Phone authentication method
                $phone_mfa = $strong_auth | Where-Object {$null -ne $_.verificationDetail -and $_.verificationDetail.phoneNumber}
                #Get alternative Phone authentication method
                $alt_phone_mfa = $strong_auth | Where-Object {$null -ne $_.verificationDetail -and $_.verificationDetail.alternativePhoneNumber}
                #Get default authentication method
                if($null -ne ($User.searchableDeviceKey | Where-Object {$_.usage -eq 'FIDO'})){
                    #Get FIDO data
                    $fido_raw_data = $User.searchableDeviceKey | Where-Object {$_.usage -eq 'FIDO'}
                    if(@($fido_raw_data).Count -gt 0){
                        $output = @()
                        foreach($fido_key in $fido_raw_data){
                            $fido2Details = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($fido_key.keyMaterial)) | ConvertFrom-Json)
                            $fidoCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2([Convert]::FromBase64String($fido2Details.x5c[0]), [String]::Empty, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet)
                            $fido2DetailsObj = [PSCustomObject][ordered]@{
                                Usage = $fido_key.usage
                                Version = $fido2Details.version
                                DisplayName = $fido2Details.displayName
                                fidoKeyCert = $fidoCert
                                creationTime = $fido_key.creationTime
                                deviceId = $fido_key.deviceId
                                keyIdentifier = $fido_key.keyIdentifier
                                fidoKeyCertRaw = $fido_key.keyMaterial
                                fidoAaGuid = $fido_key.fidoAaGuid
                                fidoAuthenticatorVersion = $fido_key.fidoAuthenticatorVersion
                                fidoAttestationCertificates = $fido_key.fidoAttestationCertificates
                            }
                            #Add to array
                            $output+=$fido2DetailsObj
                            #Add to user object
                            $User | Add-Member -type NoteProperty -name fidoDetails -value $output -Force

                        }
                        if($weak_methods.Count -gt 0){
                            $mfaStatus = 'Weak'
                            $mfaenabled = $true
                            [void]$methods.Add('FIDO2 Authentication');
                        }
                        else{
                            $mfaStatus = 'Strong'
                            $mfaenabled = $true
                            [void]$methods.Add('FIDO2 Authentication');
                        }
                    }
                }
                elseif($O365Object.canRequestMFAForUsers -eq $false -and $O365Object.isConfidentialApp -eq $false){
                    $mfaenabled = $null
                    $mfaStatus = 'Unknown'
                    [void]$methods.Add('Unknown');
                }
                elseif($mfa_methods.Count -gt 0){
                    #Office Phone
                    if($office_phone_mfa){
                        $mfaStatus = 'Weak'
                        $mfaenabled = $true
                        [void]$methods.Add('Office Phone');
                        [void]$weak_methods.Add('Office Phone');
                    }
                    #Phone MFA
                    if($phone_mfa){
                        $mfaStatus = 'Weak'
                        $mfaenabled = $true
                        [void]$methods.Add('Phone Call');
                        [void]$weak_methods.Add('Phone Call');
                    }
                    #Alternative phone
                    if($alt_phone_mfa){
                        $mfaStatus = 'Weak'
                        $mfaenabled = $true
                        [void]$methods.Add('Alternate Phone');
                        [void]$weak_methods.Add('Alternate Phone');
                    }
                    #Get SMS auth method
                    if($null -ne $mfa_methods){
                        $sms_method = $mfa_methods.Where({$_.methodType -eq 'OneWaySms'})
                        if($sms_method.Count -gt 0 -and $phone_mfa){
                            $mfaStatus = 'Weak'
                            $mfaenabled = $true
                            [void]$methods.Add('SMS');
                            [void]$weak_methods.Add('SMS');
                        }
                    }
                    #Get PhoneApp method
                    if($null -ne $mfa_methods){
                        $phoneappMethod = $mfa_methods.Where({$_.methodType -eq 'PhoneAppNotification'})
                        if($phoneappMethod.Count -gt 0 -and $phoneAppDetails){
                            if($weak_methods.Count -gt 0){
                                $mfaStatus = 'Weak'
                                $mfaenabled = $true
                                [void]$methods.Add('Microsoft Authenticator');
                            }
                            else{
                                $mfaStatus = 'Strong'
                                $mfaenabled = $true
                                [void]$methods.Add('Microsoft Authenticator');
                            }
                        }
                    }
                    #Get Authenticator method
                    if($null -ne $mfa_methods){
                        $phoneappMethod = $mfa_methods.Where({$_.methodType -eq 'PhoneAppOTP'})
                        $pad = $phoneAppDetails.Where({$_.authenticationType -eq 'OTP'})
                        if($phoneappMethod.Count -gt 0 -and $pad.Count -gt 0){
                            if($weak_methods.Count -gt 0){
                                $mfaStatus = 'Weak'
                                $mfaenabled = $true
                                [void]$methods.Add('Software OATH Token');
                            }
                            else{
                                $mfaStatus = 'Strong'
                                $mfaenabled = $true
                                [void]$methods.Add('Software OATH Token');
                            }
                        }
                    }
                }
                else{
                    $mfaenabled = $false
                    $mfaStatus = 'Weak'
                    [void]$methods.Add('NotConfigured');
                }
                $User | Add-Member -type NoteProperty -name mfaenabled -value $mfaenabled -Force
                $User | Add-Member -type NoteProperty -name mfaStatus -value $mfaStatus -Force
                $User | Add-Member -type NoteProperty -name mfaMethods -value ($methods -join ",") -Force
                #Add id property
                $User | Add-Member -type NoteProperty -name id -value $User.objectId -Force
                #return User
                $User
            }
        }
        else{
            @($allUsers).ForEach({
                #Add id property
                $_ | Add-Member -type NoteProperty -name id -value $_.objectId -Force
                $_
            })
        }
    }
    End{
        #Nothing to do here
    }
}



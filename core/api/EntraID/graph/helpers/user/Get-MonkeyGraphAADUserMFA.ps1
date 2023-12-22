Function Get-MonkeyGraphAADUserMFA {
    <#
        .SYNOPSIS
        Get MFA details for user

        .DESCRIPTION
        Get MFA details for user

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphAADUserMFA
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'User', ValueFromPipeline = $True)]
        [Object]$User,

        [Parameter(Mandatory=$True, ParameterSetName = 'UserId', ValueFromPipeline = $True)]
        [String]$UserId
    )
    Begin{
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
            $User = Get-MonkeyGraphObject @params
        }
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
                $sms_method = $mfa_methods | Where-Object {$_.methodType -eq 'OneWaySms'}
                if($sms_method -and $phone_mfa){
                    $mfaStatus = 'Weak'
                    $mfaenabled = $true
                    [void]$methods.Add('SMS');
                    [void]$weak_methods.Add('SMS');
                }
            }
            #Get PhoneApp method
            if($null -ne $mfa_methods){
                $phoneappMethod = $mfa_methods | Where-Object {$_.methodType -eq 'PhoneAppNotification'}
                if($phoneappMethod -and $phoneAppDetails){
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
                $phoneappMethod = $mfa_methods | Where-Object {$_.methodType -eq 'PhoneAppOTP'}
                if($phoneappMethod -and $phoneAppDetails[0].authenticationType -eq 'OTP'){
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
        #return user
        $User
    }
}
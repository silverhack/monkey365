Function Get-MonkeyMsGraphMFAUserDetail {
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
            File Name	: Get-MonkeyMsGraphMFAUserDetail
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'User', ValueFromPipeline = $True)]
        [Object]$User,

        [Parameter(Mandatory=$True, ParameterSetName = 'UserId', ValueFromPipeline = $True)]
        [String]$UserId,

        [parameter(Mandatory=$false,HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        #Set vars
        $auth_translate = @{
            "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" = "Microsoft Authenticator";
            "#microsoft.graph.phoneAuthenticationMethod" = "Phone Authentication";
            "#microsoft.graph.passwordAuthenticationMethod" = "Password Authentication";
            "#microsoft.graph.fido2AuthenticationMethod" = "FIDO2 Authentication";
            "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" = "Windows Hello For Business";
            "#microsoft.graph.emailAuthenticationMethod" = "Email Authentication";
            "#microsoft.graph.temporaryAccessPassAuthenticationMethod" = "Temporary Password Authentication";
            "#microsoft.graph.softwareOathAuthenticationMethod" = "Software OATH Token";
        }
        #Strong MFA options
        $strong_mfa_options = @(
            'Microsoft Authenticator',
            'FIDO2 Authentication',
            'Windows Hello For Business',
            'Software OATH Token'
        )
    }
    Process{
        #Set vars
        $auth_options = @()
        [array]$mfa_methods = @()
        $mfaenabled = $mfaStatus = $auth_details = $null
        #Check if userId
        if($PSCmdlet.ParameterSetName -eq 'UserId'){
            $User = Get-MonkeyMSGraphUser @PSBoundParameters
        }
        #Get Authentication details
        if($O365Object.canRequestMFAForUsers -eq $true -or $O365Object.isConfidentialApp -eq $True){
            $params = @{
                Authentication = $graphAuth;
                ObjectType = ("users/{0}/authentication/methods" -f $user.id);
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $auth_details = Get-MonkeyMSGraphObject @params
        }
        if($null -ne $auth_details){
            foreach($auth_method in $auth_details){
                if($null -ne $auth_method.PsObject.Properties.Item('@odata.type')){
                    if($auth_translate.ContainsKey($auth_method.'@odata.type')){
                        $auth_type = $auth_translate[$auth_method.'@odata.type']
                    }
                    else{
                        $auth_type = $null
                    }
                    #Add to array
                    $auth_options+= [PSCustomObject]@{
                        AuthenticationMethodId = $auth_method.Id;
                        OdataMethod            = $auth_method.'@odata.type';
                        MethodType             = $auth_type;
                        AdditionalProperties   = $auth_method;
                    }
                }
            }
            #Determine whether the MFA is strong or not
            if($auth_options.Count -gt 1){
                $mfaenabled = $true
                $mfaStatus = $null
                #Check if temporary passwords is enabled
                $temporary_pass = $auth_options | Where-Object {$_.OdataMethod -eq "#microsoft.graph.temporaryAccessPassAuthenticationMethod" -and $_.AdditionalProperties.isUsable -eq $true}
                #Check if SMS Authentication is enabled
                $smsSign = $auth_options | Where-Object {$_.AuthenticationMethodId -eq "3179e48a-750b-4051-897c-87b9720928f7" -and ($_.AdditionalProperties.smsSignInState -eq "ready")}
                #Check if Phone Authentication is enabled
                $PhoneSign = $auth_options | Where-Object {$_.AuthenticationMethodId -eq "3179e48a-750b-4051-897c-87b9720928f7" -and ($_.AdditionalProperties.smsSignInState -eq "notConfigured")}
                #Check if Office Phone Authentication is enabled
                $officePhone = $auth_options | Where-Object {$_.AuthenticationMethodId -eq "e37fc753-ff3b-4958-9484-eaa9425c82bc"}
                #Check if alternate Phone Authentication is enabled
                $alternatePhone = $auth_options | Where-Object {$_.AuthenticationMethodId -eq "b6332ec1-7057-4abe-9331-3d72feddfe41"}
                #Check if strong authentication methods are available for user
                $strong = $auth_options | Where-Object {$_.MethodType -in $strong_mfa_options}
                if($strong){
                    foreach($auth in $strong){
                        $mfa_methods+= $auth.MethodType
                    }
                }
                if($null -ne $temporary_pass){
                    $mfaStatus = 'Weak'
                    $mfaenabled = $false
                    $mfa_methods+='Temporary password'
                }
                if($null -ne $smsSign){
                    $mfaStatus = 'Weak'
                    $mfaenabled = $true
                    $mfa_methods+='SMS'
                }
                if($null -ne $PhoneSign){
                    $mfaStatus = 'Weak'
                    $mfaenabled = $true
                    $mfa_methods+='Phone Call'
                }
                if($null -ne $officePhone){
                    $mfaStatus = 'Weak'
                    $mfaenabled = $true
                    $mfa_methods+='Office Phone'
                }
                if($null -ne $alternatePhone){
                    $mfaStatus = 'Weak'
                    $mfaenabled = $true
                    $mfa_methods+='Alternate Phone'
                }
                if(($null -ne $temporary_pass -or $null -ne $smsSign -or $null -ne $alternatePhone -or $null -ne $officePhone) -and $strong){
                    $mfaStatus = 'Weak'
                    $mfaenabled = $true
                }
                elseif($strong -and ($null -eq $temporary_pass -and $null -eq $smsSign -and $null -eq $alternatePhone -and $null -eq $officePhone)){
                    $mfaStatus = 'Strong'
                    $mfaenabled = $true
                    $mfa_methods = $strong | Select-Object -ExpandProperty MethodType
                }
            }
            else{
                $mfaenabled = $false
                $mfaStatus = 'Weak'
                $mfa_methods+='NotConfigured'
            }
        }
        else{
            $mfaenabled = $null
            $mfaStatus = 'Unknown'
            $mfa_methods+='Unknown'
        }
        #Populate user with MFA options
        $User | Add-Member -type NoteProperty -name mfaenabled -value $mfaenabled -Force
        $User | Add-Member -type NoteProperty -name mfaStatus -value $mfaStatus -Force
        $User | Add-Member -type NoteProperty -name mfaMethods -value ($mfa_methods -join ",") -Force
        $User | Add-Member -type NoteProperty -name StrongAuthenticationMethod -value $auth_options -Force
        #return user
        return $User
    }
    End{
        #Nothing to do here
    }
}
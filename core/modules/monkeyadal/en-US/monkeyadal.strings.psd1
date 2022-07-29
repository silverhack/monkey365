ConvertFrom-StringData @'
    ClearAdalCacheMessage            = Authentication Token Cache Cleared
    AdalInvalidAuthContext           = Invalid authentication context
    AcquireTokenFailed               = Acquire token failed. The error was: {0}
    AcquireSilentTokenFailed         = Acquire silent token failed
    AdalUnknownError                 = Unknown error. The error was: {0}
    AccessTokenErrorMessage          = Unable to get new access token for {0}
    ADALAuthModeMessage              = Using ADAL with {0} authentication flow
    MissingApplicationId             = Unable to connect without a valid ApplicationId
    MissingTenantIdMessage           = Unable to connect without a valid TenantId
    AdalMissingCertificate           = Unable to connect to Azure without a valid certificate
    AdalUnknownAuthFlow              = Unknown authentication flow
    AdalUnsupportedOSErrorMessage    = Use of ADAL library is not supported on PowerShell core on {0}
    UnableToLoadAdalLibrary          = Unable to load ADAL library in {0}
    ADALLoadedSuccessfully           = ADAL authentication library was loaded successfully
    AuthenticationAttempMessage      = Trying to authenticate to {0}
    SuccessfullyConnectionMsg        = Successfully connected to {0}
'@
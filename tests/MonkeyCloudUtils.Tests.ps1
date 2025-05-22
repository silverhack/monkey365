# PSScriptAnalyzer - ignore test file
Import-Module Pester
Set-StrictMode -Version Latest

Describe 'MonkeyCloudUtils' {
    BeforeAll {
        #Import module monkeymsal
        #Import monkeycloudutils
        $Module = Get-ChildItem ("{0}/core/modules/monkeymsal" -f (Split-Path $PSScriptRoot -Parent)) -Filter '*.psm1'
        $MyModule = $Module.DirectoryName
        Import-Module $MyModule -Force
        $Module = Get-ChildItem ("{0}/core/modules/monkeycloudutils" -f (Split-Path $PSScriptRoot -Parent)) -Filter '*.psm1'
        $MyModule = $Module.DirectoryName
        Import-Module $MyModule -Force
    }
    It 'Read Token' {
        $token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJNb25rZXkzNjUiLCJpYXQiOjE3MTE2NTI5NjIsImV4cCI6MjA1ODcyMTc2MiwiYXVkIjoiaHR0cHM6Ly9zaWx2ZXJoYWNrLmdpdGh1Yi5pby9tb25rZXkzNjUvIiwic3ViIjoiaGVsbG9AbW9ua2V5MzY1IiwiR2l2ZW5OYW1lIjoiSnVhbiIsIlN1cm5hbWUiOiJHYXJyaWRvIiwiRW1haWwiOiJqZ2Fycmlkb0B0cmlhbmEuY29tIiwiUm9sZSI6WyJQcmluY2lwYWwgU2VjdXJpdHkgQ29uc3VsdGFudCIsIkNsb3VkIEFkbWluaXN0cmF0b3IiXX0.f5yXZdMaI7z2ueev7YbzTnty8K3N2kLN5XlzpGLOnsk'
        $decoded = Read-JWTtoken -token $token
        $decoded.Email | Should -Be 'jgarrido@triana.com'
    }
    It 'Get Environment' {
        InModuleScope monkeycloudutils {
            $environment = Get-MonkeyEnvironment -Environment AzureUSGovernment
            $environment.Graphv2 | Should -Be 'https://graph.microsoft.us/'
        }
    }
    It 'Get Tenant name' {
        InModuleScope monkeycloudutils {
            $tenant = [pscustomobject]@{
                verifiedDomains = @(@{
                        "Name" = "Monkey365"
                        "Capabilities" = "OfficeCommunicationsOnline"
                        "isInitial" = $true
                    }
                );
            }
            $default = Get-DefaultTenantName -TenantDetails $tenant
            $default | Should -Be 'Monkey365'
        }
    }
    It 'Get Exo Redirect Uri' {
        InModuleScope monkeycloudutils {
            $uri = Get-MonkeyExoRedirectUri
            $uri | Should -Be 'https://login.microsoftonline.com/common/oauth2/nativeclient'
        }
    }
    It 'Get Exo application' {
        InModuleScope monkeycloudutils {
            $app = New-MsalApplicationForExo
            $app | Should -BeOfType [Microsoft.Identity.Client.PublicClientApplication]
        }
    }
    It 'Get PnP application' {
        InModuleScope monkeycloudutils {
            $app = New-MsalApplicationForPnP
            $app | Should -BeOfType [Microsoft.Identity.Client.PublicClientApplication]
        }
    }
    It 'Get SPO application' {
        InModuleScope monkeycloudutils {
            $app = New-MsalApplicationForSPO
            $app | Should -BeOfType [Microsoft.Identity.Client.PublicClientApplication]
        }
    }
    It 'Test Tenant Id' {
        InModuleScope monkeycloudutils {
            Test-IsValidTenantId -TenantId ([System.Guid]::NewGuid()) | Should -Be $true
        }
    }
    It 'Test Audience' {
        InModuleScope monkeycloudutils {
            $token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJNb25rZXkzNjUiLCJpYXQiOjE3MTE2NTI5NjIsImV4cCI6MjA1ODcyMTc2MiwiYXVkIjoiaHR0cHM6Ly9zaWx2ZXJoYWNrLmdpdGh1Yi5pby9tb25rZXkzNjUvIiwic3ViIjoiaGVsbG9AbW9ua2V5MzY1IiwiR2l2ZW5OYW1lIjoiSnVhbiIsIlN1cm5hbWUiOiJHYXJyaWRvIiwiRW1haWwiOiJqZ2Fycmlkb0B0cmlhbmEuY29tIiwiUm9sZSI6WyJQcmluY2lwYWwgU2VjdXJpdHkgQ29uc3VsdGFudCIsIkNsb3VkIEFkbWluaXN0cmF0b3IiXX0.f5yXZdMaI7z2ueev7YbzTnty8K3N2kLN5XlzpGLOnsk'
            Test-IsValidAudience -token $token -audience silverhack.github.io | Should -Be $true
        }
    }
    It 'OneDrive Url' {
        InModuleScope monkeycloudutils {
            Get-OneDriveUrl -Endpoint "silverhack" | Should -Be "https://silverhack-my.sharepoint.com"
        }
    }
    It 'SharePoint Url' {
        InModuleScope monkeycloudutils {
            Get-SharepointUrl -Endpoint "silverhack" | Should -Be "https://silverhack.sharepoint.com"
        }
    }
    It 'SharePoint Admin Url' {
        InModuleScope monkeycloudutils {
            Get-SharepointAdminUrl -Endpoint "silverhack" | Should -Be "https://silverhack-admin.sharepoint.com"
        }
    }
    It 'Public Tenant Info' {
        InModuleScope monkeycloudutils {
            $tinfo = Get-PublicTenantInformation -Domain "fbi.gov"
            $tinfo.TenantRegionScope | Should -Be "USGov"
        }
    }
}

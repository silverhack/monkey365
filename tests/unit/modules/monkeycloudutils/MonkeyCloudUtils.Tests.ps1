Set-StrictMode -Version Latest

Describe 'MonkeyCloudUtils' {
    BeforeAll {
        $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        Import-Module (Join-Path $script:repoRoot 'src\monkey365\core\modules\monkeymsal') -Force -ErrorAction Stop
        Import-Module (Join-Path $script:repoRoot 'src\monkey365\core\modules\monkeycloudutils') -Force -ErrorAction Stop
    }

    It 'decodes a JWT payload without contacting an external service' {
        $token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJNb25rZXkzNjUiLCJpYXQiOjE3MTE2NTI5NjIsImV4cCI6MjA1ODcyMTc2MiwiYXVkIjoiaHR0cHM6Ly9zaWx2ZXJoYWNrLmdpdGh1Yi5pby9tb25rZXkzNjUvIiwic3ViIjoiaGVsbG9AbW9ua2V5MzY1IiwiR2l2ZW5OYW1lIjoiSnVhbiIsIlN1cm5hbWUiOiJHYXJyaWRvIiwiRW1haWwiOiJqZ2Fycmlkb0B0cmlhbmEuY29tIiwiUm9sZSI6WyJQcmluY2lwYWwgU2VjdXJpdHkgQ29uc3VsdGFudCIsIkNsb3VkIEFkbWluaXN0cmF0b3IiXX0.f5yXZdMaI7z2ueev7YbzTnty8K3N2kLN5XlzpGLOnsk'
        (Read-JWTtoken -Token $token).Email | Should -Be 'jgarrido@triana.com'
    }

    It 'returns the Azure US Government endpoints' {
        InModuleScope monkeycloudutils {
            (Get-MonkeyEnvironment -Environment AzureUSGovernment).Graphv2 |
                Should -Be 'https://graph.microsoft.us/'
        }
    }

    It 'selects the initial verified tenant domain' {
        InModuleScope monkeycloudutils {
            $tenant = [pscustomobject]@{
                verifiedDomains = @([pscustomobject]@{
                    Name = 'Monkey365'
                    Capabilities = 'OfficeCommunicationsOnline'
                    isInitial = $true
                })
            }
            Get-DefaultTenantName -TenantDetails $tenant | Should -Be 'Monkey365'
        }
    }

    It 'builds tenant-specific SharePoint URLs' {
        InModuleScope monkeycloudutils {
            Get-OneDriveUrl -Endpoint 'silverhack' | Should -Be 'https://silverhack-my.sharepoint.com'
            Get-SharepointUrl -Endpoint 'silverhack' | Should -Be 'https://silverhack.sharepoint.com'
            Get-SharepointAdminUrl -Endpoint 'silverhack' | Should -Be 'https://silverhack-admin.sharepoint.com'
        }
    }

    It 'validates a tenant GUID' {
        InModuleScope monkeycloudutils {
            Test-IsValidTenantId -TenantId ([guid]::NewGuid()) | Should -BeTrue
        }
    }

    AfterAll {
        Remove-Module monkeycloudutils, monkeymsal -Force -ErrorAction Ignore
    }
}

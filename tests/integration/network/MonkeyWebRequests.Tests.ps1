# PSScriptAnalyzer - ignore test file
Set-StrictMode -Version Latest

Describe 'Monkey web request HTTP integration' -Tag 'Network' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        Import-Module (Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhttpwebrequest') -Force -ErrorAction Stop
    }
    It 'Serves pages over http' {
        InModuleScope monkeyhttpwebrequest {
            $retData = Invoke-MonkeyWebRequest -url 'http://google.com/' -AllowAutoRedirect $true -RawResponse
            $StatusCode = $retData | Select-Object -ExpandProperty StatusCode
            $retData.Dispose()
            $StatusCode | Should -Be 'OK'
        }
    }

    It 'Serves pages over https' {
        InModuleScope monkeyhttpwebrequest {
            $retData = Invoke-MonkeyWebRequest -url "https://google.co.uk/" -AllowAutoRedirect $true -RawResponse
            $StatusCode = $retData | Select-Object -ExpandProperty StatusCode
            $retData.Dispose()
            $StatusCode | Should -Be 'OK'
        }
    }

    AfterAll {
        Remove-Module monkeyhttpwebrequest -Force -ErrorAction SilentlyContinue
    }
}

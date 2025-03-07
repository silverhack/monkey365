# PSScriptAnalyzer - ignore test file
Import-Module Pester
Set-StrictMode -Version Latest

Describe 'Google' {
    BeforeAll {
        $Module = Get-ChildItem ("{0}/core/modules/monkeyhttpwebrequest" -f (Split-Path $PSScriptRoot -Parent)) -Filter '*.psm1'
        $MyModule = $Module.DirectoryName
        Import-Module $MyModule -Force
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
}


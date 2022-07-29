# PSScriptAnalyzer - ignore test file
Import-Module Pester
Set-StrictMode -Version Latest

Describe 'Google' {
    BeforeAll {
        $Module = Get-ChildItem ("{0}/core/modules/monkeywebrequest" -f (Split-Path $PSScriptRoot -Parent)) -Filter '*.psm1'
        $MyModule = $Module.DirectoryName
        Import-Module $MyModule -Force
    }
    It 'Serves pages over http' {
        InModuleScope monkeywebrequest {
            $retData = Invoke-UrlRequest -url 'http://google.com/' -AllowAutoRedirect -returnRawResponse
            $StatusCode = $retData | Select-Object -ExpandProperty StatusCode
            $retData.Close()
            $retData.Dispose()
            $StatusCode | Should -Be 'OK'
        }
    }

    It 'Serves pages over https' {
        InModuleScope monkeywebrequest {
            $retData = Invoke-UrlRequest -url "https://google.co.uk/" -AllowAutoRedirect -returnRawResponse
            $StatusCode = $retData | Select-Object -ExpandProperty StatusCode
            $retData.Close()
            $retData.Dispose()
            $StatusCode | Should -Be 'OK'
        }
    }
}
# PSScriptAnalyzer - ignore test file
Import-Module Pester
Set-StrictMode -Version Latest

Describe 'Star Wars' {
    BeforeAll {
        $Module = Get-ChildItem ("{0}/core/modules/monkeyhttpwebrequest" -f (Split-Path $PSScriptRoot -Parent)) -Filter '*.psm1'
        $MyModule = $Module.DirectoryName
        Import-Module $MyModule -Force
    }
    It 'Get Han Solo height' {
        Invoke-MonkeyWebRequest -url "https://swapi.info/api/people/14" | Select-Object -ExpandProperty height | Should -Be '180'
    }

    It 'Han Solo is Id = 14' {
        $Han = Invoke-MonkeyWebRequest -url "https://swapi.info/api/people/14"
        $Han.name | Should -Be 'Han Solo'
    }
}


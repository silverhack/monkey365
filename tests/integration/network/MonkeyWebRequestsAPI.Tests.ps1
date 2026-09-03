# PSScriptAnalyzer - ignore test file
Set-StrictMode -Version Latest

Describe 'Monkey web request API integration' -Tag 'Network' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        Import-Module (Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhttpwebrequest') -Force -ErrorAction Stop
    }
    It 'Get Han Solo height' {
        Invoke-MonkeyWebRequest -url "https://swapi.info/api/people/14" | Select-Object -ExpandProperty height | Should -Be '180'
    }

    It 'Han Solo is Id = 14' {
        $Han = Invoke-MonkeyWebRequest -url "https://swapi.info/api/people/14"
        $Han.name | Should -Be 'Han Solo'
    }

    AfterAll {
        Remove-Module monkeyhttpwebrequest -Force -ErrorAction Ignore
    }
}

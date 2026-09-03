Set-StrictMode -Version Latest

Describe 'MonkeyHTML utilities' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    Context 'Convert-UrlToJsDelivr' {
        It 'uses main by default' {
            InModuleScope monkeyhtml {
                $result = Convert-UrlToJsDelivr -Url 'https://github.com/SilverHack/Monkey365Assets/css/site.css'
                $result.AbsoluteUri | Should-Be 'https://cdn.jsdelivr.net/gh/silverhack/monkey365assets@main/css/site.css'
            }
        }

        It 'uses an explicit branch' {
            InModuleScope monkeyhtml {
                (Convert-UrlToJsDelivr -Url 'https://github.com/u/r/a.js' -Branch develop).AbsoluteUri |
                    Should-Be 'https://cdn.jsdelivr.net/gh/u/r@develop/a.js'
            }
        }

        It 'uses an explicit tag' {
            InModuleScope monkeyhtml {
                (Convert-UrlToJsDelivr -Url 'https://github.com/u/r/a.js' -Tag v1.2.3).AbsoluteUri |
                    Should-Be 'https://cdn.jsdelivr.net/gh/u/r@v1.2.3/a.js'
            }
        }

        It 'supports the latest release alias' {
            InModuleScope monkeyhtml {
                (Convert-UrlToJsDelivr -Url 'https://github.com/u/r/a.js' -Latest).AbsoluteUri |
                    Should-Be 'https://cdn.jsdelivr.net/gh/u/r@latest/a.js'
            }
        }

        It 'returns nothing for non-GitHub URLs' {
            InModuleScope monkeyhtml {
                Convert-UrlToJsDelivr -Url 'https://example.org/u/r/a.js' |
                    Should-BeNull
            }
        }
    }

    Context 'Format-PsObject' {
        It 'represents null and empty values as NotSet' {
            InModuleScope monkeyhtml {
                Format-PsObject -InputObject $null | Should-Be 'NotSet'
                Format-PsObject -InputObject '' | Should-Be 'NotSet'
                Format-PsObject -InputObject @{} | Should-Be 'NotSet'
                Format-PsObject -InputObject @() | Should-Be 'NotSet'
            }
        }

        It 'converts booleans to report-friendly labels' {
            InModuleScope monkeyhtml {
                Format-PsObject -InputObject $true | Should-Be 'Enabled'
                Format-PsObject -InputObject $false | Should-Be 'Disabled'
            }
        }

        It 'HTML-escapes ordinary strings' {
            InModuleScope monkeyhtml {
                Format-PsObject -InputObject '<script>&' | Should-Be '&lt;script&gt;&amp;'
            }
        }

        It 'recursively formats dictionaries and objects' {
            InModuleScope monkeyhtml {
                $result = Format-PsObject -InputObject ([ordered]@{
                    enabled = $true
                    nested = [pscustomobject]@{ text = '<value>' }
                })
                $result.enabled | Should-Be 'Enabled'
                $result.nested.text | Should-Be '&lt;value&gt;'
            }
        }

        It 'preserves collections while formatting their items' {
            InModuleScope monkeyhtml {
                $result = Format-PsObject -InputObject @($true, $false, '<x>')
                $result | Should-BeCollection -Count 3
                $result[0] | Should-Be 'Enabled'
                $result[1] | Should-Be 'Disabled'
                $result[2] | Should-Be '&lt;x&gt;'
            }
        }

        It 'preserves scalar numeric values' {
            InModuleScope monkeyhtml {
                Format-PsObject -InputObject 42 | Should-Be 42
            }
        }
    }

    Context 'Update-XMLIndent' {
        It 'returns indented XML without changing content' {
            InModuleScope monkeyhtml {
                [xml]$document = '<root><child>value</child></root>'
                $result = Update-XMLIndent -Content $document -Indent 2
                $result | Should-MatchString "\r?\n\s{2}<child>value</child>"
                ([xml]$result).root.child | Should-Be 'value'
            }
        }
    }
}

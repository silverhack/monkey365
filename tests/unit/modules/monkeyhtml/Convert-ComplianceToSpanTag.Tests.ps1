Set-StrictMode -Version Latest

Describe "Convert-ComplianceToSpanTag" {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
        Mock -CommandName New-HtmlTag -MockWith { } -ModuleName monkeyhtml
    }
    Context "When Compliance is a valid object with all properties" {
        It "should call New-HtmlTag for name, version, and reference" {
            InModuleScope monkeyhtml {
                $compliance = [PSCustomObject]@{
                    name      = "TestName"
                    version   = "1.0"
                    reference = "TestReference"
                }
                Convert-ComplianceToSpanTag -Compliance $compliance
                Should-Invoke -CommandName New-HtmlTag -Times 3 -Exactly -Scope It
            }
        }
    }
    Context "When Compliance is a string" {
        It "should call New-HtmlTag with the string value" {
            InModuleScope monkeyhtml {
                $compliance = "TestString"

                Convert-ComplianceToSpanTag -Compliance $compliance

                Should-Invoke -CommandName New-HtmlTag -Times 1 -Exactly -Scope It
            }
        }
    }
    Context "When Compliance is an empty object" {
        It "should not call New-HtmlTag" {
            InModuleScope monkeyhtml {
                $compliance = [PSCustomObject]@{}

                Convert-ComplianceToSpanTag -Compliance $compliance

                Should-Invoke -CommandName New-HtmlTag -Times 0 -Exactly -Scope It
            }
        }
    }
    It "should use the provided template" {
        InModuleScope monkeyhtml {
            Remove-Item Alias:\New-HtmlTag -ErrorAction Ignore
            $compliance = "TestString"
            [xml]$template = "<html><body></body></html>"

            $output = Convert-ComplianceToSpanTag -Compliance $compliance -Template $template
            $output.OwnerDocument | Should-BeSame $template
        }
    }
}

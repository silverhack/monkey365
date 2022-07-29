# PSScriptAnalyzer - ignore test file
Import-Module Pester
Set-StrictMode -Version Latest

Describe 'AST' {
    BeforeAll {
        $Module = Get-ChildItem ("{0}/core/modules/monkeyast" -f (Split-Path $PSScriptRoot -Parent)) -Filter '*.psm1'
        $MyModule = $Module.DirectoryName
        Import-Module $MyModule -Force
    }
    It 'Get Function Name' {
        $obj = Get-ChildItem ("{0}/tests/Get-MonkeyTest.ps1" -f (Split-Path $PSScriptRoot -Parent))
        $my_ast = Get-AstFunction -objects $obj -recursive
        $my_ast.Name | Should -Be 'Get-MonkeyTest'
    }
    It 'Get Command Metadata' {
        InModuleScope monkeyast {
            $my_cmd = Get-CommandMetadata -CommandInfo (Get-Command Get-ChildItem)
            $my_cmd.Name | Should -Be 'Get-ChildItem'
        }
    }
    It 'Get Command from ScriptBlock' {
        InModuleScope monkeyast {
            $a = [scriptblock]::Create('Get-ChildItem C:\temp')
            $my_cmd = Get-CommandToExecute -ScriptBlock $a
            $my_cmd[0].Extent.Text | Should -Be 'Get-ChildItem'
        }
    }

    It 'Get Type' {
        InModuleScope monkeyast {
            $cmd = Get-Command Get-ChildItem
            $my_cmd = Get-NewScriptBlock -CommandInfo $cmd
            $my_cmd.Ast | Should -BeOfType [System.Management.Automation.Language.Ast]
        }
    }
}
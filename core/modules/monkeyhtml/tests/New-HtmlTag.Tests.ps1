Set-StrictMode -Version Latest
Import-Module Pester


Describe "New-HtmlTag Tests" {
    BeforeAll {
        $module = (Get-Item $PSScriptRoot).Parent
        Import-Module $module.FullName -Force
        # Mock template object
        [xml]$global:MockTemplate = "<html></html>"
    }

    It "Creates a tag with the correct name" {
        InModuleScope monkeyhtml {
            $result = New-HtmlTag -Name "div" -Template $MockTemplate
            $result.LocalName | Should -Be "div"
        }
    }

    It "Sets attributes correctly" {
        InModuleScope monkeyhtml {
            $attributes = @{ "data-test" = "value"; "role" = "button" }
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Attributes $attributes
            $result.GetAttribute("data-test") | Should -Be "value"
            $result.GetAttribute("role") | Should -Be "button"
        }
    }

    It "Adds class names correctly" {
        InModuleScope monkeyhtml {
            $classNames = @("class1", "class2")
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -ClassName $classNames
            $result.GetAttribute("class") | Should -Be "class1 class2"
        }
    }

    It "Sets the ID correctly" {
        InModuleScope monkeyhtml {
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Id "test-id"
            $result.GetAttribute("id") | Should -Be "test-id"
        }
    }

    It "Adds inner text correctly" {
        InModuleScope monkeyhtml {
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Text "Hello World" -InnerText
            $result.InnerText | Should -Be "Hello World"
        }
    }

    It "Adds text as a text node by default" {
        InModuleScope monkeyhtml {
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Text "Hello World"
            $result.ChildNodes[0].NodeType | Should -Be "Text"
            $result.ChildNodes[0].Value | Should -Be "Hello World"
        }
    }

    It "Appends objects correctly" {
        InModuleScope monkeyhtml {
            [xml]$childNode = "<child>Child Content</child>"
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -AppendObject $childNode
            $result.ChildNodes[0].OuterXml | Should -Be "<child>Child Content</child>"
        }
    }

    It "Marks the tag as empty when Empty switch is used" {
        InModuleScope monkeyhtml {
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Empty
            $result.InnerText | Should -Be ""
        }
    }
}
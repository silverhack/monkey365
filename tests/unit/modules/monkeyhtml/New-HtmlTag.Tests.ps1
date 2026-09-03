Set-StrictMode -Version Latest

Describe "New-HtmlTag Tests" {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
        [xml]$script:mockTemplate = "<html></html>"
    }

    It "Creates a tag with the correct name" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $result = New-HtmlTag -Name "div" -Template $MockTemplate
            $result.LocalName | Should-Be "div"
        }
    }

    It "Sets attributes correctly" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $attributes = @{ "data-test" = "value"; "role" = "button" }
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Attributes $attributes
            $result.GetAttribute("data-test") | Should-Be "value"
            $result.GetAttribute("role") | Should-Be "button"
        }
    }

    It "Adds class names correctly" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $classNames = @("class1", "class2")
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -ClassName $classNames
            $result.GetAttribute("class") | Should-Be "class1 class2"
        }
    }

    It "Sets the ID correctly" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Id "test-id"
            $result.GetAttribute("id") | Should-Be "test-id"
        }
    }

    It "Adds inner text correctly" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Text "Hello World" -InnerText
            $result.InnerText | Should-Be "Hello World"
        }
    }

    It "Adds text as a text node by default" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Text "Hello World"
            $result.ChildNodes[0].NodeType | Should-Be "Text"
            $result.ChildNodes[0].Value | Should-Be "Hello World"
        }
    }

    It "Appends objects correctly" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            [xml]$childNode = "<child>Child Content</child>"
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -AppendObject $childNode
            $result.ChildNodes[0].OuterXml | Should-Be "<child>Child Content</child>"
        }
    }

    It "Marks the tag as empty when Empty switch is used" {
        InModuleScope monkeyhtml -Parameters @{ MockTemplate = $script:mockTemplate } {
            param($MockTemplate)
            $result = New-HtmlTag -Name "div" -Template $MockTemplate -Empty
            $result.InnerText | Should-BeEmptyString
        }
    }
}

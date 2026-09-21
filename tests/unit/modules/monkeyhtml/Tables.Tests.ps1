Set-StrictMode -Version Latest

Describe 'MonkeyHTML table rendering' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    It 'renders object properties as headers and rows' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $table = New-HtmlTableFromObject -Data @(
                [pscustomobject]@{ Name = 'Alpha'; Count = 1 }
                [pscustomobject]@{ Name = 'Beta'; Count = 2 }
            ) -Id inventory -ClassName compact -Template $template

            $table.id | Should-Be 'inventory'
            $table.class | Should-Be 'table monkey-table compact'
            @($table.SelectNodes('./thead/tr/th')) | Should-BeCollection -Count 2
            @($table.SelectNodes('./tbody/tr')) | Should-BeCollection -Count 2
            $table.SelectSingleNode('./tbody/tr[2]/td[1]').InnerText | Should-Be 'Beta'
        }
    }

    It 'decorates enabled, disabled, and missing values with semantic badges' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $table = New-HtmlTableFromObject -Data ([pscustomobject]@{
                Enabled = $true
                Disabled = $false
                Missing = $null
            }) -Template $template

            $table.SelectSingleNode('.//span[text()="Enabled"]').class | Should-Be 'badge badge-success badge-xl'
            $table.SelectSingleNode('.//span[text()="Disabled"]').class | Should-Be 'badge badge-warning badge-xl'
            $table.SelectSingleNode('.//span[text()="NotSet"]').class | Should-Be 'badge badge-disabled badge-xl'
        }
    }

    It 'renders list layout and highlights selected properties' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $table = New-HtmlTableFromObject -Data ([pscustomobject]@{
                Name = 'Alpha'
                State = 'Enabled'
                Count = 3
            }) -AsList -Emphasis @('State') -EmphasisClass important -Template $template

            $table.type | Should-Be 'asList'
            $table.class | Should-MatchString 'monkey-table-vertical'
            $table.SelectSingleNode('.//tr[td="State:"]/td[last()]').class | Should-Be 'important'
            $table.SelectSingleNode('.//tr[td="State:"]/td[last()]').InnerText | Should-Be 'Enabled'
        }
    }

    It 'generates a stable table id shape when none is supplied' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $table = New-HtmlTableFromObject -Data ([pscustomobject]@{ Name = 'Alpha' }) -Template $template
            $table.id | Should-MatchString '^MonkeyTable_[a-f0-9]{32}$'
        }
    }

    It 'adds action cells to rows and targets the matching extended object' {
        InModuleScope monkeyhtml {
            [xml]$template = '<html></html>'
            $table = New-HtmlTableFromObject `
                -Data ([pscustomobject]@{ Name = 'Alpha'; Count = 1 }) `
                -ExtendedData @([ordered]@{ id = 'raw-alpha' }) `
                -ShowModalButton `
                -Template $template

            @($table.SelectNodes('./thead/tr/th')) | Should-BeCollection -Count 3
            @($table.SelectNodes('./tbody/tr/td')) | Should-BeCollection -Count 3
            $button = $table.SelectSingleNode('./tbody/tr/td[last()]/button')
            $button | Should-NotBeNull
            $button.GetAttribute('data-bs-target') | Should-Be '#raw-alpha'
        }
    }
}

Set-StrictMode -Version Latest

Describe 'MonkeyHTML reusable components' {
    BeforeAll {
        $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
        $modulePath = Join-Path $repoRoot 'src\monkey365\core\modules\monkeyhtml'
        Import-Module $modulePath -Force -ErrorAction Stop
    }

    Context 'New-HtmlCard' {
        It 'builds a complete card with semantic sections' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $card = New-HtmlCard -Id card1 -ClassName custom -Style 'width: 10rem' `
                    -Header heading -HeaderClass header-extra -Title title -TitleClass title-extra `
                    -SubTitle subtitle -SubTitleClass subtitle-extra -CardText body `
                    -BodyClass body-extra -FooterText footer -FooterClass footer-extra -Template $template

                $card.Name | Should-Be 'div'
                $card.id | Should-Be 'card1'
                $card.class | Should-Be 'card custom'
                $card.style | Should-Be 'width: 10rem'
                $card.SelectSingleNode('./div[contains(@class,"card-header")]').InnerText | Should-Be 'heading'
                $card.SelectSingleNode('.//h5[contains(@class,"card-title")]').InnerText | Should-Be 'title'
                $card.SelectSingleNode('.//h6[contains(@class,"card-subtitle")]').InnerText | Should-Be 'subtitle'
                $card.SelectSingleNode('.//p[contains(@class,"card-text")]').InnerText | Should-Be 'body'
                $card.SelectSingleNode('./div[contains(@class,"card-footer")]').InnerText | Should-Be 'footer'
            }
        }

        It 'imports XML document and element content into card sections' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                [xml]$header = '<strong>header</strong>'
                [xml]$body = '<section>body</section>'
                [xml]$footerDocument = '<em>footer</em>'

                $card = New-HtmlCard -HeaderObject $header -BodyObject $body.DocumentElement `
                    -FooterObject $footerDocument -Template $template

                $card.SelectSingleNode('.//strong').InnerText | Should-Be 'header'
                $card.SelectSingleNode('.//section').InnerText | Should-Be 'body'
                $card.SelectSingleNode('.//em').InnerText | Should-Be 'footer'
            }
        }

        It 'groups body and footer in a collapsible region' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $card = New-HtmlCard -Header heading -BodyObject body -FooterText footer `
                    -Collapsible -Template $template

                $header = $card.SelectSingleNode('./div[contains(@class,"card-header")]')
                $collapse = $card.SelectSingleNode('./div[contains(@class,"collapse")]')
                $header.GetAttribute('data-bs-toggle') | Should-Be 'collapse'
                $header.GetAttribute('data-bs-target') | Should-Be ("#{0}" -f $collapse.id)
                $collapse.SelectSingleNode('./div[contains(@class,"card-body")]').InnerText | Should-Be 'body'
                $collapse.SelectSingleNode('./div[contains(@class,"card-footer")]').InnerText | Should-Be 'footer'
            }
        }
    }

    Context 'New-HtmlContainerCard' {
        It 'builds a titled container with category and icon' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $card = New-HtmlContainerCard -CardTitle Azure -CardCategory Cloud -Id azure `
                    -ClassName featured -Icon @('bi', 'bi-cloud') -Template $template

                $card.id | Should-Be 'azure'
                $card.class | Should-Be 'card monkey-card featured'
                $card.SelectSingleNode('.//h6[@class="card-category"]').InnerText | Should-Be 'Cloud'
                $card.SelectSingleNode('.//h4[@class="title-header"]').InnerText | Should-Be 'Azure'
                $card.SelectSingleNode('.//i').class | Should-Be 'bi bi-cloud'
            }
        }

        It 'appends XML documents, elements, and text to its body' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                [xml]$document = '<section><b>document</b></section>'
                [xml]$elementDocument = '<aside>element</aside>'

                $card = New-HtmlContainerCard -CardTitle title -Icon icon `
                    -AppendObject @($document, $elementDocument.DocumentElement, 'tail') -Template $template
                $body = $card.SelectSingleNode('.//div[contains(@class,"card-body")]')

                $body.SelectSingleNode('./section/b').InnerText | Should-Be 'document'
                $body.SelectSingleNode('./aside').InnerText | Should-Be 'element'
                $body.InnerText | Should-MatchString 'tail$'
            }
        }

        It 'uses an image with accessible alternate text' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $card = New-HtmlContainerCard -CardTitle SharePoint -Img '/img/sharepoint.svg' -Template $template
                $image = $card.SelectSingleNode('.//img')

                $image.src | Should-Be '/img/sharepoint.svg'
                $image.alt | Should-Be 'SharePoint'
            }
        }
    }

    Context 'New-HtmlModal' {
        It 'builds an accessible static modal with content and controls' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $modal = New-HtmlModal -Id details -Title Details -BodyObject body -FooterText footer `
                    -IconHeaderClass 'bi bi-info' -AddCloseButton -StaticBackdrop -Template $template

                $modal.id | Should-Be 'details'
                $modal.GetAttribute('aria-labelledby') | Should-Be 'detailsLabel'
                $modal.GetAttribute('data-bs-backdrop') | Should-Be 'static'
                $modal.SelectSingleNode('.//h5[@id="detailsLabel"]').InnerText | Should-Be 'Details'
                $modal.SelectSingleNode('.//div[contains(@class,"modal-body")]').InnerText | Should-Be 'body'
                $modal.SelectNodes('.//button[@data-bs-dismiss="modal"]') | Should-BeCollection -Count 2
                $modal.SelectSingleNode('.//i').class | Should-Be 'bi bi-info'
            }
        }

        It 'applies size and custom classes and can remove animation' {
            InModuleScope monkeyhtml {
                Mock Get-Random { 42 }
                [xml]$template = '<html></html>'
                $modal = New-HtmlModal -Title title -Size large -RemoveAnimation -CenteredScrollable `
                    -DialogClass dialog-extra -ContentClass content-extra -HeaderClass header-extra `
                    -BodyClass body-extra -TitleClass title-extra -Template $template

                $modal.id | Should-Be 'monkey_modal_42'
                $modal.class | Should-Be 'modal'
                $modal.SelectSingleNode('.//div[contains(@class,"modal-dialog")]').class |
                    Should-MatchString 'dialog-extra modal-lg'
                $modal.SelectSingleNode('.//div[contains(@class,"modal-dialog")]').class |
                    Should-MatchString 'modal-dialog-centered modal-dialog-scrollable'
                $modal.SelectSingleNode('.//div[contains(@class,"modal-content")]').class |
                    Should-MatchString 'content-extra'
                $modal.SelectSingleNode('.//div[contains(@class,"modal-header")]').class |
                    Should-MatchString 'header-extra'
                $modal.SelectSingleNode('.//div[contains(@class,"modal-body")]').class |
                    Should-MatchString 'body-extra'
            }
        }
    }

    Context 'New-HTMLTab' {
        It 'creates the default details and resources tabs with linked panes' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $tabs = New-HTMLTab -Default -Id finding -Template $template
                $links = @($tabs.SelectNodes('.//a'))
                $panes = @($tabs.SelectNodes('.//div[contains(@class,"tab-pane")]'))

                $links | Should-BeCollection -Count 2
                $panes | Should-BeCollection -Count 2
                $links[0].InnerText | Should-Be 'Finding Details'
                $links[1].InnerText | Should-Be 'Affected Resources'
                $links[0].href | Should-Be ("#{0}" -f $panes[0].id)
                $links[1].href | Should-Be ("#{0}" -f $panes[1].id)
            }
        }

        It 'creates custom tabs and applies component classes' {
            InModuleScope monkeyhtml {
                [xml]$template = '<html></html>'
                $tabs = New-HTMLTab -Tabs @('Overview', 'Evidence') -Id custom `
                    -ClassName wrapper -UlClassName navigation -LiClassName item `
                    -TabPaneClassName pane -TabContentClassName content -Template $template

                $tabs.class | Should-Be 'card wrapper'
                $tabs.SelectSingleNode('./ul').class | Should-MatchString 'navigation'
                @($tabs.SelectNodes('.//li[contains(@class,"item")]')) | Should-BeCollection -Count 2
                $panes = @($tabs.SelectNodes('.//div[contains(@class,"pane")]'))
                $links = @($tabs.SelectNodes('.//a'))
                $panes | Should-BeCollection -Count 2
                $links[0].InnerText | Should-Be 'Overview'
                $links[1].InnerText | Should-Be 'Evidence'
                $panes[0].id | Should-NotBe $panes[1].id
                $links[0].href | Should-Be ("#{0}" -f $panes[0].id)
                $links[1].href | Should-Be ("#{0}" -f $panes[1].id)
                $tabs.SelectSingleNode('./div[contains(@class,"tab-content")]').class |
                    Should-MatchString 'content'
            }
        }
    }
}

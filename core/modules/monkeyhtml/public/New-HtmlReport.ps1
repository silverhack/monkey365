# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Function New-HtmlReport{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HtmlReport
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$matched,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$rules,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$user_info,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$exec_info,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$data,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$chartData,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$tableData,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$dashboardData,

        [Parameter(Mandatory=$True)]
        [ValidateSet('Azure','Microsoft365','EntraID')]
        [String]$Instance,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Environment,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Tenant
    )
    Begin{
        #Update psObject
        Update-PsObject
        #main template
        [xml]$template = '<html lang="en" xmlns="http://www.w3.org/1999/html"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><meta name="description" content="Monkey365 report"/><meta name="author" content="Juan Garrido"/><title>Monkey365 Report</title><!-- Monkey365 favicon --><link href="assets/inc-monkey/favicon.ico" rel="icon" type="image/x-icon"/><!-- jQuery --><script src="assets/inc-jquery/jquery-3.5.1.min.js"> </script><script src="assets/inc-jquery-ui/jquery-ui.min.js"> </script><!-- Charts --><script src="assets/inc-charts/js/chartkick.min.js"> </script><script src="assets/inc-charts/js/Chart.bundle.min.js"> </script><!-- JQuery UI CSS --><link href="assets/inc-jquery-ui/jquery-ui.min.css" rel="stylesheet"/><!-- Bootstrap core CSS --><link href="assets/inc-bootstrap/css/bootstrap.min.css" rel="stylesheet"/><!-- Bootstrap icons --><link href="assets/inc-bootstrap/font/bootstrap-icons.css" rel="stylesheet"/><!-- Fontawesome CSS --><link href="assets/inc-fontawesome/css/all.min.css" rel="stylesheet"/><!-- Office UI --><link href="assets/inc-fabric-icons/css/fabric-icons.css" rel="stylesheet"/><!-- Fallback fonts to solve CORS issue--><link href="https://use.fontawesome.com/releases/v5.6.3/css/all.css" rel="stylesheet"/><script src="assets/inc-bootstrap/js/bootstrap.bundle.min.js"> </script><!-- Bootstrap table --><script src="assets/inc-datatables/js/jquery.dataTables.min.js"> </script><script src="assets/inc-datatables/js/dataTables.bootstrap.min.js"> </script><script src="assets/inc-datatables/js/dataTables.bootstrap4.min.js"> </script><script src="assets/inc-datatables/js/dataTables.foundation.min.js"> </script><script src="assets/inc-datatables/js/dataTables.jqueryui.min.js"> </script><script src="assets/inc-datatables/js/dataTables.semanticui.min.js"> </script><!-- Bootstrap table buttons --><script src="assets/inc-datatables-buttons/js/dataTables.buttons.min.js"> </script><script src="assets/inc-datatables-buttons/js/jszip.min.js"> </script><script src="assets/inc-datatables-buttons/js/pdfmake.min.js"> </script><script src="assets/inc-datatables-buttons/js/vfs_fonts.js"> </script><script src="assets/inc-datatables-buttons/js/buttons.html5.min.js"> </script><script src="assets/inc-datatables-buttons/js/buttons.print.min.js"> </script><script src="assets/inc-datatables-buttons/js/buttons.jqueryui.min.js"> </script><script src="assets/inc-datatables-buttons/js/buttons.foundation.min.js"> </script><script src="assets/inc-datatables-buttons/js/buttons.bootstrap.min.js"> </script><script src="assets/inc-datatables-buttons/js/buttons.bootstrap4.min.js"> </script><script src="assets/inc-jquery-ui/jquery-resizable.min.js"> </script><!-- Datatables --><link href="assets/inc-datatables/css/dataTables.bootstrap.min.css" rel="stylesheet"/><link href="assets/inc-datatables/css/dataTables.bootstrap4.min.css" rel="stylesheet"/><link href="assets/inc-datatables/css/dataTables.foundation.min.css" rel="stylesheet"/><link href="assets/inc-datatables/css/dataTables.jqueryui.min.css" rel="stylesheet"/><link href="assets/inc-datatables/css/dataTables.semanticui.min.css" rel="stylesheet"/><link href="assets/inc-datatables/css/jquery.dataTables.min.css" rel="stylesheet"/><!-- Datatable Buttons --><link href="assets/inc-datatables-buttons/css/buttons.bootstrap.min.css" rel="stylesheet"/><link href="assets/inc-datatables-buttons/css/buttons.bootstrap4.min.css" rel="stylesheet"/><link href="assets/inc-datatables-buttons/css/buttons.dataTables.min.css" rel="stylesheet"/><link href="assets/inc-datatables-buttons/css/buttons.foundation.min.css" rel="stylesheet"/><link href="assets/inc-datatables-buttons/css/buttons.jqueryui.min.css" rel="stylesheet"/><link href="assets/inc-datatables-buttons/css/buttons.semanticui.min.css" rel="stylesheet"/><!-- Highlight --><link href="assets/inc-highlight/styles/default.min.css" rel="stylesheet"/><script src="assets/inc-highlight/js/highlight.min.js"> </script><!-- Monkey365 --><script src="assets/inc-monkey/js/helpers.js"> </script><link href="assets/inc-monkey/css/design.css" rel="stylesheet"/></head><body xmlns="" class="monkey-scrollbar"/></html>'
        #Set variable template for using in whole script
        Set-Variable -Name template -Value $template -Scope script
        Set-Variable -Name matched -Value $matched -Scope script
        Set-Variable -Name rules -Value $rules -Scope script
        Set-Variable -Name user_info -Value $user_info -Scope script
        Set-Variable -Name data -Value $data -Scope script
        Set-Variable -Name exec_info -Value $exec_info -Scope script
        Set-Variable -Name environment -Value $Environment -Scope script
        Set-Variable -Name tenant -Value $Tenant -Scope script
        if($null -ne $dashboardData -and $dashboardData.Count -gt 0){
            Set-Variable -Name dashboards -Value $dashboardData -Scope script
        }
        if($null -ne $tableData -and $tableData.Count -gt 0){
            Set-Variable -Name dtables -Value $tableData -Scope Script
        }
        if($null -ne $chartData -and $chartData.Count -gt 0){
            Set-Variable -Name dcharts -Value $chartData -Scope script
        }
        #Copy scripts and remove body
        $scripts = $template.html.body.Clone()
        $old = $template.DocumentElement.body
        [void]$template.DocumentElement.RemoveChild($old)
        #Create body
        $body = $template.CreateElement("body")
        [void]$body.SetAttribute('class','monkey-scrollbar')
        #Create wrapper div
        $wrapper_div = $template.CreateElement("div")
        [void]$wrapper_div.SetAttribute('class','wrapper')
        [void]$wrapper_div.SetAttribute('id','monkey_container')
        #Create main element
        $main_div = $template.CreateElement("div")
        [void]$main_div.SetAttribute('class','main')
        #Create content element
        $content_div = $template.CreateElement("div")
        [void]$content_div.SetAttribute('class','content')
        #Create container-fluid element
        $container_div = $template.CreateElement("div")
        [void]$container_div.SetAttribute('class','container-fluid')
        [void]$container_div.SetAttribute('id','monkey_content')
        #Get Empty card
        $monkey_card = New-MonkeyEmptyCard
        #convert Monkey global card
        if($monkey_card -is [System.Xml.XmlDocument]){
            $monkey_card = $template.ImportNode($monkey_card.get_DocumentElement(), $True)
        }
        #Get execution info
        $exec_info = New-ExecutionInfoPanel
        if($exec_info -is [System.Xml.XmlDocument]){
            $exec_info = $template.ImportNode($exec_info.get_DocumentElement(), $True)
        }
        #Get Modal
        $param = @{
            modal_title = "Monkey365 error";
            id_modal = "my_modal";
            WithFooter = $True;
            addCloseButton = $True;
            modal_icon_header_class = "bi bi-cloud-drizzle";
        }
        $modal = New-HtmlModal @param
        if($modal -is [System.Xml.XmlDocument]){
            $modal = $template.ImportNode($modal.get_DocumentElement(), $True)
        }
        #Get sidebar
        $sidebar = New-SideBar -items $matched
        if($sidebar -is [System.Xml.XmlDocument]){
            $sidebar = $template.ImportNode($sidebar.get_DocumentElement(), $True)
        }
        #Get Horizontal Navbar
        $navbar = New-HorizontalNavBar -user_info $user_info
        if($navbar -is [System.Xml.XmlDocument]){
            $navbar = $template.ImportNode($navbar.get_DocumentElement(), $True)
        }
        #Get Subscription Info
        $sub_info = New-SubscriptionInfo -Instance $Instance
        if($sub_info -is [System.Xml.XmlDocument]){
            $sub_info = $template.ImportNode($sub_info.get_DocumentElement(), $True)
        }
        #Get main Dashboard
        $main_dashboard = New-MainDashboard2
        if($main_dashboard -is [System.Xml.XmlDocument]){
            $main_dashboard = $template.ImportNode($main_dashboard.get_DocumentElement(), $True)
        }
        #Get all issues
        $formatted_issues = Get-HtmlIssue
        $all_issues = $formatted_issues.html_issues
        if($all_issues -is [System.Xml.XmlDocument]){
            $all_issues = $template.ImportNode($all_issues.get_DocumentElement(), $True)
        }
        #Add detailed objects to html
        $extended_objects = $formatted_issues.extended_objects
        if($extended_objects -is [System.Xml.XmlDocument]){
            $extended_objects = $template.ImportNode($extended_objects.get_DocumentElement(), $True)
        }
        #Get Dashboards
        $all_dashboards = Invoke-HtmlDashboards
        if($all_dashboards){
            #Get sidebar
            $sidebar = New-SideBar -items $matched
            #Update sidebar with new dashboards
            if($sidebar -is [System.Xml.XmlDocument]){
                $sidebar = Update-SideBar -sidebar $sidebar -dashboards $all_dashboards
            }
        }
        else{
            #Get sidebar
            $sidebar = New-SideBar -items $matched
        }
        #Get About author modal
        $modal_author = New-HtmlAboutAuthorModal
        if($modal_author -is [System.Xml.XmlDocument]){
            $modal_author = $template.ImportNode($modal_author.get_DocumentElement(), $True)
        }
        #Get About monkey365 modal
        $monkey_modal = New-HtmlAboutTool
        if($monkey_modal -is [System.Xml.XmlDocument]){
            $monkey_modal = $template.ImportNode($monkey_modal.get_DocumentElement(), $True)
        }
    }
    Process{
        #Add modal to body
        $c = $template.CreateComment('Monkey365 modal')
        [void]$body.AppendChild($c);
        #Add sidebar to wrapper
        [void]$body.AppendChild($modal);
        $c = $template.CreateComment('End Monkey365 modal')
        #Add author modal to body
        $c = $template.CreateComment('Monkey365 about author modal')
        [void]$body.AppendChild($c);
        #Add modal to wrapper
        [void]$body.AppendChild($modal_author);
        $c = $template.CreateComment('End Monkey365 about author modal')
        #Add monkey365 modal to body
        $c = $template.CreateComment('Monkey365 about tool modal')
        [void]$body.AppendChild($c);
        #Add modal to wrapper
        [void]$body.AppendChild($monkey_modal);
        $c = $template.CreateComment('End Monkey365 about tool modal')
        [void]$body.AppendChild($c);

        #Add monkey365 detailed modal objects to body
        $c = $template.CreateComment('Monkey365 extended_data modals')
        [void]$body.AppendChild($c);
        #Add modal to wrapper
        foreach($new_modal in $extended_objects){
            #Add issue
            if($new_modal -is [System.Xml.XmlDocument]){
                [void]$body.AppendChild($template.ImportNode($new_modal.get_DocumentElement(), $True));
            }
            else{
                [void]$body.AppendChild($template.ImportNode($new_modal, $True));
            }
        }
        $c = $template.CreateComment('End Monkey365 extended_data modals')
        [void]$body.AppendChild($c);

        #Create comment for sidebar
        $c = $template.CreateComment('Sidebar')
        [void]$wrapper_div.AppendChild($c);
        #Add sidebar to wrapper
        if($sidebar -is [System.Xml.XmlDocument]){
            $sidebar = $template.ImportNode($sidebar.get_DocumentElement(), $True)
        }
        [void]$wrapper_div.AppendChild($sidebar);
        $c = $template.CreateComment('End Sidebar')
        [void]$wrapper_div.AppendChild($c);
        #Create comment for navbar
        $c = $template.CreateComment('Horizontal navbar')
        [void]$main_div.AppendChild($c);
        #Add navbar to main div
        [void]$main_div.AppendChild($navbar);
        $c = $template.CreateComment('End horizontal navbar')
        [void]$main_div.AppendChild($c);

        #Add subscription info to container
        $c = $template.CreateComment('Subscription info')
        [void]$container_div.AppendChild($c);
        [void]$container_div.AppendChild($sub_info);
        $c = $template.CreateComment('End subscription info')
        [void]$container_div.AppendChild($c);

        #Add execution info to content-wrapper div
        $c = $template.CreateComment('Execution info')
        [void]$container_div.AppendChild($c);
        [void]$container_div.AppendChild($exec_info);
        $c = $template.CreateComment('End Execution info')
        [void]$container_div.AppendChild($c);

        #Add main dashboard to content-wrapper
        $c = $template.CreateComment('Dashboard Overall info')
        [void]$container_div.AppendChild($c);
        [void]$container_div.AppendChild($main_dashboard);
        $c = $template.CreateComment('End Dashboard Overall info')
        [void]$container_div.AppendChild($c);
        #Add monkey card to content-wrapper
        $c = $template.CreateComment('Monkey365 global issues card')
        [void]$container_div.AppendChild($c);
        [void]$container_div.AppendChild($monkey_card);
        $c = $template.CreateComment('End Monkey365 global issues card')
        [void]$container_div.AppendChild($c);
        #Add all issues to content-wrapper
        foreach($issue in $all_issues){
            #Add issue
            if($issue -is [System.Xml.XmlDocument]){
                [void]$container_div.AppendChild($template.ImportNode($issue.get_DocumentElement(), $True));
            }
            else{
                [void]$container_div.AppendChild($template.ImportNode($issue, $True));
            }
        }
        #Add all dashboards
        foreach($section in $all_dashboards){
            if($section.data -is [System.Xml.XmlDocument]){
                [void]$container_div.AppendChild($template.ImportNode($section.data.get_DocumentElement(), $True));
            }
            else{
                [void]$container_div.AppendChild($template.ImportNode($section.data, $True));
            }
        }
        #Add container to content div
        [void]$content_div.AppendChild($container_div);
        #Add content div to main element
        [void]$main_div.AppendChild($content_div);
        #Add main to wrapper
        [void]$wrapper_div.AppendChild($main_div);
        #Add wrapper to body element
        [void]$body.AppendChild($wrapper_div);
        #Add scripts
        if($scripts.PSObject.Properties.Item('script')){
            foreach($src in $scripts.script.src){
                $new_src = $template.CreateElement("script")
                [void]$new_src.SetAttribute('src',$src)
                $new_src.InnerText = [string]::Empty
                [void]$body.AppendChild($new_src)
            }
        }
        #Add more javascript
        $new_src = $template.CreateElement("script")
        [void]$new_src.SetAttribute('src','assets/inc-monkey/js/monkey_helper.js')
        [void]$new_src.AppendChild($template.CreateWhitespace(""))
        #$new_src.InnerText = [string]::Empty
        [void]$body.AppendChild($new_src)
        #Add to template
        [void]$template.DocumentElement.AppendChild($body)
        #Create comment for body
        $c = $template.CreateComment('End body element')
        [void]$template.DocumentElement.AppendChild($c);
        #Format indented
        $indented = Update-XMLIndent -Content $template -Indent 1
        return $indented
    }
    End{
        #Cleaning vars
        Remove-Variable -Name template -ErrorAction Ignore
        Remove-Variable -Name matched -ErrorAction Ignore
        Remove-Variable -Name rules -ErrorAction Ignore
        Remove-Variable -Name user_info -ErrorAction Ignore
        Remove-Variable -Name data -ErrorAction Ignore
        Remove-Variable -Name exec_info -ErrorAction Ignore
        Remove-Variable -Name dcharts -ErrorAction Ignore
        Remove-Variable -Name dashboards -ErrorAction Ignore
        Remove-Variable -Name environment -ErrorAction Ignore
        Remove-Variable -Name tenant -ErrorAction Ignore
        Remove-Variable -Name dtables -ErrorAction Ignore
    }
}


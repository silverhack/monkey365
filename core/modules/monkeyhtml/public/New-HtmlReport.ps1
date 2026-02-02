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
        [Parameter(Mandatory=$true, HelpMessage="Report Object")]
        [Object]$Report,

        [parameter(Mandatory= $true, ParameterSetName = 'ConfigFile', HelpMessage= "json config")]
        [ValidateScript({
            if( -Not (Test-Path -Path $_) ){
                throw ("The HTML config does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not (Test-Path -Path $_ -PathType Leaf) ){
                throw "The HTML config argument must be a json file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.json)"){
                throw "The file specified in the config argument must be of type json"
            }
            return $true
        })]
        [System.IO.FileInfo]$ConfigFile,

        [Parameter(Mandatory=$true, ParameterSetName = 'LocalCDN', HelpMessage="Load resources from local source")]
        [String]$LocalRepository,

        [Parameter(Mandatory=$true, ParameterSetName = 'CDN', HelpMessage="Load resources from external source")]
        [String]$Repository,

        [Parameter(Mandatory=$false, HelpMessage="Repository branch")]
        [String]$Branch = "main",

        [Parameter(Mandatory=$true, ParameterSetName = 'Config', HelpMessage="Config object")]
        [Object]$Config,

        [Parameter(Mandatory=$false, HelpMessage="Local assets path")]
        [Parameter(Mandatory=$true, ParameterSetName = 'Config', HelpMessage="Config object")]
        [System.IO.DirectoryInfo]$AssetsPath,

        [Parameter(Mandatory=$true, HelpMessage="Execution info object")]
        [Object]$ExecutionInfo,

        [Parameter(Mandatory=$true, HelpMessage="Rules")]
        [Object]$Rules,

        [Parameter(Mandatory=$true, HelpMessage="Ruleset info")]
        [Object]$RulesetInfo,

        [Parameter(Mandatory=$false, HelpMessage="Instance")]
        [String]$Instance,

        [parameter(Mandatory= $true, HelpMessage= "Directory output")]
        [ValidateScript({
            If( -Not (Test-Path -Path $_) ){
                throw ("The directory does not exist in {0}" -f (Split-Path -Path $_))
            }
            If(-Not (Test-Path -Path $_ -PathType Container) ){
                throw "The OutDir argument must be a directory. Files are not allowed."
            }
            return $true
        })]
        [System.IO.DirectoryInfo]$OutDir
    )
    Process{
        Write-Verbose $Script:messages.InitializeMonkeyhtml
        $initialized = Initialize-MonkeyHtml @PSBoundParameters
        If($initialized){
            $header = Get-HtmlHeader
            #Add to template
            [void]$Script:Template.DocumentElement.AppendChild($header)
            #Add body
            $bodyDiv = New-HtmlTag -Name body -ClassName "monkey-scrollbar"
            $bodyDiv.RemoveAttribute("xmlns");
            #Add wrapper
            $wrapperDiv = New-HtmlTag -Name div -ClassName "wrapper"
            #Add sidebar Div
            $sideBarDiv = New-SideBar -InputObject $Script:Report
            #Add main Div
            $mainDiv = New-HtmlTag -Name div -ClassName "main"
            #Get navBar
            $navBar = New-HTMLNavBar
            #Get issue cards
            $ContainerCards = Get-HtmlContainerCard -InputObject $Script:Report
            #Get all modal objects
            $modals = Get-AllModalHtmlObject -Report $Script:Report
            $c = $Script:Template.CreateComment('Monkey365 modal objects')
            #Add to body
            [void]$bodyDiv.AppendChild($c);
            #Add modals
            Foreach($modalObj in $modals){
                [void]$bodyDiv.AppendChild($modalObj);
            }
            $c = $Script:Template.CreateComment('End Monkey365 modal objects')
            #Add to body
            [void]$bodyDiv.AppendChild($c);
            #Add to main div
            [void]$mainDiv.AppendChild($navBar);
            #Add sidebar and main to wrapper div
            $c = $Script:Template.CreateComment('Sidebar')
            [void]$wrapperDiv.AppendChild($c);
            [void]$wrapperDiv.AppendChild($sideBarDiv);
            $c = $Script:Template.CreateComment('End Sidebar');
            [void]$wrapperDiv.AppendChild($c);
            #Create Div class content
            $DivContent = New-HtmlTag -Name div -ClassName "content"
            #Create Div container fluid
            $DivContainerFluid = New-HtmlTag -Name div -ClassName "container-fluid" -Id "Monkey365Data"
            #Add provider info
            $Provider = New-AccountInfo -Instance $Instance
            #Add to container fluid
            $c = $Script:Template.CreateComment('Provider info');
            [void]$DivContainerFluid.AppendChild($c);
            [void]$DivContainerFluid.AppendChild($Provider);
            $c = $Script:Template.CreateComment('End Provider info');
            [void]$DivContainerFluid.AppendChild($c);
            #Add scan details info content
            $scanInfoContent = New-HtmlScanDetailsCard
            If($scanInfoContent){
                $c = $Script:Template.CreateComment('Monkey365 scan info');
                [void]$DivContainerFluid.AppendChild($c);
                [void]$DivContainerFluid.AppendChild($scanInfoContent);
                $c = $Script:Template.CreateComment('End Monkey365 scan info');
                [void]$DivContainerFluid.AppendChild($c);
            }
            #Add dashboard to main content
            $mainDashboard = New-HtmlMainDashboard -InputObject $Script:Report -HorizontalStackedBar -Donut
            If($mainDashboard){
                $c = $Script:Template.CreateComment('Monkey365 main dashboard');
                [void]$DivContainerFluid.AppendChild($c);
                [void]$DivContainerFluid.AppendChild($mainDashboard);
                $c = $Script:Template.CreateComment('End Monkey365 main dashboard');
                [void]$DivContainerFluid.AppendChild($c);
            }
            #Add finding cards
            $c = $Script:Template.CreateComment('Monkey365 finding cards');
            [void]$DivContainerFluid.AppendChild($c);
            Foreach($containerCard in @($ContainerCards)){
                [void]$DivContainerFluid.AppendChild($containerCard);
            }
            $c = $Script:Template.CreateComment('End Monkey365 finding cards');
            [void]$DivContainerFluid.AppendChild($c);
            #Get empty card
            $monkeyEmptyCard = New-HtmlContainerCard -CardTitle "Monkey365 findings" -Img (Get-SvgIcon -InputObject monkey365)
            #Get Body
            $cardBody = $monkeyEmptyCard.SelectSingleNode('//div[contains(@class,"card-body")]')
            #Add Id
            [void]$cardBody.SetAttribute('id','Monkey365Findings')
            $newRow = $Script:Template.CreateElement("div");
            [void]$newRow.SetAttribute('class','row d-none')
            [void]$newRow.SetAttribute('id','Monkey365GlobalFindings')
            #Append card
            [void]$newRow.AppendChild($monkeyEmptyCard);
            $c = $Script:Template.CreateComment('Monkey365 empty card')
            #Add to body
            [void]$DivContainerFluid.AppendChild($c);
            #Add row
            [void]$DivContainerFluid.AppendChild($newRow);
            $c = $Script:Template.CreateComment('End Monkey365 empty card')
            [void]$DivContainerFluid.AppendChild($c);
            #Add to div content
            [void]$DivContent.AppendChild($DivContainerFluid);
            #Add div content to main div
            [void]$mainDiv.AppendChild($DivContent);
            #Add main content to wrapper div
            [void]$wrapperDiv.AppendChild($mainDiv);
            #Add to body
            [void]$bodyDiv.AppendChild($wrapperDiv);
            #Insert body into html
            #$myHeader = $html.ImportNode($header.get_DocumentElement(), $True)
            #$myHeader.RemoveAttribute("xmlns");
            #Add more javascript
            $helperJS = Get-JSHelper
            ForEach($helper in @($helperJS)){
                [void]$bodyDiv.AppendChild($helper);
            }
            #Add to template
            [void]$Script:Template.DocumentElement.AppendChild($bodyDiv)
            #Create comment for body
            $c = $Script:Template.CreateComment('End body element')
            [void]$Script:Template.DocumentElement.AppendChild($c);
            #Add to html
            [void]$Script:Template.html.SetAttribute('xmlns','http://www.w3.org/1999/html')
            #Set html document type
            #check PsVersion
            If($PSVersionTable.PSVersion.Major -lt 7){
                $documentType = $Script:Template.CreateDocumentType('html',$null,$null,$null)
            }
            Else{
                $documentType = $Script:Template.CreateDocumentType('html','-//W3C//DTD HTML 4.01//EN','http://www.w3.org/TR/html4/strict.dtd',$null)
            }
            #$documentType = $html.CreateDocumentType('html',$null,$null,$null)
            [void]$Script:Template.PrependChild($documentType);
            $indented = Update-XMLIndent -Content $Script:Template -Indent 1
            $_decodedHtml = [System.Web.HttpUtility]::HtmlDecode($indented)
            #Set out file
            If($PSCmdlet.ParameterSetName.ToLower() -eq "cdn"){
                $outFile = ("{0}{1}monkey365_cdn_{2}{3}.html" -f $Script:OutDir, [System.IO.Path]::DirectorySeparatorChar, $ExecutionInfo.tenant.tenantId.Replace('-',''), ([System.DateTime]::UtcNow).ToString("yyyyMMddHHmmss"))
            }
            ElseIf($PSCmdlet.ParameterSetName.ToLower() -eq "localcdn"){
                $outFile = ("{0}{1}monkey365_localcdn_{2}{3}.html" -f $Script:OutDir, [System.IO.Path]::DirectorySeparatorChar, $ExecutionInfo.tenant.tenantId.Replace('-',''), ([System.DateTime]::UtcNow).ToString("yyyyMMddHHmmss"))
            }
            Else{
                $outFile = ("{0}{1}monkey365_local_{2}{3}.html" -f $Script:OutDir, [System.IO.Path]::DirectorySeparatorChar, $ExecutionInfo.tenant.tenantId.Replace('-',''), ([System.DateTime]::UtcNow).ToString("yyyyMMddHHmmss"))
            }
            $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
            [System.IO.File]::WriteAllLines($outFile, $_decodedHtml, $Utf8NoBomEncoding)
        }
    }
    End{
        #Cleaning vars
        Remove-Variable -Name Template -Force -ErrorAction Ignore
        Remove-Variable -Name Report -Force -ErrorAction Ignore
        Remove-Variable -Name ExecutionInfo -Force -ErrorAction Ignore
        Remove-Variable -Name Rules -Force -ErrorAction Ignore
        Remove-Variable -Name RulesetInfo -Force -ErrorAction Ignore
    }
}

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

Function Get-HTMLNavBarGitHubInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HTMLNavBarGitHubInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $false, HelpMessage= "Repository Url")]
        [String]$Url = "https://github.com/silverhack/monkey365",

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        #Set null
        $version = $stargazers = $null;
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        $BaseUrl = $Url -replace "github.com","api.github.com/repos"
        Try{
            $repo = Invoke-WebRequest -Uri $BaseUrl -UserAgent "Monkey365" -UseBasicParsing -ErrorAction Ignore
            $content = $repo.Content | ConvertFrom-Json
            #Get StarGazers
            $stargazers = $content | Select-Object -ExpandProperty stargazers_count -ErrorAction Ignore
            #Get latest release
            $repoUrl = ("{0}/releases/latest" -f $BaseUrl);
            $repo = Invoke-WebRequest -Uri $repoUrl -UserAgent "Monkey365" -UseBasicParsing -ErrorAction Ignore
            $content = $repo.Content | ConvertFrom-Json
            #Get tag name
            $version = $content | Select-Object -ExpandProperty tag_name -ErrorAction Ignore
        }
        Catch{
            Write-Error $_.Exception
        }
    }
    Process{
        #UL properties
        $ULProperties = @{
            Name = 'ul';
            ClassName = 'monkey365-source';
            Template = $TemplateObject;
        }
        #Create element
        $listGroup = New-HtmlTag @ULProperties
        #li properties
        $liProperties = @{
            Name = 'li';
            ClassName = 'list-group-item';
            Template = $TemplateObject;
        }
        #Create main row
        $listGroupItem = New-HtmlTag @liProperties
        #Create a element
        $aProperties = @{
            Name = 'a';
            ClassName = 'monkey-source-link';
            Attributes = @{
                href = $Url;
                title = "Go to repository";
                target = "_blank";
            }
            Template = $TemplateObject;
        }
        #Create element
        $aHref = New-HtmlTag @aProperties
        #Set GitHub group item
        $listItem = $listGroupItem.Clone();
        #Set empty i tag
        $iProperties = @{
            Name = 'i';
            ClassName = 'bi bi-github';
            Empty = $True;
            Template = $TemplateObject;
        }
        #Create element
        $iTag = New-HtmlTag @iProperties
        #Add to listItem
        [void]$listItem.AppendChild($iTag);
        #Create span object
        $spanProperties = @{
            Name = "span";
            ClassName = "bi-icon";
            Id = "GitHub";
            Text = $Version.ToLower();
            CreateTextNode = $True;
            Template = $TemplateObject;
        }
        #Create element
        $spanObj = New-HtmlTag @spanProperties
        #Add to list item
        [void]$listItem.AppendChild($spanObj);
        #Add to list group
        [void]$listGroup.AppendChild($listItem);
        #Set stars group item
        $listItem = $listGroupItem.Clone();
        #Set empty i tag
        $iProperties = @{
            Name = 'i';
            ClassName = 'bi bi-star-fill';
            Empty = $True;
            Template = $TemplateObject;
        }
        #Create element
        $iTag = New-HtmlTag @iProperties
        #Add to listItem
        [void]$listItem.AppendChild($iTag);
        #Create span object
        $spanProperties = @{
            Name = "span";
            ClassName = "bi-icon";
            Id = "Stars";
            Text = $stargazers;
            CreateTextNode = $True;
            Template = $TemplateObject;
        }
        #Create element
        $spanObj = New-HtmlTag @spanProperties
        #Add to list item
        [void]$listItem.AppendChild($spanObj);
        #Add to list group
        [void]$listGroup.AppendChild($listItem);
        #Add list group to ahref
        [void]$aHref.AppendChild($listGroup);
        return $aHref
    }
    End{
        #Nothing to do here
    }
}

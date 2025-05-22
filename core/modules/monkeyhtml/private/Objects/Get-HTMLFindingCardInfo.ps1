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

Function Get-HTMLFindingCardInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HTMLFindingCardInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage= "Finding Object")]
        [Object]$FindingObject,

        [parameter(Mandatory= $false, HelpMessage= "Template")]
        [System.Xml.XmlDocument]$Template
    )
    Begin{
        If($PSBoundParameters.ContainsKey('Template') -and $PSBoundParameters['Template']){
            $TemplateObject = $PSBoundParameters['Template']
        }
        ElseIf($null -ne (Get-Variable -Name Template -Scope Script -ErrorAction Ignore)){
            $TemplateObject = $script:Template
        }
        Else{
            [xml]$TemplateObject = "<html></html>"
        }
        #Set array
        $allCols = [System.Collections.Generic.List[System.Xml.XmlElement]]::new()
        #Div properties
        $divProperties = @{
            Name = 'div';
            ClassName = 'card-content';
            Template = $TemplateObject;
        }
        #Create element
        $cardContent = New-HtmlTag @divProperties
        #Div properties
        $divProperties = @{
            Name = 'div';
            ClassName = 'row';
            Template = $TemplateObject;
        }
        #Create main row
        $mainRow = New-HtmlTag @divProperties
        #Create list-group element
        $ulProperties = @{
            Name = 'ul';
            ClassName = 'list-group';
            Template = $TemplateObject;
        }
        #Create element
        $listGroup = New-HtmlTag @ulProperties
        #Create list-group-item element
        $liProperties = @{
            Name = 'li';
            ClassName = 'list-group-item monkey-finding-info border-0';
            Template = $TemplateObject;
        }
        #Create element
        $listGroupItem = New-HtmlTag @liProperties
        #Create span element
        $spanProperties = @{
            Name = 'span';
            ClassName = 'text-justify font-weight-bold';
            Template = $TemplateObject;
        }
        #Create element
        $spanLabel = New-HtmlTag @spanProperties
    }
    Process{
        #Get listgroup
        $_listGroup = $listGroup.Clone()
        #Get listgroupitem
        $groupItem = $listGroupItem.Clone()
        #Get Rule Id
        $ruleIdSpan = $spanLabel.Clone()
        #Add text
        [void]$ruleIdSpan.AppendChild($TemplateObject.CreateTextNode("Rule Id"))
        #Add to list group item
        [void]$groupItem.AppendChild($ruleIdSpan);
        #Add to list group
        [void]$_listGroup.AppendChild($groupItem);
        #Create input group for input text
        $divProperties = @{
            Name = 'div';
            ClassName = 'input-group mt-2';
            Template = $TemplateObject;
        }
        #Create element
        $inputGroup = New-HtmlTag @divProperties
        #Create guid
        $ruleGuid = ("{0}-{1}" -f $FindingObject.idSuffix, [System.Guid]::NewGuid().Guid.Replace('-',''))
        $inputProperties = @{
            Name = 'input';
            ClassName = 'form-control border-end-0';
            Id = $ruleGuid;
            Attributes = @{
                type = "text";
                disabled = "";
                value = $FindingObject.idSuffix;
            }
            Template = $TemplateObject;
        }
        #Create element
        $inputTag = New-HtmlTag @inputProperties
        #Add to input group
        [void]$inputGroup.AppendChild($inputTag);
        #Set empty i tag
        $iProperties = @{
            Name = 'i';
            ClassName = 'bi bi-copy';
            Empty = $True;
            Template = $TemplateObject;
        }
        #Create element
        $iTag = New-HtmlTag @iProperties
        #Create button and append I tag
        $buttonProperties = @{
            Name = 'button';
            ClassName = 'btn monkey-clipboard';
            Id = ("{0}" -f $ruleGuid);
            Attributes = @{
                type = "button";
                "data-bs-target" = ("{0}" -f $ruleGuid);
            };
            AppendObject = $iTag;
            Template = $TemplateObject;
        }
        #Create element
        $buttonTag = New-HtmlTag @buttonProperties
        #Create span object and append button
        $spanProperties = @{
            Name = 'span';
            ClassName = 'input-group-append border-start-0 rounded-end';
            AppendObject = $buttonTag;
            Template = $TemplateObject;
        }
        #Create element
        $spanButton = New-HtmlTag @spanProperties
        #Add to input group
        [void]$inputGroup.AppendChild($spanButton);
        #Add to list group item
        $groupItem = $listGroupItem.Clone()
        [void]$groupItem.AppendChild($inputGroup);
        #Add to list group
        [void]$_listGroup.AppendChild($groupItem);
        #Create div and append list group
        $divProperties = @{
            Name = 'div';
            ClassName = 'col-md-4 id-suffix';
            AppendObject = $_listGroup;
            Template = $TemplateObject;
        }
        #Create element
        $divIdSuffix = New-HtmlTag @divProperties
        #Add to column array
        [void]$allCols.Add($divIdSuffix);
        #Add Severity
        #Get listgroup
        $_listGroup = $listGroup.Clone()
        #Get listgroupitem
        $groupItem = $listGroupItem.Clone()
        #Get Severity span tag
        $severitySpan = $spanLabel.Clone()
        #Add text
        [void]$severitySpan.AppendChild($TemplateObject.CreateTextNode("Severity"))
        #Add to list group item
        [void]$groupItem.AppendChild($severitySpan);
        #Add to list group
        [void]$_listGroup.AppendChild($groupItem);
        #Get listgroupitem
        $groupItem = $listGroupItem.Clone()
        #Get Flag
        $badgeColor = $FindingObject.level | Get-BadgeFromLevel
        $spanProperties = @{
            Name = "span";
            ClassName = ("badge badge-xl {0} mt-2" -f $badgeColor);
            Text = $FindingObject.level.ToLower();
            CreateTextNode = $True;
            Template = $TemplateObject;
        }
        #Create element
        $spanObj = New-HtmlTag @spanProperties
        #Add to group item
        [void]$groupItem.AppendChild($spanObj);
        #Add to list group
        [void]$_listGroup.AppendChild($groupItem);
        #Create div and append list group
        $divProperties = @{
            Name = 'div';
            ClassName = 'col-md-1';
            AppendObject = $_listGroup;
            Template = $TemplateObject;
        }
        #Create element
        $divSeverity = New-HtmlTag @divProperties
        #Add to column array
        [void]$allCols.Add($divSeverity);
        #Add Status
        #Get listgroup
        $_listGroup = $listGroup.Clone()
        #Get listgroupitem
        $groupItem = $listGroupItem.Clone()
        #Get Severity span tag
        $statusSpan = $spanLabel.Clone()
        #Add text
        [void]$statusSpan.AppendChild($TemplateObject.CreateTextNode("Status"))
        #Add to list group item
        [void]$groupItem.AppendChild($statusSpan);
        #Add to list group
        [void]$_listGroup.AppendChild($groupItem);
        #Get listgroupitem
        $groupItem = $listGroupItem.Clone()
        #Get Flag
        $badgeColor = $FindingObject.statusCode | Get-BadgeFromStatusCode
        $spanProperties = @{
            Name = "span";
            ClassName = ("badge badge-xl {0} mt-2" -f $badgeColor);
            Text = $FindingObject.statusCode.ToLower();
            CreateTextNode = $True;
            Template = $TemplateObject;
        }
        #Create element
        $spanObj = New-HtmlTag @spanProperties
        #Add to group item
        [void]$groupItem.AppendChild($spanObj);
        #Add to list group
        [void]$_listGroup.AppendChild($groupItem);
        #Create div and append list group
        $divProperties = @{
            Name = 'div';
            ClassName = 'col-md-1';
            AppendObject = $_listGroup;
            Template = $TemplateObject;
        }
        #Create element
        $divStatus = New-HtmlTag @divProperties
        #Add to column array
        [void]$allCols.Add($divStatus);
        #Add Compliance
        #Get listgroup
        $_listGroup = $listGroup.Clone()
        #Get listgroupitem
        $groupItem = $listGroupItem.Clone()
        #Get Severity span tag
        $complianceSpan = $spanLabel.Clone()
        #Add text
        [void]$complianceSpan.AppendChild($TemplateObject.CreateTextNode("Compliance"))
        #Add to list group item
        [void]$groupItem.AppendChild($complianceSpan);
        #Add to list group
        [void]$_listGroup.AppendChild($groupItem);
        #Get listgroupitem
        $groupItem = $listGroupItem.Clone()
        #Get compliance data
        $complianceData = $FindingObject.compliance | Convert-ComplianceToSpanTag -Template $TemplateObject
        If($null -ne $complianceData){
            ForEach($spanObj in @($complianceData)){
                #Add to group item
                [void]$groupItem.AppendChild($spanObj);
            }
        }
        #Add to list group
        [void]$_listGroup.AppendChild($groupItem);
        #Create div and append list group
        $divProperties = @{
            Name = 'div';
            ClassName = 'col-md-4';
            AppendObject = $_listGroup;
            Template = $TemplateObject;
        }
        #Create element
        $divCompliance = New-HtmlTag @divProperties
        #Add to column array
        [void]$allCols.Add($divCompliance);
        #Add resources count
        If($FindingObject.statusCode.ToLower() -eq "fail"){
            #Get listgroup
            $_listGroup = $listGroup.Clone()
            #Get listgroupitem
            $groupItem = $listGroupItem.Clone()
            #Get Severity span tag
            $violationSpan = $spanLabel.Clone()
            #Add text
            [void]$violationSpan.AppendChild($TemplateObject.CreateTextNode("Rule Violations"))
            #Add to list group item
            [void]$groupItem.AppendChild($violationSpan);
            #Add to list group
            [void]$_listGroup.AppendChild($groupItem);
            #Get listgroupitem
            $groupItem = $listGroupItem.Clone()
            $hProperties = @{
                Name = "h4";
                ClassName = "mt-2";
                Text = $FindingObject.affectedResourcesCount();
                CreateTextNode = $True;
                Template = $TemplateObject;
            }
            #Create element
            $H4Obj = New-HtmlTag @hProperties
            #Add to group item
            [void]$groupItem.AppendChild($H4Obj);
            #Add to list group
            [void]$_listGroup.AppendChild($groupItem);
            #Create div and append list group
            $divProperties = @{
                Name = 'div';
                ClassName = 'col-md-1';
                AppendObject = $_listGroup;
                Template = $TemplateObject;
            }
            #Create element
            $divViolation = New-HtmlTag @divProperties
            #Add to column array
            [void]$allCols.Add($divViolation);
        }
        #Add columns to main row
        If($allCols.Count -gt 0){
            ForEach($col in $allCols){
                [void]$mainRow.AppendChild($col);
            }
            #Add main row to card content
            [void]$cardContent.AppendChild($mainRow)
        }
        return $cardContent
    }
    End{
        #Nothing to do here
    }
}

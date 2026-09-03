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

Function Convert-ComplianceToSpanTag{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-ComplianceToSpanTag
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True,  HelpMessage= "Compliance objects")]
        [Object]$Compliance,

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
    }
    Process{
        Foreach($complianceObj in @($PSBoundParameters['Compliance']).Where({$null -ne $_})){
            #check if PsObject
            $isPsCustomObject = ([System.Management.Automation.PSCustomObject]).IsAssignableFrom($complianceObj.GetType())
            #check if PsObject
            $isPsObject = ([System.Management.Automation.PSObject]).IsAssignableFrom($complianceObj.GetType())
            If($isPsObject -or $isPsCustomObject){
                #Get Name, version and reference
                $Name = $complianceObj | Select-Object -ExpandProperty name -ErrorAction Ignore
                $Version = $complianceObj | Select-Object -ExpandProperty version -ErrorAction Ignore
                $Reference = $complianceObj | Select-Object -ExpandProperty reference -ErrorAction Ignore
                If($null -ne $Name){
                    #Set span object
                    $spanProperties = @{
                        Name = 'span';
                        ClassName = 'badge bg-primary badge-xl mt-2';
                        Text = $Name;
                        CreateTextNode = $True;
                        Template = $TemplateObject;
                    }
                    #Create element
                    New-HtmlTag @spanProperties
                }
                If($null -ne $Version){
                    #Set span object
                    $spanProperties = @{
                        Name = 'span';
                        ClassName = 'badge bg-info badge-xl mt-2';
                        Text = $Version;
                        CreateTextNode = $True;
                        Template = $TemplateObject;
                    }
                    #Create element
                    New-HtmlTag @spanProperties
                }
                If($null -ne $Reference){
                    #Set span object
                    $spanProperties = @{
                        Name = 'span';
                        ClassName = 'badge bg-success badge-xl mt-2';
                        Text = $Reference;
                        CreateTextNode = $True;
                        Template = $TemplateObject;
                    }
                    #Create element
                    New-HtmlTag @spanProperties
                }
            }
            ElseIf ($complianceObj -is [string] -and $complianceObj.Length -gt 0){
                #Set span object
                $spanProperties = @{
                    Name = 'span';
                    ClassName = 'badge bg-primary badge-xl mt-2';
                    Text = $complianceObj;
                    CreateTextNode = $True;
                    Template = $TemplateObject;
                }
                #Create element
                New-HtmlTag @spanProperties
            }
        }
    }
    End{
        #Nothing to do here
    }
}

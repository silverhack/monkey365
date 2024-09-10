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

Function New-GoToLink{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-GoToLink
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param (
            [Parameter(Mandatory=$true, HelpMessage="Issue")]
            [Object]$issue,

            [Parameter(Mandatory=$true, HelpMessage="Instance")]
            [string]$instance,

            [Parameter(Mandatory=$true, HelpMessage="Issue Id")]
            [string]$idx
    )
    Begin{
        $div = [xml] '<div class="row"></div>'
        $raw_data = $id_resource = $portal_url = $tenant_id = $link = $a_link = $null
        try{
            if($null -ne $issue.psobject.Properties.Item('affectedResources')){
                if(@($issue.affectedResources).Count -gt 1){
                    $raw_data = $issue.affectedResources.Item($idx)
                }
                else{
                    $raw_data = $issue.affectedResources
                }
            }
            if($null -ne $raw_data -and $instance -eq "azure"){
                #Try to get ID for resource
                if($null -ne $raw_data.psobject.Properties.Item('id')){
                    $id_resource = $raw_data.id
                }
                #Get Azure portal url
                $portal_url = $environment.Item('AzurePortal')
                #Get Tenant Id
                if($null -ne $tenant -and $null -ne $tenant.psobject.Properties.Item('tenantId')){
                    $tenant_id = $tenant.TenantId
                }
                #Construct URL
                if($null -ne $portal_url -and $null -ne $tenant_id -and $null -ne $id_resource){
                    $link = ("{0}//#@{1}/resource/{2}" -f $portal_url,$tenant_id,$id_resource)
                }
            }
            if($null -eq $link -and $null -ne $issue.output.html.actions.psobject.Properties.Item('directLink')){
                $link = $issue.output.html.actions.directLink
            }
        }
        catch{
            $e = $_.Exception
            $line = $_.InvocationInfo.ScriptLineNumber
            #$msg = $e.Message
            Write-Warning ($script:messages.unableToCreateGoToLink)
            #verbose
            Write-Debug $_.Exception
            Write-Debug ("caught exception: {0} at {1}" -f $e,$line)
        }
    }
    Process{
        if($null -ne $link){
            #Create a element
            $a_link = $div.CreateNode([System.Xml.XmlNodeType]::Element, $div.Prefix, 'a', $div.NamespaceURI);
            [void]$a_link.SetAttribute('class',"btn btn-success me-2")
            [void]$a_link.SetAttribute('href',$link)
            [void]$a_link.SetAttribute('target','_blank')
            #Create i element
            $params = @{
                tagname = "i";
                classname = "bi bi-cloud-haze";
                empty = $True;
                own_template = $div;
            }
            $i_element = New-HtmlTag @params
            #append i to a
            [void]$a_link.AppendChild($i_element)
        }
    }
    End{
        #return a element
        return $a_link
    }
}

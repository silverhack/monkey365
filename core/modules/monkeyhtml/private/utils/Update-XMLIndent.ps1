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

Function Update-XMLIndent{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-XMLIndent
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [Alias("IndentXML")]
    param
    (
        [xml]$Content,
        [int]$Indent
    )

    # String Writer and XML Writer objects to write XML to string
    $StringWriter = New-Object System.IO.StringWriter
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter

    # Default = None, change Formatting to Indented
    $xmlWriter.Formatting = "indented"

    # Gets or sets how many IndentChars to write for each level in
    # the hierarchy when Formatting is set to Formatting.Indented
    $xmlWriter.Indentation = $Indent

    $Content.WriteContentTo($XmlWriter)
    $XmlWriter.Flush();$StringWriter.Flush()
    $StringWriter.ToString()
}

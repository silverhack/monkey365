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

Function New-EmptyMetadataObject {
<#
        .SYNOPSIS
		Create a new empty metadata object

        .DESCRIPTION
		Create a new empty metadata object

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-EmptyMetadataObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	Param ()
    Process{
        Try{
            $monkey_metadata = @{
			    Id = ("emptyCollector{0}" -f (Get-Random -Minimum 10 -Maximum 1000));
			    Provider = $null;
			    Resource = $null;
			    ResourceType = $null;
			    resourceName = $null;
			    collectorName = $null;
			    ApiType = $null;
			    description = "Empty metadata collector";
			    Group = @();
			    Tags = @();
			    references = @(
				    "https://silverhack.github.io/monkey365/"
			    );
			    ruleSuffixes = @();
			    dependsOn = @();
			    enabled = $true;
			    supportClientCredential = $false;
		    }
            return $monkey_metadata
        }
        catch{
            Write-Verbose $_.Exception.Message
        }
    }
}

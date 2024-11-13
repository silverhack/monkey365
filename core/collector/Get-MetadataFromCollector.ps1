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

Function Get-MetadataFromCollector{
    <#
        .SYNOPSIS
        Get metadata from installed collectors
        .DESCRIPTION
        Get metadata from installed collectors
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MetadataFromCollector
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraID","Microsoft365")]
        [String]$Provider,

        [Parameter(Mandatory=$false, HelpMessage="Cloud resource")]
        [String[]]$Service
    )
    Begin{
        $AstCollectors = $null;
        $collectors = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        If($null -ne (Get-Variable -Name O365Object -ErrorAction Ignore)){
            $localPath = $O365Object.Localpath;
        }
        ElseIf($null -ne (Get-Variable -Name ScriptPath -ErrorAction Ignore)){
            $localPath = $ScriptPath;
        }
        Else{
            $localPath = $MyInvocation.MyCommand.Path
        }
        If($null -eq $localPath){
            break
        }
        $_path = ("{0}{1}collectors{2}{3}" -f $localPath,[System.IO.Path]::DirectorySeparatorChar,[System.IO.Path]::DirectorySeparatorChar,$Provider)
    }
    Process{
        If([System.IO.Directory]::Exists($_path)){
            $allDirs = [System.Collections.Generic.List[System.String]]::new()
            If($PSBoundParameters.ContainsKey('Service') -and $PSBoundParameters['Service']){
                $directories = @($_path).GetEnumerator()| ForEach-Object {Get-MonkeyDirectory -Path $_ -Pattern $Service -Recurse -First}
                Foreach($dir in @($directories)){
                    [void]$allDirs.Add($dir);
                }
            }
            Else{
                [void]$allDirs.Add($_path);
            }
            If($allDirs.Count -gt 0){
                Try{
                    $allCollectors = $allDirs.GetEnumerator() | ForEach-Object {[System.IO.Directory]::EnumerateFiles($_,"*.ps1",[System.IO.SearchOption]::AllDirectories)}
                    $AstCollectors = Get-AstFunction $allCollectors
                }
                Catch{
                    Write-Warning $_.Exception.Message
                }
            }
        }
        Else{
            Write-Warning ("Directory {0} was not found" -f $_path)
        }
    }
    End{
        If($null -ne $AstCollectors){
            Foreach($collector in $AstCollectors){
                #Get internal Var
                $monkey_var = $collector.Body.BeginBlock.Statements | Where-Object {($null -ne $_.Psobject.Properties.Item('Left')) -and $_.Left.VariablePath.UserPath -eq 'monkey_metadata'}
                if($monkey_var -and [bool]($monkey_var.Right.Expression.StaticType.ImplementedInterfaces.Where({$_.FullName -eq "System.Collections.IDictionary"}))){
                    Try{
                        #Get Safe value
                        $new_dict = [ordered]@{}
                        foreach ($entry in $monkey_var.Right.Expression.KeyValuePairs.GetEnumerator()){
                            $new_dict.Add($entry.Item1, $entry.Item2.SafeGetValue())
                        }
                        #Add file properties
                        $new_dict.Add('File',[System.IO.fileinfo]::new($collector.Extent.File))
                        #Create PsObject
                        $obj = New-Object -TypeName PSCustomObject -Property $new_dict
                        #Add to array
                        [void]$collectors.Add($obj)
                    }
                    Catch{
                        Write-Error $_
                    }
                }
            }
        }
        #return collectors
        $collectors
    }
}
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
        [String[]]$Service,

        [Parameter(Mandatory=$false, HelpMessage="Api Type")]
        [String[]]$ApiType
    )
    Begin{
        $AstCollectors = $null;
        $collectors = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        $selectedCollectors = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
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
            Try{
                $allCollectors = [System.IO.Directory]::EnumerateFiles($_path,"*.ps1",[System.IO.SearchOption]::AllDirectories).Where({$_.EndsWith('.ps1')})
                $astCollectors = Get-AstFunction $allCollectors
                If($null -ne $astCollectors){
                    Foreach($collector in @($astCollectors)){
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
                #Filter data
                If($collectors.Count -gt 0){
                    If($PSBoundParameters.ContainsKey('Service') -and $PSBoundParameters['Service']){
                        Foreach($srv in $PSBoundParameters['Service'].GetEnumerator()){
                            $_collectors = $collectors.Where({$srv -in $_.Group})
                            foreach($collector in @($_collectors)){
                                If($selectedCollectors.Where({$_.Id -eq $collector.Id}).Count -eq 0){
                                    [void]$selectedCollectors.Add($collector);
                                }
                            }
                        }
                    }
                    ElseIf($PSBoundParameters.ContainsKey('ApiType') -and $PSBoundParameters['ApiType']){
                        Foreach($_api in $PSBoundParameters['ApiType'].GetEnumerator()){
                            $_collectors = $collectors.Where({$_.ApiType.ToLower() -eq $_api.ToLower()})
                            foreach($collector in @($_collectors)){
                                If($selectedCollectors.Where({$_.Id -eq $collector.Id}).Count -eq 0){
                                    [void]$selectedCollectors.Add($collector);
                                }
                            }
                        }
                    }
                    Else{
                        Foreach($collector in $collectors){
                            [void]$selectedCollectors.Add($collector);
                        }
                    }
                    #return collectors
                    $selectedCollectors
                }
                Else{
                    Write-Warning "Collectors were not found"
                }
            }
            Catch{
                Write-Warning $_.Exception.Message
            }
        }
        Else{
            Write-Warning ("Directory {0} was not found" -f $_path)
        }
    }
    End{
        #Nothing to do here
    }
}

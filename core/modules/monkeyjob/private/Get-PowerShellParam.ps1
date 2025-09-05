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

Function Get-PowerShellParam{
    <#
        .SYNOPSIS
        Get PowerShell params

        .DESCRIPTION
        Get PowerShell params

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PowerShellParam
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    Param (
        [Parameter(Mandatory=$True,position=0,ParameterSetName='ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$True,Position = 0, ParameterSetName = 'Command')]
        [String]$Command,

        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = 'FilePath', HelpMessage = 'PowerShell Script file')]
        [ValidateScript(
            {
            if( -Not ($_ | Test-Path) ){
                throw ("The PowerShell file does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The argument must be a ps1 file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.ps1)"){
                throw "The script specified argument must be of type ps1"
            }
            return $true
        })]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory=$false, HelpMessage="arguments")]
        [Object]$Arguments,

        [Parameter(Mandatory=$false)]
        $InputObject,

        [Parameter(Mandatory=$False, HelpMessage="RunspacePool")]
        [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool
    )
    Try{
        If($PSCmdlet.ParameterSetName -eq 'ScriptBlock'){
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Set-ScriptBlock")
            $newPsboundParams = [ordered]@{}
            if($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                foreach($p in $param.GetEnumerator()){
                    if($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
            }
            $_ScriptBlock = Set-ScriptBlock @newPsboundParams
            If($_ScriptBlock){
                $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-PowerShellObject")
                $newPsboundParams = [ordered]@{}
                If($null -ne $MetaData){
                    $param = $MetaData.Parameters.Keys
                    foreach($p in $param.GetEnumerator()){
                        If($p -eq "ScriptBlock"){$newPsboundParams.Add($p,$_ScriptBlock)}
                        ElseIf($PSBoundParameters.ContainsKey($p)){
                            $newPsboundParams.Add($p,$PSBoundParameters[$p])
                        }
                    }
                }
                return $newPsboundParams
            }
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'Command'){
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-PowerShellObject")
            $newPsboundParams = [ordered]@{}
            If($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                foreach($p in $param.GetEnumerator()){
                    If($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
            }
            return $newPsboundParams
        }
        Else{
            $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Set-ScriptBlock")
            $newPsboundParams = [ordered]@{}
            If($null -ne $MetaData){
                $param = $MetaData.Parameters.Keys
                foreach($p in $param.GetEnumerator()){
                    If($p -eq "ScriptBlock"){continue}
                    If($PSBoundParameters.ContainsKey($p)){
                        $newPsboundParams.Add($p,$PSBoundParameters[$p])
                    }
                }
            }
            $_ScriptBlock = Set-ScriptBlock -ScriptBlock {$File.FullName} @PSBoundParameters
            If($_ScriptBlock){
                $MetaData = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-PowerShellObject")
                $newPsboundParams = [ordered]@{}
                If($null -ne $MetaData){
                    $param = $MetaData.Parameters.Keys
                    foreach($p in $param.GetEnumerator()){
                        If($p -eq "ScriptBlock"){$newPsboundParams.Add($p,$_ScriptBlock)}
                        ElseIf($PSBoundParameters.ContainsKey($p)){
                            $newPsboundParams.Add($p,$PSBoundParameters[$p])
                        }
                    }
                }
                return $newPsboundParams
            }
        }
    }
    Catch{
        Write-Error $_.Exception
    }
}

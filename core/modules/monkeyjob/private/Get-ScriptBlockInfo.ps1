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

Function Get-ScriptBlockInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ScriptBlockInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param (
            [Parameter(Mandatory=$True,position=0,ParameterSetName='ScriptBlock')]
            [System.Management.Automation.ScriptBlock]$ScriptBlock
    )
    try{
        $scriptToImport = $null
        $rawCommand = Get-CommandToExecute -ScriptBlock $ScriptBlock -First
        if($rawCommand){
            $command = $rawCommand.Value
            $commandName = $command
        }
        else{
            $command = $null
            $commandName = $null
        }
        $commandInfo = Get-CommandInfo -ScriptBlock $ScriptBlock
        if($null -ne $rawCommand){
            $commandInfo = Get-Command -Name $rawCommand.Value
        }
        else{
            $commandInfo = $null
        }
        if($null -eq $commandInfo){
            if($null -ne $rawCommand){
                Write-Warning -Message ("Unable to get command information from {0}" -f $rawCommand.Value)
            }
            else{
                Write-Warning -Message ("Unable to get command information")
            }
            return
        }
        $commandType = $commandInfo.CommandType
        $MetaData = Get-CommandMetadata -CommandInfo $commandInfo
        $NewScriptBlock = Get-NewScriptBlock -CommandInfo $CommandInfo
        if($null -ne $NewScriptBlock -and $null -ne $NewScriptBlock.ast.ParamBlock){
            $Paramblock = $NewScriptBlock.ast.ParamBlock.ToString()
        }
        else{
            $Paramblock = $null
            $supportValueFromPipeline = $null
            $dummyfnc = $null
            $tempScriptBlock = $null
            $ScriptBlockWithoutPipeline = $null
        }
        if($null -ne $NewScriptBlock){
            if($NewScriptBlock.File){
                $commandName = $NewScriptBlock.Ast.Parent.Name
                $scriptToImport = $NewScriptBlock
            }
            elseif($null -ne $commandType -and $commandType -eq 'ExternalScript' -and $null -ne $MetaData -and $MetaData.Name){
                $scriptToImport = [ScriptBlock]::Create($(Get-Content $MetaData.Name | Out-String))
                $commandName = $MetaData.Name
            }
            else{
                $commandName = $command
                $scriptToImport = $null
            }
            $supportValueFromPipeline = Get-ValueFromPipeline -ScriptBlock $NewScriptBlock
            #Create dummy function to get parameters
            if($null -ne $Paramblock){
                $dummyfnc = $Paramblock
                $dummyfnc += "`n `$returnHashtable = `$PSBoundParameters `n"
                $dummyfnc += "return `$returnHashtable"
            }
            else{
                $dummyfnc = $null
            }
            #Create temp scriptBlock
            $txtScriptBlock = ($ScriptBlock.ToString()).Replace($command,"MonkeyDummyFunction")
            $txtScriptBlock = $txtScriptBlock.Replace('$_', '$inputobject')
            $ScriptBlockWithoutPipeline = [Scriptblock]::Create($txtScriptBlock)
            if($supportValueFromPipeline){
                $txtScriptBlock = "`$inputobject | " + $txtScriptBlock
            }
            $tempScriptBlock = [Scriptblock]::Create($txtScriptBlock)
        }
        $scriptBlockInfo = [PSCustomObject] @{
            rawCommand = $rawCommand
            passedScriptBlock = $ScriptBlock
            command = $command
            commandInfo = $commandInfo
            commandType = $commandType
            commandName = $commandName
            scriptBlock = $NewScriptBlock
            scriptToImport = $scriptToImport
            supportValueFromPipeline = $supportValueFromPipeline
            params = $Paramblock
            dummyFunction = $dummyfnc
            dummyFunctionName = "MonkeyDummyFunction"
            tempScriptBlock = $tempScriptBlock
            tempScriptBlockWithoutPipeline = $ScriptBlockWithoutPipeline
        }
        return $scriptBlockInfo
    }
    catch{
        Write-Error $_
    }
}

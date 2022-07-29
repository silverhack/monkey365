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

Function Get-ParamsUsed{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-ParamsUsed
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$True,position=0,ParameterSetName='Job')]
        [Object]$Job
    )
    try{
        $requiredFields = @("tempScriptBlock","tempScriptBlockWithoutPipeline", "dummyFunctionName")
        $matched = $requiredFields.GetEnumerator() | Where-Object {$Job.psobject.Properties.Item($_)}
        if($matched.Count -eq 3){
            $params = @{
                ScriptBlock = $Job.tempScriptBlock
                ErrorAction = "SilentlyContinue"
                ErrorVariable = 'MonkeyError'
            }
            $paramused = Invoke-Command @params 2>$null
            if ($MonkeyError.Count -gt 0){
                if($MonkeyError[-1] -is [System.Management.Automation.ErrorRecord]){
                    if($null -ne $MonkeyError[-1].Exception.Psobject.Properties.Item('ErrorId') -and $MonkeyError[-1].Exception.ErrorId -eq 'InputObjectNotBound'){
                        Write-Verbose ($script:messages.PipelineNotSupported -f $Job.command.ToString())
                        #Retry without the Pipeline object
                        $params.ScriptBlock = $Job.tempScriptBlockWithoutPipeline
                        $paramused = Invoke-Command @params 2>$null
                        if ($MonkeyError.Count -gt 0){
                            Write-Error ($script:messages.UnableToExecuteCommand -f $Job.command.ToString())
                            Write-Error $MonkeyError
                        }
                    }
                    else{
                        #Unknown error
                        Write-Error "Unknown ErrorId"
                        Write-Error $MonkeyError[-1]
                    }
                }
                elseif($MonkeyError[-1] -is [exception]){
                    if($null -ne $MonkeyError[-1].Exception.Psobject.Properties.Item('ErrorId') -and $MonkeyError[-1].Exception.ErrorId -eq 'InputObjectNotBound'){
                        Write-Verbose ($script:messages.PipelineNotSupported -f $Job.command.ToString())
                        #Retry without the Pipeline object
                        $params.ScriptBlock = $Job.tempScriptBlockWithoutPipeline
                        $paramused = Invoke-Command @params 2>$null
                        if ($MonkeyError.Count -gt 0){
                            Write-Error ($script:messages.UnableToExecuteCommand -f $Job.command.ToString())
                            Write-Error $MonkeyError
                        }
                    }
                    else{
                        #Unknown error
                        Write-Error "Unknown ErrorId"
                        Write-Error $MonkeyError[-1]
                    }
                }
                else{
                    #Unknown error
                    Write-Error "Unrecognized exception"
                    Write-Error $MonkeyError[-1]
                }
            }
            if($paramused){
                return $paramused
            }
        }
        else{
            Write-Warning $script:messages.UnknownObject
        }
    }
    catch{
        Write-Error $_
    }
}

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

Function Update-PsObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-PsObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

  [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="Medium")]
  [cmdletbinding()]
  param()
  Begin{
      $Types = @(
          'System.Management.Automation.PSCustomObject',
          'System.Management.Automation.PSObject',
          'Deserialized.System.Management.Automation.PSCustomObject',
          'Deserialized.System.Management.Automation.PSObject',
          'Deserialized.System.Object'
      )
      if (-not $PSBoundParameters.ContainsKey('Confirm')) {
          $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
      }
      if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
          $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
      }
  }
  Process{
      if ($PSCmdlet.ShouldProcess('PsObjects','Add GetPropertyByPath method')){
          foreach($t in $Types){
              Update-TypeData -TypeName $t -MemberType ScriptMethod -MemberName GetPropertyByPath -Value {
                  param($propPath)
                  Set-StrictMode -Version 1
                  $obj = $this
                  foreach ($prop in $propPath -split '\.') {
                    # See if the property spec has an index (e.g., 'foo[3]')
                    if ($prop -match '(.+?)\[(.+?)\]$') {
                        if($null -ne $obj.($Matches.1)){
                            #Check if PsMethod
                            if(($obj.($Matches.1)).Gettype().FullName -eq 'System.Management.Automation.PSMethod'){
                                $obj = $obj | Select-Object -ExpandProperty ($Matches.1) -ErrorAction Ignore
                                if($null -ne $obj){
                                    $obj = $obj[$Matches.2]
                                }
                            }
                            else{
                                $obj = $obj.($Matches.1)[$Matches.2]
                            }
                        }
                    }
                    else{
                        if($null -ne ($obj.$prop)){
                            if(($obj.$prop).Gettype().FullName -eq 'System.Management.Automation.PSMethod'){
                                #Check if Invoke is present
                                if($null -ne (Get-Member -inputobject $obj.$prop -name "Invoke" -Membertype Method)){
                                    $obj = $obj | Select-Object -ExpandProperty $prop -ErrorAction Ignore
                                }
                            }
                            else{
                                $obj = $obj.$prop;
                            }
                        }
                        else{
                            $obj = $null;
                        }
                    }
                  }
                  # Output: If the value is an array, output it as a single object
                  if ($null -ne $obj -and @($obj).Count -gt 1) {
                    , $obj
                  }
                  else {
                    $obj
                  }
              } -Force -ErrorAction SilentlyContinue
          }
      }
  }
  End{
      #Nothing to do here
  }
}

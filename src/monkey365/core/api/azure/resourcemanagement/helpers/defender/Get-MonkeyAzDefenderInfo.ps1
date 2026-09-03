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

Function Get-MonkeyAzDefenderInfo {
    <#
        .SYNOPSIS
		Get information about Azure Defender

        .DESCRIPTION
		Get information about Azure Defender

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzDefenderInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param ()
    Begin{
        #set null
        $pricingConfig = $provisioningConfig = $null
        #Get internal config
		$config = $O365Object.internal_config.resourceManager;
        If($null -ne $config){
            $pricingConfig = $config.Where({$_.Name -eq "azurePricings"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
            $provisioningConfig = $config.Where({$_.Name -eq "autoProvisioning"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
            $securityContactConfig = $config.Where({$_.Name -eq "azureContacts"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
            $policyConfig = $config.Where({$_.Name -eq "policyAssignments"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
            $serverVulnerabilityConfig = $config.Where({$_.Name -eq "serverVulnerabilityAssessment"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
            $defenderConfig = $config.Where({$_.Name -eq "defenderSetting"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
            $assessmentConfig = $config.Where({$_.Name -eq "azureAssessments"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
            $subAssessmentConfig = $config.Where({$_.Name -eq "azureSubAssessments"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
            $automationConfig = $config.Where({$_.Name -eq "defenderAutomations"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        }
        #Create defender Object
        $defenderObject = New-MonkeyDefenderObject
    }
    Process{
        Try{
            If($null -ne $defenderObject -and $null -ne $config){
                #Get pricing
                $pricingId = ("{0}/providers/{1}/pricings" -f $O365Object.current_subscription.id, $pricingConfig.provider)
                $p = @{
			        Id = $pricingId;
                    ApiVersion = $pricingConfig.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.pricing = Get-MonkeyAzObjectById @p
                #Get defender settings
                $settingsId = ("{0}/providers/{1}/settings" -f $O365Object.current_subscription.id, $defenderConfig.provider)
                $p = @{
			        Id = $settingsId;
                    ApiVersion = $defenderConfig.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.settings = Get-MonkeyAzObjectById @p
                #Get defender assessments
                $assessmentId = ("{0}/providers/{1}/assessments" -f $O365Object.current_subscription.id, $assessmentConfig.provider)
                $p = @{
			        Id = $assessmentId;
                    ApiVersion = $assessmentConfig.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.assessments = Get-MonkeyAzObjectById @p
                #Get defender subAssessments
                $assessmentId = ("{0}/providers/{1}/subAssessments" -f $O365Object.current_subscription.id, $subAssessmentConfig.provider)
                $p = @{
			        Id = $assessmentId;
                    ApiVersion = $subAssessmentConfig.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.subAssessments = Get-MonkeyAzObjectById @p
                #Get defender export configuration
                $automationId = ("{0}/providers/{1}/automations" -f $O365Object.current_subscription.id, $automationConfig.provider)
                $p = @{
			        Id = $automationId;
                    ApiVersion = $automationConfig.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.continuousExport = Get-MonkeyAzObjectById @p
                #Get auto provisioning
                $provisioningId = ("{0}/providers/{1}/autoProvisioningSettings" -f $O365Object.current_subscription.id, $provisioningConfig.provider)
                $p = @{
			        Id = $provisioningId;
                    ApiVersion = $provisioningConfig.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.autoProvisioningSettings = Get-MonkeyAzObjectById @p
                #Get security contacts
                $securityContactId = ("{0}/providers/{1}/securityContacts" -f $O365Object.current_subscription.id, $securityContactConfig.provider)
                $p = @{
			        Id = $securityContactId;
                    ApiVersion = $securityContactConfig.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.securityContacts = Get-MonkeyAzObjectById @p
                #Get policy assignments
                $policyId = ("{0}/providers/{1}/policyAssignments" -f $O365Object.current_subscription.id, $policyConfig.provider)
                $p = @{
			        Id = $policyId;
                    ApiVersion = $policyConfig.api_version;
                    Filter = "atScope()";
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.policyAssignments = Get-MonkeyAzObjectById @p
                #Get server vulnerability assessments setting
                $serverVulnerabilityId = ("{0}/providers/{1}/serverVulnerabilityAssessmentsSettings/azureServersSetting" -f $O365Object.current_subscription.id, $serverVulnerabilityConfig.provider)
                $p = @{
			        Id = $serverVulnerabilityId;
                    ApiVersion = $serverVulnerabilityConfig.api_version;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    InformationAction = $O365Object.InformationAction;
		        }
		        $defenderObject.serverVulnerabilityAssessments = Get-MonkeyAzObjectById @p
                return $defenderObject
            }
        }
        Catch{
            Write-Verbose $_
        }
    }
}

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

Function Get-MonkeyCSOMProperty{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMProperty
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $false, HelpMessage="Client Object")]
        [object]$ClientObject,

        [Parameter(Mandatory= $false, HelpMessage="properties")]
        [string[]]$Properties,

        [parameter(Mandatory=$false, HelpMessage="Endpoint")]
        [String]$Endpoint
    )
    Begin{
        #Check if clientObject has the property
        foreach($prop in $Properties){
            if($null -ne $ClientObject.Psobject.Properties.Item($prop)){
                #Remove property
                $ClientObject.PSObject.Properties.Remove($prop)
            }
        }
        #Set False
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        if($Endpoint){
            [uri]$sps_uri = $Endpoint
        }
        else{
            [uri]$sps_uri = $Authentication.resource
        }
        $select_all_properties = @(
            'Folder','Lists',
            'RoleDefinitionBindings',
            'Member','ParentList',
            'RoleAssignments','File',
            'RootFolder','Webs'
        )
        $raw_data = $out_obj = $null
        [xml]$_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><ObjectPaths><Identity Id="59" Name="" /></ObjectPaths></Request>'
        #Set actions tag
        $actions_tag = $_data.CreateElement("Actions",$_data.Request.xmlns)
        $actions_tag.RemoveAttribute("xmlns");
        #Set root Query tag
        $root_query_tag = $_data.CreateElement("Query",$_data.Request.xmlns)
        #Add attributes
        [void]$root_query_tag.SetAttribute('Id','63')
        [void]$root_query_tag.SetAttribute('ObjectPathId','59')
        $root_query_tag.RemoveAttribute("xmlns");
        #Set SubQuery tag
        $sub_query_tag = $_data.CreateElement("Query",$_data.Request.xmlns)
        #Add attributes
        [void]$sub_query_tag.SetAttribute('SelectAllProperties','false')
        $sub_query_tag.RemoveAttribute("xmlns");
        #Set Properties tag
        $root_properties_tag = $_data.CreateElement("Properties",$_data.Request.xmlns)
        $nested_ = @()
        $all_properties = @()
        foreach($property in $ClientObject.psobject.Properties){
            if($null -ne $property.Value -and $property.Value -is [PSCustomObject]){
                #Set property name
                $xml_nested_prop = $_data.CreateElement("Property",$_data.Request.xmlns)
                #Add attributes
                [void]$xml_nested_prop.SetAttribute('Name',$property.Name)
                $xml_nested_prop.RemoveAttribute("xmlns");
                #Set NestedQuery xml
                $xml_nestedQuery = $_data.CreateElement("Query",$_data.Request.xmlns)
                [void]$xml_nestedQuery.SetAttribute('SelectAllProperties','true')
                $xml_nestedQuery.RemoveAttribute("xmlns");
                $array_properties = $_data.CreateElement("Properties",$_data.Request.xmlns)
                [void]$xml_nestedQuery.AppendChild($array_properties)
                #Create nested properties
                $xml_ChildQuery = $_data.CreateElement("ChildItemQuery",$_data.Request.xmlns)
                [void]$xml_ChildQuery.SetAttribute('SelectAllProperties','false')
                $xml_ChildQuery.RemoveAttribute("xmlns");
                $array_properties = $_data.CreateElement("Properties",$_data.Request.xmlns)
                if($null -ne ($property.value.PSObject.Properties.Item('_Child_Items_'))){
                    foreach($nested_element in $property.value._Child_Items_.GetEnumerator()){
                        foreach($nested_property in $nested_element.psobject.Properties){
                            if($nested_property.Name -eq "_ObjectType_" -or $nested_property.Name -eq "_ObjectIdentity_" -or $nested_property.Name -eq "_ObjectVersion_"){
                                continue
                            }
                            else{
                                $xml_prop = $_data.CreateElement("Property",$_data.Request.xmlns)
                                #Add attributes
                                [void]$xml_prop.SetAttribute('Name',$nested_property.Name)
                                [void]$xml_prop.SetAttribute('ScalarProperty','true')
                                $xml_prop.RemoveAttribute("xmlns");
                                [void]$array_properties.AppendChild($xml_prop)
                            }
                        }
                        #Add to ChildQuery
                        [void]$xml_ChildQuery.AppendChild($array_properties)
                    }
                    #Check if childnodes are empty
                    if($xml_ChildQuery.HasChildNodes -eq $false){
                        #Add empty property
                        $array_properties = $_data.CreateElement("Properties",$_data.Request.xmlns)
                        #Add to ChildQuery
                        [void]$xml_ChildQuery.AppendChild($array_properties)
                    }
                }
                else{
                    #Empty collection
                    $array_properties = $_data.CreateElement("Properties",$_data.Request.xmlns)
                    #Add to ChildQuery
                    [void]$xml_ChildQuery.AppendChild($array_properties)
                }
                #add
                [void]$xml_nested_prop.AppendChild($xml_nestedQuery)
                [void]$xml_nested_prop.AppendChild($xml_ChildQuery)
                $nested_ += $xml_nested_prop
            }
            elseif($property.Name.Contains("$")){
                $xml_prop = $_data.CreateElement("Property",$_data.Request.xmlns)
                #Add attributes
                [void]$xml_prop.SetAttribute('Name',$property.Name.Split('$')[0])
                [void]$xml_prop.SetAttribute('ScalarProperty','true')
                $xml_prop.RemoveAttribute("xmlns");
                $all_properties+=$xml_prop
                #[void]$_data.Request.Actions.Query.Query.Properties.AppendChild($xml_prop)
            }
            elseif($property.Name -eq "_ObjectType_" -or $property.Name -eq "_ObjectIdentity_" -or $property.Name -eq "_ObjectVersion_"){
                continue
            }
            elseif($property.Name.Contains("raw")){
                continue
            }
            else{
                $xml_prop = $_data.CreateElement("Property",$_data.Request.xmlns)
                #Add attributes
                [void]$xml_prop.SetAttribute('Name',$property.Name)
                [void]$xml_prop.SetAttribute('ScalarProperty','true')
                $xml_prop.RemoveAttribute("xmlns");
                $all_properties+=$xml_prop
                #[void]$_data.Request.Actions.Query.Query.Properties.AppendChild($xml_prop)
            }
        }
        #Add new properties
        foreach($property in $Properties){
            $xml_prop = $_data.CreateElement("Property",$_data.Request.xmlns)
            [void]$xml_prop.SetAttribute('Name',$property)
            #Add attributes
            if($property -in $select_all_properties){
                [void]$xml_prop.SetAttribute('SelectAll','true')
            }
            else{
                [void]$xml_prop.SetAttribute('ScalarProperty','true')
            }
            $xml_prop.RemoveAttribute("xmlns");
            $all_properties+=$xml_prop
            #[void]$_data.Request.Actions.Query.Query.Properties.AppendChild($xml_prop)
        }
        if($all_properties){
            foreach($prop in $all_properties){
                #Add to properties collection
                [void]$root_properties_tag.AppendChild($prop)
            }
            #Add to Subquery
            [void]$sub_query_tag.AppendChild($root_properties_tag)
            #Add to root query
            [void]$root_query_tag.AppendChild($sub_query_tag)
            #Add to actions
            [void]$actions_tag.AppendChild($root_query_tag)
            #Add to xml _data
            [void]$_data.Request.PrependChild($actions_tag)
        }
        if($nested_){
            foreach($n in $nested_){
                [void]$_data.Request.Actions.Query.Query.Properties.AppendChild($n)
            }
        }
        #Set object identity
        $_data.Request.ObjectPaths.Identity.Name = $ClientObject._ObjectIdentity_
    }
    Process{
        $p = @{
            Authentication = $Authentication;
            Endpoint = $sps_uri.AbsoluteUri;
            Data = $_data;
            Verbose = $Verbose;
            Debug = $Debug;
            InformationAction = $InformationAction;
        }
        $raw_data = Invoke-MonkeyCSOMRequest @p
        if($raw_data){
            $out_obj = New-Object PSObject
            foreach($property in $properties){
                if($null -ne $raw_data.psobject.properties.Item($property)){
                    $element = $raw_data | Select-Object -ExpandProperty $property
                    #Check if child items
                    if($element.psobject.Properties.Item('_Child_Items_')){
                        $values = $element._Child_Items_
                    }
                    else{
                        $values = $element
                    }
                    $out_obj | Add-Member NoteProperty -name $property -value $values
                }
            }
        }
    }
    End{
        if($null -ne $out_obj){
            return $out_obj
        }
    }
}

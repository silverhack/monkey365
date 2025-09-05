Function Split-Array {
    <#
        .SYNOPSIS
		Separates elements into small arrays

        .DESCRIPTION
		Separates elements into small arrays

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Split-Array
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([System.object[]])]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
        ,
        [Parameter(Mandatory, Position = 0)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Elements
    )
    Begin {
        $queue = [System.Collections.Generic.Queue[object]]::new($Elements)
    }
    Process {
        $queue.Enqueue($InputObject)
        if ($queue.Count -eq $Elements) {
            , $queue.ToArray()
            $queue.Clear()
        }
    }
    End {
        if ($queue.Count) {
          , $queue.ToArray()
        }
    }
}

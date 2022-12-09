enum GitDiffInclusion {
    Left  = 0
    Right = 1
    Both  = 3
}

function ConvertFrom-GitDiff {
    <#
        .SYNOPSIS
            Converts git diff text to an object.

        .OUTPUTS
            A PSCustomObject of the converted Diff.

        .EXAMPLE
            ConvertFrom-GitDiff -diffText <textual results of a git diff command>

            git diff | ConvertFrom-GitDiff
    #>
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string]
        $diffText
    )

    $diff = [PSCustomObject]@{
        LeftHash      = ""
        RightHash     = ""
        Mode          = ""
        LeftFilename  = ""
        RightFilename = ""
        Chunks        = (New-Object System.Collections.Generic.List[PSCustomObject])
        Messages      = (New-Object System.Collections.Generic.List[string])
    }

    $capture = $false

    $lineList = $diffText.Replace("$([char]13)","").Split([char]10)

    $chunk = $null

    foreach ($line in $lineList) {

        if ($line.StartsWith("diff") -And -not($capture)) {

            # "Ignore"

        } elseif ($line.StartsWith("index") -And -not($capture)) {

            if ($line -match "^index ([0-9A-Fa-f]+)..([0-9A-Fa-f]+) ([0-9]+)$") {
                $diff.LeftHash  = $matches[1]
                $diff.RightHash = $matches[2]
                $diff.Mode      = $matches[3]
            }

        } elseif ($line.StartsWith("---") -And -not($capture)) {

            if ($line -match "^--- (.*)$") {
                $diff.LeftFilename  = $matches[1]
            }

        } elseif ($line.StartsWith("+++") -And -not($capture)) {

            if ($line -match "^\+\+\+ (.*)$") {
                $diff.RightFilename  = $matches[1]
            }

        } elseif ($line -match "^\\\s*(.*)$") {

            $diff.Messages.Add($matches[1])

        } elseif ($line -match "^@@ .* \+([0-9]+),[0-9]+ @@\s*(.*)$") {

            $capture = $true

            $chunk = [PSCustomObject]@{
                StartLine = [long]$matches[1]
                LineCount = 1
                Lines     = (New-Object System.Collections.Generic.List[PSCustomObject])
            }

            $chunk.Lines.Add([PSCustomObject]@{
                Line      = $matches[2]
                Inclusion = [GitDiffInclusion]::Both
            })

            $diff.Chunks.Add($chunk)

        } elseif ($capture) {

            if ($line -match "^([\s\+\-])(.*)$") {

                $chunk.LineCount++

                $chunk.Lines.Add([PSCustomObject]@{
                    Line      = $matches[2]
                    Inclusion = switch ($matches[1]) {
                        "+"     { [GitDiffInclusion]::Right }
                        "-"     { [GitDiffInclusion]::Left  }
                        default { [GitDiffInclusion]::Both  }
                    }
                })
            }
        }
    }

    return $diff
}

Export-ModuleMember -Function *

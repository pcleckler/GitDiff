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
    #>
    param (
        [Parameter(Mandatory = $true)]
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
    }

    $capture = $false

    $lineList = $diffText.Replace("$([char]13)","").Split([char]10)

    $chunk = $null

    foreach ($line in $lineList) {

        switch ($true) {

            ($line.StartsWith("diff") -And -not($capture)) {
                # "Ignore"
            }

            ($line.StartsWith("index") -And -not($capture)) {

                if ($line -match "^index ([0-9A-Fa-f]+)..([0-9A-Fa-f]+) ([0-9]+)$") {
                    $diff.LeftHash  = $matches[1]
                    $diff.RightHash = $matches[2]
                    $diff.Mode      = $matches[3]
                }
            }

            ($line.StartsWith("---") -And -not($capture)) {

                if ($line -match "^--- (.*)$") {
                    $diff.LeftFilename  = $matches[1]
                }
            }

            ($line.StartsWith("+++") -And -not($capture)) {

                if ($line -match "^\+\+\+ (.*)$") {
                    $diff.RightFilename  = $matches[1]
                }
            }

            $line.StartsWith("@@") {

                # Break up line by RegEx
                if ($line -match "^@@ .* \+([0-9]+),[0-9]+ @@\s*(.*)$") {

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
                }
            }

            (-Not($line.StartsWith("@@")) -And $capture) {

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
    }

    return $diff
}

Export-ModuleMember -Function *

<#
────────────────────────────────────────────────────────────
📄  adomm.psfl.ps1 — Powershell Shared Function Library
🔧  Version:    1.1 (Stable)
📅  Updated:    2025-07-02
👤  Author:     Mantas Adomavičius
📦  Used by:    Ping Monitor v1.1 + Clock Matrix v8.1
🗂️   Usage:      Dot-source or auto-import via $PSCommandPath
────────────────────────────────────────────────────────────
#>

if ($PSCommandPath -eq $null) { function GetPSCommandPath() { return $MyInvocation.PSCommandPath; } $PSCommandPath = GetPSCommandPath }
if (-not $Global:Folder) { $Global:Folder = ($PSCommandPath -replace '[^\\]+$', '') -replace '\\$', '' }
$h = Get-Host; $ui = $h.UI.RawUI;

function Set-Buffer-Width-To-Window-Width {
    try {
        $bufferSize = $ui.BufferSize
        $windowSize = $ui.WindowSize
        if ($bufferSize.Width -ne $windowSize.Width) {
            $bufferSize.Width = $windowSize.Width
            $ui.BufferSize = $bufferSize
        }
    } catch {}
}

function reset {
    Set-Buffer-Width-To-Window-Width
    $cursorY = $ui.CursorPosition.Y
    $maxY = $ui.BufferSize.Height - 1
    if ($cursorY -gt $maxY) {
        $ui.CursorPosition = @{ X = 0; Y = $maxY }
    }
}

function Clear-ConsoleWindow {
    Set-Buffer-Width-To-Window-Width
    Clear-Host
    $cursorY = $ui.CursorPosition.Y
    $maxY = $ui.BufferSize.Height - 1
    if ($cursorY -gt $maxY) {
        $ui.CursorPosition = @{ X = 0; Y = $maxY }
    }
}

function Enable-ResizeWatcher {
    param (
        [Parameter()]
        [Alias('Action')]
        $OnResize = { reset }
    )

    if (-not ($OnResize -is [ScriptBlock])) {
        try {
            $OnResize = [ScriptBlock]::Create($OnResize.ToString())
        } catch {
            Write-Host "⚠️ Invalid OnResize value. Resize watcher will do nothing." -ForegroundColor Red
            return { }
        }
    }

    $script:_resize_ui = (Get-Host).UI.RawUI
    $script:_resize_lastSize = $script:_resize_ui.WindowSize
    $script:_resize_callback = $OnResize

    function Check-Resize {
        $currentSize = $script:_resize_ui.WindowSize
        if (
            $currentSize.Width -ne $script:_resize_lastSize.Width -or
            $currentSize.Height -ne $script:_resize_lastSize.Height
        ) {
            $script:_resize_lastSize = $currentSize
            if ($script:_resize_callback -is [ScriptBlock]) {
                & $script:_resize_callback
            }
        }
    }

    return (Get-Item function:Check-Resize).ScriptBlock
}



function timestamp { return [Math]::Round([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"),[System.MidpointRounding]::AwayFromZero) }

$mf = New-Module -ascustomobject {
	function time_difference($timestamp_exec,$timestamp_now) {
		$timestamp_diff =[Math]::Round(($timestamp_exec-$timestamp_now),3);
		$time = "";
		$timestamp_diff_d = [Math]::Floor([decimal](($timestamp_diff/60/60/24)));
		$timestamp_diff_h = [Math]::Floor([decimal](($timestamp_diff/60/60)-($timestamp_diff_d*24)));
		$timestamp_diff_min = [Math]::Floor([decimal](($timestamp_diff/60)-($timestamp_diff_d*24*60)-($timestamp_diff_h*60)));
		$timestamp_diff_sec = [Math]::Floor(($timestamp_diff-($timestamp_diff_d*24*60*60)-($timestamp_diff_h*60*60)-($timestamp_diff_min*60)));
		if($timestamp_diff_d -gt 0){ $time += "$timestamp_diff_d d "}
		if($timestamp_diff_h -gt 0){ $time += "$timestamp_diff_h h "}
		if($timestamp_diff_min -gt 0){ $time += "$timestamp_diff_min m " }
		if($timestamp_diff_sec -gt 0){ $time += "$timestamp_diff_sec s " }
		return $time.Trim()
	}
	
	function ping($host, $count = 4) {
		$pinger = New-Object System.Net.NetworkInformation.Ping
		$vals   = New-Object System.Collections.Generic.List[int]

		for ($i = 0; $i -lt $count; $i++) {
			for ($r = 0; $r -lt 3; $r++) {
				try {
					$reply = $pinger.Send($host, 1000)
					if ($reply.Status -eq 'Success') { [void]$vals.Add([int]$reply.RoundtripTime); break }
				} catch {}
			}
		}

		try { $pinger.Dispose() } catch {}

		if ($vals.Count -eq 0) { return 0 }
		if ($vals.Count -le 2) { 
			return [int][math]::Ceiling(($vals | Measure-Object -Average).Average) 
		}

		# 3+ samples → drop the max, average the rest
		$sorted  = $vals | Sort-Object
		$trimmed = $sorted[0..($sorted.Count - 2)]   # drops largest
		$sum     = ($trimmed | Measure-Object -Sum).Sum
		return [int][math]::Ceiling($sum / $trimmed.Count)
	}

}

function mute {
	$obj = new-object -com wscript.shell
	$obj.SendKeys([char]175)
	$obj.SendKeys([char]173)
}


function Repaint-ConsoleFromBottom {
    $filePath = "$Folder\Ping-Check\Ping-Check-$(Get-Date -Format 'yyyy-MM-dd').txt"
	
    if (Test-Path $filePath -PathType Leaf) {
		Clear-ConsoleWindow
        Set-Buffer-Width-To-Window-Width
        $text = Get-Content $filePath
        $i = 0
        $err = 0

        foreach ($logLine in $text) {
            $i++
            if ($i % 2 -gt 0) {
                $colour = "Gray"
                $colour2 = "DarkYellow"
            } else {
                $colour = "White"
                $colour2 = "Yellow"
            }

            if ($logLine -match '^\!') { $colour = $colour2 }
            if ($logLine -match '^\*') { $colour = "Red"; $err++ }

            if ($i -lt $text.Count) {
				Write-Host "$logLine" -ForegroundColor $colour
			} else {
				Write-Host "$logLine" -ForegroundColor $colour -NoNewline
			}

        }

        if ($err -gt 0) { $PingErrorCount = " (*$err)" } else { $PingErrorCount = "" }
		
        $ui.WindowTitle = "$Global:PingMonitorVersion$PingErrorCount"
		
		Set-Buffer-Width-To-Window-Width
		
    }
}

function Get-DaySuffix {
    param([int]$Day = (Get-Date).Day)

    switch ($Day) {
        {$_ -in 11..13} { return 'th' }
        {$_ % 10 -eq 1} { return 'st' }
        {$_ % 10 -eq 2} { return 'nd' }
        {$_ % 10 -eq 3} { return 'rd' }
        default         { return 'th' }
    }
}



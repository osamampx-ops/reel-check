param([Parameter(Mandatory)][string]$Video, [string]$Out = "$env:TEMP\reel-check")
# Measures a vertical reel with ffmpeg and writes frame sheets for Claude to look at.
if ($Video -match '^https?://') {
  New-Item -ItemType Directory -Force $Out | Out-Null
  yt-dlp -q -o "$Out\reel.%(ext)s" --merge-output-format mp4 $Video
  $Video = "$Out\reel.mp4"
}
if (-not (Test-Path $Video)) { throw "Video not found: $Video" }
New-Item -ItemType Directory -Force $Out | Out-Null

$dur = [double](ffprobe -v error -show_entries format=duration -of csv=p=0 $Video)
$size = ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 $Video

# Visual change every 0.5 s (mean pixel difference; works for motion graphics with no hard cuts)
$diffLog = ffmpeg -hide_banner -i $Video -vf "fps=2,scale=108:192,format=gray,tblend=all_mode=difference,signalstats,metadata=print:key=lavfi.signalstats.YAVG" -an -f null - 2>&1 | ForEach-Object { "$_" }
$diff = @($diffLog | Select-String 'YAVG=([\d.]+)' | ForEach-Object { [double]$_.Matches[0].Groups[1].Value })
$beats = @(for ($i = 0; $i -lt $diff.Count; $i++) { if ($diff[$i] -ge 4) { [math]::Round(($i + 1) / 2, 1) } })
$run = 0; $still = 0; foreach ($d in $diff) { if ($d -lt 1.5) { $run++; $still = [math]::Max($still, $run) } else { $run = 0 } }

# Loudness (integrated LUFS) and silence at the start
$loud = (ffmpeg -hide_banner -i $Video -af ebur128 -f null - 2>&1 | Select-String 'I:\s+(-?[\d.]+) LUFS' | Select-Object -Last 1).Matches.Groups[1].Value
$sil = ffmpeg -hide_banner -i $Video -af "silencedetect=n=-40dB:d=0.4" -f null - 2>&1 | Select-String 'silence_(start|end): ([\d.]+)' | ForEach-Object { "$($_.Matches[0].Groups[1].Value) $($_.Matches[0].Groups[2].Value)" }

# Sheets: first 3 s at 4 fps (the hook), then the whole reel at 1 fps
ffmpeg -v error -y -t 3 -i $Video -vf "fps=4,scale=270:-1,tile=6x2" -frames:v 1 "$Out\hook.jpg"
$rows = [math]::Ceiling($dur / 6)
ffmpeg -v error -y -i $Video -vf "fps=1,scale=200:-1,tile=6x$rows" -frames:v 1 "$Out\full.jpg"

[pscustomobject]@{
  duration_s     = [math]::Round($dur, 1)
  size           = $size
  visual_beats   = $beats.Count
  beats_per_10s  = [math]::Round($beats.Count / $dur * 10, 1)
  beat_times_s   = $beats -join ' '
  longest_still_s = $still / 2
  loudness_lufs  = $loud
  silences       = $sil -join '; '
  hook_sheet     = "$Out\hook.jpg"
  full_sheet     = "$Out\full.jpg"
} | ConvertTo-Json

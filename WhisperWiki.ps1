# TIL functions need to be above wherever it's called.
function Wait-Key {
    $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

# Lots of setup to make sure I'm running in the proper file locations.
# Also some default settings.
$scriptLocation = $MyInvocation.MyCommand.Path | Split-Path
$settingsFile = Join-Path $scriptLocation "settings.json"
$settingsExist = Test-Path $settingsFile
$defaultSettings = [PSCustomObject]@{
    "programPath" = ".\bin\main.exe"
    "modelPath" = ".\models\ggml-small.en.bin"
    "outputPath" = ".\output"
    "filePickerPath" = $null
    "cpuThreads" = 4 # 4 is default, 7 is max efficiency: https://github.com/ggerganov/whisper.cpp/issues/200
}

# Just so you don't have to cd to the script location before running it.
Set-Location $scriptLocation

# Can't read from the settings later on if it doesn't exist, so here is where it's created.
if (!$settingsExist) {
    New-Item $settingsFile | Out-Null
    Write-Output "settings.json file doesn't exist, so it has been created.
Please edit the settings file to your required settings.
Press any key to exit..."
    Set-Content $settingsFile (ConvertTo-Json $defaultSettings)
    Wait-Key
    Exit
}

# I should really put some error handling for malformed JSON here...
$settings = Get-Content $settingsFile | ConvertFrom-Json
$tempAudio = (Join-Path $settings.outputPath "output.wav")

# Sets up the file chooser dialogue, to be able to choose the audio file to process.
Add-Type -AssemblyName System.Windows.Forms
$filePicker = New-Object System.Windows.Forms.OpenFileDialog
# Doing this to set a "default location" for the file chooser, if the setting is null.
# Also Microsoft recommends null being on the left: https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-null?view=powershell-5.1#checking-for-null
if ($null -eq $settings.filePickerPath) {
    $settings.filePickerPath = $scriptLocation
}
$filePicker.InitialDirectory = $settings.filePickerPath
$filePicker.Title = "Choose Audio File..."
$filePickResult = $filePicker.ShowDialog()

if ($filePickResult -ne [System.Windows.Forms.DialogResult]::OK){
    Write-Output "No file chosen. Exiting..."
    Wait-Key
    Exit
}
# Gets just the name of the audio file without the extension so I can use that as the name for the other files later on.
# This is easier in later (than 5.1) versions of powershell with an updated Split-Path module.
$fileName = (Split-Path $filePicker.FileName -Leaf) -replace '\.[^.]*$',''

# Converts audio to the only audio type this implementation of whisper accepts.
ffmpeg -i $filePicker.FileName -ar 16000 -ac 1 -c:a pcm_s16le $tempAudio | Out-Null

# Starts the whisper process on the audio file, to transcribe it to text.
# The .srt and .txt file is generated here.
Start-Process -NoNewWindow -Wait -FilePath $settings.programPath -ArgumentList "-f",$tempAudio,"-m",$settings.modelPath,"-t",$settings.cpuThreads,"-osrt","-otxt","-pc"

Remove-Item $tempAudio
Rename-Item (Join-Path $settings.outputPath "output.wav.srt") "$fileName.srt"

# Grabbing the generated text from the text file to transform it for the wikitext.
$text = (Get-Content (Join-Path $settings.outputPath "output.wav.txt"))
Rename-Item (Join-Path $settings.outputPath "output.wav.txt") "$fileName.txt"

# There seems to be a weird issue with how the text is generated, which includes a space at the start of each line.
# This fixes that.
for ($i = 0; $i -lt $text.Length; $i++){
    $text[$i] = $text[$i].Substring(1)
}

# This is the template I use for all the Prime Office Hours. R.I.P. Sounder
# The template is located here: https://wiki.neosvr.com/Template:ProbablePrime_Office_Hours_Sounder
$wikiTemplate = @('{{',
'Template:ProbablePrime_Office_Hours_Sounder|',
'previous=OfficeHours:ProbablePrime:|',
'next=OfficeHours:ProbablePrime:|',
'audioFile=File:.ogg|',
'description=',
'* Talking points go here',
'}}',
"","","","")

# Had to use the .NET ArrayList here to be able to add to a list. If I used the default poweshell shortcut of += on an array,
# it would make a new array for every +=, which is inefficient.
#
# I also add an empty line between each line of text since the MediaWiki formatting is weird, and wouldn't have made newlines if it was formatted
# similarly to the .txt file.
$wikiOutput = [System.Collections.ArrayList]::new()
$wikiOutput.AddRange($wikiTemplate)
foreach ($line in $text) {
    $wikiOutput.Add($line) | Out-Null
    $wikiOutput.Add("") | Out-Null
}

New-Item (Join-Path $settings.outputPath "$filename.wikitext")
Set-Content -Path (Join-Path $settings.outputPath "$filename.wikitext") -Value $wikiOutput.ToArray()
Write-Output '

Complete! Press any key to close...'
Wait-Key
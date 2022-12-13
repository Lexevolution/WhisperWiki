# WhisperWiki
Script that I specifically made to use OpenAI's Whisper (more specifically, the c++ port) to generate a wiki page.

## First Time Instructions
[ffmpeg](https://ffmpeg.org/) is required and needs to be available through the PATH environment variable for this script to work.
- Download the `WhisperWiki.ps1` script, and put it in its own folder
- Download the latest build of [whisper.cpp](https://github.com/ggerganov/whisper.cpp)
  - The windows binaries can be found in the [Actions Tab](https://github.com/ggerganov/whisper.cpp/actions)
  - Click on the latest workflow
  - Scroll down (sometimes it doesn't let you scroll properly) to the Artifacts, and download the 32 or 64 bit binaries
- Create a folder in the folder you placed the script (and name it "bin" or something), and extract the Whisper binaries to it.
- Create two other folders (preferrably called "models" and "output")
- Download one or more of the Whisper ggml models and place them in the models folder
  - Whisper model files are available [here](https://huggingface.co/datasets/ggerganov/whisper.cpp/tree/main) or [here](https://ggml.ggerganov.com/)
  - Larger model = more accurate output, but slower
  - More info about the models can be found [here](https://github.com/ggerganov/whisper.cpp/tree/master/models)
- Run the script once to generate the settings file
- Edit the settings file to your needs (More info below)
- Run the script (again)!

If done correctly, the file structure should look something like this:
![image](https://user-images.githubusercontent.com/31176843/207340137-2c1c325e-1b30-4933-963a-8a96bbe84d28.png)

## Usage
The `settings.json` file is where you will change all the necessary settings before running the script. All file paths in the settings file can be direct, or relative to the script's location.
### Setting descriptions
- `programPath` - The path to the `main.exe` binary, which is used for transcription (`.\\bin\\main.exe` by default)
- `modelPath` - The path to the model file used for the transcription (`.\\models\\ggml-small.en.bin` by default)
- `outputPath` - The path where the script will place the resulting transcript files (`.\\output` by default)
- `filePickerPath` - An optional path which makes the file chooser automatically open from that location. If null, will open at the script's location. (`null` by default)
- `cpuThreads` - The number of CPU threads to use for transcribing. [Diminishing returns above 7 threads](https://github.com/ggerganov/whisper.cpp/issues/200) (`4` by default)
---
Once all the settings are set, you just run the script, and a file picker will open. Choose your audio file, which will be fed in to Whisper for transcribing. The output files produce a .srt for timed close captions, a .txt for transcript, and a .wikitext for the Neos Wiki. You can then edit the values for the .wikitext template to add the previous page, the next page, the audio file, and the description.

Here's a filled out template for reference:![image](https://user-images.githubusercontent.com/31176843/207352258-5be8fc1e-37f9-42d2-abf0-49f9de22717b.png)

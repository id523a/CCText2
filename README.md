# CCText2
Stores files for use with ComputerCraft.

# How to Load Music into Cassette Tapes (Minecraft 1.7.10, ComputerCraft, Computronics)

1. Convert your audio file to a WAV file.  
2. Use [LionRay](https://github.com/gamax92/LionRay) to create a DFPWM file from the WAV file. Uncheck the DFPWM1a box, and pick any sample rate between 32768 and 65536.  
    Higher sample rates give higher quality but need longer, more expensive tapes.  
3. Use a base64 encoder, such as https://www.base64encode.org/, to convert the DFPWM file to a text file.  
    Base64 is used to ensure that the file won't be corrupted when it's sent through a medium that only allows text, such as the [ComputerCraft HTTP API](https://computercraft.info/wiki/HTTP_\(API\)).  
4. Upload the text file to a file-hosting service.  
5. Get the raw download link for the text file. If you uploaded it to GitHub, it will be something that begins with `https://raw.githubusercontent.com/`.  
6. In Minecraft, make sure you have a [ComputerCraft computer](http://www.computercraft.info/wiki/Computer) with a [Computronics tape drive](https://wiki.vexatos.com/wiki:computronics:tape) next to it.  
7. On the computer, enter:  
    `pastebin get YVfC4ner github` to install [this program](https://pastebin.com/YVfC4ner) that fetches text files from GitHub.  
    `github id523a/CCText2/master/writetape.lua writetape` to install [writetape.lua](https://github.com/id523a/CCText2/blob/master/writetape.lua).  
    `github id523a/CCText2/master/tape.lua tape` to install [tape.lua](https://github.com/id523a/CCText2/blob/master/tape.lua).  
8. Insert a blank cassette tape into the tape drive, of the correct length.  
   *Minimum tape length (mins)* = *audio length (mins)* × *chosen sample rate* / 32768  
9. On the computer, enter: `tape setspeed <samplerate>`, where `<samplerate>` is replaced by your chosen sample rate.  
    This writes a value into the tape that indicates the correct playback speed.  
10. Enter `writetape <URL>` where `<URL>` is replaced with the raw download URL from step 5.  
	This downloads the file, decodes it, and writes it to the tape.  
11. Enter `tape silence` to fill the rest of the tape with silence.  
	This prevents the clicking noises when the tape ends.  
12. Enter `tape label "<something>"` to label the tape.  
13. To play the tape: `tape play`  
    To stop and rewind the tape: `tape stop`  

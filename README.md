# audio-review
This is a simple iOS application I created to refresh my memory on working with Apple's audio toolbox. It includes the following elements:
 - A custom audio recorder I created several years ago in Objective-C
 - A custom audio waveform view I created several years ago in Objective-C
 - A basic, single view controller application created on 1/31/2022 in Swift to use those older classes

The custom audio recorder uses an audio unit renderer to render raw audio data into a memory buffer and sample it for level metering. This provides higher resolution sample data for fast level metering from the microphone. Also, the recorder uses ExtAudioFile methods to write the audio data to an .mp4 file, though this file is not currently being used by the application and is just overwritten with each use.

The custom audio waveform view uses core animation and a CADisplayLink timer to render the waveform smoothly while audio is being recorded and/or the user is scrolling through the waveform.

The swift application has a simple record/stop button, an instance of the audio waveform, and a scroll view for scrolling through the audio waveform. The error handling in the application is very limited.
 

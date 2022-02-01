//
//  EGAAudioRecorder.m
//  waveform
//
//  Created by Joe Helton on 6/21/12.
//  Copyright (c) 2012 Endgame Apps. All rights reserved.
//

#import "EGAAudioRecorder.h"

#define checkStatus(status) \
if ((status) != noErr) {\
    NSLog(@"Audio Recorder Error: %d -> %s:%d", (int)(status), __FILE__, __LINE__);\
    [self handleErrorStatus:status];\
    return;\
}

#define checkStatusExt(status, rv) \
if ((status) != noErr) {\
    NSLog(@"Audio Recorder Error: %d -> %s:%d", (int)(status), __FILE__, __LINE__);\
    [self handleErrorStatus:status];\
    return (rv);\
}

const float EGAAudioRecorderSampleRate = 44100;
const AudioFileTypeID EGAAudioRecorderFileType = kAudioFileMPEG4Type;
const NSString * EGAAudioFileExtension = @"m4a";

@interface EGAAudioRecorder() {
 
    AudioComponentInstance _ioAudioUnit;
    AudioStreamBasicDescription _ioAudioFormat;
    AudioStreamBasicDescription	_fileAudioFormat;
    ExtAudioFileRef _fileRef;
    SInt16 _peakSampleValue;
    UInt64 _frameCounter;
    NSTimeInterval _duration;
    float _peakAudioLevel;
}

- (void)notifyDelegateOfRecordedAudio;
- (void)handleErrorStatus:(OSStatus)status;

@end

@implementation EGAAudioRecorder

#pragma mark -
#pragma mark Audio Unit Input Callback

static OSStatus recordingCallback(void *inRefCon, 
								  AudioUnitRenderActionFlags *ioActionFlags, 
								  const AudioTimeStamp *inTimeStamp, 
								  UInt32 inBusNumber, 
								  UInt32 inNumberFrames, 
								  AudioBufferList *ioData) {
    
	EGAAudioRecorder *recorder = (__bridge EGAAudioRecorder *)inRefCon;
	OSStatus status = noErr;
	
    //initialize local variables
    UInt32 numSamples = inNumberFrames * recorder->_ioAudioFormat.mChannelsPerFrame;
    SInt16 audioData[numSamples];
    UInt32 audioDataSize = numSamples * sizeof(SInt16);
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mDataByteSize = audioDataSize;
    bufferList.mBuffers[0].mNumberChannels = recorder->_ioAudioFormat.mChannelsPerFrame;
    bufferList.mBuffers[0].mData = audioData;
    
    //render audio data into our in memory buffer
    status = AudioUnitRender(recorder->_ioAudioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    if (status != noErr) {
        [recorder handleErrorStatus:status];
        return status;
    }
    
    //capture sample data for level metering
    for (int i = 0; i < bufferList.mNumberBuffers; i++) {
        AudioBuffer buffer = bufferList.mBuffers[i];
        SInt16 *samples = (SInt16 *)buffer.mData;
        int length = buffer.mDataByteSize / sizeof(SInt16);
        for (int sampleCounter = 0; sampleCounter < length; sampleCounter++) {
            SInt16 sample = samples[sampleCounter];
            samples[sampleCounter] = sample;
            if(sample > recorder->_peakSampleValue) {
                recorder->_peakSampleValue = sample;
            }
        }
    }
    
    //write audio data to our audio file
    status = ExtAudioFileWriteAsync(recorder->_fileRef, inNumberFrames, &bufferList);
    if (status == noErr) {
        recorder->_frameCounter += inNumberFrames;
        recorder->_duration = (double)recorder->_frameCounter/(double)EGAAudioRecorderSampleRate;
        recorder->_peakAudioLevel = (float)recorder->_peakSampleValue/(float)INT16_MAX;
        recorder->_peakSampleValue = 0;
        [recorder notifyDelegateOfRecordedAudio];
        
    } else {
        [recorder handleErrorStatus:status];
    }
    
	return status;
}

#pragma mark - Initialization

- (id)initWithURL:(NSURL *)fileURL {
    
	if(self = [super init]) {
		
		OSStatus status = noErr;
		
        _url = fileURL;
        
        //configure io audio format. io format is 16 bit LPCM @ 44.1 kHz
		_ioAudioFormat.mFormatID			= kAudioFormatLinearPCM;
		_ioAudioFormat.mFormatFlags         = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        _ioAudioFormat.mSampleRate          = EGAAudioRecorderSampleRate;
		_ioAudioFormat.mChannelsPerFrame	= 1;
		_ioAudioFormat.mBitsPerChannel      = 16;
		_ioAudioFormat.mBytesPerFrame       = 2;
		_ioAudioFormat.mBytesPerPacket      = 2;
		_ioAudioFormat.mFramesPerPacket     = 1;
		_ioAudioFormat.mReserved			= 0;
        
        //configure file audio format. file format is AAC Encoded MPEG4 @ 44.1 kHz
        _fileAudioFormat.mFormatID			= kAudioFormatMPEG4AAC;
        _fileAudioFormat.mFormatFlags		= 0;
        _fileAudioFormat.mSampleRate        = EGAAudioRecorderSampleRate;
        _fileAudioFormat.mChannelsPerFrame	= 1;
        _fileAudioFormat.mBitsPerChannel    = 0;
        _fileAudioFormat.mBytesPerFrame     = 0;
        _fileAudioFormat.mBytesPerPacket    = 0;
        _fileAudioFormat.mFramesPerPacket	= 1024;
        _fileAudioFormat.mReserved			= 0;
		
        //define the audio unit description. used to instantiate the audio unit.
		AudioComponentDescription ioComponentDescription;
		ioComponentDescription.componentType = kAudioUnitType_Output;
		ioComponentDescription.componentSubType = kAudioUnitSubType_RemoteIO; //use kAudioUnitSubType_HALOutput on Mac OS X
		ioComponentDescription.componentFlags = 0;
		ioComponentDescription.componentFlagsMask = 0;
		ioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        
		//instatiate the audio unit
		AudioComponent ioComponent = AudioComponentFindNext(NULL, &ioComponentDescription);
		status = AudioComponentInstanceNew(ioComponent, &_ioAudioUnit);
		checkStatusExt(status, nil);
		
		//enable IO on our audio unit (this property should be set on the input scope in element 1 for input)
		UInt32 flag = 1;
		status = AudioUnitSetProperty(_ioAudioUnit,
									  kAudioOutputUnitProperty_EnableIO, 
									  kAudioUnitScope_Input, 
									  1, //remoteio uses element 0 for ouput (speaker) and element 1 for input (microphone)
									  &flag, 
									  sizeof(flag));
		checkStatusExt(status, nil);
		
		//disable buffer allocation
		flag = 0;
		status = AudioUnitSetProperty(_ioAudioUnit,
									  kAudioUnitProperty_ShouldAllocateBuffer,
									  kAudioUnitScope_Output, 
									  0,
									  &flag, 
									  sizeof(flag));
		checkStatusExt(status, nil);
		
		//configure an input callback (global scope).  the input callback is invoked when the audio unit 
		//has audio data avaialable to retrieve via the AudioUnitRender method.
		AURenderCallbackStruct callbackStruct;
		callbackStruct.inputProc = recordingCallback;
		callbackStruct.inputProcRefCon = (__bridge void *)self;
		status = AudioUnitSetProperty(_ioAudioUnit,
									  kAudioOutputUnitProperty_SetInputCallback, 
									  kAudioUnitScope_Global, 
									  0, //always 0 for global scope
									  &callbackStruct, 
									  sizeof(callbackStruct));
		checkStatusExt(status, nil);
        
        //configure stream format property on the output scope
        status = AudioUnitSetProperty(_ioAudioUnit,
                                      kAudioUnitProperty_StreamFormat, 
                                      kAudioUnitScope_Output, 
                                      1, //use element 1 here
                                      &_ioAudioFormat,
                                      sizeof(_ioAudioFormat));
		checkStatusExt(status, nil);
	}
	return self;
}

- (void)dealloc {
    
    if (_recording) {
        [self stop];
    }
    if (_readyToRecord) {
        [self endRecording];
    }
}

#pragma mark - Basic Recording

- (void)prepareToRecord {
    
    @synchronized(self) {
        
        if (_readyToRecord) return;
        
        _frameCounter = 0;
        _duration = 0.0;
        OSStatus status = noErr;
        
        //create a new audio file at the specified file url with the file format
        status = ExtAudioFileCreateWithURL((__bridge CFURLRef)_url, EGAAudioRecorderFileType, &_fileAudioFormat, NULL, kAudioFileFlags_EraseFile, &_fileRef);
        checkStatus(status);
        
        //assign the io format as the client data format for the file. this will allow is to write data in the io format to the file
        UInt32 propertySize = sizeof(_ioAudioFormat);
        status = ExtAudioFileSetProperty(_fileRef, kExtAudioFileProperty_ClientDataFormat, propertySize, &_ioAudioFormat);
        checkStatus(status);
        
        //perform an initial aysnc write of NULL to the audio file to initialize the asynchronous mechanism.
        status = ExtAudioFileWriteAsync(_fileRef, 0, NULL);
        checkStatus(status);
        
        //initialize the audio unit
        status = AudioUnitInitialize(_ioAudioUnit);
        checkStatus(status);
        
        _readyToRecord = YES;
    }
}

- (void)record {
    
    @synchronized(self) {
        
        NSAssert(_readyToRecord, @"EGAAudioRecorder received 'record' message but the recorder is not ready to record.");
        
        if (_recording && !_paused) return;
        
        OSStatus status = noErr;
        
        //start the audio unit
        status = AudioOutputUnitStart(_ioAudioUnit);
        checkStatus(status);
        
        _paused = NO;
        _recording = YES;
    }
}

- (void)pause {
    
    @synchronized(self) {
        
        if (_paused || !_recording) return;
        
        OSStatus status = noErr;
        
        //stop the audio unit
        status = AudioOutputUnitStop(_ioAudioUnit);
        checkStatus(status);
        
        _paused = YES;
    }
}

- (void)stop {

    @synchronized(self) {
        
        if (!_recording) return;
        
        OSStatus status = noErr;
        
        //stop the audio unit
        status = AudioOutputUnitStop(_ioAudioUnit);
        checkStatus(status);
        
        _paused = NO;
        _recording = NO;
    }
}

- (void)endRecording {
    
    @synchronized(self) {
        
        if (!_readyToRecord) return;
        
        OSStatus status = noErr;
        
        //clean up audio unit
        status = AudioUnitUninitialize(_ioAudioUnit);
        checkStatus(status);
        
        //close the audio file
        status = ExtAudioFileDispose(_fileRef);
        checkStatus(status);
        
        _readyToRecord = NO;
    }
}

- (BOOL)deleteAudioFile:(NSError **)error {
    
    BOOL result = [[NSFileManager defaultManager] removeItemAtURL:_url error:error];
    if (result) {
        _url = nil;
    }
    return  result;
}

- (BOOL)moveAudioFileToURL:(NSURL *)url error:(NSError **)error {

    BOOL result = [[NSFileManager defaultManager] moveItemAtURL:_url toURL:url error:error];
    if (result) {
        _url = url;
    }
    return result;
}

#pragma mark - Level Metering

- (void)notifyDelegateOfRecordedAudio {

    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_delegate audioRecorder:self didRecordAudioAtPeakAudioLevel:self->_peakAudioLevel withUpdatedDuration:self->_duration];
    });
}

#pragma mark - Error Handling

- (void)handleErrorStatus:(OSStatus)status {

    //TODO: Add a localized description for this.
    NSString *localizedDescription = NSLocalizedString(@"AudioRecorderError", nil);
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : localizedDescription };
	NSError *error = [[NSError alloc] initWithDomain:NSOSStatusErrorDomain code:status userInfo:userInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_delegate audioRecorderErrorOccurred:self error:error];
    });
}

@end


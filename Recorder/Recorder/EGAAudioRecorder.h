//
//  EGAAudioRecorder.h
//  waveform
//
//  Created by Joe Helton on 6/21/12.
//  Copyright (c) 2012 Endgame Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol EGAAudioRecorderDelegate;

extern const float EGAAudioRecorderSampleRate;
extern const AudioFileTypeID EGAAudioRecorderFileType;
extern const NSString * EGAAudioFileExtension;

@interface EGAAudioRecorder : NSObject

//properties
@property (nonatomic, readonly, strong) NSURL *url;
@property (nonatomic, readonly, getter=isRecording) BOOL recording;
@property (nonatomic, readonly, getter=isPaused) BOOL paused;
@property (nonatomic, readonly, getter=isReadyToRecord) BOOL readyToRecord;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) float peakAudioLevel;
@property (nonatomic, weak) id<EGAAudioRecorderDelegate> delegate;

//initialization
- (id)initWithURL:(NSURL *)fileURL;

//basic recording
- (void)prepareToRecord;
- (void)record;
- (void)pause;
- (void)stop;
- (void)endRecording;

//audio file management
- (BOOL)deleteAudioFile:(NSError **)error;
- (BOOL)moveAudioFileToURL:(NSURL *)url error:(NSError **)error;

@end

@protocol EGAAudioRecorderDelegate <NSObject>

- (void)audioRecorderErrorOccurred:(EGAAudioRecorder *)recorder error:(NSError *)error;
- (void)audioRecorder:(EGAAudioRecorder *)recorder didRecordAudioAtPeakAudioLevel:(float)level withUpdatedDuration:(NSTimeInterval)duration;

@end
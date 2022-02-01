//
//  EGAAudioWaveformView.h
//  SpeakEasy
//
//  Created by Joe Helton on 8/14/12.
//  Copyright (c) 2012 Endgame Apps. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EGAAudioWaveformView : UIView

//this property determines whether or not the waveform will update based on property value chages. if the waveform is not active, it will not update when property values are changed. setting isActive to NO should be thought of as putting the waveform in low power usage mode. it can be used to suspend all drawing operations.

@property (nonatomic, getter=isActive) BOOL active;

//appearance and layout properties

@property (nonatomic) CGFloat xScale;
@property (nonatomic) CGFloat yScale;
@property (nonatomic) CGFloat playheadRelativeXPosition;
@property (nonatomic, getter=isInverted) BOOL inverted;

@property (nonatomic, strong) UIColor *baselineColor;
@property (nonatomic, strong) UIColor *beforePlayheadWaveformGradientColor1;
@property (nonatomic, strong) UIColor *beforePlayheadWaveformGradientColor2;
@property (nonatomic, strong) UIColor *afterPlayheadWaveformGradientColor1;
@property (nonatomic, strong) UIColor *afterPlayheadWaveformGradientColor2;

//audio properties (these properties should aways be considered and updated together, i.e. if you add values to audioWaveformData you should also update audioDuration and possibly audioPositionAtPlayhead)

@property (nonatomic, strong) NSMutableData *audioWaveformData;
@property (nonatomic) NSTimeInterval audioDuration;
@property (nonatomic) NSTimeInterval audioPositionAtPlayhead;

//helpful methods for converting audio position (time) values to points on our graph and vice versa. in these points only the X value is significant.
//given a point within or outside the bounds of our view, returns an audio position (time) value which matches that point on the waveform
- (NSTimeInterval)audioPositionAtLocation:(CGPoint)location;
//given an audio position (time) returns a point on the waveform either within or outside the bounds of our view which matches that audio position
- (CGPoint)locationOfAudioPosition:(NSTimeInterval)position;

//returns the theoretical size of the audio waveform. this size will typically exceed the bounds of this view.
- (CGSize)waveformSize;

//returns the range of the data value within the audio waveform data for the current playhead position
- (NSRange)rangeOfDataValueAtPlayhead;
//given an audio position (time) returns the range of the data value within the audio waveform data that represents that audio position
- (NSRange)rangeOfDataValueAtAudioPosition:(NSTimeInterval)audioPosition;

@end

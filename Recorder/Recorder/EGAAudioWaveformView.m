//
//  EGAAudioWaveformView.m
//  SpeakEasy
//
//  Created by Joe Helton on 8/14/12.
//  Copyright (c) 2012 Endgame Apps. All rights reserved.
//

#import "EGAAudioWaveformView.h"

@interface EGAAudioWaveformView ()

@property (nonatomic, strong) CALayer *baselineLayer;
@property (nonatomic, strong) CAGradientLayer *beforePlayheadGradientLayer;
@property (nonatomic, strong) CAShapeLayer *beforePlayheadShapeLayer;
@property (nonatomic, strong) CAGradientLayer *afterPlayheadGradientLayer;
@property (nonatomic, strong) CAShapeLayer *afterPlayheadShapeLayer;

@property (nonatomic) BOOL needsRedrawWaveform;
@property (nonatomic, strong) CADisplayLink *displayLinkTimer;

@end

@implementation EGAAudioWaveformView

#pragma mark - UIView Overrides

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        [self audioWaveformViewCommonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self audioWaveformViewCommonInit];
    }
    return self;
}

- (void)audioWaveformViewCommonInit {
    
    _inverted = YES;
    _xScale = 1.0f;
    _yScale = 1.0f;
    _audioDuration = 0.0;
    _audioPositionAtPlayhead = 0.0;
    _audioWaveformData = [NSMutableData data];
    
    _baselineColor = [ UIColor darkGrayColor];
    _beforePlayheadWaveformGradientColor1 = [UIColor darkGrayColor];
    _beforePlayheadWaveformGradientColor2 = [UIColor darkGrayColor];
    _afterPlayheadWaveformGradientColor1 = [UIColor lightGrayColor];
    _afterPlayheadWaveformGradientColor2 = [UIColor lightGrayColor];
    
    _baselineLayer = [[CALayer alloc] init];
    _baselineLayer.backgroundColor = [_baselineColor CGColor];
    [self.layer addSublayer:_baselineLayer];
    
    _beforePlayheadGradientLayer = [[CAGradientLayer alloc] init];
    _beforePlayheadGradientLayer.colors = @[ (id)_beforePlayheadWaveformGradientColor1.CGColor, (id)_beforePlayheadWaveformGradientColor2.CGColor ];
    _beforePlayheadShapeLayer = [[CAShapeLayer alloc] init];
    _beforePlayheadShapeLayer.frame = self.layer.bounds;
    
    [_beforePlayheadGradientLayer setMask:_beforePlayheadShapeLayer];
    [self.layer addSublayer:_beforePlayheadGradientLayer];
    
    _afterPlayheadGradientLayer = [[CAGradientLayer alloc] init];
    _afterPlayheadGradientLayer.colors = @[ (id)_afterPlayheadWaveformGradientColor1.CGColor, (id)_afterPlayheadWaveformGradientColor2.CGColor ];
    _afterPlayheadShapeLayer = [[CAShapeLayer alloc] init];
    _afterPlayheadShapeLayer.frame = self.layer.bounds;
    _afterPlayheadShapeLayer.transform = CATransform3DMakeTranslation( - (self.layer.bounds.size.width * _playheadRelativeXPosition) , 0.0f, 0.0f);
    
    [_afterPlayheadGradientLayer setMask:_afterPlayheadShapeLayer];
    [self.layer addSublayer:_afterPlayheadGradientLayer];
    
    _active = YES;
    
    _playheadRelativeXPosition = 0.5f;
    
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
}

- (void)layoutSublayersOfLayer:(CALayer *)layer {
    
    [super layoutSublayersOfLayer:layer];
    
    if (layer == self.layer) {
        
        _baselineLayer.frame = CGRectMake(layer.frame.origin.x, (layer.bounds.size.height - 1.0f) / 2.0f, layer.frame.size.width, 1.0f);
        _beforePlayheadGradientLayer.frame = CGRectMake(0.0f, 0.0f, layer.bounds.size.width * _playheadRelativeXPosition, layer.bounds.size.height);
        _afterPlayheadGradientLayer.frame = CGRectMake(layer.bounds.size.width * _playheadRelativeXPosition, 0, layer.bounds.size.width - (layer.bounds.size.width * _playheadRelativeXPosition), layer.bounds.size.height);
        _afterPlayheadShapeLayer.transform = CATransform3DMakeTranslation( - (layer.bounds.size.width * _playheadRelativeXPosition) , 0.0f, 0.0f);
        
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {

    [super willMoveToSuperview:newSuperview];
    
    if (newSuperview) {
        _displayLinkTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateDisplay)];
        _displayLinkTimer.preferredFramesPerSecond = 0;
        [_displayLinkTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        _displayLinkTimer.paused = !_active;
    } else {
        [_displayLinkTimer invalidate];
        _displayLinkTimer = nil;
    }    
}

#pragma mark - Custom Property Setters

- (void)setActive:(BOOL)active {
    
    if (active != _active) {        
        _active = active;
        _displayLinkTimer.paused = !active;
    }
}

- (void)setAudioDuration:(NSTimeInterval)audioDuration {
    
    _audioDuration = audioDuration;
    _needsRedrawWaveform = YES;
}

- (void)setAudioPositionAtPlayhead:(NSTimeInterval)audioPositionAtPlayhead {

    _audioPositionAtPlayhead = audioPositionAtPlayhead;
    _needsRedrawWaveform = YES;
}

- (void)setAudioWaveformData:(NSMutableData *)audioWaveformData {
    
    _audioWaveformData = audioWaveformData;
    _needsRedrawWaveform = YES;
}

- (void)setBaselineColor:(UIColor *)baselineColor {
    
    _baselineColor = baselineColor;
    _baselineLayer.backgroundColor = [_baselineColor CGColor];
    _needsRedrawWaveform = YES;
}

- (void)setBeforePlayheadWaveformGradientColor1:(UIColor *)beforePlayheadWaveformGradientColor1 {
    
    _beforePlayheadWaveformGradientColor1 = beforePlayheadWaveformGradientColor1;
    _beforePlayheadGradientLayer.colors = @[ (id)_beforePlayheadWaveformGradientColor1.CGColor, (id)_beforePlayheadWaveformGradientColor2.CGColor ];
    _needsRedrawWaveform = YES;
}

- (void)setBeforePlayheadWaveformGradientColor2:(UIColor *)beforePlayheadWaveformGradientColor2 {
    
    _beforePlayheadWaveformGradientColor2 = beforePlayheadWaveformGradientColor2;
    _beforePlayheadGradientLayer.colors = @[ (id)_beforePlayheadWaveformGradientColor1.CGColor, (id)_beforePlayheadWaveformGradientColor2.CGColor ];
    _needsRedrawWaveform = YES;
}

- (void)setAfterPlayheadWaveformGradientColor1:(UIColor *)afterPlayheadWaveformGradientColor1 {
    
    _afterPlayheadWaveformGradientColor1 = afterPlayheadWaveformGradientColor1;
    _afterPlayheadGradientLayer.colors = @[ (id)_afterPlayheadWaveformGradientColor1.CGColor, (id)_afterPlayheadWaveformGradientColor2.CGColor ];
    _needsRedrawWaveform = YES;
}

- (void)setAfterPlayheadWaveformGradientColor2:(UIColor *)afterPlayheadWaveformGradientColor2 {
    
    _afterPlayheadWaveformGradientColor2 = afterPlayheadWaveformGradientColor2;
    _afterPlayheadGradientLayer.colors = @[ (id)_afterPlayheadWaveformGradientColor1.CGColor, (id)_afterPlayheadWaveformGradientColor2.CGColor ];
    _needsRedrawWaveform = YES;
}

- (void)setXScale:(CGFloat)xScale {
    
    if (_xScale != xScale) {
        _xScale = xScale;
        _needsRedrawWaveform = YES;
    }
}

- (void)setYScale:(CGFloat)yScale {
    
    if (_yScale != yScale) {
        _yScale = yScale;
        _needsRedrawWaveform = YES;
    }
}

#pragma mark - Public Method Implementation

- (NSTimeInterval)audioPositionAtLocation:(CGPoint)location {
    
    float samplesPerSecond = [self samplesPerSecond];
    
    NSTimeInterval timeOffset = location.x / _xScale / samplesPerSecond;
    if (_inverted) {
        CGSize waveformSize = [self waveformSize];
        NSTimeInterval duration = waveformSize.width / _xScale / samplesPerSecond;
        return duration - timeOffset;
    }
    
    return timeOffset;
}

- (CGPoint)locationOfAudioPosition:(NSTimeInterval)position {
    
    float samplesPerSecond = [self samplesPerSecond];
    
    CGFloat x, y;
    x = position * samplesPerSecond * _xScale;
    y = self.bounds.size.height/2.0f;
    if (_inverted) {
        x = [self waveformSize].width - x;
    }
    
    return CGPointMake(x, y);
}

- (CGSize)waveformSize {
    
    CGFloat width = 0.0f;
    if (_audioWaveformData) {
        size_t sampleSize = sizeof(float);
        float numberOfSamples = (float)[_audioWaveformData length] / (float)sampleSize;
        width = numberOfSamples * _xScale;
    }
    
    return CGSizeMake(width, self.bounds.size.height * _yScale);
}

- (NSRange)rangeOfDataValueAtPlayhead {
    
    return [self rangeOfDataValueAtAudioPosition:_audioPositionAtPlayhead];
}

- (NSRange)rangeOfDataValueAtAudioPosition:(NSTimeInterval)audioPosition {
    
    size_t sampleSize = sizeof(float);
    int index = ceilf(audioPosition * [self samplesPerSecond]);
    NSRange range = NSMakeRange(index * sampleSize, sampleSize);
    return range;
}

#pragma mark - Internal Methods

- (void)updateDisplay {
    
    @synchronized(self) {
        
        if (_needsRedrawWaveform) {
            _needsRedrawWaveform = NO;
            [self redrawWaveform];
        }
        
    }
}

- (void)redrawWaveform {
    
    if (_audioWaveformData) {
        
        //making the audio waveform will require creating a path of the audio level measurements plotted along the x axis (our graph). this code creates a basic path and adds lines to it for each audio level measurement in our audio data up to the maximum number of audio samples that can be displayed given the xScale and the size of this view. if the waveform should be inverted, we will read through the audio data backwards.
        
        //create the basic path and start at 0,0
        CGMutablePathRef basicWaveformPath = CGPathCreateMutable();
        CGPathMoveToPoint(basicWaveformPath, NULL, 0.0f, 0.0f);
        
        //calculate the size of our graph, the index (in terms of our graph) of the playhead and the data index at the location of the playhead
        float graphSize = self.bounds.size.width;
        float playheadGraphIndex = _playheadRelativeXPosition * graphSize;
        NSInteger playheadDataPointIndex = ceilf(_audioPositionAtPlayhead * [self samplesPerSecond]);
        
        if (_xScale >= 1.0f) { //an x scale factor greater than or equal to 1 means each individual data point can be plotted directly to a point on our graph
            
            //calculate our starting data point index based on the playhead location and the audio postion at the playhead
            NSInteger dataPointIndex = 0;
            if (_inverted) {
                dataPointIndex = ceilf(playheadDataPointIndex + (playheadGraphIndex / _xScale));
            } else {
                dataPointIndex = ceilf(playheadDataPointIndex - (playheadGraphIndex / _xScale));
            }
            
            float graphIndex = 0.0f;
            
            for (graphIndex = 0.0f; graphIndex < graphSize; graphIndex += _xScale) {
                
                float dataPointValue = [self getAudioSampleValueAtIndex:dataPointIndex];
                CGPathAddLineToPoint(basicWaveformPath, NULL, graphIndex, dataPointValue);
                
                if (_inverted) {
                    dataPointIndex--;
                } else {
                    dataPointIndex++;
                }
                
            }
            
            //add a final line to our path to bring it back to our baseline (0.0 on the y axis)
            CGPathAddLineToPoint(basicWaveformPath, NULL, graphIndex, 0.0f);
            
        } else { //an x scale value less than 1 means we will want to start averaging data values to keep from plotting more than one data point per graphics point on the screen
            
            //as an example we will use an xScale value of 0.3
            NSUInteger numberOfDataPointsToAverage = ceilf(1.0f/_xScale); //in our example numberOfDataPointsToAverage would be 4
            float effectiveScale = numberOfDataPointsToAverage * _xScale; //now we can produce an effective scale value to use when plotting points on the graph (1.2 in our example)
            
            //calculate our starting data point index based on the playhead location and the audio postion at the playhead
            NSInteger dataPointIndex = 0;
            if (_inverted) {
                dataPointIndex = ceilf(playheadDataPointIndex + (playheadGraphIndex / _xScale));
            } else {
                dataPointIndex = ceilf(playheadDataPointIndex - (playheadGraphIndex / _xScale));
            }
            
            float graphIndex = 0.0f;
            
            for (graphIndex = 0.0f; graphIndex < graphSize; graphIndex += effectiveScale) {
                
                float dataPointValue = [self getAudioSampleValueAverageFor:numberOfDataPointsToAverage samplesStartingWithSampleAtIndex:dataPointIndex inverted:_inverted];
                CGPathAddLineToPoint(basicWaveformPath, NULL, graphIndex, dataPointValue);
                
                if (_inverted) {
                    dataPointIndex -= numberOfDataPointsToAverage;
                } else {
                    dataPointIndex += numberOfDataPointsToAverage;
                }
                
            }
        
            //add a final line to our path to bring it back to our baseline (0.0 on the y axis)
            CGPathAddLineToPoint(basicWaveformPath, NULL, graphIndex, 0.0f);
            
        }
        
        //at this point, the waveform path is a basic a series of lines drawn connecting several points. but the size of an audio sample ranges from 0.0f to 1.0f so the "tallest" line in this graph only extends to 1.0 on the y axis. we now need to scale the height to 1/2 the height of our view and move the path up to the midpoint of our view's height. then we will need to scale the width and height of the path to correspond to our x and y zoom scale values. finally, we will duplicate the path and rotate it around the x axis to form the bottom half of our waveform. to do all of this we will need to create a new, final mutable path and add the basic path to it twice, once for the top half and again for the bottom half of the waveform, while applying transforms to translate and scale it.
        
        //create the final waveform path that will actually be applied to our shape layer
        CGMutablePathRef finalWaveformPath = CGPathCreateMutable();
        
        //create the transform initially as the identity transform.
        CGAffineTransform transform = CGAffineTransformIdentity;
        
        //apply a translation (causes the path to move up to the midpoint of our view's y axis) and a scale (causes the path to grow to 1/2 the height of our view) to the transform. also, we want to go ahead and apply our xScale and yScale values with this transform.
        double halfHeight = floor(self.bounds.size.height / 2.0f);
        transform = CGAffineTransformTranslate(transform, 0.0f, halfHeight);
        transform = CGAffineTransformScale(transform, 1.0f, halfHeight * _yScale);
        
        //now we have the transform we need to create the top half of our waveform shape. next, we add the basic path to our final waveform path, applying this transform, to make the top half of our shape.
        
        //add the basic path to our final shape path
        CGPathAddPath(finalWaveformPath, &transform, basicWaveformPath);
        
        //the shape path now contains the top half of the waveform. next we need to make one adjustment to the transform to cause it to flip the waveform around the x axis and add the bottom half of the waveform to our shape path
        
        //modify the transform to flip the waveform
        transform = CGAffineTransformScale(transform, 1.0f, -1.0f);
        
        //add the waveform path to our shape path one more time, this time as the bottom half of the shape
        CGPathAddPath(finalWaveformPath, &transform, basicWaveformPath);
        
        //apply the final waveform path to the shape layer
        [_beforePlayheadShapeLayer setPath:finalWaveformPath];
        [_afterPlayheadShapeLayer setPath:finalWaveformPath];
        
        //clean up
        CGPathRelease(basicWaveformPath);
        CGPathRelease(finalWaveformPath);
        
    } else {
        
        [_beforePlayheadShapeLayer setPath:NULL];
        [_afterPlayheadShapeLayer setPath:NULL];
        
    }
    
}

- (float)getAudioSampleValueAtIndex:(NSInteger)index {
    
    size_t sampleSize = sizeof(float);
    float value = 0.0f;
    
    if (index >= 0) {
        NSRange range = NSMakeRange(index * sampleSize, sampleSize);
        if (range.location + range.length < [_audioWaveformData length]) {
            [_audioWaveformData getBytes:&value range:range];
        }
    }

    return value;
}

- (float)getAudioSampleValueAverageFor:(NSUInteger)numberOfSamples samplesStartingWithSampleAtIndex:(NSInteger)startIndex inverted:(BOOL)inverted {
    
    size_t sampleSize = sizeof(float);

    float sum = 0.0f;
    
    if (inverted) {
        
        NSInteger start = startIndex;
        NSInteger stop = startIndex - numberOfSamples;
        
        for (NSInteger index = start; index > stop; index--) {
            float value = 0.0f;
            if (index >= 0) {
                NSRange range = NSMakeRange(index * sampleSize, sampleSize);
                if (range.location + range.length < [_audioWaveformData length]) {
                    [_audioWaveformData getBytes:&value range:range];
                }
            }
            sum += value;
        }
        
    } else {
        
        NSInteger start = startIndex;
        NSInteger stop = startIndex + numberOfSamples;
        
        for (NSInteger index = start; index < stop; index++) {
            float value = 0.0f;
            if (index >= 0) {
                NSRange range = NSMakeRange(index * sampleSize, sampleSize);
                if (range.location + range.length < [_audioWaveformData length]) {
                    [_audioWaveformData getBytes:&value range:range];
                }
            }
            sum += value;
        }
            
    }
    
    return sum/numberOfSamples;
}

- (float)samplesPerSecond {
    
    size_t sampleSize = sizeof(float);
    float numberOfSamples = (float)[_audioWaveformData length] / (float)sampleSize;
    float samplesPerSecond = _audioDuration ? (numberOfSamples / _audioDuration) : 0.0f;
    return samplesPerSecond;
}

@end

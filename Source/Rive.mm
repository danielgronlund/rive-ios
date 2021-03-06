//
//  RiveFile.m
//  RiveRuntime
//
//  Created by Matt Sullivan on 8/30/20.
//  Copyright © 2020 Rive. All rights reserved.
//

#import "Rive.h"
#import "RiveRenderer.hpp"

#import "file.hpp"
#import "artboard.hpp"
#import "animation.hpp"
#import "linear_animation.hpp"
#import "linear_animation_instance.hpp"


@interface RiveLinearAnimationInstance()
-(instancetype) initWithAnimation:(rive::LinearAnimation *) riveAnimation;
@end

@interface RiveLinearAnimation ()
 -(instancetype) initWithAnimation:(rive::LinearAnimation *) riveAnimation;
@end

@interface RiveArtboard ()
@property (nonatomic, readonly) rive::Artboard* artboard;
-(instancetype) initWithArtboard:(rive::Artboard *) riveArtboard;
@end

@interface RiveRenderer ()
@property (nonatomic, readonly) rive::Renderer* renderer;
-(rive::Renderer *) renderer;
@end

// RIVE RENDERER

@implementation RiveRenderer {
    CGContextRef ctx;
}

-(instancetype) initWithContext:(CGContextRef) context {
    if (self = [super init]) {
        ctx = context;
        _renderer = new rive::RiveRenderer(context);
        return self;
    } else {
        return nil;
    }
}

-(void) dealloc {
    delete _renderer;
}

-(void) alignWithRect:(CGRect)rect withContentRect:(CGRect)contentRect withAlignment:(Alignment)alignment withFit:(Fit)fit {
//    NSLog(@"Rect in align %@", NSStringFromCGRect(rect));
    
    // Calculate the AABBs
    rive::AABB frame = rive::AABB(rect.origin.x, rect.origin.y, rect.size.width + rect.origin.x, rect.size.height + rect.origin.y);
    rive::AABB content = rive::AABB(contentRect.origin.x, contentRect.origin.y, contentRect.size.width + contentRect.origin.x, contentRect.size.height + contentRect.origin.y);

    // Work out the fit
    rive::Fit riveFit;
    switch(fit) {
        case Fill:
            riveFit = rive::Fit::fill;
            break;
        case Contain:
            riveFit = rive::Fit::contain;
            break;
        case Cover:
            riveFit = rive::Fit::cover;
            break;
        case FitHeight:
            riveFit = rive::Fit::fitHeight;
            break;
        case FitWidth:
            riveFit = rive::Fit::fitWidth;
            break;
        case ScaleDown:
            riveFit = rive::Fit::scaleDown;
            break;
        case None:
            riveFit = rive::Fit::none;
            break;
    }

    // Work out the alignment
    rive::Alignment riveAlignment = rive::Alignment(.0, .0);
    switch(alignment) {
        case TopLeft:
            riveAlignment = rive::Alignment::topLeft;
            break;
        case TopCenter:
            riveAlignment = rive::Alignment::topCenter;
            break;
        case TopRight:
            riveAlignment = rive::Alignment::topRight;
            break;
        case CenterLeft:
            riveAlignment = rive::Alignment::centerLeft;
            break;
        case Center:
            riveAlignment = rive::Alignment::center;
            break;
        case CenterRight:
            riveAlignment = rive::Alignment::centerRight;
            break;
        case BottomLeft:
            riveAlignment = rive::Alignment::bottomLeft;
            break;
        case BottomCenter:
            riveAlignment = rive::Alignment::bottomCenter;
            break;
        case BottomRight:
            riveAlignment = rive::Alignment::bottomRight;
            break;
    }
    
    _renderer->align(riveFit, riveAlignment, frame, content);
}

@end

// RIVE FILE

@implementation RiveFile {
    rive::File* riveFile;
}

+ (uint) majorVersion { return UInt8(rive::File::majorVersion); }
+ (uint) minorVersion { return UInt8(rive::File::minorVersion); }

-(nullable instancetype) initWithBytes:(UInt8 *)bytes byteLength:(UInt64)length {
    if (self = [super init]) {
        rive::BinaryReader reader = rive::BinaryReader(bytes, length);
        rive::ImportResult result = rive::File::import(reader, &riveFile);
        if (result == rive::ImportResult::success) {
            return self;
        }
    }
    return nil;
}

- (RiveArtboard *) artboard {
    return [[RiveArtboard alloc] initWithArtboard: riveFile->artboard()];
}

@end

// RIVE ARTBOARD

@implementation RiveArtboard

-(instancetype) initWithArtboard:(rive::Artboard *) riveArtboard {
    if (self = [super init]) {
        _artboard = riveArtboard;
        return self;
    } else {
        return nil;
    }
}

-(NSInteger) animationCount {
    return _artboard->animationCount();
}

-(RiveLinearAnimation *) animationAt:(NSInteger) index {
    if (index >= [self animationCount]) {
        return nil;
    }
    
    return [[RiveLinearAnimation alloc] initWithAnimation: reinterpret_cast<rive::LinearAnimation *>(_artboard->animation(index))];
}

-(void) advanceBy:(double) elapsedSeconds {
    _artboard->advance(elapsedSeconds);
}

-(void) draw:(RiveRenderer *) renderer {
    _artboard->draw([renderer renderer]);
}

-(NSString *) name {
    return [NSString stringWithUTF8String:_artboard->name().c_str()];
}

-(CGRect) bounds {
    rive::AABB aabb = _artboard->bounds();
    return CGRectMake(aabb.minX, aabb.minY, aabb.width(), aabb.height());
}

@end

// RIVE LINEAR ANIMATION

@implementation RiveLinearAnimation {
    rive::LinearAnimation *animation;
}

-(instancetype) initWithAnimation:(rive::LinearAnimation *) riveAnimation {
    if (self = [super init]) {
        animation = riveAnimation;
        return self;
    } else {
        return nil;
    }
}

- (NSString *) name {
    std::string str = animation->name();
    return [NSString stringWithCString:str.c_str() encoding:[NSString defaultCStringEncoding]];
}

-(RiveLinearAnimationInstance *) instance {
    return [[RiveLinearAnimationInstance alloc] initWithAnimation: animation];
}

-(NSInteger) workStart {
    return animation->workStart();
}

-(NSInteger) workEnd {
    return animation->workEnd();
}

-(NSInteger) duration {
    return animation->duration();
}

-(NSInteger) fps {
    return animation->fps();
}

-(void) apply:(float) time to:(RiveArtboard *) artboard {
    animation->apply(artboard.artboard, time);
}

@end

// RIVE LINEAR ANIMATION INSTANCE

@implementation RiveLinearAnimationInstance {
    rive::LinearAnimationInstance *instance;
}

-(instancetype) initWithAnimation:(rive::LinearAnimation *) riveAnimation {
    if (self = [super init]) {
        
        instance = new rive::LinearAnimationInstance(riveAnimation);
        return self;
    } else {
        return nil;
    }
}

-(RiveLinearAnimation *) animation {
    rive::LinearAnimation *linearAnimation = instance->animation();
    return [[RiveLinearAnimation alloc] initWithAnimation: linearAnimation];
}

-(float) time {
    return instance->time();
}

-(void) setTime:(float) time {
    instance->time(time);
}

-(void) applyTo:(RiveArtboard*) artboard {
    instance->apply(artboard.artboard);
}

-(void) advanceBy:(double)elapsedSeconds {
    instance->advance(elapsedSeconds);
}

@end

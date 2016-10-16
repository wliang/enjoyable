//
//  NJOutputMouseButton.m
//  Enjoy
//
//  Created by Yifeng Huang on 7/27/12.
//

#import "NJOutputMouseButton.h"

#import "NJOutputMouseUtils.h"

@implementation NJOutputMouseButton {
    NSDate *upTime;
    int clickCount;
    NSPoint clickPosition;
}

+ (NSTimeInterval)doubleClickInterval {
    static NSTimeInterval s_doubleClickThreshold;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_doubleClickThreshold = [[NSUserDefaults.standardUserDefaults
                                   objectForKey:@"com.apple.mouse.doubleClickThreshold"] floatValue];
        if (s_doubleClickThreshold <= 0)
            s_doubleClickThreshold = 1.0;
    });

    return s_doubleClickThreshold;
}

+ (NSDate *)dateWithClickInterval {
    return [[NSDate alloc] initWithTimeIntervalSinceNow:self.doubleClickInterval];
}

+ (NSString *)serializationCode {
    return @"mouse button";
}

- (NSDictionary *)serialize {
    return @{ @"type": self.class.serializationCode, @"button": @(_button) };
}

+ (NJOutput *)outputWithSerialization:(NSDictionary *)serialization {
    NJOutputMouseButton *output = [[NJOutputMouseButton alloc] init];
    output.button = [serialization[@"button"] intValue];
    return output;
}

- (void)trigger {
    NSPoint mouseLoc = NSEvent.mouseLocation;
    CGEventType eventType = _button == kCGMouseButtonLeft ? kCGEventLeftMouseDown
                          : _button == kCGMouseButtonRight ? kCGEventRightMouseDown
                          : kCGEventOtherMouseDown;
    CGEventRef click = _createClickEventRef(eventType, mouseLoc, _button);

    if (clickCount >= 3 || [upTime compare:[NSDate date]] == NSOrderedAscending
        || !CGPointEqualToPoint(mouseLoc, clickPosition))
        clickCount = 1;
    else
        ++clickCount;
    CGEventSetIntegerValueField(click, kCGMouseEventClickState, clickCount);
    CGEventPost(kCGHIDEventTap, click);
    CFRelease(click);
    clickPosition = mouseLoc;
}

- (void)untrigger {
    upTime = [NJOutputMouseButton dateWithClickInterval];
    NSPoint mouseLoc = NSEvent.mouseLocation;
    CGEventType eventType = _button == kCGMouseButtonLeft ? kCGEventLeftMouseUp
                          : _button == kCGMouseButtonRight ? kCGEventRightMouseUp
                          : kCGEventOtherMouseUp;
    CGEventRef click = _createClickEventRef(eventType, mouseLoc, _button);
    CGEventSetIntegerValueField(click, kCGMouseEventClickState, clickCount);
    CGEventPost(kCGHIDEventTap, click);
    CFRelease(click);
}

#pragma mark - Private methods

static CGEventRef _createClickEventRef(CGEventType eventType, NSPoint mouseLoc, CGMouseButton button) {
    NSScreen *screen = getScreenContainingPoint(mouseLoc);
    if (!screen) {
        screen = [NSScreen mainScreen];
    }
    
    return CGEventCreateMouseEvent(NULL,
                                   eventType,
                                   CGPointMake(mouseLoc.x, CGRectGetMaxY(screen.frame) - mouseLoc.y),
                                   button);
}

@end

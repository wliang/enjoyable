//
//  NJOutputMouseMove.m
//  Enjoy
//
//  Created by Yifeng Huang on 7/26/12.
//

#import "NJOutputMouseMove.h"

#import "NJInputController.h"
#import "NJOutputMouseUtils.h"

@implementation NJOutputMouseMove

+ (NSString *)serializationCode {
    return @"mouse move";
}

- (NSDictionary *)serialize {
    return @{ @"type": self.class.serializationCode,
              @"axis": @(_axis),
              @"speed": @(_speed),
              };
}

+ (NJOutput *)outputWithSerialization:(NSDictionary *)serialization {
    NJOutputMouseMove *output = [[NJOutputMouseMove alloc] init];
    output.axis = [serialization[@"axis"] intValue];
    output.speed = [serialization[@"speed"] floatValue];
    if (!output.speed)
        output.speed = 10;
    return output;
}

- (BOOL)isContinuous {
    return YES;
}

#define CLAMP(a, l, h) MIN(h, MAX(a, l))

- (BOOL)update:(NJInputController *)ic {
    if (self.magnitude < 0.05)
        return NO; // dead zone
    
    CGFloat dx = 0, dy = 0;
    switch (_axis) {
        case 0:
            dx = -self.magnitude * _speed;
            break;
        case 1:
            dx = self.magnitude * _speed;
            break;
        case 2:
            dy = -self.magnitude * _speed;
            break;
        case 3:
            dy = self.magnitude * _speed;
            break;
    }
    
    NSPoint mouseLoc = ic.mouseLoc;
    NSScreen *currentScreen = getScreenContainingPoint(mouseLoc);
    if (!currentScreen) {
        currentScreen = [NSScreen mainScreen];
    }
    NSRect currentScreenFrame = currentScreen.frame;
    
    NSPoint newMouseLoc = NSMakePoint(mouseLoc.x + dx, mouseLoc.y - dy);
    if (getScreenContainingPoint(newMouseLoc) == nil) {
        // If new mouse position is outside of screen boundary, bound it to the current screen
        newMouseLoc.x = CLAMP(newMouseLoc.x, CGRectGetMinX(currentScreenFrame), CGRectGetMaxX(currentScreenFrame) - 1);
        newMouseLoc.y = CLAMP(newMouseLoc.y, CGRectGetMinY(currentScreenFrame), CGRectGetMaxY(currentScreenFrame) - 1);
    }
    ic.mouseLoc = newMouseLoc;
    
    CGEventRef move = CGEventCreateMouseEvent(NULL,
                                              kCGEventMouseMoved,
                                              CGPointMake(newMouseLoc.x, CGRectGetMaxY(currentScreenFrame) - newMouseLoc.y),
                                              0);
    
    CGEventSetIntegerValueField(move, kCGMouseEventDeltaX, (int)dx);
    CGEventSetIntegerValueField(move, kCGMouseEventDeltaY, (int)dy);
    CGEventPost(kCGHIDEventTap, move);

    if (CGEventSourceButtonState(kCGEventSourceStateHIDSystemState, kCGMouseButtonLeft)) {
        CGEventSetType(move, kCGEventLeftMouseDragged);
        CGEventSetIntegerValueField(move, kCGMouseEventButtonNumber, kCGMouseButtonLeft);
        CGEventPost(kCGHIDEventTap, move);
    }
    if (CGEventSourceButtonState(kCGEventSourceStateHIDSystemState, kCGMouseButtonRight)) {
        CGEventSetType(move, kCGEventRightMouseDragged);
        CGEventSetIntegerValueField(move, kCGMouseEventButtonNumber, kCGMouseButtonRight);
        CGEventPost(kCGHIDEventTap, move);
    }
    if (CGEventSourceButtonState(kCGEventSourceStateHIDSystemState, kCGMouseButtonCenter)) {
        CGEventSetType(move, kCGEventOtherMouseDragged);
        CGEventSetIntegerValueField(move, kCGMouseEventButtonNumber, kCGMouseButtonCenter);
        CGEventPost(kCGHIDEventTap, move);
    }

    CFRelease(move);
    return YES;
}

@end

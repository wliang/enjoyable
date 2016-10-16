//
//  NJOutputMouseUtils.m
//  Enjoyable
//
//  Created by Wei on 10/15/16.
//
//

#import "NJOutputMouseUtils.h"

NSScreen *getScreenContainingPoint(NSPoint point) {
    for (NSScreen *screen in [NSScreen screens]) {
        if (CGRectContainsPoint(screen.frame, point)) {
            return screen;
        }
    }
    return nil;
}

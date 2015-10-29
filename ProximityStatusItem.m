
//  ProximityStatusItem.m
//  Proximity

//  Created by Seb Jachec on 13/12/2013.


#import "ProximityStatusItem.h"

@implementation ProximityStatusItem

- (void)setup {
    _inRange = NO;
    _paused = NO;
    
    [self addObserver:self forKeyPath:@"inRange" options:0 context:NULL];
    [self addObserver:self forKeyPath:@"paused" options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self) self.needsDisplay = YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [self drawStandardBackground];
    
    if (_paused) {
        //TODO: Draw image
        
    } else {
        NSRect drawRect = NSInsetRect(NSOffsetRect(_bounds, 0, 1), 3.0f, 3.0f);
        
        NSRect circleRect = _inRange? NSInsetRect(drawRect, 1.0f, 1.0f) : drawRect;
        NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:circleRect];
        
        [selected? NSColor.whiteColor : NSColor.blackColor set];
        
        if (_inRange) {
            [circle setLineWidth:2.0f];
            [circle stroke];
            
        } else {
            [circle fill];
        }
        
        if (!selected) {
            NSShadow *shadow = [NSShadow new];
            [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.5]];
            [shadow setShadowOffset:NSMakeSize(0, -1)];
            [shadow setShadowBlurRadius:0.0f];
            
            [shadow set];
            [circle stroke];
        }
    }
}

@end

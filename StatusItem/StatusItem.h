
// StatusItem.h

// Seb Jachec

#import <Foundation/Foundation.h>

@protocol StatusItemDelegate <NSObject>
@required
- (void)statusItemClicked:(BOOL)selected;

@optional
- (void)statusItemRightClicked:(BOOL)rightClickSelected;

@end


@interface StatusItem : NSView <NSMenuDelegate> {
    BOOL selected;
    BOOL menuVisible;
    NSStatusItem *statusItem;
}

@property (strong) NSImage *image;
@property (strong) NSMenu *menu;

@property (weak) id<StatusItemDelegate> delegate;

@property BOOL showMenuOnLeftMouseDown;
@property NSRect imageDrawBounds;

- (instancetype)initWithStandardThickness;
- (instancetype)initWithThickness:(CGFloat)thickness;

- (void)drawStandardBackground;

@end

#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

static IMP original_doCommandBySelector = nil;

@interface Xcode4_word_navigation : NSObject
@end

@implementation Xcode4_word_navigation
static void doCommandBySelector( id self_, SEL _cmd, SEL selector )
{
	do {
        bool wordSelectionModified = selector == @selector(moveWordRightAndModifySelection:) || selector == @selector(moveWordLeftAndModifySelection:);
        
        if(selector == @selector(moveWordLeft:) || selector == @selector(moveWordRight:) || wordSelectionModified)
        {
            NSTextView *self = (NSTextView *)self_;
			NSString *text = self.string;
			NSRange selectedRange = self.selectedRange;
		
            BOOL direction = selector == @selector(moveWordRight:) || selector == @selector(moveWordRightAndModifySelection:);
            if((selectedRange.location == 0 && !direction) || (selectedRange.location+selectedRange.location+selectedRange.length == text.length && direction))
            {
                return;
            }
            
            NSMutableCharacterSet *symbolsAndPunctuation = [NSMutableCharacterSet punctuationCharacterSet];
            [symbolsAndPunctuation formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
            
            NSMutableCharacterSet *fakeWordSet = [NSMutableCharacterSet alphanumericCharacterSet];
            [fakeWordSet formUnionWithCharacterSet:symbolsAndPunctuation];
            
            NSCharacterSet *othersSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
            
            NSRange searchRange = (direction) ? NSMakeRange(selectedRange.location+selectedRange.length+1, text.length-selectedRange.location-selectedRange.length-1) : NSMakeRange(0, selectedRange.location-1);
            
            NSRange firstCharRange = (direction) ? NSMakeRange(searchRange.location-1, 1) : NSMakeRange(searchRange.location+searchRange.length, 1);
            NSString *firstChar = [text substringWithRange:firstCharRange];
            
            NSRange nextRange = NSMakeRange(NSNotFound, 0);
            if([firstChar rangeOfCharacterFromSet:fakeWordSet].location == NSNotFound)
            {
                nextRange = [text rangeOfCharacterFromSet:fakeWordSet options:(!direction) ? NSBackwardsSearch : 0 range:searchRange];
            }
            else
            {
                if([firstChar rangeOfCharacterFromSet:symbolsAndPunctuation].location != NSNotFound)
                {
                    NSMutableCharacterSet *alphanumericAndWhitespaces = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
                    [alphanumericAndWhitespaces formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
                    nextRange = [text rangeOfCharacterFromSet:alphanumericAndWhitespaces options:(!direction) ? NSBackwardsSearch : 0 range:searchRange];
                }
                else
                {
                    nextRange = [text rangeOfCharacterFromSet:othersSet options:(!direction) ? NSBackwardsSearch : 0 range:searchRange];
                }
            }
            if(nextRange.location == NSNotFound)
            {
                break;
            }
            nextRange = NSMakeRange((direction) ? nextRange.location : nextRange.location+1, 0);
            NSRange newSelection = nextRange;
            if(wordSelectionModified)
            {
                if(direction)
                {
                    newSelection = NSMakeRange(selectedRange.location, nextRange.location-selectedRange.location);
                }
                else
                {
                    newSelection = NSMakeRange(nextRange.location, selectedRange.location+selectedRange.length-nextRange.location);
                }
            }
            [self setSelectedRange:newSelection];
            [self scrollRangeToVisible:newSelection];
            
            return;
        }
        
	} while (0);
	
    return ((void (*)(id, SEL, SEL))original_doCommandBySelector)(self_, _cmd, selector);
}

+ (void) pluginDidLoad:(NSBundle *)plugin
{
    Class class = nil;
    Method originalMethod = nil;
    
    NSLog(@"%@ initializing...", NSStringFromClass([self class]));
    
    if (!(class = NSClassFromString(@"DVTSourceTextView")))
        goto failed;
    
    if (!(originalMethod = class_getInstanceMethod(class, @selector(doCommandBySelector:))))
        goto failed;
    
    if (!(original_doCommandBySelector = method_setImplementation(originalMethod, (IMP)&doCommandBySelector)))
        goto failed;
    
    NSLog(@"%@ complete!", NSStringFromClass([self class]));
    return;
    
failed:
    NSLog(@"%@ failed. :(", NSStringFromClass([self class]));
}
@end

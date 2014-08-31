#import <Cocoa/Cocoa.h>
#include <stdio.h>
#include <asl.h>

CFMachPortRef eventTap;
aslclient asl;

#define LOGEVENT(typename) else if (type == typename) asl_log(asl, NULL, ASL_LEVEL_NOTICE, #typename);

CGEventRef catchEventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* nothing) {

    // http://stackoverflow.com/questions/4727149/application-randomly-stops-receiving-key-presses-cgeventtaps
    if (type == kCGEventTapDisabledByTimeout) {
        CGEventTapEnable(eventTap, true);
    }

    if (type == kCGEventKeyDown) { /* to listen for key events, run this program as root */
        // Key number logging is dangerous so I commented it out. Use it at your own risk.
        //int key = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        asl_log(asl, NULL, ASL_LEVEL_NOTICE, "kCGEventKey");
    }
    LOGEVENT(kCGEventMouseMoved)
    LOGEVENT(kCGEventScrollWheel)
    LOGEVENT(kCGEventLeftMouseDown)
    LOGEVENT(kCGEventRightMouseDown)

    return event;
}

int main() {
    asl = asl_open(/*ident*/"macbooklog", /*facility*/"macbooklog", ASL_OPT_NO_REMOTE);

    CFRunLoopSourceRef runLoopSource;

    eventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, 0, kCGEventMaskForAllEvents, catchEventCallback, NULL);

    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);

    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);

    CGEventTapEnable(eventTap, true);

    CFRunLoopRun();

    asl_close(asl);

    return 0;
}


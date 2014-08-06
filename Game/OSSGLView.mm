//
//  OSSGLView.mm
//  Game
//
//  A custom view meant to be used as a singleton that
//  delegates user input and rendering work to game.{h,c}.
//

#import "OSSGLView.hh"

extern "C" {
#include "game.h"
#include "oswrap/oswrap.h"
}

#include <OpenGL/gl3.h>
#import <QuartzCore/CVDisplayLink.h>

#include "glm.hpp"
#define GLM_FORCE_RADIANS
#include "matrix_transform.hpp"
using namespace glm;

#include <string.h>


/*---------------------------------------------------*\
 * Internal member variables and functions.          *
\*---------------------------------------------------*/

@interface OSSGLView() {
  CFMachPortRef eventTap;
  CVDisplayLinkRef displayLink;
}

- (void)centerCursor;

@property (atomic) CGLContextObj cglContext;
@property int xWindowSize, yWindowSize;
@property bool mouseIsFree;

@end


/*---------------------------------------------------*\
 * Globals.                                          *
\*---------------------------------------------------*/

// Instance pointer; this class is used as a singleton, and this pointer
// provides access to it from C functions called as callbacks.
OSSGLView *glView = nil;


/*-----------------------------------------------------------*\
 * C-friendly mouse control functions.                       *
\*-----------------------------------------------------------*/

extern "C" void keep_mouse() {
  CGAssociateMouseAndMouseCursorPosition(NO);
  CGDisplayHideCursor(kCGDirectMainDisplay);
  glView.mouseIsFree = NO;
  [glView centerCursor];
}

extern "C" void free_mouse() {
  CGAssociateMouseAndMouseCursorPosition(YES);
  CGDisplayShowCursor(kCGDirectMainDisplay);
  glView.mouseIsFree = YES;
}


/*---------------------------------------------------*\
 * Functions.                                        *
\*---------------------------------------------------*/

// Returns any alpha key, space, or io__esc if the escape
// key code is given; otherwise returns 0.
static unichar keyFromEvent(NSEvent *event) {
  
  // TODO Move some of this functionality into oswrap (io).
  
  int escKeyCode = 53;
  if ([event keyCode] == escKeyCode) return io__esc;
  
  int delKeyCode = 51;
  if ([event keyCode] == delKeyCode) return io__delete;
  
  int tabKeyCode = 48;
  if ([event keyCode] == tabKeyCode) return io__tab;
  
  int returnKeyCode = 36;
  if ([event keyCode] == returnKeyCode) return io__return;
  
  NSString *characters = [event characters];
  if ([characters length] == 0) return nil;
  unichar character = [characters characterAtIndex:0];
  if (isalpha(character)) return toupper(character);
  return character == ' ' ? ' ' : [event keyCode];
}

CGEventRef eventCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
  
  NSRect viewFrameInScreenCoords = [[glView window] convertRectToScreen:glView.frame];
  CGPoint mousePt = CGEventGetUnflippedLocation(event);
  mousePt.x -= viewFrameInScreenCoords.origin.x;
  mousePt.y -= viewFrameInScreenCoords.origin.y;
  
  if (type == kCGEventMouseMoved) {
    if (glView.mouseIsFree) {
      game__mouse_at(mousePt.x, mousePt.y);
    } else {
      double dx = CGEventGetDoubleValueField(event, kCGMouseEventDeltaX);
      double dy = CGEventGetDoubleValueField(event, kCGMouseEventDeltaY);
      game__mouse_moved(dx, dy);
    }
  }
  
  if (type == kCGEventLeftMouseDown) {
    game__mouse_down(mousePt.x, mousePt.y);
  }
  
  return event;
}

static void runloop() {
  CGLLockContext      (glView.cglContext);
  CGLSetCurrentContext(glView.cglContext);
  
  game__main_loop();
  
  CGLFlushDrawable(glView.cglContext);
  CGLUnlockContext(glView.cglContext);
}

static CVReturn displayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now,
                                    const CVTimeStamp* outputTime, CVOptionFlags flagsIn,
                                    CVOptionFlags* flagsOut, void* displayLinkContext) {
  runloop();
  return kCVReturnSuccess;
}


/*---------------------------------------------------*\
 * OSSGLView.                                        *
\*---------------------------------------------------*/

@implementation OSSGLView

- (void)awakeFromNib {
  glView = self;
  self.mouseIsFree = YES;
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidMoveWithNote:) name:NSWindowDidMoveNotification object:nil];
  
  NSOpenGLPixelFormatAttribute attrs[] = {
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
		0
	};
  
	self.pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	if (!self.pixelFormat) NSLog(@"No OpenGL pixel format.");
  
  self.openGLContext = [[NSOpenGLContext alloc] initWithFormat:self.pixelFormat shareContext:nil];
  GLint swap = 1;
  [self.openGLContext setValues:&swap forParameter:NSOpenGLCPSwapInterval];
  
  // Useful for debugging.
  //printf("Run dir: %s\n", file__get_path("<a resource file>"));
  printf("Save dir: %s\n", file__save_dir_for_app("MyApp"));
}

- (void)reshape {
  
  // We avoid nested actions with this bool.
  static bool isReshaping = false;
  if (isReshaping) return;
  isReshaping = true;
  
  self.frame = [[[self window] contentView] bounds];
  self.xWindowSize = self.frame.size.width;
  self.yWindowSize = self.frame.size.height;
  glViewport(0, 0, self.xWindowSize, self.yWindowSize);
  
  [self centerCursor];
  
  game__resize(self.xWindowSize, self.yWindowSize);
  
  // Give loop a way to know the mouse position before any mouse events occur.
  CGPoint mousePt = [NSEvent mouseLocation];
  game__mouse_at(mousePt.x, mousePt.y);
  
  isReshaping = false;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (void)centerCursor {
  if (self.mouseIsFree) return;
  
  NSRect frame = [[self window] frame];
  frame.origin.y = NSMaxY(((NSScreen *)NSScreen.screens[0]).frame) - NSMaxY(frame);
  CGPoint centerPt = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2);
  CGWarpMouseCursorPosition(centerPt);
  
  // TODO
  //game__skip_next_mouse_move();
}

- (void)windowDidMoveWithNote:(NSNotification *)note {
  [self centerCursor];
}

- (void)prepareOpenGL {
  [super prepareOpenGL];
  [self centerCursor];
  [[self openGLContext] makeCurrentContext];
  self.cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
  
  // Input init.
  eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, kCGEventMaskForAllEvents, eventCallback, NULL);
  if (eventTap == NULL) printf("Error: eventTap creation failed.\n");
  
  CFRunLoopSourceRef runLoopEventSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
  CFRunLoopAddSource(CFRunLoopGetMain(), runLoopEventSource, kCFRunLoopDefaultMode);
  CFRelease(runLoopEventSource);
  CGEventTapEnable(eventTap, true);
    
  game__init();
  
  // Set up and activate a display link.
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
  CVDisplayLinkSetOutputCallback(displayLink, &displayLinkCallback, (__bridge void *)self);
	CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, self.cglContext, cglPixelFormat);
	CVDisplayLinkStart(displayLink);
}

// Without this, resizing the window looks bad.
- (void)drawRect:(NSRect)dirtyRect {
  runloop();
}

- (void)dealloc {
  CVDisplayLinkRelease(displayLink);
  CGEventTapEnable(eventTap, false);
  CFRelease(eventTap);
}

- (void)keyDown:(NSEvent *)event {
  // TODO This setup is non-optimal in that some key codes look like characters.
  //      Reduce decoupling to get more meaningful key code / char string pairs.
  game__key_down(keyFromEvent(event), [[event characters] UTF8String]);
}

- (void)keyUp:(NSEvent *)event {
  game__key_up(keyFromEvent(event));
}

// Detect when the shift key is up or down.
- (void)flagsChanged:(NSEvent *)event {
  static bool shift_key_is_down = NO;
  if ([event modifierFlags] & NSShiftKeyMask) {
    game__key_down(io__shift, "");
    shift_key_is_down = YES;
  } else if (shift_key_is_down) {
    game__key_up(io__shift);
  }
}

@end
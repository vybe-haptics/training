/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main window hosting all the apps speech features.
 */

#import "SpeakingTextWindow.h"
#import "SpeakingCharacterView.h"

#import <Cocoa/Cocoa.h>

// import IOKit headers
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>
#include <stdlib.h>

@interface SpeakingTextWindow ()
{
    IBOutlet NSPopUpButton *answerSelector;
    IBOutlet NSPopUpButtonCell *LevelSelector;
    IBOutlet NSTabView *levelTab;
    
    // Main window outlets
    IBOutlet NSWindow *fWindow;
    IBOutlet NSButton *fStartStopButton;
    IBOutlet NSButton *fPauseContinueButton;
    IBOutlet NSButton *fSaveAsFileButton;
    IBOutlet NSTextView *fSpokenTextView;
    
    
    // Options panel outlets
    IBOutlet NSButton *fImmediatelyRadioButton;
    IBOutlet NSButton *fAfterWordRadioButton;
    IBOutlet NSButton *fAfterSentenceRadioButton;
    IBOutlet NSPopUpButton *fVoicesPopUpButton;
    IBOutlet NSButton *fCharByCharCheckboxButton;
    IBOutlet NSButton *fDigitByDigitCheckboxButton;
    IBOutlet NSButton *fPhonemeModeCheckboxButton;
    IBOutlet NSButton *fDumpPhonemesButton;
    IBOutlet NSButton *fUseDictionaryButton;

    // Parameters panel outlets
    IBOutlet NSTextField *fRateDefaultEditableField;
    IBOutlet NSTextField *fPitchBaseDefaultEditableField;
    IBOutlet NSTextField *fPitchModDefaultEditableField;
    IBOutlet NSTextField *fVolumeDefaultEditableField;
    IBOutlet NSTextField *fRateCurrentStaticField;
    IBOutlet NSTextField *fPitchBaseCurrentStaticField;
    IBOutlet NSTextField *fPitchModCurrentStaticField;
    IBOutlet NSTextField *fVolumeCurrentStaticField;
    IBOutlet NSButton *fResetButton;

    // Callbacks panel outlets
    IBOutlet NSButton *fHandleWordCallbacksCheckboxButton;
    IBOutlet NSButton *fHandlePhonemeCallbacksCheckboxButton;
    IBOutlet NSButton *fHandleSyncCallbacksCheckboxButton;
    IBOutlet NSButton *fHandleErrorCallbacksCheckboxButton;
    IBOutlet NSButton *fHandleSpeechDoneCallbacksCheckboxButton;
    IBOutlet NSButton *fHandleTextDoneCallbacksCheckboxButton;
    IBOutlet SpeakingCharacterView *fCharacterView;
    
    //PhonemeButtons
    
    NSString *wordCurrentPhon;
    
    //Level1
    IBOutlet NSButton *fLevel1;
    IBOutlet NSButton *fLevel2;
    IBOutlet NSButton *fLevel3;
    IBOutlet NSButton *fLevel4;
    IBOutlet NSButton *fLevel5;
    IBOutlet NSButton *fLevel6;
    IBOutlet NSButton *fLevel7;
    IBOutlet NSButton *fLevel8;
    IBOutlet NSButton *fLevel9;
    IBOutlet NSButton *fwordButton;
    
    
    // Misc. instance variables
    NSRange fOrgSelectionRange;
    long fSelectedVoiceID;
    long fSelectedVoiceCreator;
    SpeechChannel fCurSpeechChannel;
    long fOffsetToSpokenText;
    unsigned long fLastErrorCode;
    BOOL fLastSpeakingValue;
    BOOL fLastPausedValue;
    BOOL fCurrentlySpeaking;
    BOOL fCurrentlyPaused;
    BOOL fSavingToFile;
    NSData *fTextData;
    NSString *fTextDataType;
    NSString *fErrorFormatString;
    NSString *phonemeToSpeak;
    NSString *wrongPhoneme;
    NSString *phonemeBeingTested;
    NSMutableDictionary *testButtons;
    int correctAnswers;
    int wrongAnswers;
    IBOutlet NSTextField *fLastAnswer;
    IBOutlet NSTextField *fAllAnswers;
    int totalAttempts;
    
    //serial example code start
    IBOutlet NSPopUpButton *serialListPullDown;
    IBOutlet NSTextView *serialOutputArea;
    IBOutlet NSTextField *serialInputField;
    IBOutlet NSTextField *baudInputField;
    int serialFileDescriptor; // file handle to the serial port
    struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
    bool readThreadRunning;
    NSTextStorage *storage;
    //serial example code end
}

//serial example code start
- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate;
- (void)appendToIncomingText: (id) text;
- (void)incomingTextUpdateThread: (NSThread *) parentThread;
- (void) refreshSerialList: (NSString *) selectedText;
- (void) writeString: (NSString *) str;
- (void) writeByte: (uint8_t *) val;
- (void) WordToPhon: (NSString *) word;
- (IBAction) serialPortSelected: (id) cntrl;
- (IBAction) baudAction: (id) cntrl;
- (IBAction) refreshAction: (id) cntrl;
- (IBAction) sendText: (id) cntrl;
- (IBAction) sliderChange: (NSSlider *) sldr;
- (IBAction) hitAButton: (NSButton *) btn;
- (IBAction) hitBButton: (NSButton *) btn;
- (IBAction) hitCButton: (NSButton *) btn;
- (IBAction) resetButton: (NSButton *) btn;
//serial example code end



- (instancetype)init;

// Getters/Setters
@property (NS_NONATOMIC_IOSONLY, copy) NSData *textData;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *textDataType;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) SpeakingCharacterView *characterView;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldDisplayWordCallbacks;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldDisplayPhonemeCallbacks;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldDisplayErrorCallbacks;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldDisplaySyncCallbacks;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldDisplaySpeechDoneCallbacks;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL shouldDisplayTextDoneCallbacks;
//@property(readonly) NSInteger indexOfSelectedItem;



@end


#pragma mark - Constants

NSString *kPlainTextDataTypeString = @"Plain Text";
NSString *kDefaultWindowTextString = @"Welcome to Cocoa Speech Synthesis Example. "
"This application provides an example of using Apple's speech synthesis technology in a Cocoa-based application.";

NSString *kWordCallbackParamPosition = @"ParamPosition";
NSString *kWordCallbackParamLength = @"ParamLength";
NSString *kErrorCallbackParamPosition = @"ParamPosition";
NSString *kErrorCallbackParamError = @"ParamError";


#pragma mark - Prototypes

static void  OurTextDoneCallBackProc(SpeechChannel	inSpeechChannel,
                                            SRefCon			inRefCon,
                                            const void **	inNextBuf,
                                            unsigned long * inByteLen,
                                            long *			inControlFlags);
static void  OurSpeechDoneCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon);
static void  OurSyncCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon, OSType inSyncMessage);
static void  OurPhonemeCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon, short inPhonemeOpcode);

static void OurErrorCFCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon, CFErrorRef inCFErrorRef);
static void OurWordCFCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon, CFStringRef inCFStringRef, CFRange inWordCFRange);


#pragma mark -

@implementation SpeakingTextWindow


// start serial example code

/*
// executes after everything in the xib/nib is initiallized
- (void)awakeFromNib {
    // we don't have a serial port open yet
    serialFileDescriptor = -1;
    readThreadRunning = FALSE;
    
    // first thing is to refresh the serial port list
    [self refreshSerialList:@"Select a Serial Port"];
    
    // now put the cursor in the text field
    [serialInputField becomeFirstResponder];
    
}*/

// open the serial port
//   - nil is returned on success
//   - an error message is returned otherwise
- (NSString *) openSerialPort: (NSString *)serialPortFile baud: (speed_t)baudRate {
    int success;
    
    // close the port if it is already open
    if (serialFileDescriptor != -1) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
        
        // wait for the reading thread to die
        while(readThreadRunning);
        
        // re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
        sleep(0.5);
    }
    
    // c-string path to serial-port file
    const char *bsdPath = [serialPortFile cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Hold the original termios attributes we are setting
    struct termios options;
    
    // receive latency ( in microseconds )
    unsigned long mics = 3;
    
    // error message string
    NSMutableString *errorMessage = nil;
    
    // open the port
    //     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
    serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
    
    if (serialFileDescriptor == -1) {
        // check if the port opened correctly
        errorMessage = @"Error: couldn't open serial port";
    } else {
        // TIOCEXCL causes blocking of non-root processes on this serial-port
        success = ioctl(serialFileDescriptor, TIOCEXCL);
        if ( success == -1) {
            errorMessage = @"Error: couldn't obtain lock on serial port";
        } else {
            success = fcntl(serialFileDescriptor, F_SETFL, 0);
            if ( success == -1) {
                // clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
                errorMessage = @"Error: couldn't obtain lock on serial port";
            } else {
                // Get the current options and save them so we can restore the default settings later.
                success = tcgetattr(serialFileDescriptor, &gOriginalTTYAttrs);
                if ( success == -1) {
                    errorMessage = @"Error: couldn't get serial attributes";
                } else {
                    // copy the old termios settings into the current
                    //   you want to do this so that you get all the control characters assigned
                    options = gOriginalTTYAttrs;
                    
                    /*
                     cfmakeraw(&options) is equivilent to:
                     options->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
                     options->c_oflag &= ~OPOST;
                     options->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
                     options->c_cflag &= ~(CSIZE | PARENB);
                     options->c_cflag |= CS8;
                     */
                    cfmakeraw(&options);
                    
                    // set tty attributes (raw-mode in this case)
                    success = tcsetattr(serialFileDescriptor, TCSANOW, &options);
                    if ( success == -1) {
                        errorMessage = @"Error: coudln't set serial attributes";
                    } else {
                        // Set baud rate (any arbitrary baud rate can be set this way)
                        success = ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
                        if ( success == -1) {
                            errorMessage = @"Error: Baud Rate out of bounds";
                        } else {
                            // Set the receive latency (a.k.a. don't wait to buffer data)
                            success = ioctl(serialFileDescriptor, IOSSDATALAT, &mics);
                            if ( success == -1) {
                                errorMessage = @"Error: coudln't set serial latency";
                            }
                        }
                    }
                }
            }
        }
    }
    
    // make sure the port is closed if a problem happens
    if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
    }
    
    return errorMessage;
}




// updates the textarea for incoming text by appending text
- (void)appendToIncomingText: (id) text {
    // add the text to the textarea
    NSAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString: text];
    NSTextStorage *textStorage = [serialOutputArea textStorage];
    [textStorage beginEditing];
    [textStorage appendAttributedString:attrString];
    [textStorage endEditing];
    //[attrString release];
    
    // scroll to the bottom
    NSRange myRange;
    myRange.length = 1;
    myRange.location = [textStorage length];
    [serialOutputArea scrollRangeToVisible:myRange];
}

// This selector/function will be called as another thread...
//  this thread will read from the serial port and exits when the port is closed
- (void)incomingTextUpdateThread: (NSThread *) parentThread {
    
    // create a pool so we can use regular Cocoa stuff
    //   child threads can't re-use the parent's autorelease pool
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    // mark that the thread is running
    readThreadRunning = TRUE;
    
    const int BUFFER_SIZE = 100;
    char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
    int numBytes=0; // number of bytes read during read
    NSString *text; // incoming text from the serial port
    
    // assign a high priority to this thread
    [NSThread setThreadPriority:1.0];
    
    // this will loop unitl the serial port closes
    while(TRUE) {
        // read() blocks until some data is available or the port is closed
        numBytes = read(serialFileDescriptor, byte_buffer, BUFFER_SIZE); // read up to the size of the buffer
        if(numBytes>0) {
            // create an NSString from the incoming bytes (the bytes aren't null terminated)
            text = [NSString stringWithCString:byte_buffer length:numBytes];
            
            // this text can't be directly sent to the text area from this thread
            //  BUT, we can call a selctor on the main thread.
            [self performSelectorOnMainThread:@selector(appendToIncomingText:)
                                   withObject:text
                                waitUntilDone:YES];
        } else {
            break; // Stop the thread if there is an error
        }
    }
    
    // make sure the serial port is closed
    if (serialFileDescriptor != -1) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
    }
    
    // mark that the thread has quit
    readThreadRunning = FALSE;
    
    // give back the pool
    //[pool release];
}

- (void) refreshSerialList: (NSString *) selectedText {
    io_object_t serialPort;
    io_iterator_t serialPortIterator;
    
    // remove everything from the pull down list
    [serialListPullDown removeAllItems];
    
    // ask for all the serial ports
    IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
    
    // loop through all the serial ports and add them to the array
    while (serialPort = IOIteratorNext(serialPortIterator)) {
        [serialListPullDown addItemWithTitle:
         (__bridge NSString*)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),  kCFAllocatorDefault, 0)];
        IOObjectRelease(serialPort);
    }
    
    // add the selected text to the top
    [serialListPullDown insertItemWithTitle:selectedText atIndex:0];
    [serialListPullDown selectItemAtIndex:0];
    
    IOObjectRelease(serialPortIterator);
}

// send a string to the serial port
- (void) writeString: (NSString *) str {
    if(serialFileDescriptor!=-1) {
        write(serialFileDescriptor, [str cStringUsingEncoding:NSUTF8StringEncoding], [str length]);
    } else {
        // make sure the user knows they should select a serial port
        [self appendToIncomingText:@"\n ERROR:  Select a Serial Port from the pull-down menu\n"];
    }
}

// send a byte to the serial port
- (void) writeByte: (uint8_t *) val {
    if(serialFileDescriptor!=-1) {
        write(serialFileDescriptor, val, 1);
    } else {
        // make sure the user knows they should select a serial port
        [self appendToIncomingText:@"\n ERROR:  Select a Serial Port from the pull-down menu\n"];
    }
}


- (IBAction)herro:(id)sender {
    NSLog(@"fuck");
}

// action sent when serial port selected
- (IBAction) serialPortSelected: (id) cntrl {
    // open the serial port
    NSString *error = [self openSerialPort: [serialListPullDown titleOfSelectedItem] baud:[baudInputField intValue]];
    
    if(error!=nil) {
        [self refreshSerialList:error];
        [self appendToIncomingText:error];
    } else {
        [self refreshSerialList:[serialListPullDown titleOfSelectedItem]];
        [self performSelectorInBackground:@selector(incomingTextUpdateThread:) withObject:[NSThread currentThread]];
    }
}

// action from baud rate change
- (IBAction) baudAction: (id) cntrl {
    if (serialFileDescriptor != -1) {
        speed_t baudRate = [baudInputField intValue];
        
        // if the new baud rate isn't possible, refresh the serial list
        //   this will also deselect the current serial port
        if(ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate)==-1) {
            [self refreshSerialList:@"Error: Baud Rate out of bounds"];
            [self appendToIncomingText:@"Error: Baud Rate out of bounds"];
        }
    }
}

// action from refresh button 
- (IBAction) refreshAction: (id) cntrl {
    [self refreshSerialList:@"Select a Serial Port"];
    
    // close serial port if open
    if (serialFileDescriptor != -1) {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
    }
}

// action from send button and on return in the text field
- (IBAction) sendText: (id) cntrl {
    // send the text to the Arduino
    [self writeString:[serialInputField stringValue]];
    
    // blank the field
    [serialInputField setTitleWithMnemonic:@""];
}

// action from send button and on return in the text field
- (IBAction) sliderChange: (NSSlider *) sldr {
    uint8_t val = [sldr intValue];
    [self writeByte:&val];
}


// action from the A button
- (IBAction) hitAButton: (NSButton *) btn {
    [self writeString:@"A"];
}

// action from the B button
- (IBAction) hitBButton: (NSButton *) btn {
    [self writeString:@"B"];
}

// action from the C button
- (IBAction) hitCButton: (NSButton *) btn {
    [self writeString:@"C"];
}

// action from the reset button
- (IBAction) resetButton: (NSButton *) btn {
    // set and clear DTR to reset an arduino
    struct timespec interval = {0,100000000}, remainder;
    if(serialFileDescriptor!=-1) {
        ioctl(serialFileDescriptor, TIOCSDTR);
        nanosleep(&interval, &remainder); // wait 0.1 seconds
        ioctl(serialFileDescriptor, TIOCCDTR);
    }
}

//end serial example code
- (void) WordToPhon: (NSString *) word {
    NSDictionary *WordToPhon = @{
                                  @"about" : @"AX",
                                  @"din" : @"d",
                                  @"bit" : @"IH",
                                  @"beet" : @"IY",
                                  @"nap" : @"n",
                                  @"ran" : @"r",
                                  @"sin" : @"s",
                                  @"tin" : @"t"
                                  };
    wordCurrentPhon = WordToPhon[word];
}


/*----------------------------------------------------------------------------------------
 init

 Set the default text of the window.
 ----------------------------------------------------------------------------------------*/
- (instancetype)init {
    self = [super init];
    if (self) {
        // set our default window text
        const char *p = [kDefaultWindowTextString UTF8String];
        [self setTextData:[NSData dataWithBytes:p length:strlen(p)]];
        [self setTextDataType:kPlainTextDataTypeString];
    }

    return (self);
} // init

/*----------------------------------------------------------------------------------------
 close

 Make sure to stop speech when closing.
 ----------------------------------------------------------------------------------------*/
- (void)close {
    [self startStopButtonPressed:fStartStopButton];
}

/*----------------------------------------------------------------------------------------
 setTextData:

 Set our text data variable and update text in window if showing.
 ----------------------------------------------------------------------------------------*/
- (void)setTextData:(NSData *)theData {
    fTextData = theData;
    // If the window is showing, update the text view.
    if (fSpokenTextView) {
        if ([[self textDataType] isEqualToString:@"RTF Document"]) {
            [fSpokenTextView replaceCharactersInRange:NSMakeRange(0, [[fSpokenTextView string] length]) withRTF:[self textData]];
        } else {
            [fSpokenTextView replaceCharactersInRange:NSMakeRange(0, [[fSpokenTextView string] length])
                                           withString:[NSString stringWithUTF8String:[[self textData] bytes]]];
        }
    }
} // setTextData

/*----------------------------------------------------------------------------------------
 textData

 Returns autoreleased copy of text data.
 ----------------------------------------------------------------------------------------*/
- (NSData *)textData {
    return ([fTextData copy]);
}

/*----------------------------------------------------------------------------------------
 setTextDataType:

 Set our text data type variable.
 ----------------------------------------------------------------------------------------*/
- (void)setTextDataType:(NSString *)theType {
    fTextDataType = theType;
} // setTextDataType

/*----------------------------------------------------------------------------------------
 textDataType

 Returns autoreleased copy of text data.
 ----------------------------------------------------------------------------------------*/
- (NSString *)textDataType {
    return ([fTextDataType copy]);
}

/*----------------------------------------------------------------------------------------
 textDataType

 Returns reference to character view for callbacks.
 ----------------------------------------------------------------------------------------*/
- (SpeakingCharacterView *)characterView {
    return (fCharacterView);
}

/*----------------------------------------------------------------------------------------
 shouldDisplayWordCallbacks

 Returns true if user has chosen to have words hightlight during synthesis.
 ----------------------------------------------------------------------------------------*/
- (BOOL)shouldDisplayWordCallbacks {
    return ([fHandleWordCallbacksCheckboxButton intValue]);
}

/*----------------------------------------------------------------------------------------
 shouldDisplayPhonemeCallbacks

 Returns true if user has chosen to the character animate phonemes during synthesis.
 ----------------------------------------------------------------------------------------*/
- (BOOL)shouldDisplayPhonemeCallbacks {
    return ([fHandlePhonemeCallbacksCheckboxButton intValue]);
}

/*----------------------------------------------------------------------------------------
 shouldDisplayErrorCallbacks

 Returns true if user has chosen to have an alert appear in response to an error callback.
 ----------------------------------------------------------------------------------------*/
- (BOOL)shouldDisplayErrorCallbacks {
    return ([fHandleErrorCallbacksCheckboxButton intValue]);
}

/*----------------------------------------------------------------------------------------
 shouldDisplaySyncCallbacks

 Returns true if user has chosen to have an alert appear in response to an sync callback.
 ----------------------------------------------------------------------------------------*/
- (BOOL)shouldDisplaySyncCallbacks {
    return ([fHandleSyncCallbacksCheckboxButton intValue]);
}

/*----------------------------------------------------------------------------------------
 shouldDisplaySpeechDoneCallbacks

 Returns true if user has chosen to have an alert appear when synthesis is finished.
 ----------------------------------------------------------------------------------------*/
- (BOOL)shouldDisplaySpeechDoneCallbacks {
    return ([fHandleSpeechDoneCallbacksCheckboxButton intValue]);
}

/*----------------------------------------------------------------------------------------
 shouldDisplayTextDoneCallbacks

 Returns true if user has chosen to have an alert appear when text processing is finished.
 ----------------------------------------------------------------------------------------*/
- (BOOL)shouldDisplayTextDoneCallbacks {
    return ([fHandleTextDoneCallbacksCheckboxButton intValue]);
}

/*----------------------------------------------------------------------------------------
 updateSpeakingControlState

 This routine is called when appropriate to update the Start/Stop Speaking,
 Pause/Continue Speaking buttons.
 ----------------------------------------------------------------------------------------*/
- (void)updateSpeakingControlState {
    // Update controls based on speaking state
    fSaveAsFileButton.enabled = !fCurrentlySpeaking;
    fPauseContinueButton.enabled = fCurrentlySpeaking;
    fStartStopButton.enabled = !fCurrentlyPaused;
    if (fCurrentlySpeaking) {
        [fStartStopButton setTitle:NSLocalizedString(@"Stop Speaking", @"Stop Speaking")];
        [fPauseContinueButton setTitle:NSLocalizedString(@"Pause Speaking", @"Pause Speaking")];
    } else {
        [fStartStopButton setTitle:NSLocalizedString(@"Start Speaking", @"Start Speaking")];
        [fSpokenTextView setSelectedRange:fOrgSelectionRange];  // Set selection length to zero.
    }
    if (fCurrentlyPaused) {
        [fPauseContinueButton setTitle:NSLocalizedString(@"Continue Speaking", @"Continue Speaking")];
    } else {
        [fPauseContinueButton setTitle:NSLocalizedString(@"Pause Speaking", @"Pause Speaking")];
    }

    [self enableOptionsForSpeakingState:fCurrentlySpeaking];

    // update parameter fields
    NSNumber *valueAsNSNumber;
    if (noErr == CopySpeechProperty(fCurSpeechChannel, kSpeechRateProperty, (void *)&valueAsNSNumber)) {
        [fRateCurrentStaticField setDoubleValue:[valueAsNSNumber doubleValue]];
    }
    if (noErr == CopySpeechProperty(fCurSpeechChannel, kSpeechPitchBaseProperty, (void *)&valueAsNSNumber)) {
        [fPitchBaseCurrentStaticField setDoubleValue:[valueAsNSNumber doubleValue]];
    }
    if (noErr == CopySpeechProperty(fCurSpeechChannel, kSpeechPitchModProperty, (void *)&valueAsNSNumber)) {
        [fPitchModCurrentStaticField setDoubleValue:[valueAsNSNumber doubleValue]];
    }
    if (noErr == CopySpeechProperty(fCurSpeechChannel, kSpeechVolumeProperty, (void *)&valueAsNSNumber)) {
        [fVolumeCurrentStaticField setDoubleValue:[valueAsNSNumber doubleValue]];
    }
} // updateSpeakingControlState

/*----------------------------------------------------------------------------------------
 highlightWordWithParams:

 Highlights the word currently being spoken based on text position and text length
 provided in the word callback routine.
 ----------------------------------------------------------------------------------------*/
- (void)highlightWordWithParams:(NSDictionary *)params {
    UInt32 selectionPosition = [params[kWordCallbackParamPosition] longValue] + fOffsetToSpokenText;
    UInt32 wordLength = [params[kWordCallbackParamLength] longValue];

    [fSpokenTextView scrollRangeToVisible:NSMakeRange(selectionPosition, wordLength)];
    [fSpokenTextView setSelectedRange:NSMakeRange(selectionPosition, wordLength)];
    [fSpokenTextView display];
} // highlightWordWithParams

/*----------------------------------------------------------------------------------------
 displayErrorAlertWithParams:

 Displays an alert describing a text processing error provided in the error callback.
 ----------------------------------------------------------------------------------------*/
- (void)displayErrorAlertWithParams:(NSDictionary *)params {
    UInt32 errorPosition = [params[kErrorCallbackParamPosition] longValue] + fOffsetToSpokenText;
    UInt32 errorCode = [params[kErrorCallbackParamError] longValue];

    if (errorCode != fLastErrorCode) {
        OSErr theErr = noErr;
        NSString *theMessageStr = NULL;

        // Tell engine to pause while we display this dialog.
        theErr = PauseSpeechAt(fCurSpeechChannel, kImmediate);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"PauseSpeechAt"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }

        // Select offending character
        [fSpokenTextView setSelectedRange:NSMakeRange(errorPosition, 1)];
        [fSpokenTextView display];

        // Display error alert, and stop or continue based on user's desires
        NSString * messageFormat = NSLocalizedString(@"Error #%ld occurred at position %ld in the text.",
                                                     @"Error #%ld occurred at position %ld in the text.");
        theMessageStr = [NSString stringWithFormat:messageFormat,
                         (long) errorCode, (long) errorPosition];
        NSModalResponse response = [self runAlertPanelWithTitle:@"Text Processing Error"
                                                      message:theMessageStr
                                                   buttonTitles:@[@"Stop", @"Continue"]];
        if (NSAlertFirstButtonReturn == response) {
            [self startStopButtonPressed:fStartStopButton];
        } else {
            theErr = ContinueSpeech(fCurSpeechChannel);
            if (noErr != theErr) {
                [self runAlertPanelWithTitle:@"ContinueSpeech"
                                     message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                                buttonTitles:@[@"Oh?"]];
            }
        }

        fLastErrorCode = errorCode;
    }
} // displayErrorAlertWithParams

/*----------------------------------------------------------------------------------------
 displaySyncAlertWithMessage:

 Displays an alert with information about a sync command in response to a sync callback.
 ----------------------------------------------------------------------------------------*/
- (void)displaySyncAlertWithMessage:(NSNumber *)messageNumber {
    OSErr theErr = noErr;
    NSString *theMessageStr = NULL;

    // Tell engine to pause while we display this dialog.
    theErr = PauseSpeechAt(fCurSpeechChannel, kImmediate);
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"PauseSpeechAt"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    }

    // Display error alert and stop or continue based on user's desires
    UInt32 theMessageValue = [messageNumber longValue];
    NSString * messageFormat = NSLocalizedString(@"Sync embedded command was discovered containing message %ld ('%4s').",
                                                 @"Sync embedded command was discovered containing message %ld ('%4s').");
    theMessageStr = [NSString stringWithFormat:messageFormat,
                     (long) theMessageValue, (char *) &theMessageValue];

    NSInteger alertButtonClicked =
    [self runAlertPanelWithTitle:@"Sync Callback" message:theMessageStr buttonTitles:@[@"Stop", @"Continue"]];
    if (alertButtonClicked == 1) {
        [self startStopButtonPressed:fStartStopButton];
    } else {
        theErr = ContinueSpeech(fCurSpeechChannel);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"ContinueSpeech"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }
} // displaySyncAlertWithMessage

/*----------------------------------------------------------------------------------------
 speechIsDone

 Updates user interface and optionally displays an alert when generation of speech is
 finish.
 ----------------------------------------------------------------------------------------*/
- (void)speechIsDone {
    fCurrentlySpeaking = NO;
    [self updateSpeakingControlState];
    [self enableCallbackControlsBasedOnSavingToFileFlag:NO];
    if ([self shouldDisplaySpeechDoneCallbacks]) {
        [self runAlertPanelWithTitle:@"Speech Done"
                             message:@"Generation of synthesized speech is finished."
                        buttonTitles:@[@"OK"]];
    }
} // speechIsDone

/*----------------------------------------------------------------------------------------
 displayTextDoneAlert

 Displays an alert in response to a text done callback.
 ----------------------------------------------------------------------------------------*/
- (void)displayTextDoneAlert {
    OSErr theErr = noErr;

    // Tell engine to pause while we display this dialog.
    theErr = PauseSpeechAt(fCurSpeechChannel, kImmediate);
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"PauseSpeechAt"
                             message:@"Generation of synthesized speech is finished."
                        buttonTitles:@[@"OK"]];
    }

    // Display error alert, and stop or continue based on user's desires
    NSModalResponse response = [self runAlertPanelWithTitle:@"Text Done Callback"
                                                    message:@"Processing of the text has completed."
                                               buttonTitles:@[@"Stop", @"Continue"]];
    if (NSAlertFirstButtonReturn == response) {
        [self startStopButtonPressed:fStartStopButton];
    } else {
        theErr = ContinueSpeech(fCurSpeechChannel);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"ContinueSpeech"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }
} // displayTextDoneAlert

/*----------------------------------------------------------------------------------------
 startStopButtonPressed:

 An action method called when the user clicks the "Start Speaking"/"Stop Speaking"
 button.	 We either start or stop speaking based on the current speaking state.
 ----------------------------------------------------------------------------------------*/
- (IBAction)startStopButtonPressed:(id)sender {
    OSErr theErr = noErr;

    if (fCurrentlySpeaking) {
        long whereToStop;

        // Grab where to stop at value from radio buttons
        if ([fAfterWordRadioButton intValue]) {
            whereToStop = kEndOfWord;
        } else if ([fAfterSentenceRadioButton intValue]) {
            whereToStop = kEndOfSentence;
        } else {
            whereToStop = kImmediate;
        }
        if (whereToStop == kImmediate) {
            // NOTE:	We could just call StopSpeechAt with kImmediate, but for test purposes
            // we exercise the StopSpeech routine.
            theErr = StopSpeech(fCurSpeechChannel);
            if (noErr != theErr) {
                [self runAlertPanelWithTitle:@"StopSpeech"
                                     message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                                buttonTitles:@[@"Oh?"]];
            }
        } else {
            theErr = StopSpeechAt(fCurSpeechChannel, whereToStop);
            if (noErr != theErr) {
                [self runAlertPanelWithTitle:@"StopSpeechAt"
                                     message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                                buttonTitles:@[@"Oh?"]];
            }
        }

        fCurrentlySpeaking = NO;
        [self updateSpeakingControlState];
    } else {
        [self startSpeakingTextViewToURL:NULL];
    }
} // startStopButtonPressed

/*----------------------------------------------------------------------------------------
 saveAsButtonPressed:

 An action method called when the user clicks the "Save As File" button.	 We ask user
 to specify where to save the file, then start speaking to this file.
 ----------------------------------------------------------------------------------------*/
- (IBAction)saveAsButtonPressed:(id)sender {
    NSURL *selectedFileURL = NULL;

    NSSavePanel *theSavePanel = [NSSavePanel savePanel];

    [theSavePanel setPrompt:NSLocalizedString(@"Save", @"Save")];
    [theSavePanel setNameFieldStringValue:@"Synthesized Speech.aiff"];
    if (NSFileHandlingPanelOKButton == [theSavePanel runModal]) {
        selectedFileURL = [theSavePanel URL];
        [self startSpeakingTextViewToURL:selectedFileURL];
    }
} // saveAsButtonPressed

/*----------------------------------------------------------------------------------------
 startSpeakingTextViewToURL:

 This method sets up the speech channel and begins the speech synthesis
 process, optionally speaking to a file instead playing through the speakers.
 ----------------------------------------------------------------------------------------*/
- (void)startSpeakingTextViewToURL:(NSURL *)url {
    OSErr theErr = noErr;
    NSString *theViewText;

    // Grab the selection substring, or if no selection then grab entire text.
    fOrgSelectionRange = [fSpokenTextView selectedRange];
    if (!fOrgSelectionRange.length) {
        theViewText = [fSpokenTextView string];
        fOffsetToSpokenText = 0;
    } else {
        theViewText = [[fSpokenTextView string] substringWithRange:fOrgSelectionRange];
        fOffsetToSpokenText = fOrgSelectionRange.location;
    }

    // Setup our callbacks
    fSavingToFile = (url != NULL);
    if (noErr == theErr) {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechErrorCFCallBack,
                                   (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurErrorCFCallBackProc)));
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechErrorCFCallBack)"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }
    if (noErr == theErr) {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechPhonemeCallBack,
                                   (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurPhonemeCallBackProc)));
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechPhonemeCallBack)"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }
    if (noErr == theErr) {
        theErr = SetSpeechProperty(fCurSpeechChannel,
                                   kSpeechSpeechDoneCallBack,
                                   (__bridge CFTypeRef)(@((long)OurSpeechDoneCallBackProc)));
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechSpeechDoneCallBack)"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }
    if (noErr == theErr) {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechSyncCallBack,
                                   (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurSyncCallBackProc)));
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechSyncCallBack)"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }
    if (noErr == theErr) {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechTextDoneCallBack,
                                   (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurTextDoneCallBackProc)));
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechTextDoneCallBack)"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }
    if (noErr == theErr) {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechWordCFCallBack,
                                   (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurWordCFCallBackProc)));
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechWordCFCallBack)"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }

    // Set URL to save file to disk
    SetSpeechProperty(fCurSpeechChannel, kSpeechOutputToFileURLProperty, (__bridge CFTypeRef)(url));

    // Convert NSString to cString.
    // We want the text view the active view.  Also saves any parameters currently being edited.
    [fWindow makeFirstResponder:fSpokenTextView];

    theErr = SpeakCFString(fCurSpeechChannel, (__bridge CFStringRef)theViewText, NULL);
    if (noErr == theErr) {
        // Update our vars
        fLastErrorCode = 0;
        fLastSpeakingValue = NO;
        fLastPausedValue = NO;
        fCurrentlySpeaking = YES;
        fCurrentlyPaused = NO;
        [self updateSpeakingControlState];
    } else {
        [self runAlertPanelWithTitle:@"SpeakText"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    }

    [self enableCallbackControlsBasedOnSavingToFileFlag:fSavingToFile];
} // startSpeakingTextViewToURL

/*----------------------------------------------------------------------------------------
 pauseContinueButtonPressed:

 An action method called when the user clicks the "Pause Speaking"/"Continue Speaking"
 button.	 We either pause or continue speaking based on the current speaking state.
 ----------------------------------------------------------------------------------------*/
- (IBAction)pauseContinueButtonPressed:(id)sender {
    OSErr theErr = noErr;

    if (fCurrentlyPaused) {
        // We want the text view the active view.  Also saves any parameters currently being edited.
        [fWindow makeFirstResponder:fSpokenTextView];

        theErr = ContinueSpeech(fCurSpeechChannel);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"ContinueSpeech"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }

        fCurrentlyPaused = NO;
        [self updateSpeakingControlState];
    } else {
        long whereToPause;

        // Figure out where to stop from radio buttons
        if ([fAfterWordRadioButton intValue]) {
            whereToPause = kEndOfWord;
        } else if ([fAfterSentenceRadioButton intValue]) {
            whereToPause = kEndOfSentence;
        } else {
            whereToPause = kImmediate;
        }

        theErr = PauseSpeechAt(fCurSpeechChannel, whereToPause);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"PauseSpeechAt"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }

        fCurrentlyPaused = YES;
        [self updateSpeakingControlState];
    }
} // pauseContinueButtonPressed




- (IBAction)LevelPopupSelected:(id)sender {

    
            fwordButton.enabled = ![LevelSelector indexOfSelectedItem]>=1;

        }


//    if([LevelSelector indexOfSelectedItem]>=2)
//    {
//        [[fLevel2 self] setEnabled:YES];
//    }
//    if([LevelSelector indexOfSelectedItem]>=3)
//    {
//        [[fLevel3 self] setEnabled:YES];
//    }
//    if([LevelSelector indexOfSelectedItem]>=4)
//    {
//        [[fLevel4 self] setEnabled:YES];
//    }
//    if([LevelSelector indexOfSelectedItem]>=5)
//    {
//        [[fLevel5 self] setEnabled:YES];
//    }
//    if([LevelSelector indexOfSelectedItem]>=6)
//    {
//        [[fLevel6 self] setEnabled:YES];
//    }
//    if([LevelSelector indexOfSelectedItem]>=7)
//    {
//        [[fLevel7 self] setEnabled:YES];
//    }
//    if([LevelSelector indexOfSelectedItem]>=8)
//    {
//        [[fLevel8 self] setEnabled:YES];
//    }
//    if([LevelSelector indexOfSelectedItem]>=8)
//    {
//        [[fLevel8 self] setEnabled:YES];
//    }



/*----------------------------------------------------------------------------------------
 voicePopupSelected:

 An action method called when the user selects a new voice from the Voices pop-up
 menu.  We ask the speech channel to use the selected voice.	 If the current
 speech channel cannot use the selected voice, we close and open new speech
 channel with the selecte voice.
 ----------------------------------------------------------------------------------------*/
- (IBAction)voicePopupSelected:(id)sender {
    OSErr theErr = noErr;
    long theSelectedMenuIndex = [sender indexOfSelectedItem];

    if (!theSelectedMenuIndex) {
        // Use the default voice from preferences.
        // Our only choice is to close and reopen the speech channel to get the default voice.
        fSelectedVoiceCreator = 0;
        theErr = [self createNewSpeechChannel:NULL];
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"createNewSpeechChannel"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    } else {
        // Use the voice the user selected.
        VoiceSpec theVoiceSpec;
        theErr = GetIndVoice([sender indexOfSelectedItem] - 1, &theVoiceSpec);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"GetIndVoice"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
        if (noErr == theErr) {
            // Update our object fields with the selection
            fSelectedVoiceCreator = theVoiceSpec.creator;
            fSelectedVoiceID = theVoiceSpec.id;

            // Change the current voice.  If it needs another engine, then dispose the current channel and open another
            NSDictionary *voiceDict = @{(__bridge NSString *)kSpeechVoiceID:@(fSelectedVoiceID),
                                        (__bridge NSString *)kSpeechVoiceCreator:@(fSelectedVoiceCreator)};

            theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechCurrentVoiceProperty, (__bridge CFDictionaryRef) voiceDict);
            if (incompatibleVoice == theErr) {
                theErr = [self createNewSpeechChannel:&theVoiceSpec];
                if (noErr != theErr) {
                    [self runAlertPanelWithTitle:@"createNewSpeechChannel"
                                         message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                                    buttonTitles:@[@"Oh?"]];
                }
            } else if (noErr != theErr) {
                [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechCurrentVoiceProperty"
                                     message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                                buttonTitles:@[@"Oh?"]];
            }
        }
    }
    // Set editable default fields
    if (fCurSpeechChannel) {
        [self fillInEditableParameterFields];
    }
} // voicePopupSelected

/*----------------------------------------------------------------------------------------
 charByCharCheckboxSelected:

 An action method called when the user checks/unchecks the Character-By-Character
 mode checkbox.	We tell the speech channel to use this setting.
 ----------------------------------------------------------------------------------------*/
- (IBAction)charByCharCheckboxSelected:(id)sender {
    OSErr theErr = noErr;

    if ([fCharByCharCheckboxButton intValue]) {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechCharacterModeProperty, kSpeechModeLiteral);
    } else {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechCharacterModeProperty, kSpeechModeNormal);
    }
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechCharacterModeProperty)"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    }
} // charByCharCheckboxSelected

/*----------------------------------------------------------------------------------------
 digitByDigitCheckboxSelected:

 An action method called when the user checks/unchecks the Digit-By-Digit
 mode checkbox.	We tell the speech channel to use this setting.
 ----------------------------------------------------------------------------------------*/
- (IBAction)digitByDigitCheckboxSelected:(id)sender {
    OSErr theErr = noErr;

    if ([fDigitByDigitCheckboxButton intValue]) {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechNumberModeProperty, kSpeechModeLiteral);
    } else {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechNumberModeProperty, kSpeechModeNormal);
    }
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechNumberModeProperty)"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    }
} // digitByDigitCheckboxSelected

/*----------------------------------------------------------------------------------------
 phonemeModeCheckboxSelected:

 An action method called when the user checks/unchecks the Phoneme input
 mode checkbox.	We tell the speech channel to use this setting.
 ----------------------------------------------------------------------------------------*/
- (IBAction)phonemeModeCheckboxSelected:(id)sender {
    OSErr theErr = noErr;

    if ([fPhonemeModeCheckboxButton intValue]) {
#if 1
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechInputModeProperty, kSpeechModePhoneme);
#else
        OSType	theMode = modePhonemes;
        theErr = SetSpeechInfo(fCurSpeechChannel, soInputMode, &theMode);
#endif
    } else {
#if 1
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechInputModeProperty, kSpeechModeText);
#else
        OSType	theMode = modeText;
        theErr = SetSpeechInfo(fCurSpeechChannel, soInputMode, &theMode);
#endif
    }
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechInputModeProperty)"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    }
} // phonemeModeCheckboxSelected

/*----------------------------------------------------------------------------------------
 dumpPhonemesSelected:

 An action method called when the user clicks the Dump Phonemes button.	We ask
 the speech channel for a phoneme representation of the window text then save the
 result to a text file at a location determined by the user.
 ----------------------------------------------------------------------------------------*/
- (IBAction)dumpPhonemesSelected:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];

    if ([panel runModal] && [panel URL]) {
        // Get and speech text
        CFStringRef phonemesCFStringRef;
        OSErr theErr = CopyPhonemesFromText(fCurSpeechChannel, (__bridge CFStringRef)[fSpokenTextView string], &phonemesCFStringRef);
        if (noErr == theErr) {
            NSString *phonemesString = (__bridge NSString *)((CFStringRef) phonemesCFStringRef);
            NSError *nsError;
            if (![phonemesString writeToURL:[panel URL] atomically:YES encoding:NSUTF8StringEncoding error:&nsError]) {
                NSString * messageFormat = NSLocalizedString(@"writeToURL: '%@' error: %@",
                                                             @"writeToURL: '%@' error: %@");
                [self runAlertPanelWithTitle:@"CopyPhonemesFromText"
                                     message:[NSString stringWithFormat:messageFormat, [panel URL], nsError]
                                buttonTitles:@[@"Oh?"]];
            }
        } else {
            [self runAlertPanelWithTitle:@"CopyPhonemesFromText"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
        if (phonemesCFStringRef) {
            CFRelease(phonemesCFStringRef);
        }
    }
} // dumpPhonemesSelected

/*----------------------------------------------------------------------------------------
 useDictionarySelected:

 An action method called when the user clicks the "Use Dictionary…" button.
 ----------------------------------------------------------------------------------------*/
- (IBAction)useDictionarySelected:(id)sender {
    // Open file.
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    panel.message = @"Choose a dictionary file";
    panel.allowedFileTypes = @[@"xml", @"plist"];
    
    [panel setAllowsMultipleSelection:YES];
    
    if ([panel runModal]) {
        for (NSURL *fileURL in[panel URLs]) {
            // Read dictionary file into NSData object.
            NSDictionary *speechDictionary = [NSDictionary dictionaryWithContentsOfURL:fileURL];
            if (speechDictionary) {
                OSErr theErr = UseSpeechDictionary(fCurSpeechChannel, (__bridge CFDictionaryRef) speechDictionary);
                if (noErr != theErr) {
                    [self runAlertPanelWithTitle:@"UseSpeechDictionary"
                                         message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                                    buttonTitles:@[@"Oh?"]];
                }
            } else {
                NSString * messageFormat = NSLocalizedString(@"dictionaryWithContentsOfURL:'%@' returned NULL",
                                                       @"dictionaryWithContentsOfURL:'%@' returned NULL");
                [self runAlertPanelWithTitle:@"TextToPhonemes"
                                     message:[NSString stringWithFormat:messageFormat, [fileURL path]]
                                buttonTitles:@[@"Oh?"]];
            }
        }                               // next fileURL in [panel URLs]
    }
} // useDictionarySelected

/*----------------------------------------------------------------------------------------
 rateChanged:

 An action method called when the user changes the rate field.  We tell the speech
 channel to use this setting.
 ----------------------------------------------------------------------------------------*/
- (IBAction)rateChanged:(id)sender {
    OSErr theErr = SetSpeechProperty(fCurSpeechChannel,
                                     kSpeechRateProperty,
                                     (__bridge CFTypeRef)(@([fRateDefaultEditableField doubleValue])));
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"SetSpeechRate"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    } else {
        [fRateCurrentStaticField setDoubleValue:[fRateDefaultEditableField doubleValue]];
    }
} // rateChanged

/*----------------------------------------------------------------------------------------
 pitchBaseChanged:

 An action method called when the user changes the pitch base field.	 We tell the speech
 channel to use this setting.
 ----------------------------------------------------------------------------------------*/
- (IBAction)pitchBaseChanged:(id)sender {
    OSErr theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechPitchBaseProperty,
                                     (__bridge CFTypeRef)(@([fPitchBaseDefaultEditableField doubleValue])));
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"SetSpeechPitch"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    } else {
        [fPitchBaseCurrentStaticField setDoubleValue:[fPitchBaseDefaultEditableField doubleValue]];
    }
} // pitchBaseChanged

/*----------------------------------------------------------------------------------------
 pitchModChanged:

 An action method called when the user changes the pitch modulation field.  We tell
 the speech channel to use this setting.
 ----------------------------------------------------------------------------------------*/
- (IBAction)pitchModChanged:(id)sender {
    OSErr theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechPitchModProperty,
                                     (__bridge CFTypeRef)(@([fPitchModDefaultEditableField doubleValue])));
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechPitchModProperty)"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    } else {
        [fPitchModCurrentStaticField setDoubleValue:[fPitchModDefaultEditableField doubleValue]];
    }
} // pitchModChanged

/*----------------------------------------------------------------------------------------
 volumeChanged:

 An action method called when the user changes the volume field.	 We tell
 the speech channel to use this setting.
 ----------------------------------------------------------------------------------------*/
- (IBAction)volumeChanged:(id)sender {
    OSErr theErr = SetSpeechProperty(fCurSpeechChannel,
                                     kSpeechVolumeProperty,
                                     (__bridge CFTypeRef)(@([fVolumeDefaultEditableField doubleValue])));
    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechVolumeProperty)"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    } else {
        [fVolumeCurrentStaticField setDoubleValue:[fVolumeDefaultEditableField doubleValue]];
    }
} // volumeChanged

/*----------------------------------------------------------------------------------------
 resetSelected:

 An action method called when the user clicks the Use Defaults button.  We tell
 the speech channel to use this the default settings.
 ----------------------------------------------------------------------------------------*/
- (IBAction)resetSelected:(id)sender {
    OSErr theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechResetProperty, NULL);

    [self fillInEditableParameterFields];

    if (noErr != theErr) {
        [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechResetProperty)"
                             message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                        buttonTitles:@[@"Oh?"]];
    }
} // resetSelected

- (IBAction)wordCallbacksButtonPressed:(id)sender {
    if (![fHandleWordCallbacksCheckboxButton intValue]) {
        [fSpokenTextView setSelectedRange:fOrgSelectionRange];
    }
} // wordCallbacksButtonPressed

- (IBAction)phonemeCallbacksButtonPressed:(id)sender {
    if ([fHandlePhonemeCallbacksCheckboxButton intValue]) {
        [fCharacterView setExpression:kCharacterExpressionIdentifierIdle];
    } else {
        [fCharacterView setExpression:kCharacterExpressionIdentifierSleep];
    }
} // phonemeCallbacksButtonPressed

/*----------------------------------------------------------------------------------------
 enableOptionsForSpeakingState:

 Updates controls in the Option tab panel based on the passed speakingNow flag.
 ----------------------------------------------------------------------------------------*/
- (void)enableOptionsForSpeakingState:(BOOL)speakingNow {
    fVoicesPopUpButton.enabled = !speakingNow;
    fCharByCharCheckboxButton.enabled = !speakingNow;
    fDigitByDigitCheckboxButton.enabled = !speakingNow;
    fPhonemeModeCheckboxButton.enabled = !speakingNow;
    fDumpPhonemesButton.enabled = !speakingNow;
    fUseDictionaryButton.enabled = !speakingNow;
} // enableOptionsForSpeakingState

/*----------------------------------------------------------------------------------------
 enableCallbackControlsForSavingToFile:

 Updates controls in the Callback tab panel based on the passed savingToFile flag.
 ----------------------------------------------------------------------------------------*/
- (void)enableCallbackControlsBasedOnSavingToFileFlag:(BOOL)savingToFile {
    fHandleWordCallbacksCheckboxButton.enabled = !savingToFile;
    fHandlePhonemeCallbacksCheckboxButton.enabled = !savingToFile;
    fHandleSyncCallbacksCheckboxButton.enabled = !savingToFile;
    fHandleErrorCallbacksCheckboxButton.enabled = !savingToFile;
    fHandleTextDoneCallbacksCheckboxButton.enabled = !savingToFile;
    if (savingToFile || (![fHandlePhonemeCallbacksCheckboxButton intValue])) {
        [fCharacterView setExpression:kCharacterExpressionIdentifierSleep];
    } else {
        [fCharacterView setExpression:kCharacterExpressionIdentifierIdle];
    }
} // enableCallbackControlsBasedOnSavingToFileFlag

/*----------------------------------------------------------------------------------------
 fillInEditableParameterFields

 Updates "Current" fields in the Parameters tab panel based on the current state of the
 speech channel.
 ----------------------------------------------------------------------------------------*/
- (void)fillInEditableParameterFields {
    double tempDoubleValue = 0.0;
    NSNumber *tempNSNumber = NULL;

    CopySpeechProperty(fCurSpeechChannel, kSpeechRateProperty, (void *)&tempNSNumber);
    tempDoubleValue = [tempNSNumber doubleValue];

    [fRateDefaultEditableField setDoubleValue:tempDoubleValue];
    [fRateCurrentStaticField setDoubleValue:tempDoubleValue];

    CopySpeechProperty(fCurSpeechChannel, kSpeechPitchBaseProperty, (void *)&tempNSNumber);
    tempDoubleValue = [tempNSNumber doubleValue];
    [fPitchBaseDefaultEditableField setDoubleValue:tempDoubleValue];
    [fPitchBaseCurrentStaticField setDoubleValue:tempDoubleValue];

    CopySpeechProperty(fCurSpeechChannel, kSpeechPitchModProperty, (void *)&tempNSNumber);
    tempDoubleValue = [tempNSNumber doubleValue];
    [fPitchModDefaultEditableField setDoubleValue:tempDoubleValue];
    [fPitchModCurrentStaticField setDoubleValue:tempDoubleValue];

    CopySpeechProperty(fCurSpeechChannel, kSpeechVolumeProperty, (void *)&tempNSNumber);
    tempDoubleValue = [tempNSNumber doubleValue];
    [fVolumeDefaultEditableField setDoubleValue:tempDoubleValue];
    [fVolumeCurrentStaticField setDoubleValue:tempDoubleValue];
} // fillInEditableParameterFields

/*----------------------------------------------------------------------------------------
 createNewSpeechChannel:

 Create a new speech channel for the given voice spec.  A nil voice spec pointer
 causes the speech channel to use the default voice.	 Any existing speech channel
 for this window is closed first.
 ----------------------------------------------------------------------------------------*/
- (OSErr)createNewSpeechChannel:(VoiceSpec *)voiceSpec {
    OSErr theErr = noErr;

    // Dispose of the current one, if present.
    if (fCurSpeechChannel) {
        theErr = DisposeSpeechChannel(fCurSpeechChannel);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"DisposeSpeechChannel"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }

        fCurSpeechChannel = NULL;
    }
    // Create a speech channel
    if (noErr == theErr) {
        theErr = NewSpeechChannel(voiceSpec, &fCurSpeechChannel);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"NewSpeechChannel"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }
    // Setup our refcon to the document controller object so we have access within our Speech callbacks
    if (noErr == theErr) {
        theErr = SetSpeechProperty(fCurSpeechChannel, kSpeechRefConProperty, (__bridge CFTypeRef)(@((long)self)));
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"SetSpeechProperty(kSpeechRefConProperty)"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
    }

    return (theErr);
} // createNewSpeechChannel


#pragma mark - Window

/*----------------------------------------------------------------------------------------
 awakeFromNib
 
 This routine is call once right after our nib file is loaded.  We build our voices
 pop-up menu, create a new speech channel and update our window using parameters from
 the new speech channel.
 ----------------------------------------------------------------------------------------*/
- (void)awakeFromNib {
    
  //  [[wordButton self ] setEnabled:NO];

    

    
    //serial example code start
    // we don't have a serial port open yet
    serialFileDescriptor = -1;
    readThreadRunning = FALSE;
    correctAnswers = 0;
    wrongAnswers = 0;
    
    // first thing is to refresh the serial port list
    [self refreshSerialList:@"Select a Serial Port"];
    
    // now put the cursor in the text field
    [serialInputField becomeFirstResponder];
    //serial example code end
    
    
    
    OSErr theErr = noErr;
    
    fErrorFormatString = NSLocalizedString(@"Error #%d (0x%0X) returned.", @"Error #%d (0x%0X) returned.");
    // Build the Voices pop-up menu
    {
        short numOfVoices;
        long voiceIndex;
        BOOL voiceFoundAndSelected = NO;
        VoiceSpec theVoiceSpec;
        
        // Delete the existing voices from the bottom of the menu.
        while ([fVoicesPopUpButton numberOfItems] > 2) {
            [fVoicesPopUpButton removeItemAtIndex:2];
        }
        
        // Ask TTS API for each available voicez
        theErr = CountVoices(&numOfVoices);
        if (noErr != theErr) {
            [self runAlertPanelWithTitle:@"CountVoices"
                                 message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                            buttonTitles:@[@"Oh?"]];
        }
        if (noErr == theErr) {
            for (voiceIndex = 1; voiceIndex <= numOfVoices; voiceIndex++) {
                VoiceDescription theVoiceDesc;
                theErr = GetIndVoice(voiceIndex, &theVoiceSpec);
                if (noErr != theErr) {
                    [self runAlertPanelWithTitle:@"GetIndVoice"
                                         message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                                    buttonTitles:@[@"Oh?"]];
                }
                if (noErr == theErr) {
                    theErr = GetVoiceDescription(&theVoiceSpec, &theVoiceDesc, sizeof(theVoiceDesc));
                }
                if (noErr != theErr) {
                    [self runAlertPanelWithTitle:@"GetVoiceDescription"
                                         message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
                                    buttonTitles:@[@"Oh?"]];
                }
                if (noErr == theErr) {
                    // Get voice name and add it to the menu list
                    NSString *theNameString = @((char *) &(theVoiceDesc.name[1]));
                    [fVoicesPopUpButton addItemWithTitle:theNameString];
                    // Selected this item if it matches our default voice spec.
                    if ((theVoiceSpec.creator == fSelectedVoiceCreator) && (theVoiceSpec.id == fSelectedVoiceID)) {
                        [fVoicesPopUpButton selectItemAtIndex:voiceIndex - 1];
                        voiceFoundAndSelected = YES;
                    }
                }
            }
            // User preference default if problems.
            if (!voiceFoundAndSelected && (numOfVoices >= 1)) {
                // Update our object fields with the first voice
                fSelectedVoiceCreator = 0;
                fSelectedVoiceID = 0;
                
                [fVoicesPopUpButton selectItemAtIndex:0];
            }
        } else {
            [fVoicesPopUpButton selectItemAtIndex:0];
        }
    }
    
    // Create Speech Channel configured with our desired options and callbacks
    [self createNewSpeechChannel:NULL];
    
    // Set editable default fields
    [self fillInEditableParameterFields];
    
    // Enable buttons appropriatelly
    fStartStopButton.enabled = YES;
    fPauseContinueButton.enabled = NO;
    fSaveAsFileButton.enabled = YES;
    
    // Set starting expresison on animated character
    [self phonemeCallbacksButtonPressed:fHandlePhonemeCallbacksCheckboxButton];
} // awakeFromNib

/*----------------------------------------------------------------------------------------
 windowNibName

 Part of the NSDocument support. Called by NSDocument to return the nib file name of
 the document.
 ----------------------------------------------------------------------------------------*/
- (NSString *)windowNibName {
    return (@"SpeakingTextWindow");
}

/*----------------------------------------------------------------------------------------
 windowControllerDidLoadNib:

 Part of the NSDocument support. Called by NSDocument after the nib has been loaded
 to udpate window as appropriate.
 ----------------------------------------------------------------------------------------*/
- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Update the window text from data
    if ([[self textDataType] isEqualToString:@"RTF Document"]) {
        [fSpokenTextView replaceCharactersInRange:NSMakeRange(0, [[fSpokenTextView string] length]) withRTF:[self textData]];
    } else {
        [fSpokenTextView replaceCharactersInRange:NSMakeRange(0,
                                                              [[fSpokenTextView string] length])
                                       withString:[NSString stringWithUTF8String:[[self textData] bytes]]];
    }
} // windowControllerDidLoadNib


#pragma mark - NSDocument

/*----------------------------------------------------------------------------------------
 dataRepresentationOfType:

 Part of the NSDocument support. Called by NSDocument to wrote the document.
 ----------------------------------------------------------------------------------------*/
- (NSData *)dataRepresentationOfType:(NSString *)aType {
    // Write text to file.
    if ([aType isEqualToString:@"RTF Document"]) {
        [self setTextData:[fSpokenTextView RTFFromRange:NSMakeRange(0, [[fSpokenTextView string] length])]];
    } else {
        [self setTextData:[NSData dataWithBytes:[[fSpokenTextView string] cString] length:[[fSpokenTextView string] cStringLength]]];
    }

    return ([self textData]);
} // dataRepresentationOfType

/*----------------------------------------------------------------------------------------
 loadDataRepresentation: ofType:

 Part of the NSDocument support. Called by NSDocument to read the document.
 ----------------------------------------------------------------------------------------*/
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)aType {
    // Read the opened file.
    [self setTextData:data];
    [self setTextDataType:aType];

    return (YES);
} // loadDataRepresentation


#pragma mark - Utilities

/*----------------------------------------------------------------------------------------
 simple replacement method for NSRunAlertPanel
 ----------------------------------------------------------------------------------------*/
- (NSModalResponse) runAlertPanelWithTitle:(NSString *)inTitle
                                    message:(NSString *)inMessage
                               buttonTitles:(NSArray *)inButtonTitles
{
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedString(inTitle, inTitle);
    alert.informativeText = NSLocalizedString(inMessage, inMessage);
    for (NSString *buttonTitle in inButtonTitles) {
        [alert addButtonWithTitle:NSLocalizedString(buttonTitle, buttonTitle)];
    }
    return ([alert runModal]);
} // runAlertPanelWithTitle




- (void)setExpressionForPhoneme:(NSNumber *)phoneme {
    
    //NSArray *level2nums = [[NSArray alloc]initWithObjects: @10, @27, @28, @9, nil];

    int phonemeValue = [phoneme shortValue];
    int level1nums[8] = {5, 8, 6, 20, 29, 32, 33, 35};
    int level2nums[12] = {5, 8, 6, 20, 29, 32, 33, 35, 10, 27, 28, 9};
    int level3nums[16] = {5, 8, 6, 20, 29, 32, 33, 35, 10, 27, 28, 9, 40, 7, 14, 26};
    int level4nums[20] = {5, 8, 6, 20, 29, 32, 33, 35, 10, 27, 28, 9, 40, 7, 14, 26, 2, 28, 21, 24};
    int level5nums[24] = {5, 8, 6, 20, 29, 32, 33, 35, 10, 27, 28, 9, 40, 7, 14, 26, 2, 28, 21, 24, 4, 11, 37, 31};
    int level6nums[28] = {5, 8, 6, 20, 29, 32, 33, 35, 10, 27, 28, 9, 40, 7, 14, 26, 2, 28, 21, 24, 4, 11, 37, 31, 12, 15, 22, 18};
    int level7nums[32] = {5, 8, 6, 20, 29, 32, 33, 35, 10, 27, 28, 9, 40, 7, 14, 26, 2, 28, 21, 24, 4, 11, 37, 31, 12, 15, 22, 18, 3, 16, 30, 34};
    int level8nums[36] = {5, 8, 6, 20, 29, 32, 33, 35, 10, 27, 28, 9, 40, 7, 14, 26, 2, 28, 21, 24, 4, 11, 37, 31, 12, 15, 22, 18, 3, 16, 30, 34, 13, 23, 36, 39};
    int level9nums[40] = {5, 8, 6, 20, 29, 32, 33, 35, 10, 27, 28, 9, 40, 7, 14, 26, 2, 28, 21, 24, 4, 11, 37, 31, 12, 15, 22, 18, 3, 16, 30, 34, 13, 23, 36, 39, 17,38,41};//19 (35,34),25 (20,41)
 



    /*
    //uint8_t val= phonemeValue;
    //NSLog(@"%", sizeof(level1nums));
*/
    if ([LevelSelector indexOfSelectedItem] == 1) {
        for (int i=0 ; i<8 ; i++){
            if (level1nums[i] == phonemeValue){
                NSLog(@"level 1 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }
        }}
    if ([LevelSelector indexOfSelectedItem] == 2) {
        for (int i=0 ; i<12 ; i++){
            if (level2nums[i] == phonemeValue){
                NSLog(@"level 2 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }}}
    if ([LevelSelector indexOfSelectedItem] == 3) {
        for (int i=0 ; i<16 ; i++){
            if (level3nums[i] == phonemeValue){
                NSLog(@"level 3 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }
        }}
    if ([LevelSelector indexOfSelectedItem] == 4) {
        for (int i=0 ; i<20 ; i++){
            if (level4nums[i] == phonemeValue){
                NSLog(@"level 4 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }
        }}
    if ([LevelSelector indexOfSelectedItem] == 5) {
        for (int i=0 ; i<24 ; i++){
            if (level5nums[i] == phonemeValue){
                NSLog(@"level 5 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }
        }}
    if ([LevelSelector indexOfSelectedItem] == 6) {
        for (int i=0 ; i<28 ; i++){
            if (level6nums[i] == phonemeValue){
                NSLog(@"level 6 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }
        }}
    if ([LevelSelector indexOfSelectedItem] == 7) {
        for (int i=0 ; i<32 ; i++){
            if (level7nums[i] == phonemeValue){
                NSLog(@"level 7 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }
        }}
    if ([LevelSelector indexOfSelectedItem] == 8) {
        for (int i=0 ; i<36 ; i++){
            if (level8nums[i] == phonemeValue){
                NSLog(@"level 8 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }
        }}
    if ([LevelSelector indexOfSelectedItem] == 9) {
        for (int i=0 ; i<39 ; i++){
            if (level9nums[i] == phonemeValue){
                NSLog(@"level 9 phoneme %d", phonemeValue);
                write(serialFileDescriptor, (const void *) &phonemeValue, 1);
            }}}

}


- (void)AssignTestButtons:(NSInteger *)Level {
    //NSMutableArray *level1 = [[NSMutableArray alloc]initWithObjects:@"AX", @"IH", @"IY", @"d", @"n", @"r", @"s", @"t", nil];
    NSMutableArray *phonemesToTest;
    if(Level == 1){
        phonemesToTest = [[NSMutableArray alloc]initWithObjects: @"AX", @"IH", @"IY", @"d", @"n", @"r", @"s", @"t", nil];}
    int levelsize = [phonemesToTest count] - 1;
    int correctButton = arc4random_uniform(8);
    int numb = arc4random_uniform(levelsize);
    phonemeBeingTested = phonemesToTest[numb];
    NSString *correctButtonStr = [NSString stringWithFormat:@"%d", correctButton];
    testButtons = [NSMutableDictionary
                                        dictionaryWithDictionary:@{}];
    [phonemesToTest removeObject: phonemeBeingTested];
    for ( int i = 0; i < 8; i++){
        //levelsize = [phonemesToTest count] - 1;
        levelsize = [phonemesToTest count] - 1;
        if (i == correctButton){
            testButtons[[NSString stringWithFormat:@"%i", correctButton]] = phonemeBeingTested;}
        else {
            wrongPhoneme = phonemesToTest[arc4random_uniform(levelsize)];
            [phonemesToTest removeObject: wrongPhoneme];
            testButtons[[NSString stringWithFormat:@"%i", i]] = wrongPhoneme;}
        NSLog(@"i is %d", i);
    }
    
    /*To avoid repeats, uncomment remove object from array but fix issue with remove objext*/
    
}



- (IBAction)TestButtons:(id)sender {
    if (![sender isKindOfClass:[NSButton class]])
        return;
    NSString *tite = [(NSButton *)sender title];
    //[self AssignTestButtons:[LevelSelector indexOfSelectedItem]];
    NSLog(tite);
    if ([tite isEqualToString:@"vybe"]){
        SetSpeechProperty(fCurSpeechChannel,
                          kSpeechVolumeProperty,
                          (__bridge CFTypeRef)(@(0.0)));
        //SetSpeechProperty(fCurSpeechChannel, kSpeechVolumeProperty, 0);
        NSLog(phonemeBeingTested);
        [self startSpeakingButton:phonemeBeingTested];}
    else{
        SetSpeechProperty(fCurSpeechChannel,
                          kSpeechVolumeProperty,
                          (__bridge CFTypeRef)(@(1.0)));
        NSLog(@"%@", testButtons[tite]);
        NSString *wrPhonemeToSpeak = testButtons[tite];
        NSLog(testButtons[tite]);
        [self startSpeakingButton: wrPhonemeToSpeak];
    }
}


- (IBAction)WordTestButtons:(id)sender {
    SetSpeechProperty(fCurSpeechChannel,
                      kSpeechVolumeProperty,
                      (__bridge CFTypeRef)(@(1.0)));
    NSDictionary *PhonToWord = @{
     @"AX" : @"about",
     @"d" : @"din",
     @"IH" : @"bit",
     @"IY" : @"beet",
     @"n" : @"nap",
     @"r" : @"ran",
     @"s" : @"sin",
     @"t" : @"tin"
     };
    if (![sender isKindOfClass:[NSButton class]])
        return;
    NSString *tite = [(NSButton *)sender title];
    //[self AssignTestButtons:[LevelSelector indexOfSelectedItem]];
    NSString *CorrespPhon = testButtons[tite];
    NSString *TestWord = PhonToWord[CorrespPhon];
    NSLog(testButtons[tite]);
    [self startSpeakingWordButton: TestWord];
    }


- (IBAction)StartTest:(id)sender {
    NSLog(@"hellowww");
    //set answerSelector to list of phonemes being tested
    NSArray *Answs = [[NSArray alloc]initWithObjects:@" ", @"1", @"2", @"3", @"4" , @"5", @"6", @"7", @"8", nil];
    [answerSelector removeAllItems];
    [answerSelector addItemsWithTitles:Answs];
    [self AssignTestButtons:[LevelSelector indexOfSelectedItem]];
}


- (IBAction)SelectedAnswer:(id)sender {
    NSString *answer =[answerSelector titleOfSelectedItem];
    if (testButtons[answer] == phonemeBeingTested){
        correctAnswers ++;
        totalAttempts = correctAnswers + wrongAnswers;
        [fLastAnswer setStringValue:@"Correct!"];
        [fAllAnswers setStringValue:[NSString stringWithFormat: @"%d Correct / %d Attempted", correctAnswers,  totalAttempts]];
    }
    else {
        wrongAnswers ++;
        totalAttempts = correctAnswers + wrongAnswers;
        [fLastAnswer setStringValue:@"Wrong!"];
        [fAllAnswers setStringValue:[NSString stringWithFormat: @"%d Correct / %d Attempted", correctAnswers,  totalAttempts]];
    }
    [self AssignTestButtons:[LevelSelector indexOfSelectedItem]];
    
}

//CLEAR DICTIONARY

        
   // NSString *word = [(NSButton *)sender title];
   // [self startSpeakingWordButton:word];}


- (IBAction)wordButton:(id)sender {
    
//    if([LevelSelector indexOfSelectedItem] <= 2)
//    {
//        [sender setEnabled:NO];
//    }
//    
    if (![sender isKindOfClass:[NSButton class]])
        return;
    NSString *word = [(NSButton *)sender title];
    [self startSpeakingWordButton:word];
}

- (IBAction)phonemeButton:(id)sender {
    if (![sender isKindOfClass:[NSButton class]])
        return;
    NSString *phon = [(NSButton *)sender title];
    [self startSpeakingButton:phon];
}



- (void)startSpeakingButton:(NSString *)phon {
    SetSpeechProperty(fCurSpeechChannel, kSpeechInputModeProperty, kSpeechModePhoneme);
    SetSpeechProperty(fCurSpeechChannel, kSpeechPhonemeCallBack,
                      (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurPhonemeCallBackProc)));
    // Convert NSString to cString.
    // We want the text view the active view.  Also saves any parameters currently being edited.
    //[fWindow makeFirstResponder:fSpokenTextView];
    SetSpeechProperty(fCurSpeechChannel,
                      kSpeechSpeechDoneCallBack,
                      (__bridge CFTypeRef)(@((long)OurSpeechDoneCallBackProc)));
    SetSpeechProperty(fCurSpeechChannel, kSpeechTextDoneCallBack,
                      (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurTextDoneCallBackProc)));
    
    SpeakCFString(fCurSpeechChannel, (__bridge CFStringRef)phon, NULL);
    // if (noErr == theErr) {
    // Update our vars
    //fLastErrorCode = 0;
    //fLastSpeakingValue = NO;
    //fLastPausedValue = NO;
    //fCurrentlySpeaking = YES;
    //fCurrentlyPaused = NO;
    //[self updateSpeakingControlState];
    //} else {
    //[self runAlertPanelWithTitle:@"SpeakText"
    //                   message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
    //            buttonTitles:@[@"Oh?"]];
    //}
    
    //[self enableCallbackControlsBasedOnSavingToFileFlag:fSavingToFile];
}

- (void)startSpeakingWordButton:(NSString *)word {
    SetSpeechProperty(fCurSpeechChannel, kSpeechInputModeProperty, kSpeechModeText);
    SetSpeechProperty(fCurSpeechChannel, kSpeechPhonemeCallBack,
                      (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurPhonemeCallBackProc)));
    // Convert NSString to cString.
    // We want the text view the active view.  Also saves any parameters currently being edited.
    //[fWindow makeFirstResponder:fSpokenTextView];
    SetSpeechProperty(fCurSpeechChannel,
                      kSpeechSpeechDoneCallBack,
                      (__bridge CFTypeRef)(@((long)OurSpeechDoneCallBackProc)));
    SetSpeechProperty(fCurSpeechChannel, kSpeechTextDoneCallBack,
                      (__bridge CFTypeRef)(@(fSavingToFile ? (long)NULL : (long)OurTextDoneCallBackProc)));
    
    SpeakCFString(fCurSpeechChannel, (__bridge CFStringRef)word, NULL);
    // if (noErr == theErr) {
    // Update our vars
    //fLastErrorCode = 0;
    //fLastSpeakingValue = NO;
    //fLastPausedValue = NO;
    //fCurrentlySpeaking = YES;
    //fCurrentlyPaused = NO;
    //[self updateSpeakingControlState];
    //} else {
    //[self runAlertPanelWithTitle:@"SpeakText"
    //                   message:[NSString stringWithFormat:fErrorFormatString, theErr, theErr]
    //            buttonTitles:@[@"Oh?"]];
    //}
    
    //[self enableCallbackControlsBasedOnSavingToFileFlag:fSavingToFile];
}


@end

#pragma mark - Callback routines

//
// AN IMPORTANT NOTE ABOUT CALLBACKS AND THREADS
//
// All speech synthesis callbacks, except for the Text Done callback, call their specified routine on a
// thread other than the main thread.  Performing certain actions directly from a speech synthesis callback
// routine may cause your program to crash without certain safe gaurds.	 In this example, we use the NSThread
// method performSelectorOnMainThread:withObject:waitUntilDone: to safely update the user interface and
// interact with our objects using only the main thread.
//
// Depending on your needs you may be able to specify your Cocoa application is multiple threaded
// then preform actions directly from the speech synthesis callback routines.  To indicate your Cocoa
// application is mulitthreaded, call the following line before calling speech synthesis routines for
// the first time:
//
// [NSThread detachNewThreadSelector:@selector(self) toTarget:self withObject:nil];
//

/*----------------------------------------------------------------------------------------
 OurErrorCFCallBackProc

 Called by speech channel when an error occurs during processing of text to speak.
 ----------------------------------------------------------------------------------------*/
static void OurErrorCFCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon, CFErrorRef inCFErrorRef) {
    @autoreleasepool {
        SpeakingTextWindow *stw = (__bridge SpeakingTextWindow *)inRefCon;
        if ([stw shouldDisplayErrorCallbacks]) {
            [[NSAlert alertWithError:(__bridge NSError *)inCFErrorRef] performSelectorOnMainThread:@selector(runModal)
                                                                                        withObject:NULL
                                                                                     waitUntilDone:YES];
        }
    }
} // OurErrorCFCallBackProc

/*----------------------------------------------------------------------------------------
 OurTextDoneCallBackProc

 Called by speech channel when all text has been processed.	Additional text can be
 passed back to continue processing.
 ----------------------------------------------------------------------------------------*/
static void OurTextDoneCallBackProc(SpeechChannel	inSpeechChannel,
                                    SRefCon			inRefCon,
                                    const void **	inNextBuf,
                                    unsigned long * inByteLen,
                                    long *			inControlFlags) {
    @autoreleasepool {
        SpeakingTextWindow *stw = (__bridge SpeakingTextWindow *)inRefCon;
        *inNextBuf = NULL;
        if ([stw shouldDisplayTextDoneCallbacks]) {
            [stw performSelectorOnMainThread:@selector(displayTextDoneAlert)
                                  withObject:NULL
                               waitUntilDone:NO];
        }
    }
} // OurTextDoneCallBackProc

/*----------------------------------------------------------------------------------------
 OurSpeechDoneCallBackProc

 Called by speech channel when all speech has been generated.
 ----------------------------------------------------------------------------------------*/
static void OurSpeechDoneCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon) {
    @autoreleasepool {
        SpeakingTextWindow *stw = (__bridge SpeakingTextWindow *)inRefCon;
        [stw performSelectorOnMainThread:@selector(speechIsDone)
                              withObject:NULL
                           waitUntilDone:NO];
    }
} // OurSpeechDoneCallBackProc

/*----------------------------------------------------------------------------------------
 OurSyncCallBackProc

 Called by speech channel when it encouters a synchronization command within an
 embedded speech comand in text being processed.
 ----------------------------------------------------------------------------------------*/
static void OurSyncCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon, OSType inSyncMessage) {
    @autoreleasepool {
        SpeakingTextWindow *stw = (__bridge SpeakingTextWindow *)inRefCon;
        if ([stw shouldDisplaySyncCallbacks]) {
            [stw performSelectorOnMainThread:@selector(displaySyncAlertWithMessage:)
                                  withObject:@((long)inSyncMessage)
                               waitUntilDone:NO];
        }
    }
} // OurSyncCallBackProc

/*----------------------------------------------------------------------------------------
 OurPhonemeCallBackProc

 Called by speech channel every time a phoneme is about to be generated.	 You might use
 this to animate a speaking character.
 ----------------------------------------------------------------------------------------*/
static void OurPhonemeCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon, short inPhonemeOpcode) {
    @autoreleasepool {
        SpeakingTextWindow *stw = (__bridge SpeakingTextWindow *)inRefCon;
        //if ([stw shouldDisplayPhonemeCallbacks]) {
        [stw performSelectorOnMainThread:@selector(setExpressionForPhoneme:)
         //[[stw characterView] performSelectorOnMainThread:@selector(setExpressionForPhoneme:)
                              withObject:@(inPhonemeOpcode)
                           waitUntilDone:NO];
    }
}

//} // OurPhonemeCallBackProc



/*----------------------------------------------------------------------------------------
 OurWordCallBackProc

 Called by speech channel every time a word is about to be generated.  This program
 uses this callback to highlight the currently spoken word.
 ----------------------------------------------------------------------------------------*/
static void OurWordCFCallBackProc(SpeechChannel inSpeechChannel, SRefCon inRefCon, CFStringRef inCFStringRef, CFRange inWordCFRange) {
    @autoreleasepool {
        SpeakingTextWindow *stw = (__bridge SpeakingTextWindow *)inRefCon;
        if ([stw shouldDisplayWordCallbacks]) {
            [stw performSelectorOnMainThread:@selector(highlightWordWithParams:)
                                  withObject:@{kWordCallbackParamPosition:@(inWordCFRange.location), kWordCallbackParamLength:@(inWordCFRange.length)}
                               waitUntilDone:NO];
        }
    }
} // OurWordCFCallBackProc

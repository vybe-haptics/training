/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main window hosting all the apps speech features.
 */

@import Cocoa;

@interface SpeakingTextWindow : NSDocument
@property (weak) IBOutlet NSButton *PhonButton;
@property (weak) IBOutlet NSButton *t;
@property (weak) IBOutlet NSButton *s;
@property (weak) IBOutlet NSButton *r;
@property (weak) IBOutlet NSButton *n;
@property (weak) IBOutlet NSButton *IY;
@property (weak) IBOutlet NSButton *d;
@property (weak) IBOutlet NSButton *IH;
@property (weak) IBOutlet NSButton *AX;
@property(readonly, strong) NSMenuItem *selectedItem;

@end


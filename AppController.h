//
//  AppController.h
//  CUDA_Demo_1
//
//  Created by Diego Gomes on 21/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WavFile.h"
#import "WhrtfForPositionBean.h"

#include <AudioToolbox/AudioFile.h>

#include <SDL/SDL.h>
#include <SDL/SDL_Audio.h>
#include <Math.h>

@interface AppController : NSObject {
	IBOutlet NSTextField *textFieldElevation;
	IBOutlet NSTextField *textFieldAzimuth;
	IBOutlet NSSlider *azimSlider;
	WavFile *wavFile;
	int azim;
	int elev;
}

@property WavFile *wavFile;
@property int azim;
@property int elev;

- (void) playAudio2:(Uint8 *) audioStream audioLength:(int) audioLengthValue;
- (IBAction)calculateWhrtf:(id)sender;
- (IBAction)playPressed:(id)sender;
- (IBAction)pausePressed:(id)sender;
- (IBAction)loadSoundOpenPanel:(id)sender;
- (IBAction) sliderValueChanged:(id)sender; 
- (IBAction) sliderElevValueChanged:(id)sender;

void cudaCompute(void);

@end

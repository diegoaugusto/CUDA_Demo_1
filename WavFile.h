//
//  WavFile.h
//  CUDA_Demo_1
//
//  Created by Diego Gomes on 27/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SDL/SDL.h>
#import <SDL/SDL_Audio.h>

#include "WavFile.h"
#include "WavFileUtil.h"

#define NUM_OF_CHANNELS 2

@interface WavFile : NSObject {
	NSString* name;
	NSString* path;
	int sampleRate;
	Uint8 channels;
	Uint16 samples;
	Uint32 size;
	Uint8 *streamUint8;
	float** stream;
	@public SDL_AudioSpec wavSpec;
}

- (id) init;
- (id) initWithFilePath: (NSString *) filePath;
- (void) dealloc;

@property (retain) NSString* name;
@property (retain) NSString* path;
@property int sampleRate;
@property Uint8 channels;
@property Uint16 samples;
@property Uint32 size;
@property Uint8 *streamUint8;
@property float** stream;
@property SDL_AudioSpec wavSpec;

@end

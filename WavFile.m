//
//  WavFile.m
//  CUDA_Demo_1
//
//  Created by Diego Gomes on 27/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WavFile.h"


@implementation WavFile

@synthesize name;
@synthesize path;
@synthesize sampleRate;
@synthesize channels;
@synthesize samples;
@synthesize size;
@synthesize streamUint8;
@synthesize stream;
@synthesize wavSpec;

- (id) init
{
    if ( self = [super init] )
    {
        [self setName:@""];
        [self setPath:@""];
		[self setSize:0];
		[self setSampleRate:44100];
		[self setChannels:2];
		[self setSamples:4096];
		[self setStreamUint8: (Uint8 *) calloc(1, sizeof(Uint8 *))];
		[self setStream:(float **) calloc(NUM_OF_CHANNELS, sizeof(float*))];
		//[self setWavSpec:(SDL_AudioSpec *) calloc(1, sizeof(SDL_AudioSpec))];
    }
    return self;
}

- (id) initWithFilePath: (NSString *) filePath
{
    if ( self = [super init] )
    {
		SDL_AudioSpec wav_spec;
		Uint8* resultStreamUint8 = getStreamUint8([filePath UTF8String], &wav_spec);

		int floatArrayLength;
		float** resultStream = convertToFloatArray(resultStreamUint8, wav_spec.size, &floatArrayLength);
		
        [self setPath:filePath];
		[self setName:[filePath lastPathComponent]];
		[self setStreamUint8:resultStreamUint8];
		[self setStream:resultStream];
		[self setSampleRate:wav_spec.freq];
		[self setChannels:wav_spec.channels];
		[self setSamples:wav_spec.samples];
		[self setSize:wav_spec.size];
		[self setWavSpec:wav_spec];
    }
    return self;
}

- (void) dealloc
{
    [name release];
    [path release];
	size = 0;
	if (stream != NULL) {
		free(stream);
	}
    [super dealloc];
}

@end

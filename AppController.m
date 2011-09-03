//
//  AppController.m
//  CUDA_Demo_1
//
//  Created by Diego Gomes on 21/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "WhrtfUtils.h"
#import "WavFile.h"

extern float* convHost1(float* Gl_old, int filtroLength, float* sparsArray, int sparsLength);
extern float* convSimple(float* signal, int signalLength, float* filter, int filterLength);
extern float* convFFT(float* signal, int signalLength, float* filter, int filterLength);

static WhrtfForPositionBean *whrtfForPosition;


static Uint8 *audio_chunk;
static Uint32 audio_len;
static Uint8 *audio_pos;


@implementation AppController


/* 
 *	The audio function callback takes the following parameters:
 *	stream:	A pointer to the audio buffer to be filled
 *	len:	The length (in bytes) of the audio buffer
 */
void fill_audio2(void *udata, Uint8 *stream, int len) {
	/* Only play if we have data left */
	if ( audio_len == 0 ) {
		return;
	}
	
	/* Mix as much data as possible */
	len = ( len > audio_len ? audio_len : len );
	
	float** resultStream = (float**) calloc(2, sizeof(float*));
	float** data = convertToFloatArray(audio_pos, len);
	
	resultStream[0] = convFFT(data[0], (len/2), whrtfForPosition.whrtfLeft, whrtfForPosition.whrtfLeftLength);
	resultStream[1] = convFFT(data[1], (len/2), whrtfForPosition.whrtfRight, whrtfForPosition.whrtfRightLength);
	int streamLength = (len/2) + whrtfForPosition.whrtfLeftLength - 1;
	Uint8 *audioStream = convertToUint8Array(resultStream, streamLength);
	
	SDL_MixAudio(stream, audioStream, len, SDL_MIX_MAXVOLUME);

	audio_pos += len;
	audio_len -= len;
}

- (void) playAudio2:(Uint8 *) audioStream audioLength:(int) audioLengthValue {
	if( SDL_Init(SDL_INIT_TIMER | SDL_INIT_AUDIO ) <0 ) {
        return;
    }
	
	SDL_AudioSpec wav_spec = wavFile.wavSpec;
	SDL_AudioSpec wanted;
	
    /* Set the audio format */
    wanted.freq = wav_spec.freq;
    wanted.format = wav_spec.format;
    wanted.channels = wav_spec.channels;    /* 1 = mono, 2 = stereo */
    wanted.samples = wav_spec.samples;		/* Good low-latency value for callback */
    wanted.callback = fill_audio2;
    wanted.userdata = NULL;
	
	/* Open the audio device, forcing the desired format */
    if ( SDL_OpenAudio(&wanted, NULL) < 0 ) {
        fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
        return;
    }
	
	audio_len = audioLengthValue;
	audio_chunk = audioStream;
    audio_pos = audio_chunk;
	
    /* Let the callback function play the audio chunk */
    SDL_PauseAudio(0);
	
    /* Do some processing */
	
	
    /* Wait for sound to complete */
    while ( audio_len > 0 ) {
		printf("audio_len = %d\n", audio_len);
        SDL_Delay(80);         /* Sleep 1/10 second */
    }
    SDL_CloseAudio();
	
	return;
}


- (void) _loadSoundFromPath:(NSString *)theFilePath
{
	NSLog(@"O arquivo é: %@", theFilePath);
	wavFile = [[WavFile alloc] initWithFilePath:theFilePath];
	
	//[wavFile dealloc];
}

- (IBAction)calculateWhrtf:(id)sender
{
	int elev = [textFieldElevation intValue];
	int azim = [textFieldAzimuth intValue];	
	
	NSLog(@"Elev = %d, Azim = %d", elev, azim);
	
	whrtfForPosition = [WhrtfUtils calcWhrtfForPosition:elev azimValue:azim];
	
}

- (IBAction)playPressed:(id)sender
{
	NSLog(@"PlayPressed...");
	if (whrtfForPosition != NULL) {
		NSLog(@"TBD soon...");
		/*float** stream = (float**) calloc(2, sizeof(float*));
		printf("1\n");
		stream[0] = convFFT(wavFile.stream[0], (wavFile.size/2), whrtfForPosition.whrtfLeft, whrtfForPosition.whrtfLeftLength);
		printf("2\n");
		stream[1] = convFFT(wavFile.stream[1], (wavFile.size/2), whrtfForPosition.whrtfRight, whrtfForPosition.whrtfRightLength);
		printf("3\n");
		int streamLength = (wavFile.size/2) + whrtfForPosition.whrtfLeftLength -1;
		printf("4\n");
		Uint8 *audioStream = convertToUint8Array(stream, streamLength);
		printf("5\n");
		playAudio(audioStream, streamLength);
		printf("6\n");*/
		//playAudio(wavFile.streamUint8, wavFile.size);
		[self playAudio2:wavFile.streamUint8 audioLength:wavFile.size];
	} else {
		playAudio(wavFile.streamUint8, wavFile.size);
	}
}

- (IBAction)pausePressed:(id)sender
{
	NSLog(@"PausePressed...");
	
}

- (IBAction)loadSoundOpenPanel:(id)sender
{
    int result;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    NSArray *filesToOpen;
    NSString *theFileName;
    NSMutableArray *fileTypes = [NSSound soundUnfilteredFileTypes];
	// All file types NSSound understands
	
    [oPanel setAllowsMultipleSelection:NO];
	
    result = [oPanel runModalForDirectory:NSHomeDirectory() file:nil types:fileTypes];
	
    if (result == NSOKButton) {
        filesToOpen = [oPanel filenames];
        theFileName = [filesToOpen objectAtIndex:0];
        //NSLog(@"Open Panel Returned: %@.\n", theFileName);
		
        [self _loadSoundFromPath:theFileName];
    } else {
		NSLog(@"Operação cancelada!");
	}
}

@end

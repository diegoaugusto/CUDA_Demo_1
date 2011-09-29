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

#include <Math.h>
#include "runtime.h"
#define PI 3.14159265



extern float* convHost1(float* Gl_old, int filtroLength, float* sparsArray, int sparsLength);
extern float* convSimple(float* signal, int signalLength, float* filter, int filterLength);
extern float* convFFT(float* signal, unsigned int signalLength, float* filter, unsigned int filterLength);
extern float* cconvFFT(float* signal, unsigned int signalLength, float* filter, unsigned int filterLength);
extern float* shiftToRight(float* vec, int vecLength, short delay);

static WhrtfForPositionBean *whrtfForPosition;


static Uint8 *audio_chunk;
static Uint32 audio_len;
static Uint8 *audio_pos;



@implementation AppController

@synthesize wavFile;
@synthesize azim;
@synthesize elev;

void calculaITD(int azim, char ear, int *deltaL, int *deltaR) {
	int velSom = 343;
	float distP = 1.4;
	float raio = 0.08;
	float diametro = raio * 2.0;
	
	float x = (sin(azim * PI/180.0) * distP) - raio;
	float y = sqrt(pow(distP, 2) - pow((raio+x), 2));
	
	float distR, distL;
	
	if (ear == 'R') {
		distR = sqrt(pow(x, 2) + pow(y, 2));
		distL = sqrt(pow((x+diametro), 2) + pow(y, 2));
	} else if (ear == 'L') {
		distL = sqrt(pow(x, 2) + pow(y, 2));
		distR = sqrt(pow((x+diametro), 2) + pow(y, 2));
	}
	
	*deltaL = round((distL/velSom) * 44100);
	*deltaR = round((distR/velSom) * 44100);
}

static float** originalStream;

/* 
 *	The audio function callback takes the following parameters:
 *	stream:	A pointer to the audio buffer to be filled
 *	len:	The length (in bytes) of the audio buffer
 */
static int r = 0;
//static WhrtfForPositionBean *whrtfs[121][360];
static WhrtfForPositionBean *whrtfs[10][360];
static int staticAzim = 0;
static int staticElev = 0;
void fill_audio2(void *udata, Uint8 *stream, int len) {
	/* Only play if we have data left */
	/*if ( audio_len == 0 ) {
		return;
	}
	
	// Mix as much data as possible 
	len = ( len > audio_len ? audio_len : len );
	
	float** resultStream = (float**) calloc(2, sizeof(float*));
	float** data = convertToFloatArray(audio_pos, len);
	
	resultStream[0] = convFFT(data[0], (len/2), whrtfForPosition.whrtfLeft, whrtfForPosition.whrtfLeftLength);
	resultStream[1] = convFFT(data[1], (len/2), whrtfForPosition.whrtfRight, whrtfForPosition.whrtfRightLength);
	int streamLength = (len/2) + whrtfForPosition.whrtfLeftLength - 1;
	Uint8 *audioStream = convertToUint8Array(resultStream, streamLength);
	
	SDL_MixAudio(stream, audioStream, len, SDL_MIX_MAXVOLUME);
	
	audio_pos += len;
	audio_len -= len;*/
	
	
	// ###################################################
	/*if ( audio_len == 0 ) {
		return;
	}
	
	// Mix as much data as possible 
	len = ( len > audio_len ? audio_len : len );
	
	//printf("len = %d, audio_len = %d\n", len, audio_len);
	
	Uint8 *originalData = (Uint8 *) malloc(len * sizeof(Uint8));
	memcpy(originalData, audio_pos, len * sizeof(Uint8));
	
	int floatArrayLength;
	float** data = convertToFloatArray(originalData, len, &floatArrayLength);
	
	int PL = whrtfForPosition.whrtfLeftLength;
	int PR = whrtfForPosition.whrtfRightLength;
	int xrLength = floatArrayLength + PL;
	//int xrLength = floatArrayLength;

	float** Xr = (float **) calloc(2, sizeof(float*));
	Xr[0] = (float*) calloc(xrLength, sizeof(float));
	Xr[1] = (float*) calloc(xrLength, sizeof(float));

	// len == L
	for (int n = 0; n < xrLength; n++) {
		int indexL = (n + (r)*(xrLength-PL+1)-PL);
		int indexR = (n + (r)*(xrLength-PR+1)-PR);
		
		//int indexL = (n - PL);
		//int indexR = (n - PR);
		
		//printf("indexL = %d; indexR = %d\n", indexL, indexR);
		
		// Left
		if (indexL < 0) {
			Xr[0][n] = 0.0;
		} else {
			//Xr[0][n] = data[0][indexL];
			Xr[0][n] = originalStream[0][indexL];
		}

		// Right
		if (indexR < 0) {
			Xr[1][n] = 0.0;
		} else {
			//Xr[1][n] = data[1][indexR];
			Xr[1][n] = originalStream[1][indexR];
		}
	}
	r++;
	
	int deltaL, deltaR;
	calculaITD(90, 'L', &deltaL, &deltaR);
	
	float** aux = (float**) calloc(2, sizeof(float*));
	
	float *convAux = cconvFFT(Xr[0], xrLength, whrtfForPosition.whrtfLeft, whrtfForPosition.whrtfLeftLength);	
	aux[0] = shiftToRight(convAux, xrLength, deltaL);
	convAux = cconvFFT(Xr[1], xrLength, whrtfForPosition.whrtfRight, whrtfForPosition.whrtfRightLength);
	aux[1] = shiftToRight(convAux, xrLength, deltaR);
		
	float** aux2 = (float**) calloc(2, sizeof(float*));
	aux2[0] = (float*) calloc(floatArrayLength, sizeof(float));
	aux2[1] = (float*) calloc(floatArrayLength, sizeof(float));
	
	int j = 0;
	for (int i = PL; i < xrLength; i++) {
		aux2[0][j] = aux[0][i];
		aux2[1][j] = aux[1][i];
		j++;
	}
	
	Uint8 *audioStream  = convertToUint8Array(aux2, len);
	
	SDL_MixAudio(stream, audioStream, len, SDL_MIX_MAXVOLUME);
	
	free(convAux);
	free(aux[0]);
	free(aux[1]);
	free(aux);
	free(Xr[0]);
	free(Xr[1]);
	free(Xr);
	free(data[0]);
	free(data[1]);
	free(data);
	
	audio_pos += len;
	audio_len -= len;*/
	
	//#####################################
	int indexAzim = staticAzim;
	int indexElev = staticElev;
	
	//WhrtfForPositionBean *whrtfForPositionLocal = whrtfs[indexElev+40][indexAzim];
	WhrtfForPositionBean *whrtfForPositionLocal = whrtfs[indexElev][indexAzim];
	if ( audio_len == 0 ) {
		return;
	}
	
	// Mix as much data as possible 
	len = ( len > audio_len ? audio_len : len );
	
	//printf("len = %d, audio_len = %d\n", len, audio_len);
	
	Uint8 *originalData = (Uint8 *) malloc(len * sizeof(Uint8));
	memcpy(originalData, audio_pos, len * sizeof(Uint8));
	
	int floatArrayLength;
	float** data = convertToFloatArray(originalData, len, &floatArrayLength);
	
	int PL = whrtfForPositionLocal.whrtfLeftLength;
	int PR = whrtfForPositionLocal.whrtfRightLength;
	int xrLength = floatArrayLength + PL;
	//int xrLength = floatArrayLength;
	
	float** Xr = (float **) calloc(2, sizeof(float*));
	Xr[0] = (float*) calloc(xrLength, sizeof(float));
	Xr[1] = (float*) calloc(xrLength, sizeof(float));
	
	// len == L
	for (int n = 0; n < xrLength; n++) {
		int indexL = (n + (r)*(xrLength-PL+1)-PL);
		int indexR = (n + (r)*(xrLength-PR+1)-PR);
		
		//int indexL = (n - PL);
		//int indexR = (n - PR);
		
		//printf("indexL = %d; indexR = %d\n", indexL, indexR);
		
		// Left
		if (indexL < 0) {
			Xr[0][n] = 0.0;
		} else {
			//Xr[0][n] = data[0][indexL];
			Xr[0][n] = originalStream[0][indexL];
		}
		
		// Right
		if (indexR < 0) {
			Xr[1][n] = 0.0;
		} else {
			//Xr[1][n] = data[1][indexR];
			Xr[1][n] = originalStream[1][indexR];
		}
	}
	r++;
	
	int deltaL, deltaR;
	calculaITD(indexAzim, 'L', &deltaL, &deltaR);
	//calculaITD(60, 'L', &deltaL, &deltaR);
	
	float** aux = (float**) calloc(2, sizeof(float*));
	
	float *convAux = cconvFFT(Xr[0], xrLength, whrtfForPositionLocal.whrtfLeft, whrtfForPositionLocal.whrtfLeftLength);	
	aux[0] = shiftToRight(convAux, xrLength, deltaL);
	convAux = cconvFFT(Xr[1], xrLength, whrtfForPositionLocal.whrtfRight, whrtfForPositionLocal.whrtfRightLength);
	aux[1] = shiftToRight(convAux, xrLength, deltaR);
	
	float** aux2 = (float**) calloc(2, sizeof(float*));
	aux2[0] = (float*) calloc(floatArrayLength, sizeof(float));
	aux2[1] = (float*) calloc(floatArrayLength, sizeof(float));
	
	int j = 0;
	for (int i = PL; i < xrLength; i++) {
		aux2[0][j] = aux[0][i];
		aux2[1][j] = aux[1][i];
		j++;
	}
	
	Uint8 *audioStream  = convertToUint8Array(aux2, len);
	
	SDL_MixAudio(stream, audioStream, len, SDL_MIX_MAXVOLUME);
	
	free(convAux);
	free(aux[0]);
	free(aux[1]);
	free(aux);
	free(Xr[0]);
	free(Xr[1]);
	free(Xr);
	free(data[0]);
	free(data[1]);
	free(data);
	
	audio_pos += len;
	audio_len -= len;
}

//- (void) playAudio2:(Uint8 *) audioStream audioLength:(int) audioLengthValue {
- (void) playAudio2 {
	printf("playAudio2\n\n");
	
	Uint8* audioStream = wavFile.streamUint8;
	int audioLengthValue = wavFile.size;
	if( SDL_Init(SDL_INIT_TIMER | SDL_INIT_AUDIO ) < 0 ) {
        return;
    }
	
	SDL_AudioSpec wav_spec = wavFile.wavSpec;
	SDL_AudioSpec wanted, obtained;
	
    /* Set the audio format */
    wanted.freq = wav_spec.freq;
    wanted.format = wav_spec.format;
    wanted.channels = wav_spec.channels;    /* 1 = mono, 2 = stereo */
    wanted.samples = wav_spec.samples;		/* Good low-latency value for callback */
    wanted.callback = fill_audio2;
    wanted.userdata = NULL;
	
	/* Open the audio device, forcing the desired format */
    if ( SDL_OpenAudio(&wanted, &obtained) < 0 ) {
        fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
		SDL_PauseAudio(0);
        return;
    }
	
	audio_len = audioLengthValue;
	audio_chunk = audioStream;
    audio_pos = audio_chunk;
	
	/* Do some processing */
	WavFile *wavfile = [self wavFile];
	originalStream = [wavfile stream];
	
	
	/*int azim = 60;
	int j = 0;
	for (int i = -40; i < 80; i++) {
		printf("i = %d\n", i);
		WhrtfForPositionBean *whrtfForPositionLocalBean = [WhrtfUtils calcWhrtfForPosition:i azimValue:azim];
		whrtfs[j++] = whrtfForPositionLocalBean;
	}*/
	
	/*int elev = 0;
	for (int k = 0; k < 1; k++) {
		for (int i = 0; i < 360; i += 1) {
			WhrtfForPositionBean *whrtfForPositionLocalBean = [WhrtfUtils calcWhrtfForPosition:k azimValue:i];
			whrtfs[k+40][i] = whrtfForPositionLocalBean;
		}
	}*/
	
	int elev = 0;
	for (int k = 0; k < 10; k++) {
		printf("elev = %d\n", k);
		for (int i = 0; i < 360; i += 1) {
			WhrtfForPositionBean *whrtfForPositionLocalBean = [WhrtfUtils calcWhrtfForPosition:k azimValue:i];
			whrtfs[k][i] = whrtfForPositionLocalBean;
		}
	}
	
	
	//WhrtfForPositionBean *whrtfForPositionLocalBean = [WhrtfUtils calcWhrtfForPosition:elev azimValue:0];
	//whrtfs[0] = whrtfForPositionLocalBean;
	
    /* Let the callback function play the audio chunk */
    SDL_PauseAudio(0);
	
	
    /* Wait for sound to complete */
    while ( audio_len > 0 ) {
		//printf("audio_len = %d\n", audio_len);
        //SDL_Delay(100);         /* Sleep 1/10 second */
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
	elev = [textFieldElevation intValue];
	azim = [textFieldAzimuth intValue];	
	
	NSLog(@"Elev = %d, Azim = %d", elev, azim);
	
	while (azim >= 360) {
		azim = azim - 360;
	}
	
	staticAzim = azim;
	//whrtfForPosition = [WhrtfUtils calcWhrtfForPosition:elev azimValue:azim];
	
}


- (NSOperation*) test:(int) value {
	NSOperationQueue *queue = [NSOperationQueue new];  
	[queue setMaxConcurrentOperationCount:1];  
	
	NSInvocationOperation *queuerC = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(playAudio2) object:nil];
	
	[queue addOperation:queuerC];  
	[queuerC release]; 
	
	
	//NSInvocationOperation* theOp = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(playAudio2) object:wavFile] autorelease];
}

- (IBAction)playPressed:(id)sender
{
	NSLog(@"PlayPressed...");
	//if (whrtfForPosition != NULL) {
	//	NSLog(@"TBD soon...");
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
		
		[self test:1];
		
		//[self playAudio2:wavFile.streamUint8 audioLength:wavFile.size];
	//} else {
	//	playAudio(wavFile.streamUint8, wavFile.size);
	//}
}

- (IBAction)pausePressed:(id)sender
{
	NSLog(@"PausePressed...");
	SDL_PauseAudio(1);
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

- (IBAction) sliderValueChanged:(id)sender {
	int value = [sender intValue];
	staticAzim = value;
	[textFieldAzimuth setIntValue:value];
	
	//WhrtfForPositionBean *whrtfForPositionLocalBean = [WhrtfUtils calcWhrtfForPosition:elev azimValue:value];
	//whrtfs[value] = whrtfForPositionLocalBean;
	
	//[self setAzim:value];
}

- (IBAction) sliderElevValueChanged:(id)sender {
	int value = [sender intValue];
	staticElev = value;
	[textFieldElevation setIntValue:value];
	
	//WhrtfForPositionBean *whrtfForPositionLocalBean = [WhrtfUtils calcWhrtfForPosition:elev azimValue:value];
	//whrtfs[value] = whrtfForPositionLocalBean;
	
	//[self setAzim:value];
}


- (void)rotateWithEvent:(NSEvent *)event {
    //[resultsField setStringValue:[NSString stringWithFormat:@"Rotation in degree is %f", [event rotation]]];
    //[self setFrameCenterRotation:([self frameCenterRotation] + [event rotation])];
}

@end

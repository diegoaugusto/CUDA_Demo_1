/*
 *  WavFileUtil.c
 *  CUDA_Demo_1
 *
 *  Created by Diego Gomes on 27/08/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include <SDL/SDL.h>
#include <SDL/SDL_Audio.h>
#include <Math.h>

/* Inclusão do respectivo módulo de definição */
#define WAVFILEUTIL_SER
#include "WavFileUtil.h"
#undef WAVFILEUTIL_SER

// ########################################
// prototypes
Uint8* convertToUint8Array(float** data, Uint32 wavLen);
float** convertToFloatArray(Uint8 *wavBuf, Uint32 wavLen, int *floatArrayLength);
float** getStream(char* filename, SDL_AudioSpec *wavSpec);
void fill_audio(void *udata, Uint8 *stream, int len);		// callback function
void playAudio();


// ########################################
// global variables
SDL_AudioSpec wav_spec;
Uint32 wav_len;
Uint8 *wav_buf;

// ########################################
// implementation
Uint8* convertToUint8Array(float** data, Uint32 wavLen) {
	short numOfChannels = 2;
	int numOfSamplesInChannel = (wavLen/numOfChannels);
	int numOfFloatSamplesInChannel = numOfSamplesInChannel/2;
	
	short *aux = (short *) malloc(numOfSamplesInChannel * sizeof(short));
	
	int j = 0;
	for (int i = 0; i < numOfFloatSamplesInChannel; i++) {
		aux[j++] = (short) (data[0][i] * 32768);
		aux[j++] = (short) (data[1][i] * 32768);
	}
	
	// Considering only audio files with 2 channels
	/*for (int i = 0; i < numOfSamplesInChannel; i=i+2) {	
		aux[i] = (short) (data[0][j] * 32768);
		printf("aux[%d] = %d, data[0][%d] = %1.15f\n", i, aux[i], j, data[0][j]);
		aux[i+1] = (short) (data[1][j] * 32768);
		printf("aux[%d] = %d, data[1][%d] = %1.15f\n", i+1, aux[i+1], j, data[1][j]);
		j++;
	}*/
	
	j = 0;
	Uint8 *wavBuf = (Uint8 *) calloc(wavLen, sizeof(Uint8)); 
	for (int i = 0; i < numOfSamplesInChannel; i++) {
		short key = aux[i];
		Uint8 first = (key);
		Uint8 second = ((key | 0xFF) >> 8);
		wavBuf[j++] = first;
		wavBuf[j++] = second;
	}
	
	free(aux);
	
	return wavBuf;
}


float** convertToFloatArray(Uint8 *wavBuf, Uint32 wavLen, int *floatArrayLength) {
	short numOfChannels = 2;
	int numOfFloatSamplesInChannel = (wavLen/numOfChannels)/2;
	*floatArrayLength = numOfFloatSamplesInChannel;
	
	float **data = (float **) malloc(numOfChannels * sizeof(float*));
	for (int i = 0; i < numOfChannels; i++) {
		data[i] = (float *) malloc(numOfFloatSamplesInChannel * sizeof(float));
	}
	
	short *aux = (short *) malloc((wavLen/2) * sizeof(short));
	for (int i = 0; i < wavLen; i++) {			
		if (i % 2 != 0) {
			short tmp = 0;
			tmp += wavBuf[i-1];
			tmp += (wavBuf[i] << 8);
			aux[(int)floor(i/2)] = tmp;
		}
	}
	
	// Considering only audio files with 2 channels
	int j = 0;
	for (int i = 0; i < numOfFloatSamplesInChannel*2; i=i+2) {
		data[0][j] = ((float)aux[i])/32768.0f;
		data[1][j] = ((float)aux[i+1])/32768.0f;		
		j++;
	}
	
	free(aux);
	
	return data;
}

Uint8* getStreamUint8(char* filename, SDL_AudioSpec *wavSpec) {	
	/* Load the .wav file */
	if( SDL_LoadWAV(filename, &wav_spec, &wav_buf, &wav_len) == NULL ){
		fprintf(stderr, "Could not open %s: %s\n", filename, SDL_GetError());
		SDL_CloseAudio();
		exit(-1);
	}	
	
	/*printf("wav_spec.freq = %d\n", wav_spec.freq);
	 printf("wav_spec.format = %d\n", wav_spec.format);
	 printf("wav_spec.channels = %d\n", wav_spec.channels);
	 printf("wav_spec.silence = %d\n", wav_spec.silence);
	 printf("wav_spec.samples = %d\n", wav_spec.samples);
	 printf("wav_spec.size = %d\n", wav_spec.size);*/
	
	wav_spec.size = wav_len;
	*wavSpec = wav_spec;
	
	return wav_buf;
}


float** getStream(char* filename, SDL_AudioSpec *wavSpec) {
	//char* filename = "/Users/diego/Desktop/DebussyForTests.wav";
	
	/* Load the .wav file */
	if( SDL_LoadWAV(filename, &wav_spec, &wav_buf, &wav_len) == NULL ){
		fprintf(stderr, "Could not open %s: %s\n", filename, SDL_GetError());
		SDL_CloseAudio();
		exit(-1);
	}	
	
	/*printf("wav_spec.freq = %d\n", wav_spec.freq);
	printf("wav_spec.format = %d\n", wav_spec.format);
	printf("wav_spec.channels = %d\n", wav_spec.channels);
	printf("wav_spec.silence = %d\n", wav_spec.silence);
	printf("wav_spec.samples = %d\n", wav_spec.samples);
	printf("wav_spec.size = %d\n", wav_spec.size);*/
	
	short numOfChannels = wav_spec.channels;
	int numOfSamplesInChannel = (wav_len/2);
	
	float **data = (float **) malloc(numOfChannels * sizeof(float*));
	for (int i = 0; i < numOfChannels; i++) {
		data[i] = (float *) malloc(numOfSamplesInChannel * sizeof(float));
	}
	
	short *aux = (short *) malloc((wav_len/2) * sizeof(short));
	for (int i = 0; i < wav_len; i++) {			
		if (i % 2 != 0) {
			short tmp = 0;
			tmp += wav_buf[i-1];
			tmp += (wav_buf[i] << 8);
			aux[(int)floor(i/2)] = tmp;
		}
	}
	
	// Considering only audio files with 2 channels
	int j = 0;
	for (int i = 0; i < (wav_len/2); i=i+2) {
		data[0][j] = ((float)aux[i])/32768.0f;
		data[1][j] = ((float)aux[i+1])/32768.0f;		
		j++;
	}
	
	*wavSpec = wav_spec;
}

static Uint8 *audio_chunk;
static Uint32 audio_len;
static Uint8 *audio_pos;

/* 
 *	The audio function callback takes the following parameters:
 *	stream:	A pointer to the audio buffer to be filled
 *	len:	The length (in bytes) of the audio buffer
 */
static int cont = 0;
void fill_audio(void *udata, Uint8 *stream, int len) {
	/* Only play if we have data left */
	if ( audio_len == 0 ) {
		return;
	}

	/* Mix as much data as possible */
	len = ( len > audio_len ? audio_len : len );
	
	int floatArrayLength;
	float** data = convertToFloatArray(audio_pos, len, &floatArrayLength);
	Uint8 *audioStream = convertToUint8Array(data, len);
	
	//SDL_MixAudio(stream, audio_pos, len, SDL_MIX_MAXVOLUME);
	SDL_MixAudio(stream, audioStream, len, SDL_MIX_MAXVOLUME);
	
	audio_pos += len;
	audio_len -= len;
}

void playAudio(Uint8 *audioStream, int audioLength) {
	if( SDL_Init(SDL_INIT_TIMER | SDL_INIT_AUDIO ) < 0 ) {
        return 1;
    }
	
	SDL_AudioSpec wanted;
	
    /* Set the audio format */
    wanted.freq = wav_spec.freq;
    wanted.format = wav_spec.format;
    wanted.channels = wav_spec.channels;    /* 1 = mono, 2 = stereo */
    wanted.samples = wav_spec.samples;		/* Good low-latency value for callback */
    wanted.callback = fill_audio;
    wanted.userdata = NULL;
	
	/* Open the audio device, forcing the desired format */
    if ( SDL_OpenAudio(&wanted, NULL) < 0 ) {
        fprintf(stderr, "Couldn't open audio: %s\n", SDL_GetError());
        return(-1);
    }
	
	audio_len = audioLength;
	audio_chunk = audioStream;
    audio_pos = audio_chunk;
	
    /* Let the callback function play the audio chunk */
    SDL_PauseAudio(0);
	
    /* Do some processing */
	
	
    /* Wait for sound to complete */
    while ( audio_len > 0 ) {
        SDL_Delay(100);         /* Sleep 1/10 second */
    }
    SDL_CloseAudio();
	
	return;
}

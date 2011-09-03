/*
 *  WavFileUtil.h
 *  CUDA_Demo_1
 *
 *  Created by Diego Gomes on 27/08/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#if !defined(WAVFILEUTIL_CLI)
#define WAVFILEUTIL_CLI

#if defined(WAVFILEUTIL_SER)
#define WAVFILEUTIL_EXT
#else
#define WAVFILEUTIL_EXT extern
#endif


/************************Funções Exportadas**********************/
WAVFILEUTIL_EXT Uint8* convertToUint8Array(float** data, Uint32 wavLen);
WAVFILEUTIL_EXT float** convertToFloatArray(Uint8 *wavBuf, Uint32 wavLen);
WAVFILEUTIL_EXT Uint8* getStreamUint8(char* filename, SDL_AudioSpec *wavSpec);
WAVFILEUTIL_EXT float** getStream(char* filename, SDL_AudioSpec *wav_spec);
WAVFILEUTIL_EXT void playAudio(Uint8 *audioStream, int audioLength);

#undef WAVFILEUTIL_EXT

#endif
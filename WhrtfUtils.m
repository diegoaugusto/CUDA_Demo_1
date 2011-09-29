//
//  WhrtfUtils.m
//  CUDA_Demo_1
//
//  Created by Diego Gomes on 21/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>
#include <pthread.h>

#include "cuda.h"
#include "runtime.h"

/* Inclusão do respectivo módulo de definição */
#define WHRTF_SER
#include "whrtf.h"
#undef WHRTF_SER

#define SPARSECOEF_SER
#include "sparseCoefficients.h"
#undef SPARSECOEF_SER

#import "WhrtfUtils.h"

#define NUM_FILTROS 4

struct whrtf_parameters {
	// Input
	int tid;
	int elev;
	int azim;
	char ear;
	
	// Output
	float *whrtf;
	int whrtfLength;
};

void *whrtfMain2(void *arg) {
	struct whrtf_parameters *my_param;
	my_param = (struct whrtf_parameters *) arg;
	
	int tid = my_param->tid;
	int elev = my_param->elev;
	int azim = my_param->azim;
	char ear = my_param->ear;
	int whrtfLength = my_param->whrtfLength;
	
	cudaSetDevice(0);
	
	float* whr = whrtf(elev, azim, ear, &whrtfLength);
	
	my_param->whrtf = whr;
	my_param->whrtfLength = whrtfLength;
	
	if (0) {
		for (int i = 0; i < 3; i=i+3) {
			//printf("\nColunas %d a %d \n", i, i+2);
			printf("[%d] - %1.15f, %1.15f, %1.15f\n", tid, whr[i], whr[i+1], whr[i+2]);
		}
	}
}


void *whrtfMain(void *arg) {
	struct whrtf_parameters *my_param;
	my_param = (struct whrtf_parameters *) arg;
	
	int tid = my_param->tid;
	int elev = my_param->elev;
	int azim = my_param->azim;
	char ear = my_param->ear;
	int whrtfLength = my_param->whrtfLength;
	
	float** G = NULL;
	int* G_size = NULL;
	
	G_size = (int*) calloc((NUM_FILTROS+1), sizeof(int));
	G = getSparseCoefficients(elev, azim, ear, G_size);
	float* whrtf = getRespImp(NUM_FILTROS, G, G_size, &whrtfLength);
	
	for (int i = 0; i < (NUM_FILTROS+1); i++) {
		free(G[i]);
	}
	
	free(G);
	free(G_size);
	
	my_param->whrtf = whrtf;
	my_param->whrtfLength = whrtfLength;
	
	pthread_exit(NULL);
	
	return;
}

void getWhrtfFromPosition(int elev, int azim, char ear, float** whrtfL, int *whrtfLengthL, float** whrtfR, int *whrtfLengthR) {
	int flipAzim = 360 - azim;
	if (flipAzim == 360) {
		flipAzim = 0;
	}		
	
	struct whrtf_parameters *paramL, *paramR;
	paramL = (struct whrtf_parameters *) malloc(sizeof(struct whrtf_parameters));
	paramR = (struct whrtf_parameters *) malloc(sizeof(struct whrtf_parameters));
	
	paramL->tid = 0;
	paramL->elev = elev;
	paramL->azim = azim;
	paramL->ear = ear;
	
	paramR->tid = 1;
	paramR->elev = elev;
	paramR->azim = flipAzim;
	paramR->ear = ear;
	
	pthread_t threadL, threadR;	
	pthread_create(&threadL, NULL, whrtfMain, (void *) paramL);
	pthread_join( threadL, NULL);
	
	*whrtfL = paramL->whrtf;
	*whrtfLengthL = paramL->whrtfLength;
	
	if (azim != 0 && azim != 180) {
		pthread_create(&threadR, NULL, whrtfMain, (void *) paramR);
		pthread_join( threadR, NULL);
		
		*whrtfR = paramR->whrtf;
		*whrtfLengthR = paramR->whrtfLength;
	} else {
		*whrtfR = paramL->whrtf;
		*whrtfLengthR = paramL->whrtfLength;
	}
	
	free(paramL);
	free(paramR);
	//free(threadL);
	//free(threadR);
	
	return;
}





@implementation WhrtfUtils

- (id) init {
	[super init];
	return self;
}

+ (WhrtfForPositionBean*) calcWhrtfForPosition: (int) elev azimValue: (int) azim {
	char ear = 'L';
	float *whrtfL, *whrtfR;
	int whrtfLengthL, whrtfLengthR;
	
	getWhrtfFromPosition(elev, azim, ear, &whrtfL, &whrtfLengthL, &whrtfR, &whrtfLengthR);
	
	WhrtfForPositionBean *whrtfForPosition = [[WhrtfForPositionBean alloc] init];
	whrtfForPosition.elevation = elev;
	whrtfForPosition.azimuth = azim;
	whrtfForPosition.whrtfLeft = whrtfL;
	whrtfForPosition.whrtfLeftLength = whrtfLengthL;
	whrtfForPosition.whrtfRight = whrtfR;
	whrtfForPosition.whrtfRightLength = whrtfLengthR;
		
	return whrtfForPosition;
}

+ (void) calcWhrtfsThread {
	char ear = 'L';
	int whrtfLength;
	
	initCUDA();
	
	/*int elev = 0;
	int azim = 0;
	
	INIT_VARIABLES; INIT_RUNTIME;
	float* whr = whrtf(elev, azim, ear, &whrtfLength);
	END_RUNTIME; printf("\n[whrtf]: "); PRINT_RUNTIME;
	 
	cudaDeviceReset();
	 
	if (1) {
		for (int i = 0; i < whrtfLength; i=i+3) {
			printf("\nColunas %d a %d \n", i, i+2);
			printf("%1.15f, %1.15f, %1.15f\n", whr[i], whr[i+1], whr[i+2]);
		 }
	 }*/
	
	// OK - REVISADO ATÉ AQUI - 24/05/2011
	
	int numThreads = 1;
	int rc[numThreads];
	pthread_t threads[numThreads];
	
	// Implementação com threads
	struct whrtf_parameters *params;
	params = (struct whrtf_parameters *) malloc(numThreads * sizeof(struct whrtf_parameters));
	
	INIT_VARIABLES; INIT_RUNTIME;
	for (int i = 0; i < numThreads; i++) {
		params[i].tid = i;
		params[i].elev = 0;
		params[i].azim = i*5 % 360;
		params[i].ear = 'L';
		
		rc[i] = pthread_create(&threads[i], NULL, whrtfMain2, (void *) &params[i]);
	}
	
	for (int i = 0; i < numThreads; i++) {
		pthread_join( threads[i], NULL);
	}
	
	END_RUNTIME; printf("\n[%d threads]: ", numThreads); PRINT_RUNTIME;
	
	if (0) {
		for (int j = 0; j < numThreads; j++) {
			for (int i = 0; i < 3; i=i+3) {
				printf("\n[azim = %d] Colunas %d a %d \n", params[j].azim, i, i+2);
				printf("%1.15f, %1.15f, %1.15f\n", params[j].whrtf[i], params[j].whrtf[i+1], params[j].whrtf[i+2]);
			}
		}
	}
	
	cudaDeviceReset();
}

@end

//
//  WhrtfForPositionBean.h
//  CUDA_Demo_1
//
//  Created by Diego Gomes on 01/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WhrtfForPositionBean : NSObject {
	int elevation;
	int azimuth;
	float* whrtfLeft;
	int whrtfLeftLength;
	float* whrtfRight;
	int whrtfRightLength;
}

@property int elevation;
@property int azimuth;
@property float* whrtfLeft;
@property int whrtfLeftLength;
@property float* whrtfRight;
@property int whrtfRightLength;

@end

//
//  WhrtfUtils.h
//  CUDA_Demo_1
//
//  Created by Diego Gomes on 21/08/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WhrtfForPositionBean.h"


@interface WhrtfUtils : NSObject {

}

- (id) init;
+ (WhrtfForPositionBean*) calcWhrtfForPosition: (int) elev azimValue: (int) azim;
+ (void) calcWhrtfsThread;

@end

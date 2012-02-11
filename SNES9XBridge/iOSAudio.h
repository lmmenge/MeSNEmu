//
//  iOSAudio.h
//  SiOS
//
//  Created by Lucas Menge on 1/2/12.
//  Copyright (c) 2012 Lucas Menge. All rights reserved.
//

#ifndef SiOS_iOSAudio_h
#define SiOS_iOSAudio_h

#ifdef __cplusplus
extern "C" {
#endif

// starts up the AudioQueue system
void SIDemuteSound(int buffersize);
// stops the AudioQueue system
void SIMuteSound(void);

#ifdef __cplusplus
}
#endif

#endif


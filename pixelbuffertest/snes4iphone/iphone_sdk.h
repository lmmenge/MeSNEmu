#ifndef _IPHONE_SDK_H_
#define _IPHONE_SDK_H_

#ifdef __cplusplus
extern "C" {
#endif

void gp_setFramebuffer(int flip, int sync);
void app_DemuteSound(int buffersize);
void app_MuteSound(void);

#ifdef __cplusplus
}
#endif

#endif


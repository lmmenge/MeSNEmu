#import <AudioToolbox/AudioQueue.h>

#include "iOSAudio.h"

#pragma mark Defines

#define AUDIO_BUFFERS 6
#define FRAME_SIZE 2048
#define AUDIO_BUFFER_SIZE soundBufferSize /*(FRAME_SIZE*(isStereo ? 4 : 2))*/

#pragma mark - External Forward Declarations

extern void S9xMixSamplesO (signed short *buffer, int sample_count, int sample_offset);

extern volatile int __emulation_paused;

#pragma mark - Private Structures

typedef struct AQCallbackStruct {
  AudioQueueRef queue;
  UInt32 frameCount;
  AudioQueueBufferRef mBuffers[AUDIO_BUFFERS];
  AudioStreamBasicDescription mDataFormat;
} AQCallbackStruct;

#pragma mark - Global Variables

const int isStereo = 0;
AQCallbackStruct in;
int soundBufferSize = 0;
int soundInit = 0;
float __audioVolume = 1.0;

#pragma mark - Audio Queue Management

static void AQBufferCallback(
                             void *userdata,
                             AudioQueueRef outQ,
                             AudioQueueBufferRef outQB)
{
	unsigned char *coreAudioBuffer;
	coreAudioBuffer = (unsigned char*) outQB->mAudioData;
	
	outQB->mAudioDataByteSize = AUDIO_BUFFER_SIZE;
	AudioQueueSetParameter(outQ, kAudioQueueParam_Volume, __audioVolume);
	//fprintf(stderr, "sound_lastlen %d\n", sound_lastlen);
	if(__emulation_paused)
	{
    memset(coreAudioBuffer, 0, AUDIO_BUFFER_SIZE);
	}
	else
	{
	  S9xMixSamplesO((short*)coreAudioBuffer, (AUDIO_BUFFER_SIZE) / 2, 0);
  }
	AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
}

int SIOpenSound(int buffersize) {
  return 0;
  
  Float64 sampleRate = 22050.0;
  int i;
  UInt32 bufferBytes;
	
	soundBufferSize = buffersize;
	
  SIMuteSound();
	
  soundInit = 0;
	
  in.mDataFormat.mSampleRate = sampleRate;
  in.mDataFormat.mFormatID = kAudioFormatLinearPCM;
  in.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger
	| kAudioFormatFlagIsPacked;
  in.mDataFormat.mBytesPerPacket    =   4;
  in.mDataFormat.mFramesPerPacket   =   isStereo ? 1 : 2;
  in.mDataFormat.mBytesPerFrame     =   isStereo ? 4 : 2;
  in.mDataFormat.mChannelsPerFrame  =   isStereo ? 2 : 1;
  in.mDataFormat.mBitsPerChannel    =   16;
	
	
  /* Pre-buffer before we turn on audio */
  UInt32 err;
  err = AudioQueueNewOutput(&in.mDataFormat,
                            AQBufferCallback,
                            NULL,
                            NULL,
                            kCFRunLoopCommonModes,
                            0,
                            &in.queue);
	
	bufferBytes = AUDIO_BUFFER_SIZE;
	
	for (i=0; i<AUDIO_BUFFERS; i++) 
	{
		err = AudioQueueAllocateBuffer(in.queue, bufferBytes, &in.mBuffers[i]);
		/* "Prime" by calling the callback once per buffer */
		//AQBufferCallback (&in, in.queue, in.mBuffers[i]);
		in.mBuffers[i]->mAudioDataByteSize = AUDIO_BUFFER_SIZE; //samples_per_frame * 2; //inData->mDataFormat.mBytesPerFrame; //(inData->frameCount * 4 < (sndOutLen) ? inData->frameCount * 4 : (sndOutLen));
		AudioQueueEnqueueBuffer(in.queue, in.mBuffers[i], 0, NULL);
	}
	
	soundInit = 1;
	err = AudioQueueStart(in.queue, NULL);
	
	return 0;
}

void SICloseSound(void) {
	if( soundInit == 1 )
	{
		AudioQueueDispose(in.queue, true);
		soundInit = 0;
	}
}


void SIMuteSound(void) {
	if( soundInit == 1 )
	{
		SICloseSound();
	}
}

void SIDemuteSound(int buffersize) {
	if( soundInit == 0 )
	{
		SIOpenSound(buffersize);
	}
}

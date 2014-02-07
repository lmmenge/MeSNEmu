#include "iOSAudio.h"

#include <AudioToolbox/AudioQueue.h>

#include "../SNES9X/port.h"
#include "../SNES9X/apu/apu.h"

#pragma mark Defines

#define SI_AUDIO_BUFFER_COUNT 6
//#define FRAME_SIZE 2048

#pragma mark - External Forward Declarations

//extern void S9xMixSamplesO (signed short* buffer, int sample_count, int sample_offset);
extern bool8 S9xMixSamples (uint8* buffer, int sample_count);

extern volatile int SI_EmulationPaused;
extern volatile int SI_EmulationRun;
extern volatile int SI_SoundOn;

#pragma mark - Private Structures

typedef struct AQCallbackStruct {
  AudioQueueRef queue;
  UInt32 frameCount;
  AudioQueueBufferRef mBuffers[SI_AUDIO_BUFFER_COUNT];
  AudioStreamBasicDescription mDataFormat;
} AQCallbackStruct;

#pragma mark - Global Variables

//const int SI_IsStereo = 0;
const int SI_IsStereo = 1;
AQCallbackStruct SI_AQCallbackStruct = {0};
uint32_t SI_SoundBufferSizeBytes = 0;
int SI_SoundIsInit = 0;
float SI_AudioVolume = 1.0;
float SI_AQCallbackCount = 0;

volatile int SI_AudioIsOnHold = 1;

volatile int SI_AudioOffset = 0;

#pragma mark - Audio Queue Management

static void AQBufferCallback(
                             void* userdata,
                             AudioQueueRef outQ,
                             AudioQueueBufferRef outQB)
{
	outQB->mAudioDataByteSize = SI_SoundBufferSizeBytes;
  AudioQueueSetParameter(outQ, kAudioQueueParam_Volume, SI_AudioVolume);

	if(SI_EmulationPaused || !SI_EmulationRun || !SI_SoundIsInit)
  {
    SI_AudioIsOnHold = 1;
    SI_AudioOffset = 0;
    memset(outQB->mAudioData, 0, SI_SoundBufferSizeBytes);
  }
	else
  {
    SI_AudioIsOnHold = 0;

    //static int i = 0;
    //printf("willLock %i\n", i);
    //printf("locked %i\n", i);
    //i++;
    int totalSamples = S9xGetSampleCount();
    int totalBytes = totalSamples;
    int samplesToUse = totalSamples;
    int bytesToUse = totalBytes;
    if(Settings.SixteenBitSound == true)
    {
      bytesToUse *= 2;
      totalBytes *= 2;
    }
    if(bytesToUse > SI_SoundBufferSizeBytes)
    {
      bytesToUse = SI_SoundBufferSizeBytes;
      if(Settings.SixteenBitSound == true)
        samplesToUse = SI_SoundBufferSizeBytes/2;
      else
        samplesToUse = SI_SoundBufferSizeBytes;
    }
    
    // calculating the audio offset
    int samplesShouldBe = SI_SoundBufferSizeBytes;
    if(Settings.SixteenBitSound == true)
      samplesShouldBe = SI_SoundBufferSizeBytes/2;
    
    SI_AudioOffset -= (totalSamples-samplesShouldBe)*(1.0/Settings.SoundPlaybackRate)*1000-50;
    if(SI_AudioOffset > 8000)
      SI_AudioOffset = 4000;
    else if(SI_AudioOffset < -8000)
      SI_AudioOffset = -4000;
    //SI_AudioOffset = 900; // -900 is the magic number for this emulator running on iOS Simulator on my computer
    //printf("AudioOffset: %i\n", SI_AudioOffset);
  
    if(samplesToUse > 0)
      S9xMixSamples((unsigned char*)outQB->mAudioData, samplesToUse);
    
    if(bytesToUse < SI_SoundBufferSizeBytes)
    {
      if(bytesToUse == 0)
      {
        // do nothing here... we didn't copy anything... scared that if i write something to the output buffer, we'll get chirps and stuff
        //printf("0 sampes available\n");
      }
      else
      {
        //printf("Fixing %i of %i\n", bytesToUse, SI_SoundBufferSizeBytes);
        // sounds wiggly
        memset(((unsigned char*)outQB->mAudioData)+bytesToUse, ((unsigned char*)outQB->mAudioData)[bytesToUse-1], SI_SoundBufferSizeBytes-bytesToUse);
      }
    }
  }

	AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
}

int SIOpenSound(int buffersize)
{
  SI_SoundIsInit = 0;
  SI_AudioOffset = 0;
	
  if(SI_AQCallbackStruct.queue != 0)
    AudioQueueDispose(SI_AQCallbackStruct.queue, true);
  
  SI_AQCallbackCount = 0;
  memset(&SI_AQCallbackStruct, 0, sizeof(AQCallbackStruct));
  
  Float64 sampleRate = 22050.0;
  sampleRate = Settings.SoundPlaybackRate;
	SI_SoundBufferSizeBytes = buffersize;
	
  SI_AQCallbackStruct.mDataFormat.mSampleRate = sampleRate;
  SI_AQCallbackStruct.mDataFormat.mFormatID = kAudioFormatLinearPCM;
  SI_AQCallbackStruct.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
  SI_AQCallbackStruct.mDataFormat.mBytesPerPacket    =   4;
  SI_AQCallbackStruct.mDataFormat.mFramesPerPacket   =   SI_IsStereo ? 1 : 2;
  SI_AQCallbackStruct.mDataFormat.mBytesPerFrame     =   SI_IsStereo ? 4 : 2;
  SI_AQCallbackStruct.mDataFormat.mChannelsPerFrame  =   SI_IsStereo ? 2 : 1;
  SI_AQCallbackStruct.mDataFormat.mBitsPerChannel    =   Settings.SixteenBitSound ? 16: 8;
	
	
  /* Pre-buffer before we turn on audio */
  UInt32 err;
  err = AudioQueueNewOutput(&SI_AQCallbackStruct.mDataFormat,
                            AQBufferCallback,
                            NULL,
                            NULL,
                            kCFRunLoopCommonModes,
                            0,
                            &SI_AQCallbackStruct.queue);
	
	for(int i=0; i<SI_AUDIO_BUFFER_COUNT; i++) 
	{
		err = AudioQueueAllocateBuffer(SI_AQCallbackStruct.queue, SI_SoundBufferSizeBytes, &SI_AQCallbackStruct.mBuffers[i]);
    memset(SI_AQCallbackStruct.mBuffers[i]->mAudioData, 0, SI_SoundBufferSizeBytes);
		SI_AQCallbackStruct.mBuffers[i]->mAudioDataByteSize = SI_SoundBufferSizeBytes; //samples_per_frame * 2; //inData->mDataFormat.mBytesPerFrame; //(inData->frameCount * 4 < (sndOutLen) ? inData->frameCount * 4 : (sndOutLen));
		AudioQueueEnqueueBuffer(SI_AQCallbackStruct.queue, SI_AQCallbackStruct.mBuffers[i], 0, NULL);
	}
	
	SI_SoundIsInit = 1;
	err = AudioQueueStart(SI_AQCallbackStruct.queue, NULL);
	
	return 0;
}

void SICloseSound(void)
{
	if( SI_SoundIsInit == 1 )
	{
		AudioQueueDispose(SI_AQCallbackStruct.queue, true);
		SI_SoundIsInit = 0;
    SI_AudioIsOnHold = 1;
	}
}

int SIAudioOffset()
{
  return -SI_AudioOffset;
}

void SIMuteSound(void)
{
	if( SI_SoundIsInit == 1 )
	{
		SICloseSound();
	}
}

void SIDemuteSound(int buffersize)
{
	if( SI_SoundIsInit == 0 )
	{
		SIOpenSound(buffersize);
	}
}

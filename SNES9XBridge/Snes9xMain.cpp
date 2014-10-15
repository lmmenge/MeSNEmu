#include "Snes9xMain.h"

#include <sys/stat.h>
#include <sys/time.h>

#include "../SNES9X/snes9x.h"
#include "../SNES9X/memmap.h"
#include "../SNES9X/apu/apu.h"
#include "../SNES9X/controls.h"
#include "../SNES9X/display.h"

#include "iOSAudio.h"

#pragma mark Defines

#define MAX_PATH 255
#define DIR_SEPERATOR	"/"

#define	ASSIGN_BUTTONf(n, s)	S9xMapButton (n, cmd = S9xGetCommandT(s), false)

#pragma mark - External Forward Declarations

// client-implemented functions called up by the emulator
extern "C" void SIFlipFramebufferClient(int width, int height);
extern "C" void SILoadRunningStateForGameNamed(const char* romFileName);
extern "C" void SISaveRunningStateForGameNamed(const char* romFileName);

// these are reset when stopping/resetting to make sure the auto-frameskip works
extern struct timeval SI_NextFrameTime;
extern int SI_FrameTimeDebt;
extern int SI_SleptLastFrame;

// audio tracking
extern volatile int SI_AudioIsOnHold;

#pragma mark - Global Variables

// initial flags set by the UI
int SI_SoundOn = 1;
int SI_AutoFrameskip = 1;
int SI_Frameskip = 0;

// run management flags which are set by the UI
volatile int SI_EmulationRun = 0;
volatile int SI_EmulationSaving = 0;
volatile int SI_EmulationPaused = 0;
// run management flags which are set by the emulator to notify of status
volatile int SI_EmulationDidPause = 1;
volatile int SI_EmulationIsRunning = 0;

// internal paths
char SI_DocumentsPath[1024];
char SI_RunningStatesPath[1024];
char SI_SRAMPath[1024];

#pragma mark - Emulator-Client internal interfaces

void SIFlipFramebuffer(int width, int height)
{
  //memcpy(screenPixels, vrambuffer, 256*224*2);
  SIFlipFramebufferClient(width, height);
}

const char* SIGetFilename(const char* ex)
{
  static char filename [PATH_MAX + 1];
  char drive [_MAX_DRIVE + 1];
  char dir [_MAX_DIR + 1];
  char fname [_MAX_FNAME + 1];
  char ext [_MAX_EXT + 1];
  
  _splitpath (Memory.ROMFilename, drive, dir, fname, ext);
  //strcpy (filename, SIGetSnapshotDirectory());
  strcpy (filename, "");
  strcat (filename, SLASH_STR);
  strcat (filename, fname);
  strcat (filename, ex);
  return (filename);
}

#pragma mark - Path management

extern "C" void SISetSystemPath(const char* path)
{
  strcpy(SI_DocumentsPath, path);
}

extern "C" void SISetRunningStatesPath(const char* path)
{
  strcpy(SI_RunningStatesPath, path);
}

extern "C" void SISetSRAMPath(const char* path)
{
  strcpy(SI_SRAMPath, path);
}

#pragma mark - Emulated hardware management

extern "C" void SISetScreen(unsigned char* screen)
{
  GFX.Screen = (uint16*)screen;
}

extern "C" void SISetSoundOn(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  SI_SoundOn = value;
}

extern "C" void SISetAutoFrameskip(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  SI_AutoFrameskip = value;
}

extern "C" void SISetFrameskip(int value)
{
  SI_Frameskip = value;
}

#pragma mark - Run-state management

extern "C" void SISetEmulationRunning(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  SI_EmulationRun = value;
}

extern "C" void SISetEmulationPaused(int value)
{
  if(value < 0)
    value = 0;
  else if(value > 1)
    value = 1;
  if(SI_EmulationPaused != value)
  {
    if(value == 0)
    {
      // we're unpausing. Reset the frameskip metrics
      SI_NextFrameTime = (timeval){0,0};
      SI_FrameTimeDebt = 0;
      SI_SleptLastFrame = 0;
    }
    else
      SI_EmulationDidPause = 0;
    
    SI_EmulationPaused = value;
  }
  else if(SI_EmulationPaused == 1)
    SI_EmulationDidPause = 1;
}

extern "C" void SIWaitForPause()
{
  if(SI_EmulationPaused == 1 && SI_EmulationIsRunning == 1)
    // wait for the pause to conclude
    while((SI_EmulationDidPause == 0 || SI_AudioIsOnHold == 0) && SI_EmulationIsRunning == 1){}
}

extern "C" void SIWaitForEmulationEnd()
{
  while(SI_EmulationIsRunning == 1){}
}

extern "C" void SIReset()
{
  SI_EmulationPaused = 1;
  SISaveSRAM();
  S9xReset();
  SILoadSRAM();
  
  SI_NextFrameTime = (timeval){0,0};
  SI_FrameTimeDebt = 0;
  SI_SleptLastFrame = 0;
  
  SI_EmulationPaused = 0;
}

#pragma mark - Controller updates

extern "C" void SISetControllerPushButton(unsigned long button)
{
  S9xReportButton((uint32)button, (bool)1);
}

extern "C" void SISetControllerReleaseButton(unsigned long button)
{
  S9xReportButton((uint32)button, (bool)0);
}

#pragma mark - SRAM Management

void SILoadSRAM()
{
	char path[MAX_PATH];
	
	sprintf(path, "%s%s%s", SI_SRAMPath, DIR_SEPERATOR, SIGetFilename(".srm"));
	Memory.LoadSRAM(path);
}

void SISaveSRAM()
{
	char path[MAX_PATH];
#if 0	
	if (CPU.SRAMModified)
#endif
	{
		sprintf(path, "%s%s%s", SI_SRAMPath, DIR_SEPERATOR, SIGetFilename(".srm"));
		Memory.SaveSRAM(path);
		sync();
	}
}

#pragma mark - Notifications to the emulator

extern "C" void SIUpdateSettings()
{
  if(SI_AutoFrameskip)
    Settings.SkipFrames = AUTO_FRAMERATE;
  else
    Settings.SkipFrames = SI_Frameskip;
}

#pragma mark - Main starting point

extern "C" int SIStartWithROM(char* rom_filename)
{
  // notify that we're running
  SI_EmulationIsRunning = 1;
  
  // frameskip settings reset
  SI_NextFrameTime = (timeval){0, 0};
  SI_FrameTimeDebt = 0;
  SI_SleptLastFrame = 0;
  
  // ensure dirs exist
  mode_t dir_mode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH;
	mkdir(SI_SRAMPath, dir_mode);
  
  // unix init
	ZeroMemory(&Settings, sizeof(Settings));
	Settings.MouseMaster = TRUE;
	Settings.SuperScopeMaster = TRUE;
	Settings.JustifierMaster = TRUE;
	Settings.MultiPlayer5Master = TRUE;
	Settings.FrameTimePAL = 20000;
	Settings.FrameTimeNTSC = 16667;
	Settings.SixteenBitSound = TRUE;
	Settings.Stereo = TRUE;
  //Settings.Stereo = FALSE;
	Settings.SoundPlaybackRate = 32000;
  //Settings.SoundPlaybackRate = 22050;
	//Settings.SoundInputRate = 32000;
  Settings.SoundInputRate = 32000;
  Settings.SoundSync = FALSE;
	Settings.SupportHiRes = TRUE;
	Settings.Transparency = TRUE;
	Settings.AutoDisplayMessages = TRUE;
	Settings.InitialInfoStringTimeout = 120;
	Settings.HDMATimingHack = 100;
	Settings.BlockInvalidVRAMAccessMaster = TRUE;
	Settings.StopEmulation = TRUE;
	Settings.WrongMovieStateProtection = TRUE;
	Settings.DumpStreamsMaxFrames = -1;
	Settings.StretchScreenshots = 1;
	Settings.SnapshotScreenshots = TRUE;
  if(SI_AutoFrameskip)
    Settings.SkipFrames = AUTO_FRAMERATE;
  else
    Settings.SkipFrames = SI_Frameskip;
  //Settings.SkipFrames = 1;
	Settings.TurboSkipFrames = 15;
	Settings.CartAName[0] = 0;
	Settings.CartBName[0] = 0;
#ifdef NETPLAY_SUPPORT
	Settings.ServerName[0] = 0;
#endif
  
	CPU.Flags = 0;
  
	/*S9xLoadConfigFiles(argv, argc);
	rom_filename = S9xParseArgs(argv, argc);
  
	make_snes9x_dirs();*/
  
	if (!Memory.Init() || !S9xInitAPU())
	{
		fprintf(stderr, "Snes9x: Memory allocation failure - not enough RAM/virtual memory available.\nExiting...\n");
		Memory.Deinit();
		S9xDeinitAPU();
		exit(1);
	}
  
  int samplecount = Settings.SoundPlaybackRate/(Settings.PAL ? 50 : 60);
  int soundBufferSize = samplecount<<(1+(Settings.Stereo?1:0));
  S9xInitSound(soundBufferSize, 0);
	S9xSetSoundMute(TRUE);
  
  S9xReset();
  
  S9xUnmapAllControls();
  S9xSetController(0, CTL_JOYPAD, 0, 0, 0, 0);
  //S9xSetController(1, CTL_JOYPAD, 1, 0, 0, 0);
  
  s9xcommand_t	cmd;
  
	ASSIGN_BUTTONf(SI_BUTTON_X,         "Joypad1 X");
	ASSIGN_BUTTONf(SI_BUTTON_A,         "Joypad1 A");
	ASSIGN_BUTTONf(SI_BUTTON_B,         "Joypad1 B");
	ASSIGN_BUTTONf(SI_BUTTON_Y,         "Joypad1 Y");
	ASSIGN_BUTTONf(SI_BUTTON_L,         "Joypad1 L");
	ASSIGN_BUTTONf(SI_BUTTON_R,         "Joypad1 R");
	ASSIGN_BUTTONf(SI_BUTTON_SELECT,    "Joypad1 Select");
	ASSIGN_BUTTONf(SI_BUTTON_START,     "Joypad1 Start");
	ASSIGN_BUTTONf(SI_BUTTON_UP,        "Joypad1 Up");
	ASSIGN_BUTTONf(SI_BUTTON_DOWN,      "Joypad1 Down");
	ASSIGN_BUTTONf(SI_BUTTON_LEFT,      "Joypad1 Left");
	ASSIGN_BUTTONf(SI_BUTTON_RIGHT,     "Joypad1 Right");
  
	S9xReportControllers();
  
#ifdef GFX_MULTI_FORMAT
	S9xSetRenderPixelFormat(RGB565);
#endif
  
	uint32	saved_flags = CPU.Flags;
	bool8	loaded = FALSE;
  
	if (Settings.Multi)
	{
		loaded = Memory.LoadMultiCart(Settings.CartAName, Settings.CartBName);
    
		if (!loaded)
		{
			char	s1[PATH_MAX + 1], s2[PATH_MAX + 1];
			char	drive[_MAX_DRIVE + 1], dir[_MAX_DIR + 1], fname[_MAX_FNAME + 1], ext[_MAX_EXT + 1];
      
			s1[0] = s2[0] = 0;
      
			if (Settings.CartAName[0])
			{
				_splitpath(Settings.CartAName, drive, dir, fname, ext);
				snprintf(s1, PATH_MAX + 1, "%s%s%s", S9xGetDirectory(ROM_DIR), SLASH_STR, fname);
				if (ext[0] && (strlen(s1) <= PATH_MAX - 1 - strlen(ext)))
				{
					strcat(s1, ".");
					strcat(s1, ext);
				}
			}
      
			if (Settings.CartBName[0])
			{
				_splitpath(Settings.CartBName, drive, dir, fname, ext);
				snprintf(s2, PATH_MAX + 1, "%s%s%s", S9xGetDirectory(ROM_DIR), SLASH_STR, fname);
				if (ext[0] && (strlen(s2) <= PATH_MAX - 1 - strlen(ext)))
				{
					strcat(s2, ".");
					strcat(s2, ext);
				}
			}
      
			loaded = Memory.LoadMultiCart(s1, s2);
		}
	}
	else
    if (rom_filename)
    {
      char rom_path[1024] = {0};
      sprintf(rom_path,"%s%s%s",SI_DocumentsPath,DIR_SEPERATOR,rom_filename);
      
      loaded = Memory.LoadROM(rom_path);
      
      /*if (!loaded && rom_filename[0])
      {
        char	s[PATH_MAX + 1];
        char	drive[_MAX_DRIVE + 1], dir[_MAX_DIR + 1], fname[_MAX_FNAME + 1], ext[_MAX_EXT + 1];
        
        _splitpath(rom_filename, drive, dir, fname, ext);
        snprintf(s, PATH_MAX + 1, "%s%s%s", S9xGetDirectory(ROM_DIR), SLASH_STR, fname);
        if (ext[0] && (strlen(s) <= PATH_MAX - 1 - strlen(ext)))
        {
          strcat(s, ".");
          strcat(s, ext);
        }
        
        loaded = Memory.LoadROM(s);
      }*/
    }
  
	if (!loaded)
	{
		fprintf(stderr, "Error opening the ROM file.\n");
		exit(1);
	}
  
	//NSRTControllerSetup();
	//Memory.LoadSRAM(S9xGetFilename(".srm", SRAM_DIR));
  SILoadSRAM();
	//S9xLoadCheatFile(S9xGetFilename(".cht", CHEAT_DIR));
  
	CPU.Flags = saved_flags;
	Settings.StopEmulation = FALSE;
  
#ifdef DEBUGGER
	struct sigaction sa;
	sa.sa_handler = sigbrkhandler;
#ifdef SA_RESTART
	sa.sa_flags = SA_RESTART;
#else
	sa.sa_flags = 0;
#endif
	sigemptyset(&sa.sa_mask);
	sigaction(SIGINT, &sa, NULL);
#endif
  
  GFX.Pitch = 512*2;
  /*vrambuffer = (uint8*) malloc (GFX.Pitch * SNES_HEIGHT_EXTENDED*2);
	memset (vrambuffer, 0, GFX.Pitch * SNES_HEIGHT_EXTENDED*2);
  GFX.Screen = (uint16*)vrambuffer;*/
  S9xGraphicsInit();
  
#ifdef NETPLAY_SUPPORT
	if (strlen(Settings.ServerName) == 0)
	{
		char	*server = getenv("S9XSERVER");
		if (server)
		{
			strncpy(Settings.ServerName, server, 127);
			Settings.ServerName[127] = 0;
		}
	}
  
	char	*port = getenv("S9XPORT");
	if (Settings.Port >= 0 && port)
		Settings.Port = atoi(port);
	else
    if (Settings.Port < 0)
      Settings.Port = -Settings.Port;
  
	if (Settings.NetPlay)
	{
		NetPlay.MaxFrameSkip = 10;
    
		if (!S9xNPConnectToServer(Settings.ServerName, Settings.Port, Memory.ROMName))
		{
			fprintf(stderr, "Failed to connect to server %s on port %d.\n", Settings.ServerName, Settings.Port);
			S9xExit();
		}
    
		fprintf(stderr, "Connected to server %s on port %d as player #%d playing %s.\n", Settings.ServerName, Settings.Port, NetPlay.Player, Memory.ROMName);
	}
#endif
  
  // HACK: disabling SMV
	/*if (play_smv_filename)
	{
		uint32	flags = CPU.Flags & (DEBUG_MODE_FLAG | TRACE_FLAG);
		if (S9xMovieOpen(play_smv_filename, TRUE) != SUCCESS)
			exit(1);
		CPU.Flags |= flags;
	}
	else
    if (record_smv_filename)
    {
      uint32	flags = CPU.Flags & (DEBUG_MODE_FLAG | TRACE_FLAG);
      if (S9xMovieCreate(record_smv_filename, 0xFF, MOVIE_OPT_FROM_RESET, NULL, 0) != SUCCESS)
        exit(1);
      CPU.Flags |= flags;
    }
    else
      if (snapshot_filename)
      {
        uint32	flags = CPU.Flags & (DEBUG_MODE_FLAG | TRACE_FLAG);
        if (!S9xUnfreezeGame(snapshot_filename))
          exit(1);
        CPU.Flags |= flags;
      }*/
  
	//S9xGraphicsMode();
  
	sprintf(String, "\"%s\" %s: %s", Memory.ROMName, TITLE, VERSION);
	//S9xSetTitle(String);
  
#ifdef JOYSTICK_SUPPORT
	uint32	JoypadSkip = 0;
#endif
  
  SILoadRunningStateForGameNamed(rom_filename);
  SI_EmulationPaused = 0;
  
  //if(SI_SoundOn)
  SIDemuteSound(soundBufferSize);
	S9xSetSoundMute(FALSE);
  
#ifdef NETPLAY_SUPPORT
	bool8	NP_Activated = Settings.NetPlay;
#endif
  
	while (1)
	{
#ifdef NETPLAY_SUPPORT
		if (NP_Activated)
		{
			if (NetPlay.PendingWait4Sync && !S9xNPWaitForHeartBeatDelay(100))
			{
				S9xProcessEvents(FALSE);
				continue;
			}
      
			for (int J = 0; J < 8; J++)
				old_joypads[J] = MovieGetJoypad(J);
      
			for (int J = 0; J < 8; J++)
				MovieSetJoypad(J, joypads[J]);
      
			if (NetPlay.Connected)
			{
				if (NetPlay.PendingWait4Sync)
				{
					NetPlay.PendingWait4Sync = FALSE;
					NetPlay.FrameCount++;
					S9xNPStepJoypadHistory();
				}
			}
			else
			{
				fprintf(stderr, "Lost connection to server.\n");
				S9xExit();
			}
		}
#endif
    
#ifdef DEBUGGER
		if (!Settings.Paused || (CPU.Flags & (DEBUG_MODE_FLAG | SINGLE_STEP_FLAG)))
#else
    if (!Settings.Paused && !SI_EmulationPaused)
#endif
    {
      S9xMainLoop();
    }
    
#ifdef NETPLAY_SUPPORT
		if (NP_Activated)
		{
			for (int J = 0; J < 8; J++)
				MovieSetJoypad(J, old_joypads[J]);
		}
#endif
    
#ifdef DEBUGGER
		if(Settings.Paused || (CPU.Flags & DEBUG_MODE_FLAG))
#else
    if(Settings.Paused || SI_EmulationPaused)
#endif
        S9xSetSoundMute(TRUE);
    
#ifdef DEBUGGER
		if (CPU.Flags & DEBUG_MODE_FLAG)
			S9xDoDebug();
		else
#endif
      if(Settings.Paused || SI_EmulationPaused || !SI_EmulationRun)
      {
        SISaveSRAM();
        SISaveRunningStateForGameNamed(rom_filename);
        SI_EmulationDidPause = 1;
        
        do {
          //S9xProcessEvents(FALSE);
          if(!SI_EmulationRun)
            break;
          usleep(100000);
        } while (SI_EmulationPaused);
        
        if(!SI_EmulationRun)
        {
          SISaveSRAM();
          SISaveRunningStateForGameNamed(rom_filename);
          
          SIMuteSound();
          
          S9xGraphicsDeinit();
          Memory.Deinit();
          S9xDeinitAPU();
          break;
        }
      }
    
#ifdef JOYSTICK_SUPPORT
		if (unixSettings.JoystickEnabled && (JoypadSkip++ & 1) == 0)
			ReadJoysticks();
#endif
    
		//S9xProcessEvents(FALSE);
    
#ifdef DEBUGGER
		if(!Settings.Paused && !(CPU.Flags & DEBUG_MODE_FLAG))
#else
    if(!Settings.Paused && !SI_EmulationPaused)
#endif
      S9xSetSoundMute(FALSE);
	}
  SI_EmulationIsRunning = 0;
  
	return (0);
}

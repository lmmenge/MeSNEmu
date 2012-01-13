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
#define SNES_SRAM_DIR "sram"

#define	ASSIGN_BUTTONf(n, s)	S9xMapButton (n, cmd = S9xGetCommandT(s), false)

enum
{
  SIOS_UP=0x1,
  SIOS_LEFT=0x4,
  SIOS_DOWN=0x10,
  SIOS_RIGHT=0x40,
  SIOS_START=1<<8,
  SIOS_SELECT=1<<9,
  SIOS_L=1<<10,
  SIOS_R=1<<11,
  SIOS_A=1<<12,
  SIOS_B=1<<13,
  SIOS_X=1<<14,
  SIOS_Y=1<<15,
  SIOS_VOL_UP=1<<23,
  SIOS_VOL_DOWN=1<<22,
  SIOS_PUSH=1<<27
};

#pragma mark - External Forward Declarations

extern "C" void SIFlipFramebufferClient(void);

extern char SI_DocumentsPath[1024];
extern int SI_SoundOn;
extern int SI_AutoFrameskip;
extern int SI_Frameskip;
extern volatile int SI_EmulationRun;
extern volatile int SI_EmulationPaused;
extern unsigned int *screenPixels;

extern struct timeval SI_NextFrameTime;
extern int SI_FrameTimeDebt;
extern int SI_SleptLastFrame;

#pragma mark - Global Variables

char currentWorkingDir[MAX_PATH+1];
char snesSramDir[MAX_PATH+1];

uint8 *vrambuffer = NULL;

#pragma mark - Utility Functions

void SIFlipFramebuffer(int flip, int sync)
{
  //memcpy(screenPixels, vrambuffer, 256*224*2);
  SIFlipFramebufferClient();
}

const char* SIGetSnapshotDirectory(void)
{
  S9xMessage (0,0,"get snapshot dir");
  return "";
}

const char *SIGetFilename (const char *ex)
{
  static char filename [PATH_MAX + 1];
  char drive [_MAX_DRIVE + 1];
  char dir [_MAX_DIR + 1];
  char fname [_MAX_FNAME + 1];
  char ext [_MAX_EXT + 1];
  
  _splitpath (Memory.ROMFilename, drive, dir, fname, ext);
  strcpy (filename, SIGetSnapshotDirectory());
  strcat (filename, SLASH_STR);
  strcat (filename, fname);
  strcat (filename, ex);
  return (filename);
}

void SILoadSRAM (void)
{
	char path[MAX_PATH];
	
	sprintf(path,"%s%s%s",snesSramDir,DIR_SEPERATOR,SIGetFilename (".srm"));
	Memory.LoadSRAM (path);
}

void SISaveSRAM (void)
{
	char path[MAX_PATH];
#if 0	
	if (CPU.SRAMModified)
#endif
	{
		sprintf(path,"%s%s%s",snesSramDir,DIR_SEPERATOR,SIGetFilename (".srm"));
		Memory.SaveSRAM (path);
		sync();
	}
}

#pragma mark - Save State I/O

// save state file I/O
int  (*statef_open)(const char *fname, const char *mode);
int  (*statef_read)(void *p, int l);
int  (*statef_write)(void *p, int l);
void (*statef_close)();
static FILE  *state_file = 0;

int state_unc_open(const char *fname, const char *mode)
{
	state_file = fopen(fname, mode);
	return (int) state_file;
}

int state_unc_read(void *p, int l)
{
	return fread(p, 1, l, state_file);
}

int state_unc_write(void *p, int l)
{
	return fwrite(p, 1, l, state_file);
}

void state_unc_close()
{
	fclose(state_file);
}

#pragma mark - Start Up and Tear Down

extern "C" void SIUpdateSettings ()
{
  if(SI_AutoFrameskip)
    Settings.SkipFrames = AUTO_FRAMERATE;
  else
    Settings.SkipFrames = SI_Frameskip;
}

extern "C" int SIStartWithROM (char* rom_filename)
{
  // legacy init
  SI_NextFrameTime = (timeval){0, 0};
  SI_FrameTimeDebt = 0;
  SI_SleptLastFrame = 0;
  
  // saves
	statef_open  = state_unc_open;
	statef_read  = state_unc_read;
	statef_write = state_unc_write;
	statef_close = state_unc_close;
  
  // paths
  sprintf(currentWorkingDir, "%s", SI_DocumentsPath);
	sprintf(snesSramDir,"%s%s%s",currentWorkingDir,DIR_SEPERATOR,SNES_SRAM_DIR);
  
  // ensure dirs exist
  mode_t dir_mode = S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH;
	mkdir(snesSramDir,dir_mode);
  
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
  
	ASSIGN_BUTTONf(SIOS_X,         "Joypad1 X");
	ASSIGN_BUTTONf(SIOS_A,         "Joypad1 A");
	ASSIGN_BUTTONf(SIOS_B,         "Joypad1 B");
	ASSIGN_BUTTONf(SIOS_Y,         "Joypad1 Y");
	ASSIGN_BUTTONf(SIOS_L,         "Joypad1 L");
	ASSIGN_BUTTONf(SIOS_R,         "Joypad1 R");
	ASSIGN_BUTTONf(SIOS_SELECT,    "Joypad1 Select");
	ASSIGN_BUTTONf(SIOS_START,     "Joypad1 Start");
	ASSIGN_BUTTONf(SIOS_UP,        "Joypad1 Up");
	ASSIGN_BUTTONf(SIOS_DOWN,      "Joypad1 Down");
	ASSIGN_BUTTONf(SIOS_LEFT,      "Joypad1 Left");
	ASSIGN_BUTTONf(SIOS_RIGHT,     "Joypad1 Right");
  
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
  
  GFX.Pitch = SNES_WIDTH*2;
  /*vrambuffer = (uint8 *) malloc (GFX.Pitch * SNES_HEIGHT_EXTENDED*2);
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
      S9xMainLoop();
    
#ifdef NETPLAY_SUPPORT
		if (NP_Activated)
		{
			for (int J = 0; J < 8; J++)
				MovieSetJoypad(J, old_joypads[J]);
		}
#endif
    
#ifdef DEBUGGER
		if (Settings.Paused || (CPU.Flags & DEBUG_MODE_FLAG))
#else
      if (Settings.Paused || SI_EmulationPaused)
#endif
        S9xSetSoundMute(TRUE);
    
#ifdef DEBUGGER
		if (CPU.Flags & DEBUG_MODE_FLAG)
			S9xDoDebug();
		else
#endif
      if (Settings.Paused || SI_EmulationPaused || !SI_EmulationRun)
      {
        SISaveSRAM();
        
        do {
          //S9xProcessEvents(FALSE);
          if(!SI_EmulationRun)
            break;
          usleep(100000);
        } while (SI_EmulationPaused);
        
        if(!SI_EmulationRun)
        {
          SISaveSRAM();
          
          SIMuteSound();
          if(vrambuffer != NULL)
            free(vrambuffer);
          vrambuffer = NULL;
          
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
		if (!Settings.Paused && !(CPU.Flags & DEBUG_MODE_FLAG))
#else
      if (!Settings.Paused && !SI_EmulationPaused)
#endif
        S9xSetSoundMute(FALSE);
	}
  
	return (0);
}

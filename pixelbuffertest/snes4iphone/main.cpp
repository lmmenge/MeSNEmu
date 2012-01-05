#include <sys/stat.h>

#include "snes9x/snes9x.h"
#include "snes9x/memmap.h"
#include "snes9x/apu/apu.h"
#include "snes9x/controls.h"
#include "snes9x/display.h"

#include "iphone_sdk.h"

#define MAX_PATH 255
#define DIR_SEPERATOR	"/"
#define SNES_SRAM_DIR "sram"

#define EMUVERSION "LMSNES 0.1 (2012-01-05)"

enum
{
  GP2X_UP=0x1,
  GP2X_LEFT=0x4,
  GP2X_DOWN=0x10,
  GP2X_RIGHT=0x40,
  GP2X_START=1<<8,
  GP2X_SELECT=1<<9,
  GP2X_L=1<<10,
  GP2X_R=1<<11,
  GP2X_A=1<<12,
  GP2X_B=1<<13,
  GP2X_X=1<<14,
  GP2X_Y=1<<15,
  GP2X_VOL_UP=1<<23,
  GP2X_VOL_DOWN=1<<22,
  GP2X_PUSH=1<<27
};

extern char SYSTEM_DIR[1024];
char currentWorkingDir[MAX_PATH+1];
char snesSramDir[MAX_PATH+1];

extern volatile int __emulation_paused;
extern volatile int __emulation_run;

void S9xSaveSRAM (void);

//---------------------------------------------------------------------------

typedef unsigned char	bool8_32;

typedef struct {
  int playback_rate;
  bool8 stereo;
  bool8 mute_sound;
  uint8 sound_switch;
  int noise_gen;
	uint32 freqbase; // notaz
} SoundStatus;

static SoundStatus		so;

uint8 *vrambuffer = NULL;
char fps_display[256];
int samplecount=0;

void S9xExit ()
{
}
   
//extern "C"
//{

  const char * S9xGetDirectory (enum s9x_getdirtype dirtype)
  {
    static int	index = 0;
    static char	path[4][PATH_MAX + 1];
    
    char	inExt[16];
    char	drive[_MAX_DRIVE + 1], dir[_MAX_DIR + 1], fname[_MAX_FNAME + 1], ext[_MAX_EXT + 1];
    
    index++;
    if (index > 3)
      index = 0;
    
    switch (dirtype)
    {
      case SNAPSHOT_DIR:		strcpy(inExt, ".frz");	break;
      case SRAM_DIR:			strcpy(inExt, ".srm");	break;
      case SCREENSHOT_DIR:	strcpy(inExt, ".png");	break;
      case SPC_DIR:			strcpy(inExt, ".spc");	break;
      case CHEAT_DIR:			strcpy(inExt, ".cht");	break;
      case BIOS_DIR:			strcpy(inExt, ".bio");	break;
      case LOG_DIR:			strcpy(inExt, ".log");	break;
      default:				strcpy(inExt, ".xxx");	break;
    }
    
    _splitpath(S9xGetFilename(inExt, dirtype), drive, dir, fname, ext);
    _makepath(path[index], drive, dir, "", "");
    
    int	l = strlen(path[index]);
    if (l > 1)
      path[index][l - 1] = 0;
    
    return (path[index]);
  }

  bool8 S9xDoScreenshot (int width, int height)
  {
    return true;
  }

  const char * S9xStringInput (const char *s)
  {
    return (NULL);
  }

  void S9xHandlePortCommand (s9xcommand_t cmd, int16 data1, int16 data2)
  {
    return;
  }

  bool S9xPollAxis (uint32 id, int16 *value)
  {
    return (false);
  }

  void S9xToggleSoundChannel (int c)
  {
    static int	channel_enable = 255;
    
    if (c == 8)
      channel_enable = 255;
    else
      channel_enable ^= 1 << c;
    
    S9xSetSoundControl(channel_enable);
  }

  bool S9xPollButton (uint32 id, bool *pressed)
  {
    *pressed = false;
    return true;
  }

  bool8 S9xContinueUpdate (int width, int height)
  {
    return (true);
  }

  bool S9xPollPointer (uint32 id, int16 *x, int16 *y)
  {
    *x = *y = 0;
    
    return (true);
  }
  
  const char * S9xChooseFilename (bool8 read_only)
  {
    return (NULL);
  }
  
  const char * S9xChooseMovieFilename (bool8 read_only)
  {
    return (NULL);
  }
  
	void S9xSetPalette ()
	{

	}

	bool8 S9xOpenSnapshotFile (const char *fname, bool8 read_only, STREAM *file)
	{
		if (read_only)
		{
      *file = OPEN_STREAM(fname,"rb");
			if (*file) 
				return(TRUE);
		}
		else
		{
      *file = OPEN_STREAM(fname,"w+b");
			if (*file) 
				return(TRUE);
		}

		return (FALSE);	
	}
	
	void S9xCloseSnapshotFile (STREAM file)
	{
		CLOSE_STREAM(file);
	}

   void S9xMessage (int /* type */, int /* number */, const char *message)
   {
		printf ("%s\n", message);
   }

   const char *S9xGetSnapshotDirectory(void)
   {
      S9xMessage (0,0,"get snapshot dir");
      return "";
   }

   bool8_32 S9xInitUpdate ()
   {
	  //GFX.Screen = (uint8 *) framebuffer16 + (640*8) + 64;

	  return (TRUE);
   }

   //bool8_32 S9xDeinitUpdate (int Width, int Height, bool8_32) // HACK: renamed
   bool8 S9xDeinitUpdate (int width, int height)
   {
	  
    // TODO clear Z buffer if not in fastsprite mode
		gp_setFramebuffer(0,0);
	   
	   return (TRUE);
   }

   //const char *S9xGetFilename (const char *ex) // HACK: renamed
  const char *S9xGetFilename (const char *ex, enum s9x_getdirtype dirtype)
   {
      static char filename [PATH_MAX + 1];
      char drive [_MAX_DRIVE + 1];
      char dir [_MAX_DIR + 1];
      char fname [_MAX_FNAME + 1];
      char ext [_MAX_EXT + 1];

      _splitpath (Memory.ROMFilename, drive, dir, fname, ext);
      strcpy (filename, S9xGetSnapshotDirectory ());
      strcat (filename, SLASH_STR);
      strcat (filename, fname);
      strcat (filename, ex);
      return (filename);
   }

  const char *S9xGetFilename (const char *ex)
  {
    static char filename [PATH_MAX + 1];
    char drive [_MAX_DRIVE + 1];
    char dir [_MAX_DIR + 1];
    char fname [_MAX_FNAME + 1];
    char ext [_MAX_EXT + 1];
    
    _splitpath (Memory.ROMFilename, drive, dir, fname, ext);
    strcpy (filename, S9xGetSnapshotDirectory ());
    strcat (filename, SLASH_STR);
    strcat (filename, fname);
    strcat (filename, ex);
    return (filename);
  }

   //const char *S9xGetFilenameInc (const char *e)
const char * S9xGetFilenameInc (const char *inExt, enum s9x_getdirtype dirtype)
   {
      S9xMessage (0,0,"get filename inc");
      //return e;
     return inExt;
   }

   void S9xSyncSpeed(void)
   {
      //S9xMessage (0,0,"sync speed");
   }

   const char *S9xBasename (const char *f)
   {
      const char *p;

      S9xMessage (0,0,"s9x base name");

      if ((p = strrchr (f, '/')) != NULL || (p = strrchr (f, '\\')) != NULL)
         return (p + 1);

      return (f);
   }

//};

//bool8_32 S9xOpenSoundDevice (int mode, bool8_32 stereo, int buffer_size)
bool8 S9xOpenSoundDevice (void) // HACK: this is never called, apparently
	{
		so.sound_switch = 255;
		//so.playback_rate = mode;
		so.stereo = FALSE;//stereo;
		return TRUE;
	}
	
void S9xAutoSaveSRAM (void)
{
	//since I can't sync the data, there is no point in even writing the data
	//out at this point.  Instead I'm now saving the data as the users enter the menu.
  S9xSaveSRAM();
	//sync();  can't sync when emulator is running as it causes delays
}

void S9xLoadSRAM (void)
{
	char path[MAX_PATH];
	
	sprintf(path,"%s%s%s",snesSramDir,DIR_SEPERATOR,S9xGetFilename (".srm"));
	Memory.LoadSRAM (path);
}

void S9xSaveSRAM (void)
{
	char path[MAX_PATH];
#if 0	
	if (CPU.SRAMModified)
#endif
	{
		sprintf(path,"%s%s%s",snesSramDir,DIR_SEPERATOR,S9xGetFilename (".srm"));
		Memory.SaveSRAM (path);
		sync();
	}
}

void _makepath (char *path, const char *, const char *dir,
	const char *fname, const char *ext)
{
	if (dir && *dir)
	{
		strcpy (path, dir);
		strcat (path, "/");
	}
	else
	*path = 0;
	strcat (path, fname);
	if (ext && *ext)
	{
		strcat (path, ".");
		strcat (path, ext);
	}
}

void _splitpath (const char *path, char *drive, char *dir, char *fname,
	char *ext)
{
	*drive = 0;

	char *slash = strrchr (path, '/');
	if (!slash)
		slash = strrchr (path, '\\');

	char *dot = strrchr (path, '.');

	if (dot && slash && dot < slash)
		dot = NULL;

	if (!slash)
	{
		strcpy (dir, "");
		strcpy (fname, path);
		if (dot)
		{
			*(fname + (dot - path)) = 0;
			strcpy (ext, dot + 1);
		}
		else
			strcpy (ext, "");
	}
	else
	{
		strcpy (dir, path);
		*(dir + (slash - path)) = 0;
		strcpy (fname, slash + 1);
		if (dot)
		{
			*(fname + (dot - slash) - 1) = 0;
			strcpy (ext, dot + 1);
		}
		else
			strcpy (ext, "");
	}
} 

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

#pragma mark -

#define	ASSIGN_BUTTONf(n, s)	S9xMapButton (n, cmd = S9xGetCommandT(s), false)

extern "C" int iphone_main (char* rom_filename)
{
  // legacy init
  // saves
	statef_open  = state_unc_open;
	statef_read  = state_unc_read;
	statef_write = state_unc_write;
	statef_close = state_unc_close;
  
  // paths
  sprintf(currentWorkingDir, "%s", SYSTEM_DIR);
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
	//Settings.Stereo = TRUE;
  Settings.Stereo = FALSE;
	//Settings.SoundPlaybackRate = 32000;
  Settings.SoundPlaybackRate = 22050;
	//Settings.SoundInputRate = 32000;
  Settings.SoundInputRate = 22050;
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
	Settings.SkipFrames = AUTO_FRAMERATE;
  //Settings.SkipFrames = 1;
	Settings.TurboSkipFrames = 15;
	Settings.CartAName[0] = 0;
	Settings.CartBName[0] = 0;
#ifdef NETPLAY_SUPPORT
	Settings.ServerName[0] = 0;
#endif
  
/*#ifdef JOYSTICK_SUPPORT
	unixSettings.JoystickEnabled = TRUE;
#else
	unixSettings.JoystickEnabled = FALSE;
#endif
	unixSettings.ThreadSound = TRUE;
	unixSettings.SoundBufferSize = 100;
	unixSettings.SoundFragmentSize = 2048;*/
  
	ZeroMemory(&so, sizeof(so));
  
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
  
	S9xInitSound(samplecount<<(1+(Settings.Stereo?1:0)), 0);
	S9xSetSoundMute(TRUE);
  
  S9xReset();
  
  S9xUnmapAllControls();
  S9xSetController(0, CTL_JOYPAD, 0, 0, 0, 0);
  //S9xSetController(1, CTL_JOYPAD, 1, 0, 0, 0);
  
  s9xcommand_t	cmd;
  
	ASSIGN_BUTTONf(GP2X_Y,         "Joypad1 X");
	ASSIGN_BUTTONf(GP2X_B,         "Joypad1 A");
	ASSIGN_BUTTONf(GP2X_X,         "Joypad1 B");
	ASSIGN_BUTTONf(GP2X_A,         "Joypad1 Y");
	ASSIGN_BUTTONf(GP2X_L,         "Joypad1 L");
	ASSIGN_BUTTONf(GP2X_R,         "Joypad1 R");
	ASSIGN_BUTTONf(GP2X_SELECT,    "Joypad1 Select");
	ASSIGN_BUTTONf(GP2X_START,     "Joypad1 Start");
	ASSIGN_BUTTONf(GP2X_UP,        "Joypad1 Up");
	ASSIGN_BUTTONf(GP2X_DOWN,      "Joypad1 Down");
	ASSIGN_BUTTONf(GP2X_LEFT,      "Joypad1 Left");
	ASSIGN_BUTTONf(GP2X_RIGHT,     "Joypad1 Right");
  
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
      sprintf(rom_path,"%s%s%s",SYSTEM_DIR,DIR_SEPERATOR,rom_filename);
      
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
  S9xLoadSRAM();
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
  
	//S9xInitInputDevices();
	//S9xInitDisplay(argc, argv); // HACK: TODO: figure out what this does
	//S9xSetupDefaultKeymap();
	//S9xTextMode();
  
  GFX.Pitch = SNES_WIDTH*2;
  vrambuffer = (uint8 *) malloc (GFX.Pitch * SNES_HEIGHT_EXTENDED*2);
	memset (vrambuffer, 0, GFX.Pitch * SNES_HEIGHT_EXTENDED*2);
  GFX.Screen = (uint16*)vrambuffer;
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
  
	//InitTimer(); // HACK: this does nothing related to us, apparently
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
    if (!Settings.Paused)
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
      if (Settings.Paused || __emulation_paused)
#endif
        S9xSetSoundMute(TRUE);
    
#ifdef DEBUGGER
		if (CPU.Flags & DEBUG_MODE_FLAG)
			S9xDoDebug();
		else
#endif
      if (Settings.Paused || __emulation_paused || !__emulation_run)
      {
        do {
          //S9xProcessEvents(FALSE);
          if(!__emulation_run)
            break;
          usleep(100000);
        } while (__emulation_paused);
        
        if(!__emulation_run)
        {
          S9xSaveSRAM();
          
          app_MuteSound();
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
      if (!Settings.Paused && !__emulation_paused)
#endif
        S9xSetSoundMute(FALSE);
	}
  
	return (0);
}

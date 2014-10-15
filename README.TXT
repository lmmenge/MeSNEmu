README
======

This project was created as a hobby in order to have a stable and modern SNES emulator for iOS that could be compiled straight from Xcode for the benefit of developers with valid development certificates.

Previously available emulators were either only available on Cydia (which requires being jailbroken) or simply didn't run well when "home built" due to a much outdated SNES9X codebase or messy iOS implementation. In fact, this project started as a Xcode-compatible port of ZodTTD's snes4iphone and has been since rewritten beyond recognition.


Features:
=========

- SNES9X 1.53 codebase;
- SMC and ZIP support;
- Easy to understand UI;
- Automatic state saving/resuming, so you can quit and automatically return to the latest place you were;
- Manual state saving/resuming in another slot;
- Optional Auto-frameskip.


How to submit new iCade controller variants:
============================================

- Pair your bluetooth controller with the iOS device;
- Make sure your device's keyboard layout is set to US (QWERTY);
- Open Notes;
- Enter the following button sequence matching, as best as you can, the SNES button layout: Up, Right, Down, Left, Select, Start, Y, B, X, A, L, R;
- Copy the text generated (there should be 24 letters) and send it over to me with the correct controller name or comment on the controller tracking issue on GitHub.


How to build:
=============

- Download the source code;
- Open the MeSNEmu.xcodeproj in Xcode (version 4.2 was used in this project);
- Change the "Code Signing Identity" under "Build Settings" to your own;
- Choose your device in the Scheme selector;
- "Product" > "Profile" will deploy a Release build with all the optimizations available.
- Drop your ROMs into the app in iTunes and just run it.


Remarks:
========

Since this project is based on SNES9X 1.53 code which is mostly C++, it is slower than some other emulators, like SNES4iOS or SNES4ALL, which have parts of them in ASM from SNES9X 1.39. However, the 1.53 codebase has higher ROM compatibility. For instance, this emulator runs perfect on an iPad 2, but requires a frameskip of 1 for most games on an iPad 1 and frameskip of 2 for most games on an iPhone 4.


License:
========

Permission to use, copy, modify and/or distribute Snes9x/MeSNEmu in both binary and source form, for non-commercial purposes, is hereby granted without fee, providing that this license information and copyright notice appear with all copies and any derived work.

This software is provided 'as-is', without any express or implied warranty. In no event shall the authors be held liable for any damages arising from the use of this software or it's derivatives.

Snes9x/MeSNEmu is freeware for PERSONAL USE only. Commercial users should seek permission of the copyright holders first. Commercial use includes, but is not limited to, charging money for Snes9x/MeSNEmu or software derived from Snes9x/MeSNEmu, including Snes9x/MeSNEmu or derivatives in commercial game bundles, and/or using Snes9x/MeSNEmu as a promotion for your commercial product.

The copyright holders request that bug fixes and improvements to the code should be forwarded to them so everyone can benefit from the modifications in future versions.

Super NES and Super Nintendo Entertainment System are trademarks of Nintendo Co., Limited and its subsidiary companies.

Snes9x - Portable Super Nintendo Entertainment System (TM) emulator.

  (c) Copyright 1996 - 2002  Gary Henderson (gary.henderson@ntlworld.com),
                             Jerremy Koot (jkoot@snes9x.com)

  (c) Copyright 2002 - 2004  Matthew Kendora

  (c) Copyright 2002 - 2005  Peter Bortas (peter@bortas.org)

  (c) Copyright 2004 - 2005  Joel Yliluoma (http://iki.fi/bisqwit/)

  (c) Copyright 2001 - 2006  John Weidman (jweidman@slip.net)

  (c) Copyright 2002 - 2006  funkyass (funkyass@spam.shaw.ca),
                             Kris Bleakley (codeviolation@hotmail.com)

  (c) Copyright 2002 - 2010  Brad Jorsch (anomie@users.sourceforge.net),
                             Nach (n-a-c-h@users.sourceforge.net),

  (c) Copyright 2002 - 2011  zones (kasumitokoduck@yahoo.com)

  (c) Copyright 2006 - 2007  nitsuja

  (c) Copyright 2009 - 2011  BearOso,
                             OV2


  BS-X C emulator code
  (c) Copyright 2005 - 2006  Dreamer Nom,
                             zones

  C4 x86 assembler and some C emulation code
  (c) Copyright 2000 - 2003  _Demo_ (_demo_@zsnes.com),
                             Nach,
                             zsKnight (zsknight@zsnes.com)

  C4 C++ code
  (c) Copyright 2003 - 2006  Brad Jorsch,
                             Nach

  DSP-1 emulator code
  (c) Copyright 1998 - 2006  _Demo_,
                             Andreas Naive (andreasnaive@gmail.com),
                             Gary Henderson,
                             Ivar (ivar@snes9x.com),
                             John Weidman,
                             Kris Bleakley,
                             Matthew Kendora,
                             Nach,
                             neviksti (neviksti@hotmail.com)

  DSP-2 emulator code
  (c) Copyright 2003         John Weidman,
                             Kris Bleakley,
                             Lord Nightmare (lord_nightmare@users.sourceforge.net),
                             Matthew Kendora,
                             neviksti

  DSP-3 emulator code
  (c) Copyright 2003 - 2006  John Weidman,
                             Kris Bleakley,
                             Lancer,
                             z80 gaiden

  DSP-4 emulator code
  (c) Copyright 2004 - 2006  Dreamer Nom,
                             John Weidman,
                             Kris Bleakley,
                             Nach,
                             z80 gaiden

  OBC1 emulator code
  (c) Copyright 2001 - 2004  zsKnight,
                             pagefault (pagefault@zsnes.com),
                             Kris Bleakley
                             Ported from x86 assembler to C by sanmaiwashi

  SPC7110 and RTC C++ emulator code used in 1.39-1.51
  (c) Copyright 2002         Matthew Kendora with research by
                             zsKnight,
                             John Weidman,
                             Dark Force

  SPC7110 and RTC C++ emulator code used in 1.52+
  (c) Copyright 2009         byuu,
                             neviksti

  S-DD1 C emulator code
  (c) Copyright 2003         Brad Jorsch with research by
                             Andreas Naive,
                             John Weidman

  S-RTC C emulator code
  (c) Copyright 2001 - 2006  byuu,
                             John Weidman

  ST010 C++ emulator code
  (c) Copyright 2003         Feather,
                             John Weidman,
                             Kris Bleakley,
                             Matthew Kendora

  Super FX x86 assembler emulator code
  (c) Copyright 1998 - 2003  _Demo_,
                             pagefault,
                             zsKnight

  Super FX C emulator code
  (c) Copyright 1997 - 1999  Ivar,
                             Gary Henderson,
                             John Weidman

  Sound emulator code used in 1.5-1.51
  (c) Copyright 1998 - 2003  Brad Martin
  (c) Copyright 1998 - 2006  Charles Bilyue'

  Sound emulator code used in 1.52+
  (c) Copyright 2004 - 2007  Shay Green (gblargg@gmail.com)

  SH assembler code partly based on x86 assembler code
  (c) Copyright 2002 - 2004  Marcus Comstedt (marcus@mc.pp.se)

  2xSaI filter
  (c) Copyright 1999 - 2001  Derek Liauw Kie Fa

  HQ2x, HQ3x, HQ4x filters
  (c) Copyright 2003         Maxim Stepin (maxim@hiend3d.com)

  NTSC filter
  (c) Copyright 2006 - 2007  Shay Green

  GTK+ GUI code
  (c) Copyright 2004 - 2011  BearOso

  Win32 GUI code
  (c) Copyright 2003 - 2006  blip,
                             funkyass,
                             Matthew Kendora,
                             Nach,
                             nitsuja
  (c) Copyright 2009 - 2011  OV2

  Mac OS GUI code
  (c) Copyright 1998 - 2001  John Stiles
  (c) Copyright 2001 - 2011  zones

  iOS GUI code
  (c) Copyright 2012 Lucas Mendes Menge


  Specific ports contains the works of other authors. See headers in
  individual files.


  Snes9x homepage: http://www.snes9x.com/
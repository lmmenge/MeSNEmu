README
======

This project was created as a hobby in order to have a stable and modern SNES emulator for iOS that could be compiled straight from Xcode for the benefit of developers with valid development certificates.

Previously available emulators were either only available on Cydia (which requires being jailbroken) or simply didn't run well when "home built" due to a much outdated SNES9X codebase or messy iOS implementation.


Features:
=========

- SNES9X 1.53 codebase;
- SMC and ZIP support;
- Easy to understand UI;
- Automatic state saving/resuming, so you can quit and automatically return to the latest place you were;
- Manual state saving/resuming in another slot;
- Optional Auto-frameskip.


How to build:
=============

- Download the source code;
- Open the SiOS.xcodeproj in Xcode (version 4.2 was used in this project);
- Change the "Code Signing Identity" under "Build Settings" to your own;
- Choose your device in the Scheme selector;
- "Product" > "Profile" will deploy a Release build with all the optimizations available.


Remarks:
========

Since this project is based on SNES9X 1.53 code which is mostly C++, it is slower than some other emulators, like SNES4iOS or SNES4ALL, which have parts of them in ASM from SNES9X 1.39. However, the 1.53 codebase has higher ROM compatibility. For instance, this emulator runs perfect on an iPad 2, but requires a frameskip of 1 for most games on an iPad 1 and frameskip of 2 for most games on an iPhone 4.


License:
========

Permission to use, copy, modify and/or distribute Snes9x/SiOS in both binary and source form, for non-commercial purposes, is hereby granted without fee, providing that this license information and copyright notice appear with all copies and any derived work.

This software is provided 'as-is', without any express or implied warranty. In no event shall the authors be held liable for any damages arising from the use of this software or it's derivatives.

Snes9x/SiOS is freeware for PERSONAL USE only. Commercial users should seek permission of the copyright holders first. Commercial use includes, but is not limited to, charging money for Snes9x/SiOS or software derived from Snes9x/SiOS, including Snes9x/SiOS or derivatives in commercial game bundles, and/or using Snes9x/SiOS as a promotion for your commercial product.

The copyright holders request that bug fixes and improvements to the code should be forwarded to them so everyone can benefit from the modifications in future versions.

Super NES and Super Nintendo Entertainment System are trademarks of Nintendo Co., Limited and its subsidiary companies.
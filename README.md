# SoX with DSD Support

This repository contains a fork of [SoX (Sound eXchange)](http://sox.sourceforge.net/) that tracks the upstream stable releases while adding support for Direct Stream Digital (DSD) audio formats.

## Overview

This is a maintained fork that:
- Tracks the official SoX repository from SourceForge
- Incorporates DSD support from [Måns Rullgård's sox fork](https://github.com/mansr/sox)
- Uses a patch-based system for easy maintenance
- Can be easily updated when new SoX versions are released

## DSD Support Features

This fork adds the following DSD capabilities to SoX:

1. **DSD Encoding** - New `SOX_ENCODING_DSD` type for native DSD support
2. **File Formats:**
   - DSDIFF/DFF (.dff) - Direct Stream Digital Interchange File Format
   - DSF (.dsf) - DSD Storage Facility format  
   - WSD (.wsd) - Wideband Single-bit Data format (via DSDIFF handler)
3. **Effects:**
   - `sdm` - Sigma-Delta Modulator for PCM-to-DSD conversion
   - `dop` - DSD over PCM for encapsulating DSD in PCM frames

## Quick Start

### Prerequisites

You'll need the following tools and libraries:

- C compiler (GCC or Clang)
- Autotools (autoconf, automake, libtool)
- pkg-config
- Standard development libraries

On Debian/Ubuntu:
```bash
sudo apt install build-essential autoconf automake libtool pkg-config libltdl-dev
```

On Fedora/RHEL:
```bash
sudo dnf install gcc make autoconf automake libtool pkgconfig libtool-ltdl-devel
```

On macOS (using Homebrew):
```bash
brew install autoconf automake libtool pkg-config
```

### Building

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/sox-dsd.git
   cd sox-dsd
   ```

2. Apply the DSD patches:
   ```bash
   chmod +x apply-patches.sh
   ./apply-patches.sh apply
   ```

3. Build SoX:
   ```bash
   autoreconf -i
   ./configure
   make
   ```

4. Install (optional):
   ```bash
   sudo make install
   ```

## Usage Examples

### Converting DSD to PCM
```bash
# DSD to WAV (defaults to 44.1kHz/16-bit)
sox input.dsf output.wav

# DSD to high-resolution PCM
sox input.dff -r 192000 -b 24 output.flac
```

### Converting PCM to DSD
```bash
# Using Sigma-Delta Modulation (recommended)
sox input.wav -r 2822400 -e dsd output.dsf

# Using DoP (DSD over PCM) effect
sox input.wav output.dff dop
```

### Playing DSD Files
```bash
play input.dsf
play input.dff
```

### Getting DSD File Information
```bash
soxi input.dsf
```

## Maintenance

This fork uses a patch-based system to maintain DSD support:

### Check patch status
```bash
./apply-patches.sh status
```

### Remove patches (before updating from upstream)
```bash
./apply-patches.sh remove
```

### Update from upstream SoX
```bash
# Remove DSD patches
./apply-patches.sh remove

# Update from upstream
git remote add upstream https://git.code.sf.net/p/sox/code
git fetch upstream
git merge upstream/master

# Re-apply DSD patches
./apply-patches.sh apply
```

### Generate patch files (for documentation)
```bash
./apply-patches.sh generate
```

## Technical Details

The DSD support adds these new files:
- `src/dsdiff.c` - DSDIFF/DFF format handler
- `src/dsf.c` - DSF format handler
- `src/dop.c` - DoP (DSD over PCM) effect
- `src/sdm.c`, `src/sdm.h`, `src/sdm_x86.h` - Sigma-Delta Modulation effect

And modifies these existing SoX components:
- `sox.h` - Adds `SOX_ENCODING_DSD` enum
- `formats.h` - Registers DSD format handlers
- `formats.c` - Implements DSD encoding support
- `effects.h` - Registers sdm and dop effects
- `Makefile.am` - Adds the new DSD source files to the build

## Known Limitations

- DSD playback requires a DSD-capable DAC or will be converted to PCM
- Sample rate for DSD files must be a multiple of 44100 (e.g., 2822400 for DSD64)
- The sdm effect is experimental and may not produce optimal results for all material

## License

SoX is distributed under the GNU GPL and LGPL licenses. The 'sox' and 'soxi' programs are GPL, while the 'libsox' library is dual-licensed (GPL/LGPL). See the COPYING files for details.

## Contributing

To contribute to this fork:
1. Make your changes with patches applied
2. Test thoroughly with various DSD files
3. Document any changes to the patch system
4. Submit a pull request

For bugs in core SoX functionality, please report to the [upstream SoX project](https://sourceforge.net/projects/sox/).

## Acknowledgments

- The SoX development team for the excellent audio processing framework
- [Måns Rullgård](https://github.com/mansr/sox) for the original DSD implementation that this fork is based on
- Everyone who has contributed patches and bug reports

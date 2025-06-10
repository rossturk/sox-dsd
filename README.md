# SoX with DSD Support

This repository contains a modified version of SoX (Sound eXchange) with added support for Direct Stream Digital (DSD) audio formats. The DSD support has been integrated from the sox-dsd project into the current-stable SoX codebase.

## DSD Support

This modified version of SoX adds support for:

1. DSD as a new encoding type
2. DSDIFF/DFF format - Direct Stream Digital Interchange File Format
3. DSF format - DSD Storage Facility format
4. WSD format - Wideband Single-bit Data format
5. SDM effect - Sigma-Delta Modulator for PCM-to-DSD conversion
6. DoP effect - DSD over PCM for encapsulating DSD in PCM frames

## Building from Source

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
   git clone https://github.com/yourusername/sox-dsd-refactor.git
   cd sox-dsd-refactor
   ```

2. Apply the DSD patches:
   ```bash
   ./apply-patches.sh
   ```

3. Generate the build system:
   ```bash
   autoreconf -i
   ```

4. Configure the build:
   ```bash
   ./configure
   ```

5. Build SoX:
   ```bash
   make
   ```

6. Install (optional):
   ```bash
   sudo make install
   ```

## Usage Examples

### Converting DSD to PCM

```bash
sox input.dsf output.wav
```

### Converting PCM to DSD

```bash
sox input.wav -r 2822400 output.dff dop
```

or

```bash
sox input.wav -r 2822400 output.dsf sdm
```

### Playing DSD Files

```bash
play input.dsf
```

## Supported DSD File Formats

- DSDIFF/DFF (.dff) - Philips/Sony format, big-endian
- DSF (.dsf) - Sony format, little-endian
- WSD (.wsd) - Wideband Single-bit Data format

## License

SoX is distributed under the GNU GPL and LGPL licenses. See the LICENSE files for details.

## Acknowledgments

This work integrates DSD support from the sox-dsd project into the current-stable SoX codebase.
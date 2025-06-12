# Claude Code Guide to Maintaining this DSD-Augmented Fork of SoX

## Overview

This repository is a fork of [SoX (Sound eXchange)](http://sox.sourceforge.net/) that adds Direct Stream Digital (DSD) support. It tracks the upstream Sox repository while maintaining patches for DSD functionality.

## Key Files and Their Purpose

### Core DSD Functionality Files
- `src/dsdiff.c` - DSDIFF format handler (already in upstream)
- `src/dsf.c` - DSF format handler (already in upstream)
- `src/dop.c` - DoP (DSD over PCM) effect
- `src/sdm.c`, `src/sdm.h`, `src/sdm_x86.h` - Sigma-Delta Modulation effect

### Patch Management
- `apply-patches.sh` - Main script for applying/removing DSD patches
- `patches/` - Directory containing individual patch files (generated on demand)
- `.patch_status` - Tracks whether patches are currently applied

## Maintenance Tasks

### 1. Updating from Upstream Sox

```bash
# Step 1: Remove DSD patches to get clean Sox source
./apply-patches.sh remove

# Step 2: Add upstream remote if not already added
git remote add upstream https://git.code.sf.net/p/sox/code

# Step 3: Fetch and merge upstream changes
git fetch upstream
git merge upstream/master

# Step 4: Re-apply DSD patches
./apply-patches.sh apply

# Step 5: If there are conflicts, resolve them and regenerate patches
./apply-patches.sh generate
```

### 2. Understanding the Patches

The DSD support requires these modifications:

1. **sox.h** - Add `SOX_ENCODING_DSD` enum value
2. **formats.h** - Register DSDIFF and DSF format handlers
3. **formats.c** - Add DSD encoding info, precision handling, and format detection
4. **Makefile.am** - Add dop.c and sdm files to build system (NOTE: dsf.c and dsdiff.c are already there!)
5. **effects.h** - Register dop and sdm effects
6. **sdm.c** - Fix compilation issues (LSX_ALIGN, aligned_alloc)

### 3. Common Issues and Solutions

#### Multiple Definition Errors
**Problem**: `multiple definition of 'lsx_dsf_format_fn'`
**Cause**: dsf.c or dsdiff.c added twice to Makefile.am
**Solution**: These files are already in upstream Sox! Don't add them again.

#### Patch Failures
**Problem**: Patch doesn't apply cleanly
**Solution**: 
1. Check if the context has changed in upstream
2. Manually apply the change
3. Regenerate the patch with `./apply-patches.sh generate`

#### Build Errors in sdm.c
**Problem**: `aligned_alloc` not found or `LSX_ALIGN` errors
**Solution**: The patches handle this, but ensure:
- `aligned_alloc` → `lsx_malloc`
- `aligned_free` → `free`
- Remove `LSX_ALIGN(32)` from struct definitions

### 4. Testing After Updates

```bash
# Clean build
make clean
./configure
make

# Test DSD functionality
./src/sox test.dsf output.wav  # Convert DSF to WAV
./src/sox input.wav -e dsd output.dsf  # Convert to DSD
```

### 5. Release Process

When creating a new release:

```bash
# Ensure patches are applied
./apply-patches.sh status

# Tag the release
git tag -a v14.4.2-dsd-1 -m "Sox 14.4.2 with DSD support"

# Document changes in README
echo "Based on Sox 14.4.2" >> README.DSD
echo "DSD support patches applied on $(date)" >> README.DSD
```

## Important Notes

### What NOT to Modify

1. **Don't add dsf.c or dsdiff.c to Makefile.am** - They're already there in upstream!
2. **Don't modify FORMAT() macro calls** - Just ensure dsdiff and dsf are registered
3. **Don't change the apply-patches.sh logic** - It handles all the complexity

### What Might Need Updates

1. **Line number changes** - If upstream changes significantly, sed patterns might need adjustment
2. **New Sox features** - If Sox adds new encodings after OPUS, adjust the insertion point
3. **Build system changes** - If Sox switches from autotools, patches need major revision

### Debugging Tips

1. **Check patch status**: `./apply-patches.sh status`
2. **View current modifications**: `git diff src/`
3. **Verify format registration**: `grep -n "FORMAT.*ds" src/formats.h`
4. **Check encoding enum**: `grep -A5 -B5 "SOX_ENCODING_DSD" src/sox.h`

## Quick Reference

```bash
# Daily workflow
./apply-patches.sh status     # Check current state
./apply-patches.sh apply      # Apply patches
./apply-patches.sh remove     # Remove patches
./apply-patches.sh generate   # Create patch files

# Building
autoreconf -i                 # After applying patches
./configure && make           # Standard build

# Upstream sync
./apply-patches.sh remove && git merge upstream/master && ./apply-patches.sh apply
```

## Contact and Issues

If patches fail to apply or new issues arise:
1. Check if upstream Sox has restructured the affected files
2. Manually apply the logical changes (add DSD encoding, register formats, etc.)
3. Use `./apply-patches.sh generate` to create new patch files
4. Update this guide with any new learnings!

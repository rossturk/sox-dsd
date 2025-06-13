#!/usr/bin/env bash
# Maintainable patch-based system for Sox DSD support

set -e

#SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#cd "$SCRIPT_DIR"

# config
PATCH_DIR="patches"
PATCH_STATUS_FILE=".patch_status"

# colorize output!
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# check are patches applied?
check_patch_status() {
    if [ -f "$PATCH_STATUS_FILE" ]; then
        echo -e "${GREEN}Patches are currently applied${NC}"
        return 0
    else
        echo -e "${YELLOW}Patches are not applied${NC}"
        return 1
    fi
}

# remove patches (useful before upstream merge)
remove_patches() {
    echo "Removing DSD patches..."
    
    if ! check_patch_status; then
        echo "Patches are not currently applied"
        return 0
    fi
    
    # revert files we've modified
    git checkout src/sox.h src/formats.c src/formats.h src/Makefile.am src/effects.h
    
    if [ -f "src/sdm.c" ]; then
        git checkout src/sdm.c
    fi
    
    rm -f "$PATCH_STATUS_FILE"
    echo -e "${GREEN}Patches removed successfully${NC}"
}

# apply patches
apply_patches() {
    echo "Applying DSD patches..."
    
    if check_patch_status; then
        echo -e "${YELLOW}Patches are already applied. Remove them first with: $0 remove${NC}"
        return 1
    fi
    
    # creates patch directory if not exist
    mkdir -p "$PATCH_DIR"
    
    # applies dsd encoding support
    echo "1. Applying DSD encoding support..."
    if ! grep -q "SOX_ENCODING_DSD" src/sox.h; then
        sed -i '/SOX_ENCODING_OPUS.*Opus compression/a\  SOX_ENCODING_DSD       , /**< Direct Stream Digital */' src/sox.h
    fi
    
    # applies format handlers
    echo "2. Applying DSD format handlers..."
    if ! grep -q "FORMAT(dsdiff)" src/formats.h; then
        sed -i '/FORMAT(gsrt)/a\  FORMAT(dsdiff)\n  FORMAT(dsf)' src/formats.h
    fi
    
    # apply formats.c mods
    echo "3. Applying formats.c modifications..."
    if ! grep -q "DSD.*Direct Stream Digital" src/formats.c; then
        sed -i '/sox_encodings_lossy2.*Opus.*Opus/a\  {sox_encodings_none  , "DSD"          , "Direct Stream Digital"},' src/formats.c
    fi
    
    if ! grep -q "SOX_ENCODING_DSD.*return bits_per_sample" src/formats.c; then
        sed -i '/SOX_ENCODING_ULAW.*return bits_per_sample == 8.*14: 0;/a\    case SOX_ENCODING_DSD:        return bits_per_sample;' src/formats.c
    fi
    
    if ! grep -q "CHECK(dsdiff" src/formats.c; then
        sed -i '/CHECK(aiff.*0, 4, "FORM".*8,.*4, "AIFF")/a\  CHECK(dsdiff, 0, 4, "FRM8" , 8,  4, "DSD ")\n  CHECK(dsf   , 0, 4, "DSD " , 0,  0, "")' src/formats.c
    fi
    
    # applies Makefile.am mods
    echo "4. Applying Makefile.am modifications..."
    if ! grep -q "dop.c" src/Makefile.am; then
        sed -i 's/fade.c fft4g.c fft4g.h fifo.h fir.c firfit.c flanger.c gain.c \\/fade.c fft4g.c fft4g.h fifo.h fir.c firfit.c flanger.c gain.c dop.c \\/' src/Makefile.am
    fi
    
    if ! grep -q "sdm.c sdm.h sdm_x86.h" src/Makefile.am; then
        sed -i '/remix\.c repeat\.c reverb\.c reverse\.c.*silence\.c sinc\.c skeleff\.c/s/silence\.c sinc\.c skeleff\.c/sdm.c sdm.h sdm_x86.h silence.c sinc.c skeleff.c/' src/Makefile.am
    fi
    
    # applies effects.h mods
    echo "5. Applying effects.h modifications..."
    if ! grep -q "EFFECT(dop)" src/effects.h; then
        sed -i '/EFFECT(downsample)/a\  EFFECT(dop)' src/effects.h
    fi
    
    if ! grep -q "EFFECT(sdm)" src/effects.h; then
        sed -i '/EFFECT(silence)/a\  EFFECT(sdm)' src/effects.h
    fi
    
    # applies sdm.c fixes if exists
    if [ -f "src/sdm.c" ]; then
        echo "6. Applying sdm.c compilation fixes..."
        sed -i 's/struct LSX_ALIGN(32) sdm_filter/struct sdm_filter/g' src/sdm.c
        sed -i 's/struct LSX_ALIGN(32) sdm_state/struct sdm_state/g' src/sdm.c
        sed -i 's/p = aligned_alloc((size_t)32, sizeof(\*p));/p = lsx_malloc(sizeof(*p));/' src/sdm.c
        sed -i 's/aligned_free(p);/free(p);/' src/sdm.c
    fi
    
    # creates patching status file
    date > "$PATCH_STATUS_FILE"
    echo "DSD patches applied on $(date)" >> "$PATCH_STATUS_FILE"
    
    # runs autoconfm to regenerate build files
    echo "Running autoreconf..."
    autoreconf -i
    
    echo -e "${GREEN}All patches applied successfully!${NC}"
    echo ""
    echo "Now you can build with:"
    echo "  ./configure"
    echo "  make"
}

# generates patch files from current changes
generate_patches() {
    echo "Generating patch files from current changes..."
    mkdir -p "$PATCH_DIR"
    
    # generates individual patches
    git diff src/sox.h > "$PATCH_DIR/01-dsd-encoding.patch"
    git diff src/formats.h > "$PATCH_DIR/02-dsd-format-handlers.patch"
    git diff src/formats.c > "$PATCH_DIR/03-dsd-formats.patch"
    git diff src/Makefile.am > "$PATCH_DIR/04-makefile.patch"
    git diff src/effects.h > "$PATCH_DIR/05-effects.patch"
    
    if [ -f "src/sdm.c" ]; then
        git diff src/sdm.c > "$PATCH_DIR/06-sdm-fixes.patch"
    fi
    
    echo -e "${GREEN}Patches generated in $PATCH_DIR/${NC}"
}

# shows usage instructions
usage() {
    echo "Sox DSD Patch Management System"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  apply    - Apply DSD patches to Sox source"
    echo "  remove   - Remove DSD patches (useful before merging upstream)"
    echo "  status   - Check if patches are currently applied"
    echo "  generate - Generate patch files from current modifications"
    echo "  help     - Show this help message"
    echo ""
    echo "Typical workflow for updating from upstream:"
    echo "  1. $0 remove"
    echo "  2. git fetch upstream && git merge upstream/master"
    echo "  3. $0 apply"
    echo "  4. Fix any conflicts and run: $0 generate"
}

# main
case "${1:-help}" in
    apply)
        apply_patches
        ;;
    remove)
        remove_patches
        ;;
    status)
        check_patch_status
        ;;
    generate)
        generate_patches
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        usage
        exit 1
        ;;
esac

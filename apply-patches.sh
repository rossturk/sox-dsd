#!/bin/bash

# Apply DSD support to SoX by creating and applying patches

set -e  # Exit on error

echo "Applying DSD support patches..."

# First, let's restore the original files to start with a clean slate
git checkout src/sox.h src/formats.c src/formats.h src/Makefile.am src/effects.h

# Create temporary directory for patches
mkdir -p .patches

# Create patch for sox.h
cat > .patches/sox.h.patch << 'EOF'
--- src/sox.h.orig
+++ src/sox.h
@@ -549,6 +549,7 @@
   SOX_ENCODING_CVSD      , /**< Continuously Variable Slope Delta modulation */
   SOX_ENCODING_LPC10     , /**< Linear Predictive Coding */
   SOX_ENCODING_OPUS      , /**< Opus compression */
+  SOX_ENCODING_DSD       , /**< Direct Stream Digital */

   SOX_ENCODINGS            /**< End of list marker */
 } sox_encoding_t;
EOF

# Create patch for formats.h to add DSD format handlers
cat > .patches/formats.h.patch << 'EOF'
--- src/formats.h.orig
+++ src/formats.h
@@ -30,6 +30,8 @@
   FORMAT(f4)
   FORMAT(f8)
   FORMAT(gsrt)
+  FORMAT(dsdiff)
+  FORMAT(dsf)
   FORMAT(hcom)
   FORMAT(htk)
   FORMAT(ima)
EOF

# Create patch for formats.c - encoding info
cat > .patches/formats.c.1.patch << 'EOF'
--- src/formats.c.orig
+++ src/formats.c
@@ -150,6 +150,7 @@
   {sox_encodings_lossy2, "CVSD"         , "CVSD"},
   {sox_encodings_lossy2, "LPC10"        , "LPC10"},
   {sox_encodings_lossy2, "Opus"         , "Opus"},
+  {sox_encodings_none  , "DSD"          , "Direct Stream Digital"},
 };

 assert_static(array_length(s_sox_encodings_info) == SOX_ENCODINGS,
EOF

# Create patch for formats.c - DSD precision
cat > .patches/formats.c.2.patch << 'EOF'
--- src/formats.c.orig
+++ src/formats.c
@@ -176,6 +176,7 @@

     case SOX_ENCODING_ALAW:       return bits_per_sample == 8? 13: 0;
     case SOX_ENCODING_ULAW:       return bits_per_sample == 8? 14: 0;
+    case SOX_ENCODING_DSD:        return bits_per_sample;

     case SOX_ENCODING_CL_ADPCM:   return bits_per_sample? 8: 0;
     case SOX_ENCODING_CL_ADPCM16: return bits_per_sample == 4? 13: 0;
EOF

# Create patch for formats.c - auto-detection
cat > .patches/formats.c.3.patch << 'EOF'
--- src/formats.c.orig
+++ src/formats.c
@@ -69,6 +69,8 @@
   CHECK(wav   , 0, 4, "RIFX" , 8,  4, "WAVE")
   CHECK(wav   , 0, 4, "RF64" , 8,  4, "WAVE")
   CHECK(aiff  , 0, 4, "FORM" , 8,  4, "AIFF")
+  CHECK(dsdiff, 0, 4, "FRM8" , 8,  4, "DSD ")
+  CHECK(dsf   , 0, 4, "DSD " , 0,  0, "")
   CHECK(aifc  , 0, 4, "FORM" , 8,  4, "AIFC")
   CHECK(8svx  , 0, 4, "FORM" , 8,  4, "8SVX")
   CHECK(maud  , 0, 4, "FORM" , 8,  4, "MAUD")
EOF

# Create patch for Makefile.am - effects
cat > .patches/Makefile.am.1.patch << 'EOF'
--- src/Makefile.am.orig
+++ src/Makefile.am
@@ -59,7 +59,7 @@
 		compandt.c compandt.h contrast.c dcshift.c delay.c dft_filter.c \
 		dft_filter.h dither.c dither.h divide.c downsample.c earwax.c \
 		echo.c echos.c effects.c effects.h effects_i.c effects_i_dsp.c \
-		fade.c fft4g.c fft4g.h fifo.h fir.c firfit.c flanger.c gain.c \
+		fade.c fft4g.c fft4g.h fifo.h fir.c firfit.c flanger.c gain.c dop.c \
 		hilbert.c input.c ladspa.h ladspa.c loudness.c mcompand.c \
 		mcompand_xover.h noiseprof.c noisered.c \
 		noisered.h output.c overdrive.c pad.c phaser.c rate.c \
EOF

# Create patch for Makefile.am - sdm
cat > .patches/Makefile.am.2.patch << 'EOF'
--- src/Makefile.am.orig
+++ src/Makefile.am
@@ -64,7 +64,7 @@
 		mcompand_xover.h noiseprof.c noisered.c \
 		noisered.h output.c overdrive.c pad.c phaser.c rate.c \
 		rate_filters.h rate_half_fir.h rate_poly_fir0.h rate_poly_fir.h \
-		remix.c repeat.c reverb.c reverse.c silence.c sinc.c skeleff.c \
+		remix.c repeat.c reverb.c reverse.c sdm.c sdm.h sdm_x86.h silence.c sinc.c skeleff.c \
 		speed.c splice.c stat.c stats.c stretch.c swap.c \
 		synth.c tempo.c tremolo.c trim.c upsample.c vad.c vol.c
 if HAVE_PNG
EOF

# Create patch for Makefile.am - formats
cat > .patches/Makefile.am.3.patch << 'EOF'
--- src/Makefile.am.orig
+++ src/Makefile.am
@@ -112,7 +112,7 @@
   s4-fmt.c u1-fmt.c u2-fmt.c u3-fmt.c u4-fmt.c al-fmt.c la-fmt.c ul-fmt.c \
   lu-fmt.c 8svx.c aiff-fmt.c aifc-fmt.c au.c avr.c cdr.c cvsd-fmt.c \
   dvms-fmt.c dat.c hcom.c htk.c maud.c prc.c sf.c smp.c \
-  sounder.c soundtool.c sphere.c tx16w.c voc.c vox-fmt.c ima-fmt.c adpcm.c adpcm.h \
+  sounder.c soundtool.c sphere.c tx16w.c voc.c vox-fmt.c ima-fmt.c adpcm.c adpcm.h dsf.c dsdiff.c \
   ima_rw.c ima_rw.h wav.c wve.c xa.c nulfile.c f4-fmt.c f8-fmt.c gsrt.c \
   id3.c id3.h
EOF

# Create patch for effects.h - dop effect
cat > .patches/effects.h.1.patch << 'EOF'
--- src/effects.h.orig
+++ src/effects.h
@@ -35,6 +35,7 @@
   EFFECT(dither)
   EFFECT(divide)
   EFFECT(downsample)
+  EFFECT(dop)
   EFFECT(earwax)
   EFFECT(echo)
   EFFECT(echos)
EOF

# Create patch for effects.h - sdm effect
cat > .patches/effects.h.2.patch << 'EOF'
--- src/effects.h.orig
+++ src/effects.h
@@ -67,6 +67,7 @@
   EFFECT(reverse)
   EFFECT(riaa)
   EFFECT(silence)
+  EFFECT(sdm)
   EFFECT(sinc)
 #ifdef HAVE_PNG
   EFFECT(spectrogram)
EOF

# Apply patches
if ! grep -q "SOX_ENCODING_DSD" src/sox.h; then
  echo "Applying sox.h patch..."
  patch -p0 < .patches/sox.h.patch
fi

if ! grep -q "FORMAT(dsdiff)" src/formats.h; then
  echo "Applying formats.h patch..."
  patch -p0 < .patches/formats.h.patch
fi

if ! grep -q "DSD.*Direct Stream Digital" src/formats.c; then
  echo "Applying formats.c patches..."
  patch -p0 < .patches/formats.c.1.patch
  patch -p0 < .patches/formats.c.2.patch
  patch -p0 < .patches/formats.c.3.patch
fi

if ! grep -q "dop.c" src/Makefile.am; then
  echo "Applying Makefile.am patches..."
  patch -p0 < .patches/Makefile.am.1.patch
  patch -p0 < .patches/Makefile.am.2.patch
  patch -p0 < .patches/Makefile.am.3.patch
fi

if ! grep -q "EFFECT(dop)" src/effects.h; then
  echo "Applying effects.h patches..."
  patch -p0 < .patches/effects.h.1.patch
  patch -p0 < .patches/effects.h.2.patch
fi

# Re-run the automake to update Makefile
autoreconf -i

echo "All patches applied successfully!"
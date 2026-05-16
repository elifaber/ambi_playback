# Head-Tracked Binaural HOA Renderer

A real-time Higher-Order Ambisonics (HOA) binaural renderer in MATLAB with head tracking via an MPU-9250 IMU on an Arduino Nano. Audio is decoded through personalized HRTFs and rendered to headphones with dynamic orientation compensation.

Demonstrated with a stem-separated mix of *Lose Yourself to Dance* by Daft Punk.

---

## Features

- **Real-time HOA binaural rendering** at 4th order (25 channels) using a virtual loudspeaker decoder and HRTF convolution
- **Head tracking** via MPU-9250 IMU over Arduino, with automatic gyro bias calibration on startup
- **Auto-recenter** — after the head is still for 3 seconds, the reference orientation glides smoothly back to center
- **Manual recenter** button in the GUI
- **Stereo bypass** mode for A/B comparison
- **Per-speaker mute toggles** for all 11 virtual loudspeakers (L, R, C, SL, SR, RL, RR, ohFL, ohFR, ohRL, ohRR)
- **SOFA HRTF support** via `interpolateHRTF` with VBAP interpolation

---

## Requirements

### Hardware
- Arduino Nano (or compatible)
- MPU-9250 IMU (connected via I2C)
- Headphones connected as `External Headphones` audio output

### MATLAB Toolboxes
- Audio Toolbox
- DSP System Toolbox
- Sensor Fusion and Tracking Toolbox
- MATLAB Support Package for Arduino Hardware

### Files
| File | Description |
|------|-------------|
| `synth_L.mat` … `synth_RR.mat`, `ohFL.mat` … `ohRR.mat` | Virtual loudspeaker HRTFs (11 total) |
| `HATS051123_1_processed.sofa` | SOFA HRTF dataset for binaural decoding |
| `head_track/` | Folder containing `rotateHOA_N3D.m` and other head tracking helpers |
| `Lose Yourself To Dance/1.wav` … `12.wav` | Stem audio files (mono or stereo WAV) |

The expected stem layout is:

| File | Channel |
|------|---------|
| 1.wav | Left |
| 2.wav | Right |
| 3.wav + 4.wav | Centre (summed) |
| 5.wav | Side Left |
| 6.wav | Side Right |
| 7.wav | Rear Left |
| 8.wav | Rear Right |
| 9.wav | Overhead Front Left |
| 10.wav | Overhead Front Right |
| 11.wav | Overhead Rear Left |
| 12.wav | Overhead Rear Right |

---

## Setup

1. Connect the Arduino Nano with the MPU-9250 to your computer.
2. Update the serial port in the script if needed:
   ```matlab
   A = arduino('/dev/tty.usbserial-A10LSMK4', 'Nano3', 'Libraries', 'I2C');
   ```
3. Place all `.mat` HRTF files, the `.sofa` dataset, and the `head_track/` folder in the same directory as the script.
4. Place the stem WAV files in a subfolder called `Lose Yourself To Dance/`.
5. Run the script in MATLAB.

---

## Usage

On launch the script will:

1. Connect to the Arduino and initialize the IMU
2. Calibrate the gyro bias (hold your head still for a moment)
3. Record the initial head orientation as the reference
4. Open the control GUI and begin playback

### GUI Controls

| Control | Function |
|---------|----------|
| ⟳ Recenter | Immediately sets current head orientation as the new reference |
| ▶ Stereo Bypass / ◉ Stereo (ON) | Toggle between binaural HOA render and a simple stereo downmix |
| Speaker buttons (L, R, C…) | Toggle each virtual loudspeaker on (green) or off (gray) |
| ■ Stop | End playback and clean up |

Playback starts at the 1:45 mark by default. To change this, edit:
```matlab
startTimeSec = 105;
```

---

## Signal Chain

```
Stems (11 channels)
      │
      ▼
Virtual loudspeaker HRTFs        ← synth_*.mat  (FD-FIR convolution)
      │
      ▼
4th-order N3D/ACN Ambisonic bus  (25 channels)
      │
      ▼
HOA rotation                     ← rotateHOA_N3D (yaw / pitch / roll from IMU)
      │
      ▼
Ambisonic decoder matrix         ← t-design 36-point virtual array
      │
      ▼
HRTF convolution (MIMO FIR)      ← SOFA dataset, VBAP-interpolated
      │
      ▼
Stereo headphone output
```

---

## Configuration

| Parameter | Location | Default | Description |
|-----------|----------|---------|-------------|
| `SH_ORDER` | near top of script | `4` | Ambisonic order |
| `startTimeSec` | audio section | `105` | Playback start time (seconds) |
| `chunkSize` | audio section | `1024` | Audio buffer size (samples) |
| `AUTO_RECENTER_SEC` | loop setup | `3.0` | Stillness duration before auto-recenter glide |
| `STILL_THRESHOLD_DEG` | loop setup | `10.0` | Angular change threshold (degrees) for detecting movement |
| `GLIDE_CHUNKS` | loop setup | `50` | Number of chunks over which the recenter glide runs |

---

## Notes

- The IMU is read once per `samples_per_update` (8192 samples) rather than every chunk, which reduces serial overhead while keeping orientation updates timely.
- HRTF filters are windowed with a half-Hann fade (`applyHalfHann`) and truncated to 8192 taps.
- Filter levels are scaled by `/1000` after loading; adjust this if your HRTF files are at a different gain.
- All filter objects are warmed up with a zero buffer before the main loop to avoid startup transients.

# Gaussian Elimination: Solving a 3×3 System of Linear Equations Step by Step

An educational 1080p mathematical animation video and reproducible code suite demonstrating how **Gaussian Elimination** systematically solves a $3 \times 3$ system of linear equations, created for the **Linear Algebra and Calculus (M3) — Internal Assessment**.

- **Student Name:** Meka Vikas
- **University Registration Number (URN):** `E25B070539`
- **GitHub Repository:** [https://github.com/MEKAVIKAS/Gaussian-Elimination-Animation](https://github.com/MEKAVIKAS/Gaussian-Elimination-Animation)
- **GitHub Profile:** [https://github.com/MEKAVIKAS](https://github.com/MEKAVIKAS)
- **Final Rendered Video:** [`Video/M3_Gaussian_Elimination.mp4`](Video/M3_Gaussian_Elimination.mp4) (`1920 × 1080`, `16:9`, `30 fps`, `5m 33.2s`)
- ** Video-Drive-Link:** [https://drive.google.com/file/d/1kv9ghimOd7U9KXnyqMgTDmpyzbgo3TYh/view?usp=sharing]

---

## 1. Project Objectives

> *"By the end of this video, the viewer will understand how elementary row operations transform a $3 \times 3$ system into row echelon form without changing the solution set, and be able to solve the system through systematic back-substitution."*

- **Teach Why, Not Merely Present:** Pair algebraic row operations with 3D geometric intuition of intersecting planes in $\mathbb{R}^3$.
- **Voice-Over-Driven Synchronization:** Synchronize every equation reveal, matrix entry update, row swap, and back-substitution step directly to the student's original recorded human narration (`Audio/original_voiceover.m4a`).
- **Complete Reproducibility:** Provide runnable source code, storyboard PDF, mathematical proofs, and audio synchronization logs.

---

## 2. Mathematical Concepts Covered

We solve the $3 \times 3$ linear system:

$$\begin{cases}
x + y + z = 6 \\
2x - y + z = 3 \\
x + 2y - z = 2
\end{cases}
\quad \Longleftrightarrow \quad
[A \mid \mathbf{b}] =
\left[\begin{array}{ccc|c}
1 & 1 & 1 & 6 \\
2 & -1 & 1 & 3 \\
1 & 2 & -1 & 2
\end{array}\right]$$

### Core Topics & Step-by-Step Reduction
1. **Geometric Hook ($\mathbb{R}^3$):** Each linear equation defines a flat plane; the unique solution $(1, 2, 3)$ is the intersection point of all three planes ($\det(A) = 7 \neq 0$).
2. **Augmented Matrix & Row Echelon Form (REF):** Stripping variable syntax to isolate coefficients and constants, targeting an upper-triangular pivot staircase.
3. **Elementary Row Operations & Invariance:** Row swap ($R_i \leftrightarrow R_j$), row scaling ($R_i \to c R_i,\; c \neq 0$), and row replacement ($R_i \to R_i + k R_j$) correspond to invertible elementary matrices and strictly preserve the solution set.
4. **Worked Elimination Steps:**
   - $R_2 \to R_2 - 2R_1 \implies [0,\; -3,\; -1 \mid -9]$
   - $R_3 \to R_3 - R_1 \implies [0,\; 1,\; -2 \mid -4]$
   - $R_2 \leftrightarrow R_3$ (strategic swap to place clean pivot $1$ at $(2,2)$ without introducing fractions)
   - $R_3 \to R_3 + 3R_2 \implies [0,\; 0,\; -7 \mid -21]$ (Row Echelon Form achieved)
5. **Back-Substitution & Direct Verification:**
   - $-7z = -21 \implies z = 3$
   - $y - 2(3) = -4 \implies y = 2$
   - $x + 2 + 3 = 6 \implies x = 1$
   - Verified directly in all three original equations: $1+2+3=6$, $2(1)-2+3=3$, $1+2(2)-3=2$.

Full algebraic proofs and determinant checks are documented in [`Documentation/Mathematical_Verification.md`](Documentation/Mathematical_Verification.md).

---

## 3. Technologies and Tools Used

- **Native macOS Motion Graphics & Export Engine:** Objective-C++ (`clang++`), `CoreGraphics`, `CoreText` (rich subscript/superscript mathematical typography), `CoreVideo`, and `AVFoundation` (`H.264` 1080p video + `AAC` audio multiplexing).
- **Manim Community Edition (Python):** Modular scene scripts (`Code/scenes/*.py`) and color/matrix helpers (`Code/helpers/*.py`) mirroring the 6-scene architecture.
- **Audio Analysis & Storyboard Generation:** Python 3 (`wave`, `numpy`) for `10 ms` RMS envelope/pause alignment and pure-Python PDF generation (`Storyboard/generate_storyboard_pdf.py`).

---

## 4. Project Structure

```text
Gaussian-Elimination-Animation/
├── README.md                                       # Project overview, setup, and render guide
├── .gitignore                                      # Excludes OS metadata, caches, and build artifacts
├── Video/
│   └── M3_Gaussian_Elimination.mp4                 # Final 1080p 16:9 MP4 synced to human voice-over
├── Audio/
│   ├── original_voiceover.m4a                      # Master original human voice-over (333.204s, 48kHz AAC)
│   └── original_voiceover.wav                      # Uncompressed WAV copy for waveform analysis
├── Code/
│   ├── main.py                                     # Master Manim entrypoint
│   ├── requirements.txt                            # Python dependencies (manim, numpy, scipy, pypdf)
│   ├── renderer/
│   │   ├── render_video.mm                         # Audio-synced 1080p CoreGraphics/AVFoundation renderer
│   │   └── build_and_render.sh                     # One-command compile, render, and MP4 export script
│   ├── scenes/
│   │   ├── scene1_hook.py                          # Scene 1: Opening & 3D Intersecting Planes Hook
│   │   ├── scene2_concept.py                       # Scene 2: Augmented Matrix, REF & Row Operations
│   │   ├── scene3_intuition.py                     # Scene 3: Algebraic & Geometric Invariance
│   │   ├── scene4_worked_example.py                # Scene 4: Step-by-Step Elimination & Back-Substitution
│   │   ├── scene5_interpretation.py                # Scene 5: 3D Coordinate Boundaries & Verification
│   │   └── scene6_summary_credits.py               # Scene 6: Key Takeaways & Closing Frame
│   └── helpers/
│       ├── visual_palette.py                       # 3Blue1Brown-inspired color palette & metadata
│       └── matrix_display.py                       # Augmented matrix & workbench helpers
├── Storyboard/
│   ├── M3_Storyboard.pdf                           # 5-page audio-synchronized 6-scene storyboard PDF
│   └── generate_storyboard_pdf.py                  # Script to regenerate the storyboard PDF
└── Documentation/
    ├── Audio_Synchronization_Timeline.md           # Exact waveform-aligned timestamp map
    ├── Mathematical_Verification.md                # Full proofs, elementary matrices & det(A) check
    ├── Requirements_Checklist.md                   # Official college PDF compliance checklist
    ├── Export_Specifications_and_Changes.md        # Final export settings & QA audit report
    ├── References.md                               # Academic citations
    ├── AI_Disclosure.md                            # Transparent AI assistance disclosure
    └── README.md                                   # Documentation mirror
```

---

## 5. Installation and Rendering Instructions

### Option A: Render the Full Audio-Synchronized 1080p MP4 (macOS)
Requires Xcode Command Line Tools (`clang++` with macOS `AppKit`, `AVFoundation`, `CoreGraphics`, `CoreText`, and `CoreVideo` frameworks).

```bash
git clone https://github.com/MEKAVIKAS/Gaussian-Elimination-Animation.git
cd Gaussian-Elimination-Animation
bash Code/renderer/build_and_render.sh
```

This compiles `Code/renderer/render_video.mm`, renders all 9,997 frames at `1920 × 1080` (`30 fps`), multiplexes `Audio/original_voiceover.m4a` unedited, and writes the final video to `Video/M3_Gaussian_Elimination.mp4`.

### Option B: Run the Modular Manim Scene Scripts (Python)
Requires Python 3.10+ and Manim Community Edition (`ffmpeg` and a LaTeX distribution are required by Manim):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r Code/requirements.txt

cd Code
manim -pqh main.py Scene1Hook
manim -pqh main.py Scene2Concept
manim -pqh main.py Scene3Intuition
manim -pqh main.py Scene4WorkedExample
manim -pqh main.py Scene5Interpretation
manim -pqh main.py Scene6SummaryCredits
```

### Regenerate the 6-Scene Storyboard PDF
```bash
python3 Storyboard/generate_storyboard_pdf.py
cp M3_Gaussian_Elimination_Storyboard.pdf Storyboard/M3_Storyboard.pdf
```

---

## 6. Final Video Details

| Specification | Value |
| :--- | :--- |
| **Output File** | [`Video/M3_Gaussian_Elimination.mp4`](Video/M3_Gaussian_Elimination.mp4) |
| **Resolution & Aspect Ratio** | `1920 × 1080` (1080p Full HD, `16:9` Landscape) |
| **Frame Rate** | `30.00 fps` (`9,997` frames) |
| **Duration** | `333.198 s` (`5m 33.2s` — within 5m target and under 7m max) |
| **Video / Audio Codecs** | H.264 High Profile (`avc1`) + 48,000 Hz Mono AAC (`128 kbps`, original human narration) |
| **File Size** | `76 MiB` (`79,722,392 bytes`) |

---

## 7. Academic References & Acknowledgements

1. **Strang, Gilbert.** *Introduction to Linear Algebra*. 5th ed., Wellesley-Cambridge Press, 2016.
2. **Lay, David C., Steven R. Lay, and Judi J. McDonald.** *Linear Algebra and Its Applications*. 5th ed., Pearson, 2016.
3. **Sanderson, Grant (3Blue1Brown).** *Essence of Linear Algebra* (Visual & Geometric Intuition Inspiration), 2016.
4. **Anton, Howard, and Chris Rorres.** *Elementary Linear Algebra: Applications Version*. 11th ed., John Wiley & Sons, 2014.

- **Original Voice-Over:** Recorded live by **Meka Vikas** (no synthetic speech or background music).
- **AI Tool Disclosure:** Antigravity AI (Google DeepMind) assisted with timing budgeting, visual design structuring, and animation code scaffolding. All mathematical derivations, matrix reductions, and final verification were independently checked by the student. See [`Documentation/AI_Disclosure.md`](Documentation/AI_Disclosure.md) for details.

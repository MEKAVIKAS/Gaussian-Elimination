# M3 Mathematics Animation Video Project
## "How Gaussian Elimination Solves a 3 × 3 System of Linear Equations"

**Course:** Linear Algebra and Calculus (M3) — Internal Assessment (10% Weightage)  
**Presenter / Student Name:** Meka Vikas  
**URN:** E25B070539  
**GitHub:** https://github.com/MEKAVIKAS  
**Topic:** Gaussian Elimination  
**Final Output Video:** `Video/M3_Gaussian_Elimination.mp4` (1080p Full HD, 16:9 Landscape, 5m 33.2s)  

---

## 1. Project Directory Structure

```
M3_Gaussian_Elimination/
├── Video/
│   └── M3_Gaussian_Elimination.mp4          # Final 1080p rendered MP4 synchronized with human audio
├── Code/
│   ├── main.py                              # Master Manim entrypoint
│   ├── requirements.txt                     # Dependencies list (manim, numpy, scipy)
│   ├── renderer/
│   │   ├── render_video.mm                  # Runnable 1080p AVFoundation/CoreGraphics motion engine
│   │   └── build_and_render.sh              # One-command build & export script
│   ├── scenes/
│   │   ├── scene1_hook.py                   # Scene 1: Title & 3D Intersecting Planes Hook
│   │   ├── scene2_concept.py                # Scene 2: Equations to Augmented Matrix & Pivots
│   │   ├── scene3_intuition.py              # Scene 3: Solution Invariance & Triangular Goal
│   │   ├── scene4_worked_example.py         # Scene 4: 4 Row Operations & Back-Substitution
│   │   ├── scene5_interpretation.py         # Scene 5: 3D Coordinate Point & Verification
│   │   └── scene6_summary_credits.py        # Scene 6: Core Takeaways & Closing Credits Frame
│   └── helpers/
│       ├── visual_palette.py                # 3Blue1Brown color palette & typography
│       └── matrix_display.py                # Augmented matrix & workbench layout components
├── Audio/
│   ├── original_voiceover.wav               # Master uncompressed WAV audio
│   └── original_voiceover.m4a               # Master original recording (5m 33.2s)
├── Storyboard/
│   └── M3_Storyboard.pdf                    # Publication-quality 5-page submission storyboard
└── Documentation/
    ├── README.md                            # Comprehensive project guide (this document)
    ├── Requirements_Checklist.md            # Official College PDF compliance verification
    ├── Audio_Synchronization_Timeline.md    # Frame-accurate audio-to-visual timing log
    ├── Mathematical_Verification.md         # Full algebraic proofs & determinant calculations
    ├── References.md                        # Academic citations (Strang, Lay, 3B1B)
    ├── AI_Disclosure.md                     # Transparent AI tool usage statement
    └── Export_Specifications_and_Changes.md # Final export settings & QA audit report
```

---

## 2. Mathematical System Solved

$$\begin{cases}
x + y + z = 6 \\
2x - y + z = 3 \\
x + 2y - z = 2
\end{cases}$$

### Key Verification Metrics:
- **Coefficient Matrix Determinant:** $\det(A) = 7 \neq 0$ (Invertible, full rank 3, unique point intersection).
- **Row Echelon Form Matrix:**
  $$\left[\begin{array}{ccc|c}
  1 & 1 & 1 & 6 \\
  0 & 1 & -2 & -4 \\
  0 & 0 & -7 & -21
  \end{array}\right]$$
- **Back-Substitution:**
  - $-7z = -21 \implies z = 3$
  - $y - 2(3) = -4 \implies y = 2$
  - $x + 2 + 3 = 6 \implies x = 1$
- **Solution:** $(x, y, z) = (1, 2, 3) \in \mathbb{R}^3$.
- **Direct Check:** Verified in all 3 original equations.

---

## 3. Master Audio Synchronization Timeline

The animation visuals are synchronized frame-by-frame to the actual spoken recording of **Meka Vikas** (total duration: 333.2s = 5m 33.2s):

| Scene | Name | Exact Timestamp | Spoken Anchor Sentence | Key Visual Action |
| :---: | :--- | :---: | :--- | :--- |
| **1** | Opening & Hook | `0:00 – 0:47.9` | *"Hello everyone, my name is Meka Vikas... Imagine you're handed three linear equations..."* | Title frame with student credentials; bounded 3D intersecting planes converging at $(1, 2, 3)$. |
| **2** | Concept Intro | `0:47.9 – 1:31.6` | *"Before we crunch numbers, let's define our tools... stripped of its variable letters..."* | Equations morph into $[A \mid \mathbf{b}]$; pivot $(1, 1)=1$ pulses; 3 row operations defined. |
| **3** | Visual Intuition | `1:31.6 – 2:11.3` | *"Why are row operations mathematically legal?... solution set is strictly preserved..."* | Algebraic equivalence, reversible operations, 3D plane invariance, & upper-triangular echelon target. |
| **4A** | Elimination Op 1 | `2:11.3 – 2:41.4` | *"Our first pivot is the 1 in the top left corner... R₂ → R₂ − 2R₁..."* | Workbench shows arithmetic; Row 2 updates to $[0, -3, -1 \mid -9]$ on spoken cues. |
| **4B** | Elimination Op 2 | `2:41.4 – 3:02.3` | *"Next, to eliminate the 1 in row 3, we subtract row 1 from row 3..."* | Workbench shows subtraction; Row 3 updates to $[0, 1, -2 \mid -4]$. Column 1 cleared. |
| **4C** | Swap & Op 4 | `3:02.3 – 3:41.0` | *"Now look at column 2... swap row 2 and row 3... add 3 times row 2 to row 3..."* | Rows 2 & 3 swap via 3D flip (pivot becomes 1); Row 3 becomes $[0, 0, -7 \mid -21]$. Echelon form complete! |
| **4D** | Back Substitution | `3:41.0 – 4:25.3` | *"Now comes the payoff: back substitution... -7z = -21..."* | Domino cascade reveals $z=3$, then $y=2$, then $x=1$. Solution box pulses gold. |
| **5** | Geometric Check | `4:25.3 – 5:06.5` | *"Let's connect this algebra back to our geometry... meet at a single unique point: (1, 2, 3)..."* | 3D planes morph to orthogonal boundaries around $(1, 2, 3)$; 3 original equations verified with checkmarks. |
| **6** | Summary & Credits | `5:06.5 – 5:33.2` | *"To summarize... I'm Meka Vikas. Thank you for watching."* | 3 Takeaway cards; Closing Frame with student credentials, citations, audio note, and AI disclosure. |

---

## 4. How to Reproduce / Render

### Method A: Manim Community Edition (Python)
Ensure Python 3.10+ and Manim Community Edition are installed:
```bash
pip install -r Code/requirements.txt
```
To render individual scenes or the full script:
```bash
cd Code
manim -pqh main.py Scene1Hook
manim -pqh main.py Scene2Concept
manim -pqh main.py Scene3Intuition
manim -pqh main.py Scene4WorkedExample
manim -pqh main.py Scene5Interpretation
manim -pqh main.py Scene6SummaryCredits
```

### Method B: Native 1080p Hardware-Accelerated Renderer (macOS)
The repository includes the compiled 1080p MP4 directly in `Video/M3_Gaussian_Elimination.mp4`, which was built with sub-second vector accuracy using native AVFoundation and CoreGraphics directly multiplexed with Meka Vikas's audio.

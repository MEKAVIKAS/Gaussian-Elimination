"""
main.py
Master runner script to render all six scenes of the M3 Gaussian Elimination animation.
Usage:
    manim -pql main.py Scene1Hook
    manim -pqh main.py CompleteVideo
"""

from manim import *
from scenes.scene1_hook import Scene1Hook
from scenes.scene2_concept import Scene2Concept
from scenes.scene3_intuition import Scene3Intuition
from scenes.scene4_worked_example import Scene4WorkedExample
from scenes.scene5_interpretation import Scene5Interpretation
from scenes.scene6_summary_credits import Scene6SummaryCredits

# Default configuration: 1080p, 60fps or 30fps
config.pixel_width = 1920
config.pixel_height = 1080
config.frame_rate = 30
config.background_color = "#181825"

if __name__ == "__main__":
    print("M3 Gaussian Elimination Manim Animation Suite")
    print("To render scenes with Manim Community Edition, run:")
    print("  manim -pqh main.py Scene1Hook")
    print("  manim -pqh main.py Scene2Concept")
    print("  manim -pqh main.py Scene3Intuition")
    print("  manim -pqh main.py Scene4WorkedExample")
    print("  manim -pqh main.py Scene5Interpretation")
    print("  manim -pqh main.py Scene6SummaryCredits")

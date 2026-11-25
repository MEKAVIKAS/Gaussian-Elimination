"""
scene6_summary_credits.py
Scene 6: Three Core Takeaways, Official Closing Frame, Academic References & AI Disclosure.
Exact Audio Timestamp: 5:07.0 - 5:33.2 (Duration: 26.2 seconds)
"""

from manim import *
from helpers.visual_palette import *

class Scene6SummaryCredits(Scene):
    def construct(self):
        self.camera.background_color = COLOR_BG
        
        # 1. Three Takeaway Cards (5:07.0 - 5:22.0)
        sum_title = Text("Key Conceptual Takeaways", font_size=26, color=COLOR_X, weight=BOLD)
        sum_title.to_edge(UP, buff=0.8)
        
        t1 = RoundedRectangle(corner_radius=0.1, width=10.5, height=1.0, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_X, stroke_width=1.5)
        t1_text = Text("1. Data Structure: Augmented matrices isolate pure numerical coefficients from variable syntax.", font_size=15, color=COLOR_TEXT).move_to(t1)
        g1 = VGroup(t1, t1_text)
        
        t2 = RoundedRectangle(corner_radius=0.1, width=10.5, height=1.0, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_Y, stroke_width=1.5)
        t2_text = Text("2. Solution Invariance: Reversible row operations strictly preserve the unique geometric intersection point.", font_size=15, color=COLOR_TEXT).move_to(t2)
        g2 = VGroup(t2, t2_text)
        
        t3 = RoundedRectangle(corner_radius=0.1, width=10.5, height=1.0, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_PIVOT, stroke_width=1.5)
        t3_text = Text("3. Echelon Solvability: Triangular zeros uncouple variables, enabling effortless back-substitution.", font_size=15, color=COLOR_TEXT).move_to(t3)
        g3 = VGroup(t3, t3_text)
        
        cards = VGroup(g1, g2, g3).arrange(DOWN, buff=0.35).next_to(sum_title, DOWN, buff=0.5)
        
        self.play(FadeIn(sum_title), run_time=1.0)
        self.play(FadeIn(g1, shift=RIGHT*0.2), run_time=1.2)
        self.play(FadeIn(g2, shift=RIGHT*0.2), run_time=1.2)
        self.play(FadeIn(g3, shift=RIGHT*0.2), run_time=1.2)
        self.wait(8.0)
        
        self.play(FadeOut(VGroup(sum_title, cards)), run_time=1.5)
        
        # 2. Closing Frame (5:22.0 - 5:33.2)
        c_banner = Text(COURSE_NAME, font_size=16, color=COLOR_X, weight=BOLD).to_edge(UP, buff=0.8)
        c_title = Text(PROJECT_TITLE, font_size=28, color=COLOR_TEXT, weight=BOLD).next_to(c_banner, DOWN, buff=0.3)
        
        info_card = RoundedRectangle(corner_radius=0.15, width=10.5, height=1.8, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_X, stroke_width=1.5).next_to(c_title, DOWN, buff=0.4)
        info_lines = VGroup(
            Text("Verified Solution: (x = 1, y = 2, z = 3)  |  Takeaways: Augmented Form • Solution Invariance • Back-Substitution", font_size=14, color=COLOR_SUCCESS, weight=BOLD),
            Text(f"Student: {STUDENT_NAME}   |   URN: {STUDENT_ID}   |   GitHub: {GITHUB_URL}", font_size=16, color=COLOR_Z, weight=BOLD)
        ).arrange(DOWN, buff=0.3).move_to(info_card)
        
        closing_group = VGroup(c_banner, c_title, info_card, info_lines)
        self.play(FadeIn(closing_group, scale=1.05), run_time=1.5)
        self.wait(7.0)
        self.play(FadeOut(closing_group), run_time=2.0)

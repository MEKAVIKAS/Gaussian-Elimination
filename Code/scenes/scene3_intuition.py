"""
scene3_intuition.py
Scene 3: Visual Intuition: Solution Invariance, Invertibility & Row Echelon Form Goal.
Exact Audio Timestamp: 1:31.5 - 2:11.5 (Duration: 40.0 seconds)
"""

from manim import *
from helpers.visual_palette import *

class Scene3Intuition(Scene):
    def construct(self):
        self.camera.background_color = COLOR_BG
        
        # 1. Headline Question (1:31.5 - 1:40.0)
        q_text = Text("Why are Row Operations Mathematically Legal?", font_size=26, color=COLOR_X, weight=BOLD)
        q_text.to_edge(UP, buff=0.8)
        self.play(FadeIn(q_text, shift=DOWN*0.2), run_time=1.5)
        self.wait(5.0)
        
        # 2. Balancing Scale Metaphor & Invertibility (1:40.0 - 1:55.0)
        stmt1 = Text("Equation 1 is True", font_size=18, color=COLOR_SUCCESS)
        stmt2 = Text("Equation 2 is True", font_size=18, color=COLOR_SUCCESS)
        stmts = VGroup(stmt1, stmt2).arrange(DOWN, buff=0.3)
        
        comb_box = RoundedRectangle(corner_radius=0.15, width=6.5, height=1.6, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_SUCCESS, stroke_width=2)
        comb_text = VGroup(
            Text("Linear Combination:", font_size=16, color=COLOR_MUTED),
            MathTex(r"(\text{Eq } 2) + k \cdot (\text{Eq } 1) = \text{Equally True Equation!}", font_size=20, color=WHITE),
            Text("Operation is strictly invertible => Solution set is perfectly preserved.", font_size=14, color=COLOR_SUCCESS)
        ).arrange(DOWN, buff=0.15).move_to(comb_box)
        
        balance_group = VGroup(stmts, comb_box, comb_text).arrange(DOWN, buff=0.4).shift(UP * 0.2)
        self.play(FadeIn(balance_group), run_time=2.0)
        self.wait(12.0)
        
        # 3. Upper Triangular Form Target Blueprint (1:55.0 - 2:11.5)
        self.play(FadeOut(balance_group), FadeOut(q_text), run_time=1.5)
        
        target_title = Text("Target Blueprint: Upper-Triangular Row Echelon Form", font_size=22, color=COLOR_TEXT, weight=BOLD)
        target_title.to_edge(UP, buff=0.8)
        
        blueprint_matrix = MathTex(
            r"\begin{bmatrix}"
            r"\mathbf{P_1} & * & * & | & * \\"
            r"\mathbf{0} & \mathbf{P_2} & * & | & * \\"
            r"\mathbf{0} & \mathbf{0} & \mathbf{P_3} & | & *"
            r"\end{bmatrix}",
            font_size=36, color=COLOR_BRACKET
        )
        blueprint_matrix.shift(DOWN * 0.2)
        
        # Color specific elements in blueprint
        blueprint_matrix[0][1:3].set_color(COLOR_PIVOT) # P1
        blueprint_matrix[0][8:10].set_color(COLOR_PIVOT) # P2
        blueprint_matrix[0][15:17].set_color(COLOR_PIVOT) # P3
        blueprint_matrix[0][7].set_color(COLOR_SUCCESS) # 0
        blueprint_matrix[0][13:15].set_color(COLOR_SUCCESS) # 0 0
        
        domino_text = Text("Bottom row has only 1 variable remaining -> Solved effortlessly!", font_size=16, color=COLOR_SUCCESS)
        domino_text.next_to(blueprint_matrix, DOWN, buff=0.5)
        
        self.play(FadeIn(target_title), Create(blueprint_matrix), FadeIn(domino_text), run_time=2.0)
        self.wait(10.5)
        self.play(FadeOut(VGroup(target_title, blueprint_matrix, domino_text)), run_time=1.5)

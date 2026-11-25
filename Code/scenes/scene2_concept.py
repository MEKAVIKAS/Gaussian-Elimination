"""
scene2_concept.py
Scene 2: Formal Concept Introduction: Equations to Augmented Matrix, Pivots & 3 Row Operations.
Exact Audio Timestamp: 0:47.5 - 1:31.5 (Duration: 44.0 seconds)
"""

from manim import *
from helpers.visual_palette import *
from helpers.matrix_display import create_augmented_matrix_mobject

class Scene2Concept(Scene):
    def construct(self):
        self.camera.background_color = COLOR_BG
        
        # 1. Linear Equations (0:47.5 - 0:59.0)
        eq1 = MathTex(r"1x", r"+", r"1y", r"+", r"1z", r"=", r"6")
        eq2 = MathTex(r"2x", r"-", r"1y", r"+", r"1z", r"=", r"3")
        eq3 = MathTex(r"1x", r"+", r"2y", r"-", r"1z", r"=", r"2")
        
        for eq in [eq1, eq2, eq3]:
            eq[0].set_color(COLOR_X)
            eq[2].set_color(COLOR_Y)
            eq[4].set_color(COLOR_Z)
            eq[6].set_color(COLOR_CONST)
            
        system = VGroup(eq1, eq2, eq3).arrange(DOWN, buff=0.45).shift(UP * 1.5)
        self.play(FadeIn(system, shift=UP*0.2), run_time=1.5)
        self.wait(6.0)
        
        # 2. Transformation to Augmented Matrix (0:59.0 - 1:14.0)
        aug_entries = [
            [1, 1, 1, 6],
            [2, -1, 1, 3],
            [1, 2, -1, 2]
        ]
        aug_matrix = create_augmented_matrix_mobject(aug_entries).shift(UP * 1.5)
        
        label_aug = Text("Augmented Matrix [ A | b ]", font_size=20, color=COLOR_BRACKET)
        label_aug.next_to(aug_matrix, UP, buff=0.3)
        
        self.play(
            ReplacementTransform(system, aug_matrix),
            FadeIn(label_aug),
            run_time=2.5
        )
        self.wait(7.0)
        
        # 3. Pivot Highlight (1:14.0 - 1:24.0)
        pivot_box = RoundedRectangle(corner_radius=0.1, width=0.8, height=0.7, color=COLOR_PIVOT, stroke_width=3)
        pivot_box.move_to(aug_matrix[0][0].get_center())
        
        pivot_label = Text("Pivot: Leading Non-Zero Entry", font_size=16, color=COLOR_PIVOT, weight=BOLD)
        pivot_label.next_to(pivot_box, LEFT, buff=0.4)
        arrow = Arrow(pivot_label.get_right(), pivot_box.get_left(), color=COLOR_PIVOT, buff=0.1, stroke_width=2.5)
        
        self.play(Create(pivot_box), FadeIn(pivot_label), GrowArrow(arrow), run_time=1.5)
        self.wait(6.5)
        
        # 4. Three Elementary Row Operations Cards (1:24.0 - 1:31.5)
        op1_card = RoundedRectangle(corner_radius=0.1, width=3.5, height=1.0, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_X, stroke_width=1.5)
        op1_text = VGroup(Text("1. Row Swap", font_size=15, color=COLOR_X, weight=BOLD), MathTex(r"R_i \leftrightarrow R_j", font_size=18, color=WHITE)).arrange(DOWN, buff=0.1).move_to(op1_card)
        c1 = VGroup(op1_card, op1_text)
        
        op2_card = RoundedRectangle(corner_radius=0.1, width=3.5, height=1.0, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_Y, stroke_width=1.5)
        op2_text = VGroup(Text("2. Row Scale", font_size=15, color=COLOR_Y, weight=BOLD), MathTex(r"R_i \to c R_i \ (c \neq 0)", font_size=18, color=WHITE)).arrange(DOWN, buff=0.1).move_to(op2_card)
        c2 = VGroup(op2_card, op2_text)
        
        op3_card = RoundedRectangle(corner_radius=0.1, width=3.5, height=1.0, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_PIVOT, stroke_width=1.5)
        op3_text = VGroup(Text("3. Row Replacement", font_size=15, color=COLOR_PIVOT, weight=BOLD), MathTex(r"R_i \to R_i + k R_j", font_size=18, color=WHITE)).arrange(DOWN, buff=0.1).move_to(op3_card)
        c3 = VGroup(op3_card, op3_text)
        
        cards = VGroup(c1, c2, c3).arrange(RIGHT, buff=0.3).shift(DOWN * 1.8)
        
        self.play(FadeIn(cards, shift=UP*0.3), run_time=1.5)
        self.wait(6.0)
        self.play(FadeOut(VGroup(aug_matrix, label_aug, pivot_box, pivot_label, arrow, cards)), run_time=1.5)

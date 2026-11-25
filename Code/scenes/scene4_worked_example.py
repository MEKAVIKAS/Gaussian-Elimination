"""
scene4_worked_example.py
Scene 4: The Mathematical Core: 4 Row Operations to Row Echelon Form & Back-Substitution.
Exact Audio Timestamp: 2:11.5 - 4:25.5 (Duration: 134.0 seconds)
"""

from manim import *
from helpers.visual_palette import *
from helpers.matrix_display import create_augmented_matrix_mobject, create_workbench_card

class Scene4WorkedExample(Scene):
    def construct(self):
        self.camera.background_color = COLOR_BG
        
        # Section Header
        header = Text("Worked Example: Step-by-Step Elimination", font_size=24, color=COLOR_TEXT, weight=BOLD)
        header.to_edge(UP, buff=0.5)
        self.add(header)
        
        # Initial Augmented Matrix on Left
        m0_data = [[1, 1, 1, 6], [2, -1, 1, 3], [1, 2, -1, 2]]
        mat = create_augmented_matrix_mobject(m0_data).scale(0.85).to_edge(LEFT, buff=0.8).shift(DOWN*0.2)
        self.play(FadeIn(mat), run_time=1.5)
        self.wait(3.0)
        
        # ----------------------------------------------------
        # STEP 4A: R2 -> R2 - 2*R1 (2:11.5 - 2:41.0)
        # ----------------------------------------------------
        wb1 = create_workbench_card(
            title="Step 1: Eliminate x from Row 2",
            operation_label=r"R_2 \to R_2 - 2 R_1",
            calc_lines=[
                r"R_2: \quad [ \ \ 2, \ -1, \ \ 1 \ \mid \ \ 3 \ ]",
                r"-2 R_1: \ [ -2, \ -2, \ -2 \ \mid -12 \ ]",
                r"\hline",
                r"\text{New } R_2: [ \ \mathbf{0}, \ -3, \ -1 \ \mid \ -9 \ ]"
            ]
        ).scale(0.85).to_edge(RIGHT, buff=0.8).shift(DOWN*0.2)
        
        self.play(FadeIn(wb1, shift=LEFT*0.3), run_time=1.5)
        self.wait(14.0)
        
        # Update matrix to M1
        m1_data = [[1, 1, 1, 6], [0, -3, -1, -9], [1, 2, -1, 2]]
        mat1 = create_augmented_matrix_mobject(m1_data).scale(0.85).to_edge(LEFT, buff=0.8).shift(DOWN*0.2)
        self.play(Transform(mat, mat1), run_time=1.5)
        self.wait(10.0)
        
        # ----------------------------------------------------
        # STEP 4B: R3 -> R3 - R1 (2:41.0 - 3:02.0)
        # ----------------------------------------------------
        wb2 = create_workbench_card(
            title="Step 2: Eliminate x from Row 3",
            operation_label=r"R_3 \to R_3 - R_1",
            calc_lines=[
                r"R_3: \quad [ \ \ 1, \ \ 2, \ -1 \ \mid \ \ 2 \ ]",
                r"-1 R_1: \ [ -1, \ -1, \ -1 \ \mid \ -6 \ ]",
                r"\hline",
                r"\text{New } R_3: [ \ \mathbf{0}, \ \ 1, \ -2 \ \mid \ -4 \ ]"
            ]
        ).scale(0.85).to_edge(RIGHT, buff=0.8).shift(DOWN*0.2)
        
        self.play(ReplacementTransform(wb1, wb2), run_time=1.5)
        self.wait(8.5)
        
        # Update matrix to M2
        m2_data = [[1, 1, 1, 6], [0, -3, -1, -9], [0, 1, -2, -4]]
        mat2 = create_augmented_matrix_mobject(m2_data).scale(0.85).to_edge(LEFT, buff=0.8).shift(DOWN*0.2)
        self.play(Transform(mat, mat2), run_time=1.5)
        self.wait(8.0)
        
        # ----------------------------------------------------
        # STEP 4C: Swap R2 <-> R3 & Op 4: R3 -> R3 + 3R2 (3:02.0 - 3:41.0)
        # ----------------------------------------------------
        wb_swap = create_workbench_card(
            title="Step 3: Strategic Row Swap",
            operation_label=r"R_2 \leftrightarrow R_3",
            calc_lines=[
                r"\text{Avoids dividing by } -3 \text{ (no fractions!)}",
                r"\text{Row 3 has a clean pivot } 1.",
                r"\text{Swapping } R_2 \text{ and } R_3 \text{ sets pivot to } 1."
            ]
        ).scale(0.85).to_edge(RIGHT, buff=0.8).shift(DOWN*0.2)
        
        self.play(ReplacementTransform(wb2, wb_swap), run_time=1.5)
        self.wait(6.0)
        
        m3_data = [[1, 1, 1, 6], [0, 1, -2, -4], [0, -3, -1, -9]]
        mat3 = create_augmented_matrix_mobject(m3_data).scale(0.85).to_edge(LEFT, buff=0.8).shift(DOWN*0.2)
        self.play(Transform(mat, mat3), run_time=1.5)
        self.wait(5.0)
        
        # Op 4: R3 -> R3 + 3R2
        wb4 = create_workbench_card(
            title="Step 4: Eliminate y from Row 3",
            operation_label=r"R_3 \to R_3 + 3 R_2",
            calc_lines=[
                r"R_3: \quad [ \ \ 0, \ -3, \ -1 \ \mid \ \ -9 \ ]",
                r"+3 R_2: [ \ \ 0, \ \ 3, \ -6 \ \mid -12 \ ]",
                r"\hline",
                r"\text{New } R_3: [ \ \mathbf{0}, \ \ \mathbf{0}, \ -7 \ \mid -21 \ ]"
            ]
        ).scale(0.85).to_edge(RIGHT, buff=0.8).shift(DOWN*0.2)
        
        self.play(ReplacementTransform(wb_swap, wb4), run_time=1.5)
        self.wait(10.0)
        
        m_ref_data = [[1, 1, 1, 6], [0, 1, -2, -4], [0, 0, -7, -21]]
        mat_ref = create_augmented_matrix_mobject(m_ref_data).scale(0.85).to_edge(LEFT, buff=0.8).shift(DOWN*0.2)
        self.play(Transform(mat, mat_ref), run_time=1.5)
        
        # Highlight staircase
        ref_badge = Text("ROW ECHELON FORM ACHIEVED", font_size=18, color=COLOR_SUCCESS, weight=BOLD)
        ref_badge.next_to(mat, UP, buff=0.3)
        self.play(FadeIn(ref_badge), run_time=1.0)
        self.wait(10.5)
        
        # ----------------------------------------------------
        # STEP 4D: Back-Substitution Cascade (3:41.0 - 4:25.5)
        # ----------------------------------------------------
        self.play(FadeOut(wb4), FadeOut(ref_badge), run_time=1.0)
        
        bs_card = RoundedRectangle(corner_radius=0.15, width=6.5, height=4.5, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_SUCCESS, stroke_width=2).to_edge(RIGHT, buff=0.8).shift(DOWN*0.2)
        bs_title = Text("Back-Substitution Cascade", font_size=20, color=COLOR_TEXT, weight=BOLD).next_to(bs_card.get_top(), DOWN, buff=0.25)
        
        step_z = MathTex(r"-7z = -21 \implies \mathbf{z = 3}", font_size=24, color=COLOR_Z)
        step_y = MathTex(r"y - 2(3) = -4 \implies y - 6 = -4 \implies \mathbf{y = 2}", font_size=24, color=COLOR_Y)
        step_x = MathTex(r"x + 2 + 3 = 6 \implies x + 5 = 6 \implies \mathbf{x = 1}", font_size=24, color=COLOR_X)
        
        sol_box = RoundedRectangle(corner_radius=0.1, width=4.5, height=0.7, fill_color=COLOR_BG, stroke_color=COLOR_SUCCESS, stroke_width=2)
        sol_tex = MathTex(r"\mathbf{[x, y, z]^T = [1, 2, 3]^T}", font_size=26, color=WHITE).move_to(sol_box)
        sol_group = VGroup(sol_box, sol_tex)
        
        bs_content = VGroup(step_z, step_y, step_x, sol_group).arrange(DOWN, buff=0.3).next_to(bs_title, DOWN, buff=0.3)
        
        self.play(FadeIn(bs_card), FadeIn(bs_title), run_time=1.5)
        self.wait(3.0)
        self.play(FadeIn(step_z), run_time=2.0)
        self.wait(8.0)
        self.play(FadeIn(step_y), run_time=2.0)
        self.wait(8.0)
        self.play(FadeIn(step_x), run_time=2.0)
        self.wait(8.0)
        self.play(FadeIn(sol_group), Flash(sol_box, color=COLOR_SUCCESS), run_time=1.5)
        self.wait(10.0)
        
        self.play(FadeOut(VGroup(header, mat, bs_card, bs_title, bs_content)), run_time=2.0)

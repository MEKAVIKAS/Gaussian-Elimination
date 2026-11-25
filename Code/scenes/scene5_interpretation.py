"""
scene5_interpretation.py
Scene 5: Geometric Interpretation & Direct Equation Verification.
Exact Audio Timestamp: 4:25.5 - 5:07.0 (Duration: 41.5 seconds)
"""

from manim import *
from helpers.visual_palette import *

class Scene5Interpretation(ThreeDScene):
    def construct(self):
        self.camera.background_color = COLOR_BG
        
        # 1. 3D Geometric Space (4:25.5 - 4:48.0)
        axes = ThreeDAxes(
            x_range=[-1, 5, 1], y_range=[-1, 5, 1], z_range=[-1, 5, 1],
            x_length=4.5, y_length=4.5, z_length=4.5
        ).to_edge(LEFT, buff=0.8)
        self.set_camera_orientation(phi=65 * DEGREES, theta=-35 * DEGREES)
        
        # Intersecting Planes
        p1 = Surface(lambda u, v: np.array([u, v, 6 - u - v]), u_range=[0, 3], v_range=[0, 3], fill_color=COLOR_X, fill_opacity=0.5, checkerboard_colors=False)
        p2 = Surface(lambda u, v: np.array([u, v, 3 - 2*u + v]), u_range=[0, 3], v_range=[0, 3], fill_color=COLOR_Y, fill_opacity=0.5, checkerboard_colors=False)
        p3 = Surface(lambda u, v: np.array([u, v, u + 2*v - 2]), u_range=[0, 3], v_range=[0, 3], fill_color=COLOR_PIVOT, fill_opacity=0.5, checkerboard_colors=False)
        sol_point = Dot3D(point=np.array([1, 2, 3]), radius=0.18, color=COLOR_Z)
        
        self.play(Create(axes), Create(p1), Create(p2), Create(p3), FadeIn(sol_point), run_time=2.5)
        self.wait(14.0)
        
        # 2. Direct Substitution Verification Cards on Right (4:48.0 - 5:07.0)
        card_bg = RoundedRectangle(corner_radius=0.15, width=6.5, height=4.2, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_SUCCESS, stroke_width=2).to_edge(RIGHT, buff=0.8)
        title_v = Text("Verification by Direct Substitution", font_size=18, color=COLOR_TEXT, weight=BOLD).next_to(card_bg.get_top(), DOWN, buff=0.25)
        
        v1 = MathTex(r"\text{Eq 1: } (1) + (2) + (3) = 6 = 6 \quad \checkmark", font_size=20, color=COLOR_SUCCESS)
        v2 = MathTex(r"\text{Eq 2: } 2(1) - (2) + (3) = 3 = 3 \quad \checkmark", font_size=20, color=COLOR_SUCCESS)
        v3 = MathTex(r"\text{Eq 3: } (1) + 2(2) - (3) = 2 = 2 \quad \checkmark", font_size=20, color=COLOR_SUCCESS)
        
        v_lines = VGroup(v1, v2, v3).arrange(DOWN, buff=0.35, aligned_edge=LEFT).next_to(title_v, DOWN, buff=0.4)
        
        self.play(FadeIn(card_bg), FadeIn(title_v), run_time=1.5)
        self.play(FadeIn(v1), run_time=1.5)
        self.wait(2.5)
        self.play(FadeIn(v2), run_time=1.5)
        self.wait(2.5)
        self.play(FadeIn(v3), run_time=1.5)
        self.wait(6.0)
        
        self.play(FadeOut(VGroup(axes, p1, p2, p3, sol_point, card_bg, title_v, v_lines)), run_time=2.0)

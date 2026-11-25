"""
scene1_hook.py
Scene 1: Opening Title Frame, Spoken Student Introduction, and 3D Planes Geometric Hook.
Exact Audio Timestamp: 0:00 - 0:47.5 (Duration: 47.5 seconds)
"""

from manim import *
from helpers.visual_palette import *

class Scene1Hook(ThreeDScene):
    def construct(self):
        # 1. Opening Title Card (0:00 - 0:12.5)
        self.camera.background_color = COLOR_BG
        
        banner = Text("LINEAR ALGEBRA AND CALCULUS (M3) • INTERNAL ASSESSMENT", font_size=16, color=COLOR_X, weight=BOLD)
        banner.to_edge(UP, buff=0.8)
        
        title = Text("How Gaussian Elimination Solves a 3 × 3 System", font_size=32, color=COLOR_TEXT, weight=BOLD)
        title.next_to(banner, DOWN, buff=0.4)
        
        subtitle = Text("A Visual Step-by-Step Educational Explainer", font_size=20, color=COLOR_MUTED)
        subtitle.next_to(title, DOWN, buff=0.25)
        
        cred_card = RoundedRectangle(corner_radius=0.15, width=8.5, height=1.2, fill_color=COLOR_PANEL, fill_opacity=0.9, stroke_color=COLOR_X, stroke_width=1.5)
        cred_card.next_to(subtitle, DOWN, buff=0.6)
        
        student_text = Text(f"Presenter: {STUDENT_NAME}   |   Student ID: {STUDENT_ID}", font_size=18, color=COLOR_TEXT)
        student_text.move_to(cred_card.get_center())
        
        title_group = VGroup(banner, title, subtitle, cred_card, student_text)
        
        self.play(FadeIn(title_group, shift=UP*0.3), run_time=1.5)
        self.wait(9.5) # Over personal intro audio
        self.play(FadeOut(title_group, shift=DOWN*0.3), run_time=1.5)
        
        # 2. 3D Intersecting Planes & Core Question (0:12.5 - 0:47.5)
        axes = ThreeDAxes(
            x_range=[-1, 5, 1], y_range=[-1, 5, 1], z_range=[-1, 5, 1],
            x_length=5, y_length=5, z_length=5
        )
        self.set_camera_orientation(phi=70 * DEGREES, theta=-45 * DEGREES)
        
        # Three intersecting planes
        # Plane 1: x + y + z = 6  (Cyan)
        p1 = Surface(
            lambda u, v: np.array([u, v, 6 - u - v]),
            u_range=[-0.5, 3.5], v_range=[-0.5, 3.5],
            fill_color=COLOR_X, fill_opacity=0.55, checkerboard_colors=False, stroke_width=0.5
        )
        # Plane 2: 2x - y + z = 3  ==> z = 3 - 2x + y (Emerald)
        p2 = Surface(
            lambda u, v: np.array([u, v, 3 - 2*u + v]),
            u_range=[-0.5, 3.5], v_range=[-0.5, 3.5],
            fill_color=COLOR_Y, fill_opacity=0.55, checkerboard_colors=False, stroke_width=0.5
        )
        # Plane 3: x + 2y - z = 2  ==> z = x + 2y - 2 (Coral)
        p3 = Surface(
            lambda u, v: np.array([u, v, u + 2*v - 2]),
            u_range=[-0.5, 3.5], v_range=[-0.5, 3.5],
            fill_color=COLOR_PIVOT, fill_opacity=0.55, checkerboard_colors=False, stroke_width=0.5
        )
        
        # Unique intersection point (1, 2, 3)
        sol_point = Dot3D(point=np.array([1, 2, 3]), radius=0.15, color=COLOR_Z)
        
        self.play(Create(axes), run_time=2.0)
        self.play(Create(p1), Create(p2), Create(p3), run_time=3.5)
        self.play(FadeIn(sol_point, scale=1.5), Flash(sol_point, color=COLOR_Z), run_time=1.5)
        
        # 3D Orbit while narration introduces the core question
        self.begin_ambient_camera_rotation(rate=0.15)
        self.wait(12.0)
        
        # Equations HUD on screen
        self.set_camera_orientation(phi=70 * DEGREES, theta=20 * DEGREES)
        self.stop_ambient_camera_rotation()
        
        self.wait(10.0)
        self.play(FadeOut(VGroup(axes, p1, p2, p3, sol_point)), run_time=2.5)

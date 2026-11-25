"""
matrix_display.py
Helper functions and custom MObjects for constructing, highlighting,
and animating augmented matrices and calculation workbenches in Manim.
"""

from manim import *
from .visual_palette import *

def create_augmented_matrix_mobject(entries, col_colors=None):
    """
    Creates an augmented matrix 3x4 with custom entry colors and vertical divider.
    entries: 3x4 list of strings or numbers
    """
    if col_colors is None:
        col_colors = [COLOR_X, COLOR_Y, COLOR_Z, COLOR_CONST]
        
    matrix_rows = []
    for r in range(3):
        row_mobs = []
        for c in range(4):
            val_str = str(entries[r][c])
            tex = MathTex(val_str, color=col_colors[c])
            row_mobs.append(tex)
        matrix_rows.append(row_mobs)
        
    grid = VGroup(*[item for row in matrix_rows for item in row]).arrange_in_grid(
        rows=3, cols=4, col_widths=[0.9, 0.9, 0.9, 0.9], row_heights=[0.8, 0.8, 0.8]
    )
    
    # Left bracket, Right bracket
    left_bracket = MathTex(r"\left[", color=COLOR_BRACKET).scale(2.2)
    right_bracket = MathTex(r"\right]", color=COLOR_BRACKET).scale(2.2)
    left_bracket.next_to(grid, LEFT, buff=0.2)
    right_bracket.next_to(grid, RIGHT, buff=0.2)
    
    # Augmentation divider line between col 2 and col 3 (0-indexed: between 2 and 3)
    c2_x = (grid[2].get_x() + grid[3].get_x()) / 2.0
    top_y = grid.get_top()[1] + 0.1
    bot_y = grid.get_bottom()[1] - 0.1
    divider = Line(start=[c2_x, top_y, 0], end=[c2_x, bot_y, 0], color=COLOR_BRACKET, stroke_width=2.5)
    
    return VGroup(grid, left_bracket, right_bracket, divider)

def create_workbench_card(title, operation_label, calc_lines):
    """
    Creates a dedicated workbench card displaying active row operation and arithmetic.
    """
    card_bg = RoundedRectangle(
        corner_radius=0.15, width=6.2, height=4.2,
        fill_color=COLOR_PANEL, fill_opacity=0.85, stroke_color=COLOR_OP_BADGE, stroke_width=2
    )
    
    title_mob = Text(title, font_size=20, color=COLOR_TEXT, weight=BOLD)
    title_mob.next_to(card_bg.get_top(), DOWN, buff=0.25)
    
    badge_bg = RoundedRectangle(
        corner_radius=0.1, width=4.5, height=0.55,
        fill_color=COLOR_OP_BADGE, fill_opacity=0.9, stroke_width=0
    )
    badge_tex = MathTex(operation_label, color=WHITE, font_size=24)
    badge = VGroup(badge_bg, badge_tex)
    badge.next_to(title_mob, DOWN, buff=0.2)
    
    lines_group = VGroup(*[MathTex(l, font_size=22, color=COLOR_TEXT) for l in calc_lines]).arrange(DOWN, aligned_edge=LEFT, buff=0.22)
    lines_group.next_to(badge, DOWN, buff=0.3)
    
    return VGroup(card_bg, title_mob, badge, lines_group)

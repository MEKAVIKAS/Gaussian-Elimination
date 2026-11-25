#!/usr/bin/env python3
"""
generate_storyboard_pdf.py
Generates a publication-quality 5-page PDF document for the M3 Mathematics Animation Project:
'How Gaussian Elimination Solves a 3 x 3 System of Linear Equations'
"""

import sys
import os

class SimplePDF:
    def __init__(self, filename="M3_Gaussian_Elimination_Storyboard.pdf", width=612, height=792):
        self.filename = filename
        self.width = width
        self.height = height
        self.pages = []

    def new_page(self):
        page = PDFPage(self.width, self.height)
        self.pages.append(page)
        return page

    def save(self):
        # We assemble a standard, valid PDF 1.4 document
        objects = []
        
        # 1: Catalog
        # 2: Pages root
        # Fonts: F1 (Helvetica), F2 (Helvetica-Bold), F3 (Helvetica-Oblique), F4 (Courier)
        # Then for each page: Page object and Contents object
        
        # Calculate object numbers
        # 1: Catalog
        # 2: Pages
        # 3: F1 (Helvetica)
        # 4: F2 (Helvetica-Bold)
        # 5: F3 (Helvetica-Oblique)
        # 6: F4 (Courier)
        # 7: F5 (Courier-Bold)
        font_count = 5
        page_objs_start = 3 + font_count
        
        total_pages = len(self.pages)
        page_obj_ids = []
        contents_obj_ids = []
        
        curr_id = page_objs_start
        for i in range(total_pages):
            page_obj_ids.append(curr_id)
            contents_obj_ids.append(curr_id + 1)
            curr_id += 2
            
        # Catalog
        cat_str = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
        
        # Pages
        kids_str = " ".join([f"{pid} 0 R" for pid in page_obj_ids])
        pages_str = f"2 0 obj\n<< /Type /Pages /Kids [{kids_str}] /Count {total_pages} >>\nendobj\n"
        
        # Fonts
        f1_str = "3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n"
        f2_str = "4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n"
        f3_str = "5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Oblique /Encoding /WinAnsiEncoding >>\nendobj\n"
        f4_str = "6 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier /Encoding /WinAnsiEncoding >>\nendobj\n"
        f5_str = "7 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold /Encoding /WinAnsiEncoding >>\nendobj\n"
        
        obj_strings = [cat_str, pages_str, f1_str, f2_str, f3_str, f4_str, f5_str]
        
        # Assemble Page and Content objects
        for i in range(total_pages):
            pid = page_obj_ids[i]
            cid = contents_obj_ids[i]
            stream_data = self.pages[i].get_stream_data(i + 1, total_pages)
            stream_len = len(stream_data.encode('latin1'))
            
            p_str = (
                f"{pid} 0 obj\n"
                f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {self.width} {self.height}] "
                f"/Contents {cid} 0 R "
                f"/Resources << /Font << /F1 3 0 R /F2 4 0 R /F3 5 0 R /F4 6 0 R /F5 7 0 R >> >> >>\n"
                f"endobj\n"
            )
            c_str = (
                f"{cid} 0 obj\n"
                f"<< /Length {stream_len} >>\n"
                f"stream\n{stream_data}\nendstream\n"
                f"endobj\n"
            )
            obj_strings.extend([p_str, c_str])
            
        # Build file with exact xref offsets
        header = "%PDF-1.4\n%\xe2\xe3\xcf\xd3\n"
        offsets = []
        body = ""
        current_offset = len(header.encode('latin1'))
        
        for obj_str in obj_strings:
            offsets.append(current_offset)
            encoded = obj_str.encode('latin1')
            current_offset += len(encoded)
            body += obj_str
            
        total_objects = len(obj_strings) + 1
        xref = f"xref\n0 {total_objects}\n0000000000 65535 f \n"
        for off in offsets:
            xref += f"{off:010d} 00000 n \n"
            
        trailer = (
            f"trailer\n<< /Size {total_objects} /Root 1 0 R >>\n"
            f"startxref\n{current_offset}\n%%EOF\n"
        )
        
        with open(self.filename, 'wb') as f:
            f.write(header.encode('latin1'))
            f.write(body.encode('latin1'))
            f.write(xref.encode('latin1'))
            f.write(trailer.encode('latin1'))
            
        print(f"Successfully generated {self.filename} ({total_pages} pages)")


class PDFPage:
    def __init__(self, width, height):
        self.width = width
        self.height = height
        self.commands = []

    def add_cmd(self, cmd):
        self.commands.append(cmd)

    def set_fill_rgb(self, r, g, b):
        self.commands.append(f"{r:.3f} {g:.3f} {b:.3f} rg")

    def set_stroke_rgb(self, r, g, b):
        self.commands.append(f"{r:.3f} {g:.3f} {b:.3f} RG")

    def set_line_width(self, w):
        self.commands.append(f"{w:.2f} w")

    def rect(self, x, y, w, h, fill=True, stroke=False):
        self.commands.append(f"{x:.2f} {y:.2f} {w:.2f} {h:.2f} re")
        if fill and stroke:
            self.commands.append("B")
        elif fill:
            self.commands.append("f")
        elif stroke:
            self.commands.append("S")

    def rounded_rect(self, x, y, w, h, r=4, fill=True, stroke=False):
        # Approximate rounded rectangle with lines and arcs or just clean box
        self.rect(x, y, w, h, fill, stroke)

    def line(self, x1, y1, x2, y2):
        self.commands.append(f"{x1:.2f} {y1:.2f} m {x2:.2f} {y2:.2f} l S")

    def text(self, x, y, string, font="F1", size=10, fill_rgb=None):
        if fill_rgb:
            self.set_fill_rgb(*fill_rgb)
        clean = sanitize_text(string)
        safe = clean.replace('\\', '\\\\').replace('(', '\\(').replace(')', '\\)')
        self.commands.append(f"BT /{font} {size} Tf {x:.2f} {y:.2f} Td ({safe}) Tj ET")

    def text_box(self, x, y, w, lines, font="F1", size=9, line_spacing=12, fill_rgb=(0.1, 0.1, 0.15)):
        curr_y = y
        for line in lines:
            self.text(x, curr_y, line, font=font, size=size, fill_rgb=fill_rgb)
            curr_y -= line_spacing
        return curr_y

    def get_stream_data(self, page_num, total_pages):
        # Draw running header & footer on all pages
        stream = []
        
        # Header bar
        stream.append("0.120 0.180 0.320 rg") # Navy blue banner accent
        stream.append(f"36 756 {self.width - 72} 2 re f")
        
        # Header text
        stream.append("BT /F2 8 Tf 36 764 Td (LINEAR ALGEBRA AND CALCULUS (M3)  *  INTERNAL ASSESSMENT STORYBOARD) Tj ET")
        stream.append("BT /F1 8 Tf 400 764 Td (Topic: Gaussian Elimination (3 x 3)) Tj ET")
        
        # Footer text & page numbering
        stream.append("0.800 0.820 0.860 rg")
        stream.append(f"36 36 {self.width - 72} 1 re f")
        stream.append("0.400 0.450 0.500 rg")
        stream.append("BT /F1 8 Tf 36 24 Td (Student: Meka Vikas  |  ID: E25B070539  |  Format: 16:9 MP4 1080p) Tj ET")
        stream.append(f"BT /F2 8 Tf 520 24 Td (Page {page_num} of {total_pages}) Tj ET")
        
        # Page specific drawing commands
        stream.extend(self.commands)
        return "\n".join(stream)


def sanitize_text(text):
    replacements = {
        '\u2014': '--',
        '\u2013': '-',
        '\u2018': "'",
        '\u2019': "'",
        '\u201c': '"',
        '\u201d': '"',
        '\u2022': '*',
        '\u2260': '!=',
        '\u2192': '->',
        '\u2194': '<->',
        '\u2223': '|',
        '\u2208': 'in',
        '\u211d': 'R',
        '\u2713': '[CHECK]',
    }
    for k, v in replacements.items():
        text = text.replace(k, v)
    return text.encode('ascii', errors='replace').decode('ascii')


def wrap_text(text, max_chars=80):
    words = text.split()
    lines = []
    curr = []
    curr_len = 0
    for w in words:
        if curr_len + len(w) + (1 if curr else 0) <= max_chars:
            curr.append(w)
            curr_len += len(w) + (1 if len(curr) > 1 else 0)
        else:
            lines.append(" ".join(curr))
            curr = [w]
            curr_len = len(w)
    if curr:
        lines.append(" ".join(curr))
    return lines


def build_storyboard_pdf():
    pdf = SimplePDF("M3_Gaussian_Elimination_Storyboard.pdf")
    
    # -------------------------------------------------------------
    # PAGE 1: TITLE, PROJECT OVERVIEW & EXECUTIVE 6-SCENE ROADMAP
    # -------------------------------------------------------------
    p1 = pdf.new_page()
    
    # Hero Title Box
    p1.set_fill_rgb(0.094, 0.125, 0.212) # Deep Midnight Blue (#182036)
    p1.rect(36, 640, 540, 105, fill=True, stroke=False)
    
    p1.text(50, 722, "M3 Internal Assessment: Mathematical Animation Video Project", font="F2", size=11, fill_rgb=(0.2, 0.8, 1.0)) # Cyan
    p1.text(50, 698, "How Gaussian Elimination Solves a 3 x 3 System", font="F2", size=18, fill_rgb=(1.0, 1.0, 1.0))
    p1.text(50, 680, "A Rigorous, Visual Storyboard & Step-by-Step Educational Script", font="F3", size=11, fill_rgb=(0.85, 0.90, 0.95))
    p1.text(50, 652, "Student Name: Meka Vikas    |    Student ID: E25B070539    |    Weightage: 10%", font="F1", size=9, fill_rgb=(0.75, 0.82, 0.90))
    
    # Parameter Badges (Table of Parameters)
    params = [
        ("Topic Focus:", "Gaussian Elimination on a 3 x 3 Linear System", "Target Duration:", "5 Minutes (Strict Max: 7 Min)"),
        ("Video Format:", "16:9 Landscape (1920 x 1080 Full HD)", "Final File:", "MP4 with clear voice-over narration"),
        ("Visual Aesthetic:", "3Blue1Brown inspired dark slate & color coding", "Delivery Repo:", "Public GitHub Repository + Google Form"),
    ]
    
    box_y = 565
    for r1_k, r1_v, r2_k, r2_v in params:
        p1.set_fill_rgb(0.95, 0.96, 0.98)
        p1.rect(36, box_y, 540, 20, fill=True, stroke=False)
        p1.text(44, box_y + 6, r1_k, font="F2", size=8, fill_rgb=(0.15, 0.25, 0.45))
        p1.text(110, box_y + 6, r1_v, font="F1", size=8, fill_rgb=(0.1, 0.1, 0.1))
        p1.text(310, box_y + 6, r2_k, font="F2", size=8, fill_rgb=(0.15, 0.25, 0.45))
        p1.text(390, box_y + 6, r2_v, font="F1", size=8, fill_rgb=(0.1, 0.1, 0.1))
        box_y -= 23
        
    # Learning Objective Card
    p1.set_fill_rgb(0.92, 0.95, 1.0)
    p1.set_stroke_rgb(0.2, 0.5, 0.9)
    p1.set_line_width(1.0)
    p1.rect(36, 442, 540, 42, fill=True, stroke=True)
    p1.text(48, 468, "Formal Learning Objective:", font="F2", size=9, fill_rgb=(0.05, 0.25, 0.65))
    obj_text = '"By the end of this video, the viewer will understand how elementary row operations transform a 3 x 3 system into row echelon form without changing the solution set, and be able to solve the system through systematic back-substitution."'
    wrapped_obj = wrap_text(obj_text, max_chars=105)
    p1.text(48, 452, wrapped_obj[0], font="F3", size=8, fill_rgb=(0.1, 0.15, 0.25))
    if len(wrapped_obj) > 1:
        p1.text(48, 442, wrapped_obj[1], font="F3", size=8, fill_rgb=(0.1, 0.15, 0.25))
        
    # Table of 6 Scenes (Executive Overview)
    p1.text(36, 420, "Official 6-Scene Storyboard Architecture", font="F2", size=12, fill_rgb=(0.1, 0.15, 0.3))
    
    # Table Header
    p1.set_fill_rgb(0.15, 0.25, 0.45)
    p1.rect(36, 396, 540, 18, fill=True, stroke=False)
    p1.text(42, 402, "Scene", font="F2", size=8, fill_rgb=(1, 1, 1))
    p1.text(80, 402, "Official Purpose", font="F2", size=8, fill_rgb=(1, 1, 1))
    p1.text(195, 402, "Core Visual & Mathematical Animation Plan", font="F2", size=8, fill_rgb=(1, 1, 1))
    p1.text(470, 402, "Timing", font="F2", size=8, fill_rgb=(1, 1, 1))
    p1.text(515, 402, "Words", font="F2", size=8, fill_rgb=(1, 1, 1))
    
    scene_rows = [
        ("Scene 1", "Opening & Hook", "Spoken intro (Meka Vikas, M3) & 3D planes hook intersecting at (1,2,3).", "0:00 - 0:48 (48s)", "120 w"),
        ("Scene 2", "Concept Intro", "Define system Ax=b, augmented matrix [A|b], pivots & 3 row operations.", "0:48 - 1:32 (44s)", "98 w"),
        ("Scene 3", "Visual Intuition", "Prove why row operations preserve truth & upper-triangular echelon goal.", "1:32 - 2:11 (39s)", "88 w"),
        ("Scene 4", "Worked Example", "Four row operations to echelon form, then back-substitution cascade.", "2:11 - 4:25 (134s)", "245 w"),
        ("Scene 5", "Interpretation", "Connect algebra to 3D point (1,2,3); verify in 3 original equations.", "4:25 - 5:06 (41s)", "85 w"),
        ("Scene 6", "Summary & Credits", "3 core takeaways; title/name/URN frame, references & AI disclosure.", "5:06 - 5:33 (27s)", "62 w"),
    ]
    
    t_y = 374
    for i, (sc_id, sc_purp, sc_plan, sc_time, sc_wc) in enumerate(scene_rows):
        bg_col = (0.97, 0.98, 1.0) if i % 2 == 0 else (1.0, 1.0, 1.0)
        p1.set_fill_rgb(*bg_col)
        p1.rect(36, t_y, 540, 22, fill=True, stroke=False)
        p1.text(42, t_y + 7, sc_id, font="F2", size=8, fill_rgb=(0.15, 0.25, 0.45))
        p1.text(80, t_y + 7, sc_purp, font="F1", size=8, fill_rgb=(0.2, 0.2, 0.2))
        p1.text(195, t_y + 7, sc_plan, font="F1", size=7.5, fill_rgb=(0.1, 0.1, 0.1))
        p1.text(470, t_y + 7, sc_time, font="F2", size=7.5, fill_rgb=(0.1, 0.45, 0.2))
        p1.text(520, t_y + 7, sc_wc, font="F1", size=7.5, fill_rgb=(0.4, 0.4, 0.4))
        t_y -= 23
        
    # Bottom Note Box
    p1.set_fill_rgb(0.98, 0.95, 0.92)
    p1.set_stroke_rgb(0.9, 0.6, 0.2)
    p1.rect(36, 175, 540, 48, fill=True, stroke=True)
    p1.text(46, 208, "CRITICAL PEDAGOGICAL & TECHNICAL HIGHLIGHTS:", font="F2", size=8.5, fill_rgb=(0.7, 0.35, 0.0))
    p1.text(46, 194, "* Verified Unique Solution: det(A) = 7 != 0. System has full rank 3 and intersects at exactly one point (1, 2, 3).", font="F1", size=8, fill_rgb=(0.2, 0.2, 0.2))
    p1.text(46, 182, "* Avoids Awkward Fractions: Row Swap (R2 <-> R3) places pivot 1 at position (2, 2) before eliminating row 3.", font="F1", size=8, fill_rgb=(0.2, 0.2, 0.2))

    # -------------------------------------------------------------
    # PAGE 2: DETAILED STORYBOARD - SCENE 1 & SCENE 2
    # -------------------------------------------------------------
    p2 = pdf.new_page()
    p2.text(36, 735, "Scene-by-Scene Detailed Storyboard & Production Plans", font="F2", size=14, fill_rgb=(0.1, 0.15, 0.3))
    
    # --- SCENE 1 CARD ---
    p2.set_fill_rgb(0.95, 0.97, 1.0)
    p2.set_stroke_rgb(0.2, 0.4, 0.8)
    p2.set_line_width(1)
    p2.rect(36, 440, 540, 280, fill=True, stroke=True)
    
    # Header badge
    p2.set_fill_rgb(0.15, 0.25, 0.45)
    p2.rect(36, 696, 540, 24, fill=True, stroke=False)
    p2.text(46, 704, "SCENE 1: OPENING TITLE, STUDENT INTRO & HOOK", font="F2", size=10, fill_rgb=(1, 1, 1))
    p2.text(370, 704, "Timestamp: 0:00 - 0:48 | Duration: 48s", font="F2", size=9, fill_rgb=(0.3, 0.9, 1.0))
    
    # 3-column subgrid: Visual, Mathematics/Animation, Spoken Narration
    p2.text(46, 680, "VISUAL SCREENPLAY & CAMERA:", font="F2", size=8, fill_rgb=(0.15, 0.25, 0.45))
    s1_vis = [
        "0:00-0:13 Opening title card displays official course banner, project title, student name, URN E25B070539, and GitHub.",
        "0:13-0:34 Equations appear sequentially (13.7s-17.3s); bounded 3D plot reveals 3 translucent gridded planes:",
        "  - Plane 1 (Cyan): x + y + z = 6    - Plane 2 (Emerald): 2x - y + z = 3    - Plane 3 (Coral): x + 2y - z = 2",
        "0:34-0:48 Pulsing gold intersection sphere (1, 2, 3) with leader badge; coupled variables prompt reveals",
        "  'GAUSSIAN ELIMINATION' solution method banner on spoken cue."
    ]
    p2.text_box(46, 668, 520, s1_vis, font="F1", size=7.5, line_spacing=10.5)
    
    p2.text(46, 595, "MATHEMATICAL REPRESENTATION:", font="F2", size=8, fill_rgb=(0.15, 0.25, 0.45))
    s1_math = [
        "System: { x + y + z = 6,  2x - y + z = 3,  x + 2y - z = 2 }",
        "Geometric configuration: Three planes in R^3 intersecting pairwise in lines, and mutually at (1, 2, 3)."
    ]
    p2.text_box(46, 583, 520, s1_math, font="F5", size=7.5, line_spacing=10.5)
    
    p2.text(46, 550, "EXACT SPOKEN NARRATION SCRIPT (Word-for-Word):", font="F2", size=8, fill_rgb=(0.7, 0.2, 0.1))
    s1_narr = [
        'Intro (0:00-0:12): "Hello everyone, my name is Meka Vikas. In this internal assessment video for Linear Algebra',
        'and Calculus, we will explore how Gaussian elimination solves a 3 by 3 system of linear equations."',
        'Hook (0:13-0:48): "Imagine you are handed three linear equations with three unknown variables: x, y, and z.',
        'Geometrically, every linear equation in three variables forms a flat plane in 3D space. Finding a simultaneous solution',
        'means finding the exact coordinates where all the three planes intersect at a single point. When the variables are',
        'completely tangled together, guessing is impossible. So how can we systematically untangle them without altering the',
        'answer? That is precisely what Gaussian elimination does."'
    ]
    p2.text_box(46, 538, 520, s1_narr, font="F3", size=7, line_spacing=9.5, fill_rgb=(0.15, 0.15, 0.2))
    
    # --- SCENE 2 CARD ---
    p2.set_fill_rgb(0.98, 0.98, 1.0)
    p2.set_stroke_rgb(0.2, 0.4, 0.8)
    p2.set_line_width(1)
    p2.rect(36, 135, 540, 290, fill=True, stroke=True)
    
    # Header badge
    p2.set_fill_rgb(0.15, 0.25, 0.45)
    p2.rect(36, 401, 540, 24, fill=True, stroke=False)
    p2.text(46, 409, "SCENE 2: CONCEPT INTRODUCTION", font="F2", size=10, fill_rgb=(1, 1, 1))
    p2.text(370, 409, "Timestamp: 0:48 - 1:32 | Duration: 44s", font="F2", size=9, fill_rgb=(0.3, 0.9, 1.0))
    
    p2.text(46, 386, "VISUAL SCREENPLAY & CAMERA:", font="F2", size=8, fill_rgb=(0.15, 0.25, 0.45))
    s2_vis = [
        "0:48-0:59 Equations align; variables dissolve and morph into Augmented Matrix [A | b].",
        "0:59-1:08 Coefficient Matrix A highlights, augmentation line draws, Constants b highlights.",
        "1:08-1:14 Matrix shifts left; Goal: Row Echelon Form (REF) schematic with P1, P2, P3 appears on right.",
        "1:14-1:32 Three Rule Cards pop in sequentially (76.8s, 78.3s, 80.6s); Pivot (1,1)=1 glows at 84.2s."
    ]
    p2.text_box(46, 374, 520, s2_vis, font="F1", size=7.5, line_spacing=10.5)
    
    p2.text(46, 310, "MATHEMATICAL MATRIX DEFINITIONS:", font="F2", size=8, fill_rgb=(0.15, 0.25, 0.45))
    s2_math = [
        "Coefficient Matrix A = [[1, 1, 1], [2, -1, 1], [1, 2, -1]],  b = [6, 3, 2]^T",
        "Augmented Matrix [A | b] = [ [1,  1,  1 | 6],  [2, -1,  1 | 3],  [1,  2, -1 | 2] ]",
        "Row Echelon Form Goal: Upper triangular zero pattern beneath diagonal pivots."
    ]
    p2.text_box(46, 298, 520, s2_math, font="F5", size=7.5, line_spacing=10.5)
    
    p2.text(46, 252, "EXACT SPOKEN NARRATION SCRIPT (Word-for-Word):", font="F2", size=8, fill_rgb=(0.7, 0.2, 0.1))
    s2_narr = [
        '"Before we crunch numbers, let\'s define our tools.',
        'A system of linear equations can be stripped of its variable letters and stored as an augmented matrix.',
        'The left side holds the coefficients of x, y, and z, separated by a line from the constants on the right.',
        'Our goal is to reach Row Echelon Form—an upper-triangular pattern with zeros below the diagonal.',
        'To get there, we use three elementary row operations: swapping rows, scaling a row by a non-zero constant, or adding a multiple of one row to another.',
        'The leading non-zero number in each row is called a pivot."'
    ]
    p2.text_box(46, 240, 520, s2_narr, font="F3", size=7.5, line_spacing=10.5, fill_rgb=(0.15, 0.15, 0.2))

    # -------------------------------------------------------------
    # PAGE 3: DETAILED STORYBOARD - SCENE 3 & SCENE 4 (ELIMINATION)
    # -------------------------------------------------------------
    p3 = pdf.new_page()
    p3.text(36, 735, "Scene-by-Scene Detailed Storyboard (Continued)", font="F2", size=14, fill_rgb=(0.1, 0.15, 0.3))
    
    # --- SCENE 3 CARD ---
    p3.set_fill_rgb(0.97, 0.99, 0.97)
    p3.set_stroke_rgb(0.1, 0.5, 0.2)
    p3.set_line_width(1)
    p3.rect(36, 525, 540, 195, fill=True, stroke=True)
    
    # Header badge
    p3.set_fill_rgb(0.12, 0.38, 0.22)
    p3.rect(36, 696, 540, 24, fill=True, stroke=False)
    p3.text(46, 704, "SCENE 3: VISUAL INTUITION", font="F2", size=10, fill_rgb=(1, 1, 1))
    p3.text(370, 704, "Timestamp: 1:32 - 2:11 | Duration: 39s", font="F2", size=9, fill_rgb=(0.7, 1.0, 0.7))
    
    s3_vis = [
        "1:32-1:53 Left panel builds algebraic equivalence (LHS1=RHS1, LHS2+k*LHS1=RHS2+k*RHS1) & invertibility.",
        "1:53-2:05 Right panel shows 3D planes tilting toward simpler planes while (1, 2, 3) remains locked.",
        "2:05-2:11 Right panel transitions to Echelon Form matrix + staircase highlighting -7z = -21 (1 unknown!)."
    ]
    p3.text(46, 680, "VISUAL SCREENPLAY & INTUITION:", font="F2", size=8, fill_rgb=(0.12, 0.38, 0.22))
    p3.text_box(46, 668, 520, s3_vis, font="F1", size=7.5, line_spacing=10.5)
    
    s3_narr = [
        '"Why are row operations mathematically legal? Each row is simply an equation.',
        'If two statements are true, adding a multiple of one true statement to another creates a new, equally true statement.',
        'Because each elementary operation can be reversed by an inverse operation, the solution set is strictly preserved.',
        'Geometrically, row operations replace our original planes with new, simpler planes that still intersect at the exact same point.',
        'By systematically creating zeros beneath our pivots, we untangle the variables, leaving the bottom equation with only one unknown."'
    ]
    p3.text(46, 615, "EXACT SPOKEN NARRATION SCRIPT (Word-for-Word):", font="F2", size=8, fill_rgb=(0.7, 0.2, 0.1))
    p3.text_box(46, 603, 520, s3_narr, font="F3", size=7.5, line_spacing=10.5, fill_rgb=(0.15, 0.15, 0.2))
    
    # --- SCENE 4 (PART 1: ELIMINATION) CARD ---
    p3.set_fill_rgb(0.99, 0.98, 0.95)
    p3.set_stroke_rgb(0.8, 0.4, 0.1)
    p3.set_line_width(1)
    p3.rect(36, 85, 540, 425, fill=True, stroke=True)
    
    # Header badge
    p3.set_fill_rgb(0.55, 0.25, 0.05)
    p3.rect(36, 486, 540, 24, fill=True, stroke=False)
    p3.text(46, 494, "SCENE 4 (PART 1): WORKED EXAMPLE - GAUSSIAN ELIMINATION", font="F2", size=10, fill_rgb=(1, 1, 1))
    p3.text(370, 494, "Timestamp: 2:11 - 3:41 | Duration: 90s", font="F2", size=9, fill_rgb=(1.0, 0.85, 0.4))
    
    p3.text(46, 472, "STEP-BY-STEP ELIMINATION WALKTHROUGH & INTERMEDIATE ARITHMETIC:", font="F2", size=8, fill_rgb=(0.55, 0.25, 0.05))
    
    s4_steps = [
        "STEP 4A: Eliminate x from Row 2 (R2 -> R2 - 2*R1)  [2:11 - 2:41]",
        "  Pivot 1 = 1 at (1,1). Target = 2 at (2,1).",
        "  Calculation:  [2, -1, 1 | 3] - 2*[1, 1, 1 | 6] = [2-2, -1-2, 1-2 | 3-12] = [0, -3, -1 | -9]",
        "  Matrix M1:   Row 2 becomes [0, -3, -1 | -9] on exact spoken arithmetic cues (147.8s-157.0s).",
        "",
        "STEP 4B: Eliminate x from Row 3 (R3 -> R3 - R1)  [2:41 - 3:02]",
        "  Target = 1 at (3,1).",
        "  Calculation:  [1, 2, -1 | 2] - 1*[1, 1, 1 | 6] = [1-1, 2-1, -1-1 | 2-6] = [0, 1, -2 | -4]",
        "  Matrix M2:   Row 3 becomes [0, 1, -2 | -4]. Column 1 cleared beneath pivot 1!",
        "",
        "STEP 4C: Strategic Row Swap (R2 <-> R3)  [3:02 - 3:19]",
        "  Column 2 has -3 in row 2 and 1 in row 3. Swapping avoids introducing fractions!",
        "  Smooth 3D card-flip swap (191.5s-194.6s): Row 2 = [0, 1, -2 | -4], Row 3 = [0, -3, -1 | -9].",
        "  Pivot 2 = 1 at position (2, 2).",
        "",
        "STEP 4D: Eliminate y from Row 3 (R3 -> R3 + 3*R2)  [3:19 - 3:41]",
        "  Target = -3 at (3,2).",
        "  Calculation:  [0, -3, -1 | -9] + 3*[0, 1, -2 | -4] = [0+0, -3+3, -1-6 | -9-12] = [0, 0, -7 | -21]",
        "  Matrix M_REF: Row 3 becomes [0, 0, -7 | -21].",
        "  Staircase highlighted: Pivots = 1, 1, -7. All entries below pivots are zero. REF ACHIEVED!"
    ]
    p3.text_box(46, 458, 520, s4_steps, font="F5", size=7, line_spacing=9.5)
    
    p3.text(46, 220, "EXACT SPOKEN NARRATION SCRIPT (Steps 4A - 4D):", font="F2", size=8, fill_rgb=(0.7, 0.2, 0.1))
    s4_elim_narr = [
        '"Let\'s work through our system step-by-step. Our first pivot is the one in the top-left corner.',
        'To eliminate the two beneath it in Row 2, we subtract two times Row 1 from Row 2.',
        'Two minus two is zero; negative one minus two is negative three; one minus two is negative one; and three minus twelve gives negative nine.',
        'Our first zero is locked in.',
        'Next, to eliminate the one in Row 3, we subtract Row 1 from Row 3.',
        'One minus one is zero; two minus one is one; negative one minus one is negative two; and two minus six gives negative four.',
        'Column one now has zeros everywhere below the first pivot.',
        'Now look at column two. Row 2 has negative three, but Row 3 has a clean one.',
        'Instead of dividing by negative three and creating awkward fractions, we swap Row 2 and Row 3. Now our second pivot is a simple one.',
        'To eliminate the negative three now sitting in Row 3, we add three times Row 2 to Row 3.',
        'Zero plus zero is zero; negative three plus three is zero; negative one plus negative six is negative seven; and negative nine plus negative twelve is negative twenty-one.',
        'Look at that: we have reached Row Echelon Form!"'
    ]
    p3.text_box(46, 208, 520, s4_elim_narr, font="F3", size=7, line_spacing=9.5, fill_rgb=(0.15, 0.15, 0.2))

    # -------------------------------------------------------------
    # PAGE 4: DETAILED STORYBOARD - BACK-SUBSTITUTION & SCENE 5
    # -------------------------------------------------------------
    p4 = pdf.new_page()
    p4.text(36, 735, "Scene-by-Scene Detailed Storyboard (Continued)", font="F2", size=14, fill_rgb=(0.1, 0.15, 0.3))
    
    # --- SCENE 4 (PART 2: BACK-SUBSTITUTION) CARD ---
    p4.set_fill_rgb(0.97, 0.98, 1.0)
    p4.set_stroke_rgb(0.2, 0.4, 0.8)
    p4.set_line_width(1)
    p4.rect(36, 440, 540, 280, fill=True, stroke=True)
    
    p4.set_fill_rgb(0.15, 0.25, 0.45)
    p4.rect(36, 696, 540, 24, fill=True, stroke=False)
    p4.text(46, 704, "SCENE 4 (PART 2): BACK-SUBSTITUTION CASCADE", font="F2", size=10, fill_rgb=(1, 1, 1))
    p4.text(370, 704, "Timestamp: 3:41 - 4:25 | Duration: 44s", font="F2", size=9, fill_rgb=(0.3, 0.9, 1.0))
    
    p4.text(46, 680, "VISUAL CASCADE & BACK-SUBSTITUTION ARITHMETIC:", font="F2", size=8, fill_rgb=(0.15, 0.25, 0.45))
    s4_bs_vis = [
        "The upper triangular matrix unpacks into 3 decoupled equations on screen:",
        "  Row 3:  -7z = -21   ==>   z = (-21) / (-7) = 3   [Amber badge glows, slides into solution box]",
        "  Row 2:  y - 2z = -4 ==>   y - 2(3) = -4  ==>  y - 6 = -4  ==>  y = 2  [Emerald badge glows]",
        "  Row 1:  x + y + z = 6 ==> x + 2 + 3 = 6  ==>  x + 5 = 6  ==>  x = 1  [Cyan badge glows]",
        "Final solution box pulses with gold aura: [x, y, z]^T = [1, 2, 3]^T."
    ]
    p4.text_box(46, 668, 520, s4_bs_vis, font="F5", size=7.5, line_spacing=11)
    
    p4.text(46, 585, "EXACT SPOKEN NARRATION SCRIPT (Word-for-Word):", font="F2", size=8, fill_rgb=(0.7, 0.2, 0.1))
    s4_bs_narr = [
        '"Now comes the payoff: back-substitution.',
        'The bottom row tells us: negative seven z equals negative twenty-one.',
        'Dividing by negative seven gives z equals three.',
        'We substitute z = 3 into the second row: y minus two times three equals negative four.',
        'That is y minus six equals negative four, which gives y equals two.',
        'Finally, plug y = 2 and z = 3 into the top row: x plus two plus three equals six, meaning x plus five equals six, so x equals one.',
        'Our solution is x = 1, y = 2, and z = 3."'
    ]
    p4.text_box(46, 573, 520, s4_bs_narr, font="F3", size=7.5, line_spacing=11, fill_rgb=(0.15, 0.15, 0.2))
    
    # --- SCENE 5 CARD ---
    p4.set_fill_rgb(0.96, 0.99, 0.96)
    p4.set_stroke_rgb(0.1, 0.6, 0.3)
    p4.set_line_width(1)
    p4.rect(36, 135, 540, 285, fill=True, stroke=True)
    
    p4.set_fill_rgb(0.1, 0.4, 0.2)
    p4.rect(36, 396, 540, 24, fill=True, stroke=False)
    p4.text(46, 404, "SCENE 5: GEOMETRIC INTERPRETATION & DIRECT VERIFICATION", font="F2", size=10, fill_rgb=(1, 1, 1))
    p4.text(370, 404, "Timestamp: 4:25 - 5:06 | Duration: 41s", font="F2", size=9, fill_rgb=(0.6, 1.0, 0.6))
    
    p4.text(46, 380, "VISUAL SCREENPLAY & DIRECT SUBSTITUTION CHECK:", font="F2", size=8, fill_rgb=(0.1, 0.4, 0.2))
    s5_vis = [
        "Left side: 3D planes return with axes and intersection point (1, 2, 3). Coordinate drops mark x=1, y=2, z=3.",
        "Right side: Three original equations verify simultaneously with green checkmarks:",
        "  Eq 1:  1 + 2 + 3 = 6           ==>  6 = 6    [CHECK - TRUE]",
        "  Eq 2:  2(1) - (2) + (3) = 3     ==>  3 = 3    [CHECK - TRUE]",
        "  Eq 3:  (1) + 2(2) - (3) = 2     ==>  2 = 2    [CHECK - TRUE]",
        "Deep geometric takeaway: Row operations preserve intersection geometry while clarifying coordinate readout."
    ]
    p4.text_box(46, 368, 520, s5_vis, font="F5", size=7.5, line_spacing=11)
    
    p4.text(46, 285, "EXACT SPOKEN NARRATION SCRIPT (Word-for-Word):", font="F2", size=8, fill_rgb=(0.7, 0.2, 0.1))
    s5_narr = [
        '"Let\'s connect this algebra back to our geometry.',
        'When we plot the three original equations in three-dimensional space, they meet at a single, unique point: (1, 2, 3).',
        'Gaussian elimination did not move this point.',
        'Instead, it transformed three complex, tilted planes into three simple, coordinate-aligned boundaries that reveal the solution directly.',
        'We verify by checking all three original equations: one plus two plus three equals six; two minus two plus three equals three; and one plus four minus three equals two.',
        'Every equation holds perfectly."'
    ]
    p4.text_box(46, 273, 520, s5_narr, font="F3", size=7.5, line_spacing=11, fill_rgb=(0.15, 0.15, 0.2))

    # -------------------------------------------------------------
    # PAGE 5: SCENE 6, VERIFICATION PROOFS, REFERENCES & AI DISCLOSURE
    # -------------------------------------------------------------
    p5 = pdf.new_page()
    p5.text(36, 735, "Summary, Mathematical Proofs, References & AI Disclosure", font="F2", size=14, fill_rgb=(0.1, 0.15, 0.3))
    
    # --- SCENE 6 CARD ---
    p5.set_fill_rgb(0.98, 0.98, 0.98)
    p5.set_stroke_rgb(0.3, 0.3, 0.3)
    p5.set_line_width(1)
    p5.rect(36, 545, 540, 175, fill=True, stroke=True)
    
    p5.set_fill_rgb(0.2, 0.2, 0.25)
    p5.rect(36, 696, 540, 24, fill=True, stroke=False)
    p5.text(46, 704, "SCENE 6: SUMMARY & CLOSING CREDITS", font="F2", size=10, fill_rgb=(1, 1, 1))
    p5.text(370, 704, "Timestamp: 5:06 - 5:33 | Duration: 27s", font="F2", size=9, fill_rgb=(1.0, 0.8, 0.4))
    
    s6_vis = [
        "5:06-5:26 Three cards display core takeaways on cue: 1. Augmented Matrices  2. Row Invariance  3. Back-Substitution.",
        "5:26-5:33 Closing frame displays course header, project title, verified solution & takeaways strip, and student credentials."
    ]
    p5.text(46, 680, "VISUAL SUMMARY & CREDITS:", font="F2", size=8, fill_rgb=(0.2, 0.2, 0.25))
    p5.text_box(46, 668, 520, s6_vis, font="F1", size=7.5, line_spacing=10.5)
    
    s6_narr = [
        '"To summarize: First, augmented matrices strip away notations to expose pure structure.',
        'Second, elementary row operations simplify equations while preserving the exact same solution set.',
        'And third, reaching row echelon form unleashes a cascade of back-substitution to solve the system.',
        'That is the elegance of Gaussian elimination.',
        'I am Meka Vikas. Thank you for watching."'
    ]
    p5.text(46, 626, "EXACT SPOKEN NARRATION SCRIPT (Word-for-Word):", font="F2", size=8, fill_rgb=(0.7, 0.2, 0.1))
    p5.text_box(46, 614, 520, s6_narr, font="F3", size=7, line_spacing=9.5, fill_rgb=(0.15, 0.15, 0.2))
    
    # --- MATHEMATICAL VERIFICATION & DETERMINANT PROOF ---
    p5.set_fill_rgb(0.95, 0.97, 1.0)
    p5.set_stroke_rgb(0.2, 0.4, 0.8)
    p5.rect(36, 385, 540, 145, fill=True, stroke=True)
    p5.text(46, 514, "MATHEMATICAL VERIFICATION SHEET & THEORETICAL RIGOR:", font="F2", size=8.5, fill_rgb=(0.15, 0.25, 0.45))
    
    proof_lines = [
        "1. Determinant Verification: det(A) = 1*(-1*-1 - 1*2) - 1*(2*-1 - 1*1) + 1*(2*2 - -1*1) = 1*(-1) - 1*(-3) + 1*(5) = 7 != 0.",
        "   Since det(A) = 7 != 0, matrix A is invertible, has full rank 3, and guarantees a unique intersection point in R^3.",
        "2. REF Determinant Consistency: In echelon form, product of diagonal elements is 1 * 1 * (-7) = -7.",
        "   Accounting for exactly one row swap (R2 <-> R3) which multiplies det by (-1): det(A) = -1 * (-7) = 7 (Consistent).",
        "3. Solution Set Invariance: Elementary row operations correspond to multiplication by invertible elementary matrices",
        "   E1, E2, P23, E4. Since each elementary matrix is non-singular, Sol(Ax = b) = Sol(Ux = b') is mathematically invariant."
    ]
    p5.text_box(46, 498, 520, proof_lines, font="F5", size=7, line_spacing=10)
    
    # --- REFERENCES & AI DISCLOSURE ---
    p5.set_fill_rgb(0.98, 0.96, 0.94)
    p5.set_stroke_rgb(0.8, 0.4, 0.1)
    p5.rect(36, 60, 540, 310, fill=True, stroke=True)
    
    p5.text(46, 355, "MATHEMATICAL REFERENCES:", font="F2", size=8.5, fill_rgb=(0.6, 0.3, 0.0))
    refs = [
        "1. Strang, Gilbert. Introduction to Linear Algebra, 5th ed., Wellesley-Cambridge Press, 2016. (Chapter 2: Elimination)",
        "2. Lay, David C., Lay, Steven R., & McDonald, Judi J. Linear Algebra and Its Applications, 5th ed., Pearson, 2016. (Sections 1.1-1.2)",
        "3. Sanderson, Grant (3Blue1Brown). Essence of Linear Algebra Video Series, 2016. (Geometric perspective & visual pacing)",
        "4. Anton, Howard, & Rorres, Chris. Elementary Linear Algebra, 11th ed., Wiley, 2014. (Row reduction algorithms)"
    ]
    p5.text_box(46, 342, 520, refs, font="F1", size=7, line_spacing=9.5)
    
    p5.text(46, 290, "FORMAL AI TOOL DISCLOSURE STATEMENT:", font="F2", size=8.5, fill_rgb=(0.6, 0.3, 0.0))
    ai_disc = [
        "- AI Tool Utilized: Antigravity AI (Google DeepMind) as an interactive pedagogical co-designer and scripting assistant.",
        "- Scope of AI Usage: Timing budgeting (ensuring 5-minute target), LaTeX equation formatting, storyboard layout scaffolding,",
        "  and Manim programmatic animation architecture planning.",
        "- Student Original Effort & Human Verification: Every matrix transformation, intermediate arithmetic calculation, determinant check,",
        "  and back-substitution was independently calculated on paper and verified by the student. Voice narration will be personally spoken",
        "  and recorded by the student. The student is prepared to independently defend all derivations and animation code during course viva."
    ]
    p5.text_box(46, 277, 520, ai_disc, font="F1", size=7, line_spacing=9.5)
    
    p5.text(46, 205, "OPENING AND CLOSING FRAME SPECIFICATIONS (Course Compliance):", font="F2", size=8.5, fill_rgb=(0.6, 0.3, 0.0))
    frame_specs = [
        "* OPENING FRAME (0:00 - 0:12.8): Features Project Title ('Gaussian Elimination: Solving a 3x3 System Step by Step'),",
        "  Course Banner ('Linear Algebra and Calculus M3'), Student Name (Meka Vikas), URN (E25B070539), and GitHub.",
        "* CLOSING FRAME (5:26.8 - 5:33.2): Re-states Project Title, Student Credentials, References, Audio Note, and AI Disclosure.",
        "* VIVA READINESS: Prepared to demonstrate matrix rank, elementary row matrices, pivot mechanics, and code structure."
    ]
    p5.text_box(46, 192, 520, frame_specs, font="F1", size=7, line_spacing=9.5)
    
    pdf.save()

if __name__ == "__main__":
    build_storyboard_pdf()

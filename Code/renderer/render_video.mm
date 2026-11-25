#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>
#import <math.h>
#import <vector>
#import <algorithm>

typedef struct {
    double x, y, z;
} CGPoint3D;

// Smoothstep & Interpolation Utilities
static inline double clamp01(double v) {
    return v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);
}

static inline double smoothstep(double t, double t0, double t1) {
    if (t1 <= t0) return (t >= t1) ? 1.0 : 0.0;
    double u = clamp01((t - t0) / (t1 - t0));
    return u * u * (3.0 - 2.0 * u);
}

static inline double lerp(double a, double b, double u) {
    return a + (b - a) * u;
}

// Color Palette (3Blue1Brown-inspired)
static CGColorRef col_bg, col_panel, col_panel_border;
static CGColorRef col_x, col_y, col_z, col_const;
static CGColorRef col_pivot, col_badge, col_success, col_bracket;
static CGColorRef col_text, col_muted, col_gold;

#define RGBA(r, g, b, a) CGColorCreateGenericRGB((r)/255.0, (g)/255.0, (b)/255.0, (a))

void initColors() {
    col_bg           = RGBA(24, 24, 37, 1.0);       // #181825 Obsidian Dark Slate
    col_panel        = RGBA(36, 39, 58, 0.94);      // #24273A Surface Panel
    col_panel_border = RGBA(72, 80, 112, 1.0);
    col_x            = RGBA(0, 212, 255, 1.0);      // Cyan (#00D4FF)
    col_y            = RGBA(0, 230, 118, 1.0);      // Emerald (#00E676)
    col_z            = RGBA(255, 214, 0, 1.0);      // Amber (#FFD600)
    col_const        = RGBA(230, 234, 245, 1.0);    // Silver White
    col_pivot        = RGBA(255, 82, 82, 1.0);      // Coral Red (#FF5252)
    col_badge        = RGBA(171, 71, 188, 1.0);     // Royal Magenta (#AB47BC)
    col_success      = RGBA(105, 240, 174, 1.0);    // Mint Green (#69F0AE)
    col_bracket      = RGBA(121, 134, 203, 1.0);    // Cornflower Slate (#7986CB)
    col_text         = RGBA(255, 255, 255, 1.0);    // Pure White
    col_muted        = RGBA(170, 178, 200, 1.0);    // Soft Gray
    col_gold         = RGBA(255, 224, 96, 1.0);     // Bright Gold
}

CGColorRef colorWithAlpha(CGColorRef base, double alpha) {
    if (alpha >= 0.999) return CGColorRetain(base);
    return CGColorCreateCopyWithAlpha(base, clamp01(alpha));
}

// Rich Math Text Helper: supports _{sub} and ^{sup} inline markup cleanly via CoreText
NSAttributedString* buildMathAttrString(NSString *str, NSString *fontName, CGFloat fontSize, CGColorRef color) {
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] init];
    CTFontRef baseFont = CTFontCreateWithName((__bridge CFStringRef)fontName, fontSize, NULL);
    CTFontRef subFont  = CTFontCreateWithName((__bridge CFStringRef)fontName, fontSize * 0.68, NULL);
    NSDictionary *baseAttr = @{
        (__bridge id)kCTFontAttributeName: (__bridge id)baseFont,
        (__bridge id)kCTForegroundColorAttributeName: (__bridge id)color
    };
    NSDictionary *subAttr = @{
        (__bridge id)kCTFontAttributeName: (__bridge id)subFont,
        (__bridge id)kCTForegroundColorAttributeName: (__bridge id)color,
        NSBaselineOffsetAttributeName: @(-fontSize * 0.22)
    };
    NSDictionary *supAttr = @{
        (__bridge id)kCTFontAttributeName: (__bridge id)subFont,
        (__bridge id)kCTForegroundColorAttributeName: (__bridge id)color,
        NSBaselineOffsetAttributeName: @(fontSize * 0.34)
    };
    
    NSUInteger i = 0, len = str.length;
    while (i < len) {
        unichar ch = [str characterAtIndex:i];
        if ((ch == '_' || ch == '^') && i + 1 < len && [str characterAtIndex:i + 1] == '{') {
            NSRange closeR = [str rangeOfString:@"}" options:0 range:NSMakeRange(i + 2, len - (i + 2))];
            if (closeR.location != NSNotFound) {
                NSString *inner = [str substringWithRange:NSMakeRange(i + 2, closeR.location - (i + 2))];
                [res appendAttributedString:[[NSAttributedString alloc] initWithString:inner attributes:(ch == '_' ? subAttr : supAttr)]];
                i = closeR.location + 1;
                continue;
            }
        }
        NSUInteger j = i + 1;
        while (j < len) {
            unichar nj = [str characterAtIndex:j];
            if ((nj == '_' || nj == '^') && j + 1 < len && [str characterAtIndex:j + 1] == '{') break;
            j++;
        }
        NSString *chunk = [str substringWithRange:NSMakeRange(i, j - i)];
        [res appendAttributedString:[[NSAttributedString alloc] initWithString:chunk attributes:baseAttr]];
        i = j;
    }
    CFRelease(baseFont);
    CFRelease(subFont);
    return res;
}

void drawTextAlpha(CGContextRef ctx, NSString *str, CGPoint pt, NSString *fontName, CGFloat fontSize, CGColorRef color, NSTextAlignment align, double alpha) {
    if (!str || str.length == 0 || alpha <= 0.01) return;
    CGColorRef colA = colorWithAlpha(color, alpha);
    NSAttributedString *attrStr = buildMathAttrString(str, fontName, fontSize, colA);
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attrStr);
    CGFloat width = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
    CGFloat drawX = pt.x;
    if (align == NSTextAlignmentCenter) drawX = pt.x - width / 2.0;
    else if (align == NSTextAlignmentRight) drawX = pt.x - width;
    
    CGContextSaveGState(ctx);
    CGContextSetTextPosition(ctx, drawX, pt.y);
    CTLineDraw(line, ctx);
    CGContextRestoreGState(ctx);
    
    CFRelease(line);
    CGColorRelease(colA);
}

void drawText(CGContextRef ctx, NSString *str, CGPoint pt, NSString *fontName, CGFloat fontSize, CGColorRef color, NSTextAlignment align) {
    drawTextAlpha(ctx, str, pt, fontName, fontSize, color, align, 1.0);
}

void drawRoundedRect(CGContextRef ctx, CGRect rect, CGFloat r, CGColorRef fill, CGColorRef stroke, CGFloat strokeWidth) {
    CGContextSaveGState(ctx);
    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect);
    
    CGContextMoveToPoint(ctx, minx, midy);
    CGContextAddArcToPoint(ctx, minx, miny, midx, miny, r);
    CGContextAddArcToPoint(ctx, maxx, miny, maxx, midy, r);
    CGContextAddArcToPoint(ctx, maxx, maxy, midx, maxy, r);
    CGContextAddArcToPoint(ctx, minx, maxy, minx, midy, r);
    CGContextClosePath(ctx);
    
    if (fill) {
        CGContextSetFillColorWithColor(ctx, fill);
        if (stroke && strokeWidth > 0) {
            CGContextSetStrokeColorWithColor(ctx, stroke);
            CGContextSetLineWidth(ctx, strokeWidth);
            CGContextDrawPath(ctx, kCGPathFillStroke);
        } else {
            CGContextFillPath(ctx);
        }
    } else if (stroke && strokeWidth > 0) {
        CGContextSetStrokeColorWithColor(ctx, stroke);
        CGContextSetLineWidth(ctx, strokeWidth);
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
}

void drawLine(CGContextRef ctx, CGPoint p1, CGPoint p2, CGColorRef col, CGFloat w, BOOL dashed) {
    CGContextSaveGState(ctx);
    CGContextSetStrokeColorWithColor(ctx, col);
    CGContextSetLineWidth(ctx, w);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    if (dashed) {
        CGFloat dash[] = {8.0, 6.0};
        CGContextSetLineDash(ctx, 0, dash, 2);
    }
    CGContextMoveToPoint(ctx, p1.x, p1.y);
    CGContextAddLineToPoint(ctx, p2.x, p2.y);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
}

void drawArrow(CGContextRef ctx, CGPoint p1, CGPoint p2, CGColorRef col, CGFloat w) {
    drawLine(ctx, p1, p2, col, w, NO);
    double angle = atan2(p2.y - p1.y, p2.x - p1.x);
    double headLen = 13.0;
    CGPoint a1 = CGPointMake(p2.x - headLen * cos(angle - M_PI / 6.0), p2.y - headLen * sin(angle - M_PI / 6.0));
    CGPoint a2 = CGPointMake(p2.x - headLen * cos(angle + M_PI / 6.0), p2.y - headLen * sin(angle + M_PI / 6.0));
    CGContextSaveGState(ctx);
    CGContextSetFillColorWithColor(ctx, col);
    CGContextMoveToPoint(ctx, p2.x, p2.y);
    CGContextAddLineToPoint(ctx, a1.x, a1.y);
    CGContextAddLineToPoint(ctx, a2.x, a2.y);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
}

void drawSubtleGrid(CGContextRef ctx, double alpha) {
    if (alpha <= 0.01) return;
    CGColorRef gridCol = RGBA(255, 255, 255, 0.04 * alpha);
    CGContextSaveGState(ctx);
    CGContextSetStrokeColorWithColor(ctx, gridCol);
    CGContextSetLineWidth(ctx, 1.0);
    for (int x = 0; x <= 1920; x += 80) {
        CGContextMoveToPoint(ctx, x, 0);
        CGContextAddLineToPoint(ctx, x, 1080);
    }
    for (int y = 0; y <= 1080; y += 80) {
        CGContextMoveToPoint(ctx, 0, y);
        CGContextAddLineToPoint(ctx, 1920, y);
    }
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    CGColorRelease(gridCol);
}

// Matrix Renderer with non-overlapping Row Swap pills, crisp subscripts, and clean Echelon Staircase
void drawAnimatedMatrix(
    CGContextRef ctx,
    double m[3][4],
    CGPoint center,
    CGFloat cellW,
    CGFloat cellH,
    CGPoint rowOffsets[3],
    int pivR, int pivC,
    int targetR, int targetC,
    int highlightRow,
    int highlightCol,
    double dividerProgress,
    double staircaseProgress,
    BOOL showHeaders,
    double alpha
) {
    if (alpha <= 0.01) return;
    CGFloat totalW = 4 * cellW + 40;
    CGFloat totalH = 3 * cellH + 24;
    CGFloat startX = center.x - totalW / 2.0;
    CGFloat startY = center.y + totalH / 2.0 - cellH;
    
    CGColorRef brCol = colorWithAlpha(col_bracket, alpha);
    CGContextSaveGState(ctx);
    CGContextSetStrokeColorWithColor(ctx, brCol);
    CGContextSetLineWidth(ctx, 4.0);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    
    // Brackets
    CGFloat bx1 = startX - 18;
    CGFloat bx2 = startX + totalW + 18;
    CGFloat byTop = center.y + totalH / 2.0 + 10;
    CGFloat byBot = center.y - totalH / 2.0 - 10;
    
    CGContextMoveToPoint(ctx, bx1 + 20, byTop);
    CGContextAddLineToPoint(ctx, bx1, byTop);
    CGContextAddLineToPoint(ctx, bx1, byBot);
    CGContextAddLineToPoint(ctx, bx1 + 20, byBot);
    CGContextStrokePath(ctx);
    
    CGContextMoveToPoint(ctx, bx2 - 20, byTop);
    CGContextAddLineToPoint(ctx, bx2, byTop);
    CGContextAddLineToPoint(ctx, bx2, byBot);
    CGContextAddLineToPoint(ctx, bx2 - 20, byBot);
    CGContextStrokePath(ctx);
    
    // Augmentation Divider Line
    CGFloat divX = startX + 3 * cellW + 12;
    if (dividerProgress > 0.01) {
        CGFloat curBot = lerp(byTop - 8, byBot + 8, dividerProgress);
        CGContextSetLineWidth(ctx, 2.5);
        CGContextMoveToPoint(ctx, divX, byTop - 8);
        CGContextAddLineToPoint(ctx, divX, curBot);
        CGContextStrokePath(ctx);
    }
    CGContextRestoreGState(ctx);
    CGColorRelease(brCol);
    
    if (showHeaders) {
        drawTextAlpha(ctx, @"x", CGPointMake(startX + 0 * cellW + cellW/2, byTop + 18), @"HelveticaNeue-Bold", 22, col_x, NSTextAlignmentCenter, alpha);
        drawTextAlpha(ctx, @"y", CGPointMake(startX + 1 * cellW + cellW/2, byTop + 18), @"HelveticaNeue-Bold", 22, col_y, NSTextAlignmentCenter, alpha);
        drawTextAlpha(ctx, @"z", CGPointMake(startX + 2 * cellW + cellW/2, byTop + 18), @"HelveticaNeue-Bold", 22, col_z, NSTextAlignmentCenter, alpha);
        drawTextAlpha(ctx, @"b", CGPointMake(startX + 3 * cellW + 22 + cellW/2, byTop + 18), @"HelveticaNeue-Bold", 22, col_const, NSTextAlignmentCenter, alpha);
    }
    
    // Column background highlight (optional)
    if (highlightCol >= 0 && highlightCol < 3) {
        CGFloat colX = startX + highlightCol * cellW + 6;
        CGRect cRect = CGRectMake(colX, byBot + 4, cellW - 12, byTop - byBot - 8);
        CGColorRef cFill = RGBA(0, 212, 255, 0.12 * alpha);
        CGColorRef cStr  = colorWithAlpha(col_x, alpha * 0.55);
        drawRoundedRect(ctx, cRect, 10, cFill, cStr, 1.5);
        CGColorRelease(cFill);
        CGColorRelease(cStr);
    }
    
    // Row background highlight
    if (highlightRow >= 0 && highlightRow < 3) {
        CGFloat ry = startY - highlightRow * cellH + rowOffsets[highlightRow].y - 12;
        CGRect rRect = CGRectMake(startX - 6 + rowOffsets[highlightRow].x, ry, totalW + 12, cellH - 8);
        CGColorRef rFill = RGBA(171, 71, 188, 0.16 * alpha);
        CGColorRef rStr  = colorWithAlpha(col_badge, alpha * 0.7);
        drawRoundedRect(ctx, rRect, 10, rFill, rStr, 1.5);
        CGColorRelease(rFill);
        CGColorRelease(rStr);
    }
    
    // Render rows (supports clean 3D ribbon swap via rowOffsets[r].x as swapU in (0,1) or direct offset)
    for (int r = 0; r < 3; r++) {
        BOOL isMoving = (fabs(rowOffsets[r].y) > 0.5 || fabs(rowOffsets[r].x) > 0.5);
        // Optional per-row vertical scale / alpha fade packed during swap via y displacement
        double rowAlpha = alpha;
        double rowScaleY = 1.0;
        if (isMoving && fabs(rowOffsets[r].y) > 0.5) {
            double frac = clamp01(fabs(rowOffsets[r].y) / cellH); // 0 -> 1
            double c = fabs(cos(frac * M_PI));
            rowScaleY = 0.25 + 0.75 * c;
            rowAlpha = alpha * (0.12 + 0.88 * pow(c, 0.7));
        }
        
        CGFloat rowMidY = startY - r * cellH + rowOffsets[r].y + 18;
        CGContextSaveGState(ctx);
        if (rowScaleY < 0.999) {
            CGContextTranslateCTM(ctx, center.x, rowMidY);
            CGContextScaleCTM(ctx, 1.0, rowScaleY);
            CGContextTranslateCTM(ctx, -center.x, -rowMidY);
        }
        
        if (isMoving) {
            CGFloat py = startY - r * cellH + rowOffsets[r].y - 12;
            CGRect mvRect = CGRectMake(startX - 58 + rowOffsets[r].x, py, totalW + 64, cellH - 8);
            CGColorRef mvFill = RGBA(28, 32, 48, 0.92 * rowAlpha);
            CGColorRef mvBorder = colorWithAlpha((r == 2 ? col_success : col_gold), rowAlpha);
            drawRoundedRect(ctx, mvRect, 12, mvFill, mvBorder, 2.2);
            CGColorRelease(mvFill);
            CGColorRelease(mvBorder);
        }
        
        // Row labels R₁, R₂, R₃
        CGFloat ry = startY - r * cellH + rowOffsets[r].y + 8;
        NSString *rLbl = [NSString stringWithFormat:@"R_{%d}", r + 1];
        CGFloat lblX = isMoving ? (startX - 18 + rowOffsets[r].x) : (bx1 - 24 + rowOffsets[r].x);
        CGColorRef lblCol = isMoving ? (r == 2 ? col_success : col_gold) : col_muted;
        drawTextAlpha(ctx, rLbl, CGPointMake(lblX, ry), @"HelveticaNeue-Bold", 19, lblCol, NSTextAlignmentRight, rowAlpha * (isMoving ? 1.0 : 0.85));
        
        for (int c = 0; c < 4; c++) {
            CGFloat cx = startX + c * cellW + (c == 3 ? 22 : 0) + cellW / 2.0 + rowOffsets[r].x;
            CGFloat cy = startY - r * cellH + 6 + rowOffsets[r].y;
            
            // Highlight pivot cell
            if (r == pivR && c == pivC) {
                CGRect pRect = CGRectMake(cx - cellW/2 + 12, cy - 10, cellW - 24, cellH - 14);
                CGColorRef pf = RGBA(255, 82, 82, 0.25 * rowAlpha);
                CGColorRef ps = colorWithAlpha(col_pivot, rowAlpha);
                drawRoundedRect(ctx, pRect, 10, pf, ps, 2.5);
                CGColorRelease(pf);
                CGColorRelease(ps);
            }
            // Highlight target elimination cell
            if (r == targetR && c == targetC) {
                CGRect tRect = CGRectMake(cx - cellW/2 + 12, cy - 10, cellW - 24, cellH - 14);
                CGColorRef tf = RGBA(255, 214, 0, 0.22 * rowAlpha);
                CGColorRef ts = colorWithAlpha(col_z, rowAlpha);
                drawRoundedRect(ctx, tRect, 10, tf, ts, 2.5);
                CGColorRelease(tf);
                CGColorRelease(ts);
            }
            
            double val = m[r][c];
            NSString *valStr = (fabs(val - round(val)) < 1e-6) ? [NSString stringWithFormat:@"%d", (int)round(val)] : [NSString stringWithFormat:@"%.1f", val];
            valStr = [valStr stringByReplacingOccurrencesOfString:@"-" withString:@"−"];
            
            CGColorRef cCol = col_text;
            if (c == 0) cCol = col_x;
            else if (c == 1) cCol = col_y;
            else if (c == 2) cCol = col_z;
            else cCol = col_const;
            
            if (fabs(val) < 1e-6) cCol = col_success;
            if (r == pivR && c == pivC) cCol = col_pivot;
            
            drawTextAlpha(ctx, valStr, CGPointMake(cx, cy), @"HelveticaNeue-Bold", 32, cCol, NSTextAlignmentCenter, rowAlpha);
        }
        CGContextRestoreGState(ctx);
    }
    
    // Clean Echelon Staircase positioned strictly in gaps (never touches digits or divider!)
    if (staircaseProgress > 0.01) {
        CGColorRef sCol = colorWithAlpha(col_success, alpha);
        CGContextSaveGState(ctx);
        CGContextSetStrokeColorWithColor(ctx, sCol);
        CGContextSetLineWidth(ctx, 3.5);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        CGContextSetLineJoin(ctx, kCGLineJoinRound);
        
        CGFloat gapY1 = startY - 14;             // Gap between R1 and R2
        CGFloat gapY2 = startY - cellH - 14;     // Gap between R2 and R3
        CGFloat gapY3 = startY - 2*cellH - 14;   // Below R3
        CGFloat endX  = divX - 10;               // Cleanly 10px left of divider line
        
        CGPoint pts[6] = {
            CGPointMake(startX + 4, gapY1),
            CGPointMake(startX + cellW, gapY1),
            CGPointMake(startX + cellW, gapY2),
            CGPointMake(startX + 2 * cellW, gapY2),
            CGPointMake(startX + 2 * cellW, gapY3),
            CGPointMake(endX, gapY3)
        };
        
        double totalSegs = 5.0;
        double drawSegs = staircaseProgress * totalSegs;
        CGContextMoveToPoint(ctx, pts[0].x, pts[0].y);
        for (int i = 0; i < 5; i++) {
            if (drawSegs >= i + 1) {
                CGContextAddLineToPoint(ctx, pts[i+1].x, pts[i+1].y);
            } else if (drawSegs > i) {
                double f = drawSegs - i;
                CGContextAddLineToPoint(ctx, lerp(pts[i].x, pts[i+1].x, f), lerp(pts[i].y, pts[i+1].y, f));
            }
        }
        CGContextStrokePath(ctx);
        CGContextRestoreGState(ctx);
        CGColorRelease(sCol);
    }
}

// 3D Intersecting Planes with safe clipping bounds, subtle grid mesh, and clean callout badge
void draw3DPlanesScene(
    CGContextRef ctx,
    CGPoint center,
    CGFloat scale,
    CGRect clipBounds,
    double t,
    double planesReveal,
    double morphOrthogonal,
    double dropLinesProgress,
    BOOL showPointBadge,
    double alpha
) {
    if (alpha <= 0.01) return;
    CGContextSaveGState(ctx);
    if (!CGRectIsEmpty(clipBounds)) {
        CGContextClipToRect(ctx, clipBounds);
    }
    
    CGFloat theta = t * 0.36 - 0.58;
    CGFloat phi = 0.50;
    
    auto project = [center, scale, theta, phi](double x, double y, double z) -> CGPoint {
        double cx = x - 1.0;
        double cy = y - 2.0;
        double cz = z - 3.0;
        double rx = cx * cos(theta) - cy * sin(theta);
        double ry = cx * sin(theta) + cy * cos(theta);
        double py = ry * sin(phi) + cz * cos(phi);
        return CGPointMake(center.x + rx * scale, center.y + py * scale);
    };
    
    // Draw 3D Axes
    CGPoint origin = project(0, 0, 0);
    CGPoint axX = project(3.8, 0, 0);
    CGPoint axY = project(0, 3.8, 0);
    CGPoint axZ = project(0, 0, 4.2);
    
    CGColorRef axXCol = colorWithAlpha(col_x, alpha * 0.9);
    CGColorRef axYCol = colorWithAlpha(col_y, alpha * 0.9);
    CGColorRef axZCol = colorWithAlpha(col_z, alpha * 0.9);
    drawArrow(ctx, origin, axX, axXCol, 2.5);
    drawArrow(ctx, origin, axY, axYCol, 2.5);
    drawArrow(ctx, origin, axZ, axZCol, 2.5);
    CGColorRelease(axXCol); CGColorRelease(axYCol); CGColorRelease(axZCol);
    
    drawTextAlpha(ctx, @"x", CGPointMake(axX.x + 12, axX.y - 6), @"HelveticaNeue-Bold", 20, col_x, NSTextAlignmentLeft, alpha);
    drawTextAlpha(ctx, @"y", CGPointMake(axY.x + 12, axY.y - 6), @"HelveticaNeue-Bold", 20, col_y, NSTextAlignmentLeft, alpha);
    drawTextAlpha(ctx, @"z", CGPointMake(axZ.x, axZ.y + 12), @"HelveticaNeue-Bold", 20, col_z, NSTextAlignmentCenter, alpha);
    
    auto lerp3 = [](CGPoint3D a, CGPoint3D b, double u) -> CGPoint3D {
        return (CGPoint3D){lerp(a.x, b.x, u), lerp(a.y, b.y, u), lerp(a.z, b.z, u)};
    };
    
    auto drawQuadWithGrid = [ctx, project, lerp3, alpha](CGPoint3D a, CGPoint3D b, CGPoint3D c, CGPoint3D d, CGColorRef fillCol, CGColorRef strokeCol, double pAlpha) {
        if (pAlpha <= 0.01) return;
        CGPoint qa = project(a.x, a.y, a.z);
        CGPoint qb = project(b.x, b.y, b.z);
        CGPoint qc = project(c.x, c.y, c.z);
        CGPoint qd = project(d.x, d.y, d.z);
        
        CGColorRef f = colorWithAlpha(fillCol, pAlpha * alpha * 0.24);
        CGColorRef g = colorWithAlpha(strokeCol, pAlpha * alpha * 0.22);
        CGColorRef s = colorWithAlpha(strokeCol, pAlpha * alpha * 0.85);
        
        CGContextSaveGState(ctx);
        CGContextSetFillColorWithColor(ctx, f);
        CGContextMoveToPoint(ctx, qa.x, qa.y);
        CGContextAddLineToPoint(ctx, qb.x, qb.y);
        CGContextAddLineToPoint(ctx, qc.x, qc.y);
        CGContextAddLineToPoint(ctx, qd.x, qd.y);
        CGContextClosePath(ctx);
        CGContextFillPath(ctx);
        
        // Internal grid lines (3 divisions)
        CGContextSetStrokeColorWithColor(ctx, g);
        CGContextSetLineWidth(ctx, 1.0);
        for (int k = 1; k <= 3; k++) {
            double u = k / 4.0;
            CGPoint p1 = project(lerp(a.x, b.x, u), lerp(a.y, b.y, u), lerp(a.z, b.z, u));
            CGPoint p2 = project(lerp(d.x, c.x, u), lerp(d.y, c.y, u), lerp(d.z, c.z, u));
            CGContextMoveToPoint(ctx, p1.x, p1.y);
            CGContextAddLineToPoint(ctx, p2.x, p2.y);
            
            CGPoint p3 = project(lerp(a.x, d.x, u), lerp(a.y, d.y, u), lerp(a.z, d.z, u));
            CGPoint p4 = project(lerp(b.x, c.x, u), lerp(b.y, c.y, u), lerp(b.z, c.z, u));
            CGContextMoveToPoint(ctx, p3.x, p3.y);
            CGContextAddLineToPoint(ctx, p4.x, p4.y);
        }
        CGContextStrokePath(ctx);
        
        // Outer perimeter
        CGContextSetStrokeColorWithColor(ctx, s);
        CGContextSetLineWidth(ctx, 2.0);
        CGContextMoveToPoint(ctx, qa.x, qa.y);
        CGContextAddLineToPoint(ctx, qb.x, qb.y);
        CGContextAddLineToPoint(ctx, qc.x, qc.y);
        CGContextAddLineToPoint(ctx, qd.x, qd.y);
        CGContextClosePath(ctx);
        CGContextStrokePath(ctx);
        CGContextRestoreGState(ctx);
        
        CGColorRelease(f);
        CGColorRelease(g);
        CGColorRelease(s);
    };
    
    double p1Vis = clamp01(planesReveal * 3.0);
    double p2Vis = clamp01((planesReveal - 0.33) * 3.0);
    double p3Vis = clamp01((planesReveal - 0.66) * 3.0);
    
    // Plane 1: x + y + z = 6  --> morphs to x = 1 (tight bounds so it never clips top/bottom bars)
    drawQuadWithGrid(
        lerp3({-0.2,  0.2, 6.0}, {1.0, 0.2, 1.2}, morphOrthogonal),
        lerp3({ 2.8,  0.2, 3.0}, {1.0, 3.2, 1.2}, morphOrthogonal),
        lerp3({ 2.8,  3.2, 0.0}, {1.0, 3.2, 4.2}, morphOrthogonal),
        lerp3({-0.2,  3.2, 3.0}, {1.0, 0.2, 4.2}, morphOrthogonal),
        col_x, col_x, p1Vis
    );
    
    // Plane 2: 2x - y + z = 3 --> morphs to y = 2
    drawQuadWithGrid(
        lerp3({-0.2,  0.2, 3.6}, {0.0, 2.0, 1.2}, morphOrthogonal),
        lerp3({ 2.6,  0.2,-2.0}, {2.8, 2.0, 1.2}, morphOrthogonal),
        lerp3({ 2.6,  3.2, 1.0}, {2.8, 2.0, 4.2}, morphOrthogonal),
        lerp3({-0.2,  3.2, 6.6}, {0.0, 2.0, 4.2}, morphOrthogonal),
        col_y, col_y, p2Vis
    );
    
    // Plane 3: x + 2y - z = 2 --> morphs to z = 3
    drawQuadWithGrid(
        lerp3({-0.2,  0.2,-1.8}, {0.0, 0.2, 3.0}, morphOrthogonal),
        lerp3({ 2.6,  0.2, 1.0}, {2.8, 0.2, 3.0}, morphOrthogonal),
        lerp3({ 2.6,  3.2, 7.0}, {2.8, 3.2, 3.0}, morphOrthogonal),
        lerp3({-0.2,  3.2, 4.2}, {0.0, 3.2, 3.0}, morphOrthogonal),
        col_pivot, col_pivot, p3Vis
    );
    
    // Coordinate projection drop lines from (1, 2, 3) to axes
    if (dropLinesProgress > 0.01) {
        CGPoint pSol = project(1.0, 2.0, 3.0);
        CGPoint px = project(1.0, 0.0, 0.0);
        CGPoint py = project(0.0, 2.0, 0.0);
        CGPoint pz = project(0.0, 0.0, 3.0);
        
        CGColorRef lx = colorWithAlpha(col_x, alpha);
        CGColorRef ly = colorWithAlpha(col_y, alpha);
        CGColorRef lz = colorWithAlpha(col_z, alpha);
        drawLine(ctx, pSol, CGPointMake(lerp(pSol.x, px.x, dropLinesProgress), lerp(pSol.y, px.y, dropLinesProgress)), lx, 2.2, YES);
        drawLine(ctx, pSol, CGPointMake(lerp(pSol.x, py.x, dropLinesProgress), lerp(pSol.y, py.y, dropLinesProgress)), ly, 2.2, YES);
        drawLine(ctx, pSol, CGPointMake(lerp(pSol.x, pz.x, dropLinesProgress), lerp(pSol.y, pz.y, dropLinesProgress)), lz, 2.2, YES);
        CGColorRelease(lx); CGColorRelease(ly); CGColorRelease(lz);
        
        if (dropLinesProgress > 0.8) {
            double la = clamp01((dropLinesProgress - 0.8) / 0.2) * alpha;
            auto drawChip = [&](NSString *lbl, CGPoint p, CGColorRef col) {
                CGRect r = CGRectMake(p.x - 28, p.y - 13, 56, 26);
                CGColorRef bf = RGBA(18, 20, 34, 0.90 * la);
                CGColorRef bs = colorWithAlpha(col, la);
                drawRoundedRect(ctx, r, 6, bf, bs, 1.2);
                CGColorRelease(bf); CGColorRelease(bs);
                drawTextAlpha(ctx, lbl, CGPointMake(p.x, p.y - 6), @"Menlo-Bold", 15, col, NSTextAlignmentCenter, la);
            };
            drawChip(@"x=1", CGPointMake(px.x, px.y - 18), col_x);
            drawChip(@"y=2", CGPointMake(py.x + 34, py.y - 4), col_y);
            drawChip(@"z=3", CGPointMake(pz.x - 36, pz.y + 4), col_z);
        }
    }
    
    // Intersection Point (1, 2, 3)
    if (planesReveal > 0.85) {
        double ptAlpha = clamp01((planesReveal - 0.85) / 0.15) * alpha;
        CGPoint solPt = project(1.0, 2.0, 3.0);
        CGFloat pulse = 9.0 + 2.5 * sin(t * 5.0);
        
        CGColorRef aura = RGBA(255, 214, 0, 0.32 * ptAlpha);
        CGColorRef core = colorWithAlpha(col_z, ptAlpha);
        CGContextSaveGState(ctx);
        CGContextSetFillColorWithColor(ctx, aura);
        CGContextFillEllipseInRect(ctx, CGRectMake(solPt.x - pulse*2.1, solPt.y - pulse*2.1, pulse*4.2, pulse*4.2));
        CGContextSetFillColorWithColor(ctx, core);
        CGContextFillEllipseInRect(ctx, CGRectMake(solPt.x - pulse, solPt.y - pulse, pulse*2, pulse*2));
        CGContextRestoreGState(ctx);
        CGColorRelease(aura);
        CGColorRelease(core);
        
        if (showPointBadge) {
            // Position badge cleanly at top-right of the 3D region with a subtle leader line (zero overlap with z-axis!)
            CGFloat bx = !CGRectIsEmpty(clipBounds) ? (CGRectGetMaxX(clipBounds) - 245) : (center.x + 120);
            CGFloat by = !CGRectIsEmpty(clipBounds) ? (CGRectGetMaxY(clipBounds) - 72) : (center.y + 195);
            CGRect ptBadge = CGRectMake(bx, by, 232, 54);
            CGColorRef lc = colorWithAlpha(col_gold, ptAlpha * 0.85);
            drawLine(ctx, solPt, CGPointMake(bx, by + 18), lc, 1.5, YES);
            CGColorRelease(lc);
            drawRoundedRect(ctx, ptBadge, 8, colorWithAlpha(col_panel, ptAlpha), colorWithAlpha(col_z, ptAlpha), 1.8);
            drawTextAlpha(ctx, @"Intersection Point", CGPointMake(bx + 14, by + 32), @"HelveticaNeue-Bold", 13, col_text, NSTextAlignmentLeft, ptAlpha);
            drawTextAlpha(ctx, @"(x = 1, y = 2, z = 3)", CGPointMake(bx + 14, by + 11), @"Menlo-Bold", 15, col_gold, NSTextAlignmentLeft, ptAlpha);
        }
    }
    CGContextRestoreGState(ctx);
}

// Synchronized Non-Overlapping Subtitle Pill
void drawSubtitlePill(CGContextRef ctx, NSString *text) {
    if (!text || text.length == 0) return;
    CGFloat boxW = 1680;
    CGFloat boxH = 56;
    CGRect rect = CGRectMake((1920 - boxW)/2.0, 26, boxW, boxH);
    CGColorRef fill = RGBA(14, 16, 28, 0.92);
    CGColorRef stroke = RGBA(255, 255, 255, 0.22);
    drawRoundedRect(ctx, rect, 12, fill, stroke, 1.2);
    CGColorRelease(fill);
    CGColorRelease(stroke);
    drawText(ctx, text, CGPointMake(960, rect.origin.y + 18), @"HelveticaNeue-Medium", 21, col_text, NSTextAlignmentCenter);
}

// Main Frame Renderer synced strictly to Master Audio Timeline (0.0s -> 333.204s)
void renderFrameAtTime(CGContextRef ctx, double t) {
    // 1. Canvas & Subtle Background Grid
    CGContextSetFillColorWithColor(ctx, col_bg);
    CGContextFillRect(ctx, CGRectMake(0, 0, 1920, 1080));
    drawSubtleGrid(ctx, 1.0);
    
    // Persistent Top Header Bar (active during body scenes 12.8s - 326.8s)
    if (t >= 12.8 && t < 326.8) {
        CGRect topBar = CGRectMake(0, 1020, 1920, 60);
        CGColorRef topFill = RGBA(18, 20, 34, 0.94);
        drawRoundedRect(ctx, topBar, 0, topFill, NULL, 0);
        CGColorRelease(topFill);
        drawText(ctx, @"M3 MATHEMATICS ANIMATION PROJECT  •  GAUSSIAN ELIMINATION", CGPointMake(60, 1042), @"HelveticaNeue-Bold", 16, col_x, NSTextAlignmentLeft);
        drawText(ctx, @"Meka Vikas  |  URN: E25B070539", CGPointMake(1860, 1042), @"HelveticaNeue-Bold", 16, col_muted, NSTextAlignmentRight);
        drawLine(ctx, CGPointMake(0, 1020), CGPointMake(1920, 1020), col_x, 2.0, NO);
    }
    
    NSString *sub = @"";
    
    // =========================================================================
    // OPENING SEQUENCE (0.0s - 12.8s)
    // =========================================================================
    if (t < 12.8) {
        if (t < 2.8) sub = @"Hello everyone, my name is Meka Vikas.";
        else if (t < 7.0) sub = @"In this internal assessment video for Linear Algebra and Calculus,";
        else sub = @"we will explore how Gaussian elimination solves a 3 by 3 system of linear equations.";
        
        double fade = smoothstep(t, 0.0, 0.9) * (1.0 - smoothstep(t, 12.0, 12.8));
        
        CGRect card = CGRectMake(250, 230, 1420, 610);
        drawRoundedRect(ctx, card, 24, colorWithAlpha(col_panel, fade), colorWithAlpha(col_x, fade), 3.0);
        
        drawTextAlpha(ctx, @"LINEAR ALGEBRA AND CALCULUS (M3)  •  INTERNAL ASSESSMENT", CGPointMake(960, 770), @"HelveticaNeue-Bold", 21, col_x, NSTextAlignmentCenter, fade);
        drawTextAlpha(ctx, @"GAUSSIAN ELIMINATION", CGPointMake(960, 685), @"HelveticaNeue-Bold", 58, col_text, NSTextAlignmentCenter, fade);
        drawTextAlpha(ctx, @"Solving a 3×3 System of Linear Equations Step by Step", CGPointMake(960, 615), @"HelveticaNeue-Medium", 28, col_gold, NSTextAlignmentCenter, fade);
        
        // Animated accent line reveal
        double lineP = smoothstep(t, 1.0, 2.5);
        CGColorRef ac = colorWithAlpha(col_x, fade * 0.7);
        drawLine(ctx, CGPointMake(960 - 380 * lineP, 575), CGPointMake(960 + 380 * lineP, 575), ac, 2.5, NO);
        CGColorRelease(ac);
        
        CGRect credBox = CGRectMake(400, 300, 1120, 220);
        CGColorRef cbFill = RGBA(20, 22, 36, 0.94 * fade);
        drawRoundedRect(ctx, credBox, 16, cbFill, colorWithAlpha(col_panel_border, fade), 1.5);
        CGColorRelease(cbFill);
        
        drawTextAlpha(ctx, @"Presented by: Meka Vikas", CGPointMake(960, 458), @"HelveticaNeue-Bold", 28, col_text, NSTextAlignmentCenter, fade);
        drawTextAlpha(ctx, @"URN: E25B070539", CGPointMake(960, 403), @"Menlo-Bold", 24, col_success, NSTextAlignmentCenter, fade);
        drawTextAlpha(ctx, @"GitHub: https://github.com/MEKAVIKAS", CGPointMake(960, 348), @"Menlo", 20, col_x, NSTextAlignmentCenter, fade);
    }
    // =========================================================================
    // SCENE 1B: HOOK / CONTEXT (12.8s - 47.9s)
    // =========================================================================
    else if (t < 47.9) {
        if (t < 20.0) sub = @"Imagine you're handed three linear equations with three unknown variables: x, y, and z.";
        else if (t < 26.5) sub = @"Geometrically, every linear equation in three variables forms a flat plane in 3D space.";
        else if (t < 34.2) sub = @"Finding a simultaneous solution means finding the exact coordinates where all three planes intersect at a single point.";
        else if (t < 39.2) sub = @"When the variables are completely tangled together, guessing is impossible.";
        else if (t < 44.3) sub = @"So how can we systematically untangle them without altering the answer?";
        else sub = @"That is precisely what Gaussian elimination does.";
        
        double sAlpha = smoothstep(t, 12.8, 13.6) * (1.0 - smoothstep(t, 47.1, 47.9));
        
        // Progressive Equation Card on Right (13.6s -> 19.5s)
        CGRect eqCard = CGRectMake(1100, 340, 740, 560);
        drawRoundedRect(ctx, eqCard, 18, colorWithAlpha(col_panel, sAlpha), colorWithAlpha(col_panel_border, sAlpha), 2.0);
        drawTextAlpha(ctx, @"3 × 3 System of Linear Equations", CGPointMake(1470, 845), @"HelveticaNeue-Bold", 26, col_text, NSTextAlignmentCenter, sAlpha);
        
        double eq1A = smoothstep(t, 13.7, 14.7) * sAlpha;
        double eq2A = smoothstep(t, 15.0, 16.0) * sAlpha;
        double eq3A = smoothstep(t, 16.3, 17.3) * sAlpha;
        
        drawTextAlpha(ctx, @"1x  +  1y  +  1z  =  6", CGPointMake(1220, 750), @"Menlo-Bold", 32, col_x, NSTextAlignmentLeft, eq1A);
        drawTextAlpha(ctx, @"2x  −  1y  +  1z  =  3", CGPointMake(1220, 675), @"Menlo-Bold", 32, col_y, NSTextAlignmentLeft, eq2A);
        drawTextAlpha(ctx, @"1x  +  2y  −  1z  =  2", CGPointMake(1220, 600), @"Menlo-Bold", 32, col_pivot, NSTextAlignmentLeft, eq3A);
        
        // Unknown variables highlight at 18.0s - 20.5s ("x, y, and z")
        double varHighlight = smoothstep(t, 17.8, 18.4) * (1.0 - smoothstep(t, 20.2, 21.0));
        if (varHighlight > 0.01) {
            drawTextAlpha(ctx, @"Three Unknowns:   x ,   y ,   z", CGPointMake(1470, 525), @"HelveticaNeue-Bold", 22, col_gold, NSTextAlignmentCenter, varHighlight);
        }
        
        // Tangled variables graphic (34.4s - 44.0s)
        double tangleA = smoothstep(t, 34.4, 35.3) * (1.0 - smoothstep(t, 43.4, 44.2)) * sAlpha;
        if (tangleA > 0.01) {
            CGRect tBox = CGRectMake(1140, 385, 660, 125);
            drawRoundedRect(ctx, tBox, 12, RGBA(255, 82, 82, 0.16 * tangleA), colorWithAlpha(col_pivot, tangleA), 1.8);
            drawTextAlpha(ctx, @"Variables x, y, z are coupled in every equation!", CGPointMake(1470, 462), @"HelveticaNeue-Bold", 21, col_pivot, NSTextAlignmentCenter, tangleA);
            drawTextAlpha(ctx, @"How do we untangle them without altering the answer?", CGPointMake(1470, 415), @"HelveticaNeue", 18, col_text, NSTextAlignmentCenter, tangleA);
        }
        
        // Gaussian Elimination reveal (44.3s - 47.9s)
        double geA = smoothstep(t, 44.3, 45.2) * sAlpha;
        if (geA > 0.01) {
            CGRect gBox = CGRectMake(1140, 385, 660, 125);
            drawRoundedRect(ctx, gBox, 12, RGBA(0, 212, 255, 0.20 * geA), colorWithAlpha(col_x, geA), 2.5);
            drawTextAlpha(ctx, @"Systematic Solution Method:", CGPointMake(1470, 464), @"HelveticaNeue", 18, col_muted, NSTextAlignmentCenter, geA);
            drawTextAlpha(ctx, @"GAUSSIAN ELIMINATION", CGPointMake(1470, 415), @"HelveticaNeue-Bold", 32, col_x, NSTextAlignmentCenter, geA);
        }
        
        // 3D Intersecting Planes on Left inside safe bounded viewport (never touches top bar or subtitles!)
        double planesReveal = smoothstep(t, 20.2, 30.8);
        double axesA = smoothstep(t, 20.0, 21.2) * sAlpha;
        if (axesA > 0.01) {
            CGRect geoPanel = CGRectMake(70, 130, 960, 840);
            drawRoundedRect(ctx, geoPanel, 18, colorWithAlpha(col_panel, axesA * 0.45), colorWithAlpha(col_panel_border, axesA * 0.6), 1.5);
            drawTextAlpha(ctx, @"Geometric View: 3 Planes in ℝ^{3}", CGPointMake(550, 930), @"HelveticaNeue-Bold", 22, col_text, NSTextAlignmentCenter, axesA);
            CGRect clip3D = CGRectMake(85, 145, 930, 770);
            draw3DPlanesScene(ctx, CGPointMake(540, 520), 92.0, clip3D, t - 20.0, planesReveal, 0.0, 0.0, YES, axesA);
        }
    }
    // =========================================================================
    // SCENE 2: CONCEPT INTRODUCTION (47.9s - 91.6s)
    // =========================================================================
    else if (t < 91.6) {
        if (t < 52.0) sub = @"Before we crunch numbers, let's define our tools.";
        else if (t < 59.3) sub = @"A system of linear equations can be stripped of its variable letters and stored as an augmented matrix.";
        else if (t < 67.4) sub = @"The left side holds the coefficients of x, y, z, separated by a line from the constants on the right.";
        else if (t < 73.8) sub = @"Our goal is to reach row echelon form: an upper triangular pattern with zeros below the diagonal.";
        else if (t < 83.8) sub = @"We use three elementary row operations: swapping rows, scaling a row by a non-zero constant, or adding a multiple of one row to another.";
        else sub = @"The leading non-zero number in each row is called a pivot.";
        
        double sAlpha = smoothstep(t, 47.9, 48.7) * (1.0 - smoothstep(t, 90.6, 91.6));
        drawTextAlpha(ctx, @"Concept Introduction: From Equations to Augmented Matrix", CGPointMake(960, 955), @"HelveticaNeue-Bold", 32, col_text, NSTextAlignmentCenter, sAlpha);
        
        // 48.6s - 54.5s: Equations visible, morphing into Augmented Matrix at 54.5s - 58.5s!
        double morph = smoothstep(t, 54.5, 58.2);
        double eqAlpha = (1.0 - morph) * sAlpha;
        double matAlpha = morph * sAlpha;
        
        CGPoint matCenter = CGPointMake(960, 720);
        if (t > 67.8) {
            double shift = smoothstep(t, 67.8, 69.2);
            matCenter.x = lerp(960, 620, shift);
        }
        
        if (eqAlpha > 0.01) {
            drawTextAlpha(ctx, @"1x  +  1y  +  1z  =  6", CGPointMake(960, 780), @"Menlo-Bold", 34, col_x, NSTextAlignmentCenter, eqAlpha);
            drawTextAlpha(ctx, @"2x  −  1y  +  1z  =  3", CGPointMake(960, 710), @"Menlo-Bold", 34, col_y, NSTextAlignmentCenter, eqAlpha);
            drawTextAlpha(ctx, @"1x  +  2y  −  1z  =  2", CGPointMake(960, 640), @"Menlo-Bold", 34, col_pivot, NSTextAlignmentCenter, eqAlpha);
        }
        
        if (matAlpha > 0.01) {
            double m0[3][4] = {{1, 1, 1, 6}, {2, -1, 1, 3}, {1, 2, -1, 2}};
            CGPoint zOff[3] = {{0,0}, {0,0}, {0,0}};
            double divP = smoothstep(t, 63.0, 64.8);
            int pivR = (t >= 84.2) ? 0 : -1;
            int pivC = (t >= 84.2) ? 0 : -1;
            drawAnimatedMatrix(ctx, m0, matCenter, 105, 58, zOff, pivR, pivC, -1, -1, -1, -1, divP, 0.0, YES, matAlpha);
            
            // Coefficient A vs Constants b callout (59.8s - 67.4s)
            double abLeft  = smoothstep(t, 59.8, 60.8) * (1.0 - smoothstep(t, 67.0, 67.8));
            double abRight = smoothstep(t, 64.8, 65.8) * (1.0 - smoothstep(t, 67.0, 67.8));
            if (abLeft > 0.01) {
                drawTextAlpha(ctx, @"Coefficient Matrix A", CGPointMake(matCenter.x - 65, 558), @"HelveticaNeue-Bold", 19, col_x, NSTextAlignmentCenter, abLeft);
            }
            if (abRight > 0.01) {
                drawTextAlpha(ctx, @"Constants b", CGPointMake(matCenter.x + 170, 558), @"HelveticaNeue-Bold", 19, col_gold, NSTextAlignmentCenter, abRight);
            }
        }
        
        // 68.0s+: Upper Triangular Row Echelon Form Goal schematic on right with proper subscripts!
        double refGoalA = smoothstep(t, 68.0, 69.5) * sAlpha;
        if (refGoalA > 0.01) {
            CGRect gCard = CGRectMake(1060, 560, 680, 300);
            drawRoundedRect(ctx, gCard, 16, colorWithAlpha(col_panel, refGoalA), colorWithAlpha(col_success, refGoalA), 2.0);
            drawTextAlpha(ctx, @"Goal: Row Echelon Form (REF)", CGPointMake(1400, 818), @"HelveticaNeue-Bold", 22, col_success, NSTextAlignmentCenter, refGoalA);
            
            // Draw crisp REF matrix pattern with proper P_{1}, P_{2}, P_{3}
            drawTextAlpha(ctx, @"[   P_{1}     *      *    |    *   ]", CGPointMake(1400, 745), @"Menlo-Bold", 26, col_text, NSTextAlignmentCenter, refGoalA);
            drawTextAlpha(ctx, @"[    0     P_{2}     *    |    *   ]", CGPointMake(1400, 685), @"Menlo-Bold", 26, col_text, NSTextAlignmentCenter, refGoalA);
            drawTextAlpha(ctx, @"[    0      0     P_{3}   |    *   ]", CGPointMake(1400, 625), @"Menlo-Bold", 26, col_text, NSTextAlignmentCenter, refGoalA);
            drawTextAlpha(ctx, @"Upper-triangular pattern with zeros below pivots!", CGPointMake(1400, 578), @"HelveticaNeue-Bold", 16, col_gold, NSTextAlignmentCenter, refGoalA);
        }
        
        // Pivot Callout (84.2s - 91.6s)
        double pivCallA = smoothstep(t, 84.2, 85.2) * sAlpha;
        if (pivCallA > 0.01) {
            CGRect pBox = CGRectMake(45, 700, 265, 92);
            drawRoundedRect(ctx, pBox, 12, RGBA(255, 82, 82, 0.20 * pivCallA), colorWithAlpha(col_pivot, pivCallA), 2.0);
            drawTextAlpha(ctx, @"PIVOT = 1", CGPointMake(177, 754), @"HelveticaNeue-Bold", 22, col_pivot, NSTextAlignmentCenter, pivCallA);
            drawTextAlpha(ctx, @"Leading non-zero entry", CGPointMake(177, 718), @"HelveticaNeue", 15, col_text, NSTextAlignmentCenter, pivCallA);
            CGColorRef ac = colorWithAlpha(col_pivot, pivCallA);
            drawArrow(ctx, CGPointMake(310, 746), CGPointMake(406, 766), ac, 2.5);
            CGColorRelease(ac);
        }
        
        // Three Elementary Row Operations Cards appearing on exact spoken cues (76.8s, 78.3s, 80.6s)
        double c1A = smoothstep(t, 76.8, 77.6) * sAlpha;
        double c2A = smoothstep(t, 78.3, 79.2) * sAlpha;
        double c3A = smoothstep(t, 80.6, 81.5) * sAlpha;
        
        CGFloat cW = 460, cH = 185, bY = 225;
        if (c1A > 0.01) {
            drawRoundedRect(ctx, CGRectMake(180, bY, cW, cH), 14, colorWithAlpha(col_panel, c1A), colorWithAlpha(col_x, c1A), 2.0);
            drawTextAlpha(ctx, @"1. Row Swap", CGPointMake(180 + cW/2, bY + 138), @"HelveticaNeue-Bold", 22, col_x, NSTextAlignmentCenter, c1A);
            drawTextAlpha(ctx, @"R_{i}  ↔  R_{j}", CGPointMake(180 + cW/2, bY + 82), @"HelveticaNeue-Bold", 29, col_text, NSTextAlignmentCenter, c1A);
            drawTextAlpha(ctx, @"Interchanges two rows", CGPointMake(180 + cW/2, bY + 32), @"HelveticaNeue", 16, col_muted, NSTextAlignmentCenter, c1A);
        }
        if (c2A > 0.01) {
            drawRoundedRect(ctx, CGRectMake(730, bY, cW, cH), 14, colorWithAlpha(col_panel, c2A), colorWithAlpha(col_y, c2A), 2.0);
            drawTextAlpha(ctx, @"2. Row Scaling", CGPointMake(730 + cW/2, bY + 138), @"HelveticaNeue-Bold", 22, col_y, NSTextAlignmentCenter, c2A);
            drawTextAlpha(ctx, @"R_{i}  →  c ⋅ R_{i}   (c ≠ 0)", CGPointMake(730 + cW/2, bY + 82), @"HelveticaNeue-Bold", 26, col_text, NSTextAlignmentCenter, c2A);
            drawTextAlpha(ctx, @"Multiplies row by non-zero constant", CGPointMake(730 + cW/2, bY + 32), @"HelveticaNeue", 16, col_muted, NSTextAlignmentCenter, c2A);
        }
        if (c3A > 0.01) {
            drawRoundedRect(ctx, CGRectMake(1280, bY, cW, cH), 14, colorWithAlpha(col_panel, c3A), colorWithAlpha(col_pivot, c3A), 2.0);
            drawTextAlpha(ctx, @"3. Row Replacement", CGPointMake(1280 + cW/2, bY + 138), @"HelveticaNeue-Bold", 22, col_pivot, NSTextAlignmentCenter, c3A);
            drawTextAlpha(ctx, @"R_{i}  →  R_{i} + k ⋅ R_{j}", CGPointMake(1280 + cW/2, bY + 82), @"HelveticaNeue-Bold", 27, col_text, NSTextAlignmentCenter, c3A);
            drawTextAlpha(ctx, @"Adds a multiple of one row to another", CGPointMake(1280 + cW/2, bY + 32), @"HelveticaNeue", 16, col_muted, NSTextAlignmentCenter, c3A);
        }
    }
    // =========================================================================
    // SCENE 3: VISUAL INTUITION & INVARIANCE (91.6s - 131.3s)
    // =========================================================================
    else if (t < 131.3) {
        if (t < 95.2) sub = @"Why are row operations mathematically legal?";
        else if (t < 97.6) sub = @"Each row is simply an equation.";
        else if (t < 105.2) sub = @"If two statements are true, adding a multiple of one true statement to another creates a new, equally true statement.";
        else if (t < 113.3) sub = @"Because each elementary operation can be reversed by an inverse operation, the solution set is strictly preserved.";
        else if (t < 125.2) sub = @"Geometrically, row operations replace our original planes with new, simpler planes that still intersect at the exact same point.";
        else sub = @"By systematically creating zeros beneath our pivots, we untangle the variables, leaving the bottom equation with only one unknown.";
        
        double sAlpha = smoothstep(t, 91.6, 92.4) * (1.0 - smoothstep(t, 130.3, 131.3));
        drawTextAlpha(ctx, @"Visual Intuition: Why Row Operations Preserve the Solution", CGPointMake(960, 955), @"HelveticaNeue-Bold", 32, col_text, NSTextAlignmentCenter, sAlpha);
        
        // Left Panel: Algebraic Invariance (95.5s - 113s, stays visible)
        CGRect lCard = CGRectMake(110, 240, 820, 640);
        drawRoundedRect(ctx, lCard, 18, colorWithAlpha(col_panel, sAlpha), colorWithAlpha(col_x, sAlpha), 2.0);
        drawTextAlpha(ctx, @"Algebraic Equivalence & Invertibility", CGPointMake(520, 830), @"HelveticaNeue-Bold", 24, col_x, NSTextAlignmentCenter, sAlpha);
        
        double stA = smoothstep(t, 95.3, 96.8) * sAlpha;
        drawTextAlpha(ctx, @"Equation 1:   LHS_{1}  =  RHS_{1}   (True)", CGPointMake(160, 750), @"Menlo-Bold", 21, col_success, NSTextAlignmentLeft, stA);
        drawTextAlpha(ctx, @"Equation 2:   LHS_{2}  =  RHS_{2}   (True)", CGPointMake(160, 695), @"Menlo-Bold", 21, col_success, NSTextAlignmentLeft, stA);
        
        double combA = smoothstep(t, 99.0, 100.8) * sAlpha;
        if (combA > 0.01) {
            CGRect cBox = CGRectMake(150, 515, 740, 130);
            drawRoundedRect(ctx, cBox, 12, RGBA(0, 230, 118, 0.14 * combA), colorWithAlpha(col_success, combA), 1.5);
            drawTextAlpha(ctx, @"Adding a Multiple Preserves Equality:", CGPointMake(180, 602), @"HelveticaNeue-Bold", 19, col_gold, NSTextAlignmentLeft, combA);
            drawTextAlpha(ctx, @"LHS_{2} + k(LHS_{1})  =  RHS_{2} + k(RHS_{1})", CGPointMake(180, 550), @"Menlo-Bold", 22, col_text, NSTextAlignmentLeft, combA);
        }
        
        double invA = smoothstep(t, 105.4, 107.0) * sAlpha;
        if (invA > 0.01) {
            CGRect iBox = CGRectMake(150, 290, 740, 175);
            drawRoundedRect(ctx, iBox, 12, RGBA(0, 212, 255, 0.14 * invA), colorWithAlpha(col_x, invA), 1.5);
            drawTextAlpha(ctx, @"Reversible Elementary Transformations:", CGPointMake(180, 422), @"HelveticaNeue-Bold", 19, col_x, NSTextAlignmentLeft, invA);
            drawTextAlpha(ctx, @"Forward: R_{2} → R_{2} − 2R_{1}   ⇔   Inverse: R_{2} → R_{2} + 2R_{1}", CGPointMake(180, 372), @"HelveticaNeue-Bold", 19, col_text, NSTextAlignmentLeft, invA);
            double presA = smoothstep(t, 109.8, 111.0) * invA;
            drawTextAlpha(ctx, @"✓ Exact Solution Set Sol(Ax = b) is Strictly Preserved!", CGPointMake(180, 322), @"HelveticaNeue-Bold", 19, col_success, NSTextAlignmentLeft, presA);
        }
        
        // Right Panel: 113.5s - 125.2s Geometric Plane Tilt -> 125.2s - 131.3s Untangled Echelon Bottom Row
        if (t < 125.2) {
            double geoA = smoothstep(t, 113.2, 114.4) * (1.0 - smoothstep(t, 124.2, 125.2)) * sAlpha;
            if (geoA > 0.01) {
                CGRect rCard = CGRectMake(990, 240, 820, 640);
                drawRoundedRect(ctx, rCard, 18, colorWithAlpha(col_panel, geoA), colorWithAlpha(col_gold, geoA), 2.0);
                drawTextAlpha(ctx, @"Geometric Invariance in ℝ^{3}", CGPointMake(1400, 830), @"HelveticaNeue-Bold", 24, col_gold, NSTextAlignmentCenter, geoA);
                double morphGeo = smoothstep(t, 116.0, 122.8);
                CGRect clip3D = CGRectMake(1005, 255, 790, 550);
                draw3DPlanesScene(ctx, CGPointMake(1380, 515), 72.0, clip3D, t - 113.0, 1.0, morphGeo, 0.0, YES, geoA);
            }
        } else {
            double untA = smoothstep(t, 125.2, 126.2) * sAlpha;
            CGRect rCard = CGRectMake(990, 240, 820, 640);
            drawRoundedRect(ctx, rCard, 18, colorWithAlpha(col_panel, untA), colorWithAlpha(col_success, untA), 2.0);
            drawTextAlpha(ctx, @"Untangling Variables via Echelon Form", CGPointMake(1400, 830), @"HelveticaNeue-Bold", 24, col_success, NSTextAlignmentCenter, untA);
            
            double mRef[3][4] = {{1, 1, 1, 6}, {0, 1, -2, -4}, {0, 0, -7, -21}};
            CGPoint zOff[3] = {{0,0}, {0,0}, {0,0}};
            double stProg = smoothstep(t, 125.6, 128.5);
            drawAnimatedMatrix(ctx, mRef, CGPointMake(1400, 570), 100, 58, zOff, 2, 2, -1, -1, 2, -1, 1.0, stProg, YES, untA);
            
            drawTextAlpha(ctx, @"Bottom Equation Isolated:   −7z = −21   (1 Unknown!)", CGPointMake(1400, 325), @"Menlo-Bold", 20, col_gold, NSTextAlignmentCenter, untA);
        }
    }
    // =========================================================================
    // SCENE 4: WORKED EXAMPLE (131.3s - 265.3s)
    // =========================================================================
    else if (t < 265.3) {
        drawText(ctx, @"Worked Example: Gaussian Elimination & Back-Substitution", CGPointMake(960, 955), @"HelveticaNeue-Bold", 32, col_text, NSTextAlignmentCenter);
        
        CGPoint matCenter = CGPointMake(495, 580);
        CGRect wbRect = CGRectMake(970, 215, 850, 685);
        CGPoint zOff[3] = {{0,0}, {0,0}, {0,0}};
        
        // ---------------------------------------------------------------------
        // 4A: Op 1 (R2 -> R2 - 2R1) [131.3s - 161.4s]
        // ---------------------------------------------------------------------
        if (t < 161.4) {
            if (t < 139.4) sub = @"Let's work through our system step by step. Our first pivot is the 1 in the top left corner.";
            else if (t < 146.1) sub = @"To eliminate the 2 beneath it in row 2, we subtract 2 times row 1 from row 2.";
            else if (t < 157.9) sub = @"2 minus 2 is 0; −1 minus 2 is −3; 1 minus 2 is −1; and 3 minus 12 gives −9.";
            else sub = @"Our first zero is locked in.";
            
            // Exact waveform-aligned entry updates!
            double m[3][4] = {
                {1, 1, 1, 6},
                {(t >= 147.8 ? 0.0 : 2.0), (t >= 151.4 ? -3.0 : -1.0), (t >= 153.8 ? -1.0 : 1.0), (t >= 157.0 ? -9.0 : 3.0)},
                {1, 2, -1, 2}
            };
            int pivR = (t >= 135.5) ? 0 : -1;
            int pivC = (t >= 135.5) ? 0 : -1;
            int tgtR = (t >= 139.7 && t < 147.8) ? 1 : -1;
            int tgtC = (t >= 139.7 && t < 147.8) ? 0 : -1;
            int hiRow = (t >= 139.7) ? 1 : -1;
            drawAnimatedMatrix(ctx, m, matCenter, 110, 62, zOff, pivR, pivC, tgtR, tgtC, hiRow, -1, 1.0, 0.0, YES, 1.0);
            
            drawRoundedRect(ctx, wbRect, 18, col_panel, col_badge, 2.5);
            drawText(ctx, @"STEP 1: Eliminate x from Row 2", CGPointMake(1395, 845), @"HelveticaNeue-Bold", 26, col_text, NSTextAlignmentCenter);
            
            if (t >= 141.5) {
                CGRect bRect = CGRectMake(1125, 760, 540, 52);
                drawRoundedRect(ctx, bRect, 10, col_badge, NULL, 0);
                drawText(ctx, @"Operation:   R_{2}  →  R_{2}  −  2 ⋅ R_{1}", CGPointMake(1395, 777), @"Menlo-Bold", 23, col_text, NSTextAlignmentCenter);
            }
            
            if (t >= 144.2) {
                drawText(ctx, @"R_{2}:       [  2,  −1,   1  |   3 ]", CGPointMake(1055, 675), @"Menlo-Bold", 24, col_text, NSTextAlignmentLeft);
                drawText(ctx, @"− 2⋅R_{1}:   [ −2,  −2,  −2  | −12 ]", CGPointMake(1055, 605), @"Menlo-Bold", 24, col_x, NSTextAlignmentLeft);
                drawLine(ctx, CGPointMake(1045, 565), CGPointMake(1745, 565), col_panel_border, 2.0, NO);
            }
            
            if (t >= 147.5) drawText(ctx, @"New R_{2}:   [  0,", CGPointMake(1055, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
            if (t >= 151.0) drawText(ctx, @"−3,", CGPointMake(1335, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
            if (t >= 153.5) drawText(ctx, @"−1  |", CGPointMake(1435, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
            if (t >= 156.6) drawText(ctx, @"−9 ]", CGPointMake(1565, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
            
            if (t >= 158.2) {
                CGRect lockBox = CGRectMake(1055, 300, 680, 115);
                drawRoundedRect(ctx, lockBox, 12, RGBA(0, 230, 118, 0.16), col_success, 2.0);
                drawText(ctx, @"✓  First Zero Locked In at Position (2, 1)!", CGPointMake(1395, 372), @"HelveticaNeue-Bold", 21, col_success, NSTextAlignmentCenter);
                drawText(ctx, @"2 − 2 = 0   |   −1 − 2 = −3   |   1 − 2 = −1   |   3 − 12 = −9", CGPointMake(1395, 326), @"Menlo-Bold", 17, col_text, NSTextAlignmentCenter);
            }
        }
        // ---------------------------------------------------------------------
        // 4B: Op 2 (R3 -> R3 - R1) [161.4s - 182.3s]
        // ---------------------------------------------------------------------
        else if (t < 182.3) {
            if (t < 167.1) sub = @"Next, to eliminate the 1 in row 3, we subtract row 1 from row 3.";
            else if (t < 176.8) sub = @"1 minus 1 is 0; 2 minus 1 is 1; −1 minus 1 is −2; and 2 minus 6 gives us −4.";
            else sub = @"Column 1 now has zeros everywhere below the first pivot.";
            
            double m[3][4] = {
                {1, 1, 1, 6},
                {0, -3, -1, -9},
                {(t >= 168.5 ? 0.0 : 1.0), (t >= 170.3 ? 1.0 : 2.0), (t >= 173.2 ? -2.0 : -1.0), (t >= 175.8 ? -4.0 : 2.0)}
            };
            int tgtR = (t < 168.5) ? 2 : -1;
            int tgtC = (t < 168.5) ? 0 : -1;
            int hiCol = (t >= 177.2) ? 0 : -1;
            drawAnimatedMatrix(ctx, m, matCenter, 110, 62, zOff, 0, 0, tgtR, tgtC, 2, hiCol, 1.0, 0.0, YES, 1.0);
            
            drawRoundedRect(ctx, wbRect, 18, col_panel, col_badge, 2.5);
            drawText(ctx, @"STEP 2: Eliminate x from Row 3", CGPointMake(1395, 845), @"HelveticaNeue-Bold", 26, col_text, NSTextAlignmentCenter);
            
            CGRect bRect = CGRectMake(1125, 760, 540, 52);
            drawRoundedRect(ctx, bRect, 10, col_badge, NULL, 0);
            drawText(ctx, @"Operation:   R_{3}  →  R_{3}  −  R_{1}", CGPointMake(1395, 777), @"Menlo-Bold", 23, col_text, NSTextAlignmentCenter);
            
            drawText(ctx, @"R_{3}:       [  1,   2,  −1  |   2 ]", CGPointMake(1055, 675), @"Menlo-Bold", 24, col_text, NSTextAlignmentLeft);
            drawText(ctx, @"− 1⋅R_{1}:   [ −1,  −1,  −1  |  −6 ]", CGPointMake(1055, 605), @"Menlo-Bold", 24, col_x, NSTextAlignmentLeft);
            drawLine(ctx, CGPointMake(1045, 565), CGPointMake(1745, 565), col_panel_border, 2.0, NO);
            
            if (t >= 168.2) drawText(ctx, @"New R_{3}:   [  0,", CGPointMake(1055, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
            if (t >= 170.0) drawText(ctx, @" 1,", CGPointMake(1335, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
            if (t >= 172.8) drawText(ctx, @"−2  |", CGPointMake(1435, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
            if (t >= 175.4) drawText(ctx, @"−4 ]", CGPointMake(1565, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
            
            if (t >= 177.2) {
                CGRect lockBox = CGRectMake(1055, 300, 680, 115);
                drawRoundedRect(ctx, lockBox, 12, RGBA(0, 230, 118, 0.16), col_success, 2.0);
                drawText(ctx, @"✓  Column 1 Cleared: All entries below Pivot 1 are 0!", CGPointMake(1395, 372), @"HelveticaNeue-Bold", 20, col_success, NSTextAlignmentCenter);
                drawText(ctx, @"1 − 1 = 0   |   2 − 1 = 1   |   −1 − 1 = −2   |   2 − 6 = −4", CGPointMake(1395, 326), @"Menlo-Bold", 17, col_text, NSTextAlignmentCenter);
            }
        }
        // ---------------------------------------------------------------------
        // 4C: Animated Swap (R2 <-> R3) & Op 4 (R3 -> R3 + 3R2) [182.3s - 221.0s]
        // ---------------------------------------------------------------------
        else if (t < 221.0) {
            if (t < 188.8) sub = @"Now look at column 2. Row 2 has −3, but row 3 has a clean 1.";
            else if (t < 195.0) sub = @"Instead of dividing by −3 and creating awkward fractions, we swap row 2 and row 3.";
            else if (t < 198.4) sub = @"Now our second pivot is simply 1.";
            else if (t < 205.0) sub = @"To eliminate the −3 now sitting in row 3, we add 3 times row 2 to row 3.";
            else if (t < 216.5) sub = @"0 plus 0 is 0; −3 plus 3 is 0; −1 plus −6 is −7; and −9 plus −12 is −21.";
            else sub = @"Look at that: we have reached row echelon form!";
            
            // Smooth 3D card-flip Row Swap from 191.5s to 194.6s (zero collision at midpoint!)
            double swapProgress = smoothstep(t, 191.5, 194.6);
            CGPoint swapOff[3] = {{0,0}, {0,0}, {0,0}};
            if (t >= 191.5 && t < 194.6) {
                double dy = 62.0 * swapProgress;
                double arc = sin(swapProgress * M_PI);
                swapOff[1] = CGPointMake(28.0 * arc, -dy);   // Row 2 flips DOWN
                swapOff[2] = CGPointMake(-28.0 * arc, dy);   // Row 3 flips UP
            }
            
            double m[3][4];
            if (t < 194.6) {
                m[0][0]=1; m[0][1]=1;  m[0][2]=1;  m[0][3]=6;
                m[1][0]=0; m[1][1]=-3; m[1][2]=-1; m[1][3]=-9;
                m[2][0]=0; m[2][1]=1;  m[2][2]=-2; m[2][3]=-4;
            } else {
                m[0][0]=1; m[0][1]=1;  m[0][2]=1;  m[0][3]=6;
                m[1][0]=0; m[1][1]=1;  m[1][2]=-2; m[1][3]=-4;
                m[2][0]=0; m[2][1]=(t >= 208.9 ? 0.0 : -3.0);
                m[2][2]=(t >= 212.0 ? -7.0 : -1.0);
                m[2][3]=(t >= 215.3 ? -21.0 : -9.0);
            }
            
            int pivR = (t >= 194.6) ? 1 : -1;
            int pivC = (t >= 194.6) ? 1 : -1;
            if (t >= 217.2) { pivR = 2; pivC = 2; }
            int tgtR = (t >= 199.0 && t < 208.9) ? 2 : -1;
            int tgtC = (t >= 199.0 && t < 208.9) ? 1 : -1;
            if (t >= 185.3 && t < 187.2) { tgtR = 1; tgtC = 1; }
            if (t >= 187.2 && t < 191.5) { pivR = 2; pivC = 1; }
            int hiRow = (t >= 199.0) ? 2 : -1;
            int hiCol = (t >= 183.4 && t < 191.5) ? 1 : -1;
            double stairP = (t >= 217.0) ? smoothstep(t, 217.0, 219.4) : 0.0;
            
            drawAnimatedMatrix(ctx, m, matCenter, 110, 62, swapOff, pivR, pivC, tgtR, tgtC, hiRow, hiCol, 1.0, stairP, YES, 1.0);
            drawRoundedRect(ctx, wbRect, 18, col_panel, col_badge, 2.5);
            
            if (t < 198.8) {
                drawText(ctx, @"STEP 3: Strategic Row Interchange", CGPointMake(1395, 845), @"HelveticaNeue-Bold", 26, col_text, NSTextAlignmentCenter);
                
                CGRect bRect = CGRectMake(1125, 760, 540, 52);
                drawRoundedRect(ctx, bRect, 10, col_badge, NULL, 0);
                drawText(ctx, @"Operation:   Swap   R_{2}  ↔  R_{3}", CGPointMake(1395, 777), @"Menlo-Bold", 24, col_text, NSTextAlignmentCenter);
                
                CGRect whyBox = CGRectMake(1055, 470, 680, 230);
                drawRoundedRect(ctx, whyBox, 12, RGBA(255, 214, 0, 0.14), col_z, 1.5);
                drawText(ctx, @"Why Swap Row 2 and Row 3?", CGPointMake(1085, 652), @"HelveticaNeue-Bold", 22, col_gold, NSTextAlignmentLeft);
                drawText(ctx, @"•  Row 2 leads with −3 (dividing creates fractions).", CGPointMake(1085, 595), @"HelveticaNeue", 19, col_text, NSTextAlignmentLeft);
                drawText(ctx, @"•  Row 3 already has a clean leading 1!", CGPointMake(1085, 548), @"HelveticaNeue", 19, col_success, NSTextAlignmentLeft);
                drawText(ctx, @"•  Swapping places clean Pivot 2 = 1 at position (2, 2).", CGPointMake(1085, 501), @"HelveticaNeue-Bold", 19, col_x, NSTextAlignmentLeft);
            } else {
                drawText(ctx, @"STEP 4: Eliminate y from Row 3", CGPointMake(1395, 845), @"HelveticaNeue-Bold", 26, col_text, NSTextAlignmentCenter);
                
                CGRect bRect = CGRectMake(1125, 760, 540, 52);
                drawRoundedRect(ctx, bRect, 10, col_badge, NULL, 0);
                drawText(ctx, @"Operation:   R_{3}  →  R_{3}  +  3 ⋅ R_{2}", CGPointMake(1395, 777), @"Menlo-Bold", 23, col_text, NSTextAlignmentCenter);
                
                drawText(ctx, @"R_{3}:       [  0,  −3,  −1  |  −9 ]", CGPointMake(1055, 675), @"Menlo-Bold", 24, col_text, NSTextAlignmentLeft);
                drawText(ctx, @"+ 3⋅R_{2}:   [  0,   3,  −6  | −12 ]", CGPointMake(1055, 605), @"Menlo-Bold", 24, col_y, NSTextAlignmentLeft);
                drawLine(ctx, CGPointMake(1045, 565), CGPointMake(1745, 565), col_panel_border, 2.0, NO);
                
                if (t >= 206.0) drawText(ctx, @"New R_{3}:   [  0,", CGPointMake(1055, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
                if (t >= 208.5) drawText(ctx, @" 0,", CGPointMake(1335, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
                if (t >= 211.6) drawText(ctx, @"−7  |", CGPointMake(1435, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
                if (t >= 214.9) drawText(ctx, @"−21 ]", CGPointMake(1565, 505), @"Menlo-Bold", 26, col_success, NSTextAlignmentLeft);
                
                if (t >= 216.8) {
                    CGRect refBox = CGRectMake(1055, 300, 680, 115);
                    drawRoundedRect(ctx, refBox, 12, RGBA(105, 240, 174, 0.18), col_success, 2.0);
                    drawText(ctx, @"✓  ROW ECHELON FORM ACHIEVED!", CGPointMake(1395, 372), @"HelveticaNeue-Bold", 22, col_success, NSTextAlignmentCenter);
                    drawText(ctx, @"Diagonal Pivots: 1, 1, −7   •   Upper-Triangular Zeros Locked In", CGPointMake(1395, 326), @"HelveticaNeue", 18, col_text, NSTextAlignmentCenter);
                }
            }
        }
        // ---------------------------------------------------------------------
        // 4D: Back-Substitution Cascade [221.0s - 265.3s]
        // ---------------------------------------------------------------------
        else {
            if (t < 225.0) sub = @"Now comes the payoff: back-substitution.";
            else if (t < 231.7) sub = @"The bottom row tells us: −7z equals −21. Dividing by −7 gives z equals 3.";
            else if (t < 244.9) sub = @"We substitute z = 3 in the second row: y − 2(3) = −4, that is y − 6 = −4, which gives y = 2.";
            else if (t < 260.0) sub = @"Finally, plug y = 2 and z = 3 into the top row: x + 2 + 3 = 6, meaning x + 5 = 6, so x = 1.";
            else sub = @"Our solution is x = 1, y = 2, and z = 3.";
            
            int hiR = (t < 231.8) ? 2 : ((t < 245.2) ? 1 : ((t < 260.0) ? 0 : -1));
            double m[3][4] = {{1, 1, 1, 6}, {0, 1, -2, -4}, {0, 0, -7, -21}};
            drawAnimatedMatrix(ctx, m, matCenter, 110, 62, zOff, -1, -1, -1, -1, hiR, -1, 1.0, 1.0, YES, 1.0);
            
            drawRoundedRect(ctx, wbRect, 18, col_panel, col_success, 2.5);
            drawText(ctx, @"Back-Substitution Cascade", CGPointMake(1395, 845), @"HelveticaNeue-Bold", 28, col_success, NSTextAlignmentCenter);
            
            // z step (225.2s+)
            double zA = smoothstep(t, 225.2, 226.4);
            if (zA > 0.01) {
                CGRect zBox = CGRectMake(1035, 695, 720, 92);
                drawRoundedRect(ctx, zBox, 10, RGBA(255, 214, 0, 0.14 * zA), colorWithAlpha(col_z, zA), 1.5);
                drawTextAlpha(ctx, @"Row 3:   −7z  =  −21", CGPointMake(1065, 748), @"HelveticaNeue-Bold", 23, col_text, NSTextAlignmentLeft, zA);
                double zAns = smoothstep(t, 229.6, 231.0);
                drawTextAlpha(ctx, @"⇒   z = (−21) / (−7)   ⇒   z = 3", CGPointMake(1065, 710), @"HelveticaNeue-Bold", 23, col_z, NSTextAlignmentLeft, zAns * zA);
            }
            
            // y step (232.0s+)
            double yA = smoothstep(t, 232.0, 233.5);
            if (yA > 0.01) {
                CGRect yBox = CGRectMake(1035, 570, 720, 92);
                drawRoundedRect(ctx, yBox, 10, RGBA(0, 230, 118, 0.14 * yA), colorWithAlpha(col_y, yA), 1.5);
                drawTextAlpha(ctx, @"Row 2:   y  −  2(3)  =  −4", CGPointMake(1065, 623), @"HelveticaNeue-Bold", 23, col_text, NSTextAlignmentLeft, yA);
                double yMid = smoothstep(t, 239.2, 240.5);
                double yAns = smoothstep(t, 242.5, 243.8);
                drawTextAlpha(ctx, @"⇒   y − 6 = −4", CGPointMake(1065, 585), @"HelveticaNeue-Bold", 23, col_text, NSTextAlignmentLeft, yMid * yA);
                drawTextAlpha(ctx, @"⇒   y = 2", CGPointMake(1335, 585), @"HelveticaNeue-Bold", 23, col_y, NSTextAlignmentLeft, yAns * yA);
            }
            
            // x step (245.3s+)
            double xA = smoothstep(t, 245.3, 246.8);
            if (xA > 0.01) {
                CGRect xBox = CGRectMake(1035, 445, 720, 92);
                drawRoundedRect(ctx, xBox, 10, RGBA(0, 212, 255, 0.14 * xA), colorWithAlpha(col_x, xA), 1.5);
                drawTextAlpha(ctx, @"Row 1:   x  +  (2)  +  (3)  =  6", CGPointMake(1065, 498), @"HelveticaNeue-Bold", 23, col_text, NSTextAlignmentLeft, xA);
                double xMid = smoothstep(t, 253.5, 255.0);
                double xAns = smoothstep(t, 257.0, 258.5);
                drawTextAlpha(ctx, @"⇒   x + 5 = 6", CGPointMake(1065, 460), @"HelveticaNeue-Bold", 23, col_text, NSTextAlignmentLeft, xMid * xA);
                drawTextAlpha(ctx, @"⇒   x = 1", CGPointMake(1335, 460), @"HelveticaNeue-Bold", 23, col_x, NSTextAlignmentLeft, xAns * xA);
            }
            
            // Final Solution Box (260.0s+)
            double solA = smoothstep(t, 260.0, 261.3);
            if (solA > 0.01) {
                CGRect solBox = CGRectMake(1035, 275, 720, 120);
                drawRoundedRect(ctx, solBox, 14, RGBA(24, 24, 37, 0.96 * solA), colorWithAlpha(col_gold, solA), 3.0);
                drawTextAlpha(ctx, @"FINAL UNIQUE SOLUTION", CGPointMake(1395, 358), @"HelveticaNeue-Bold", 18, col_gold, NSTextAlignmentCenter, solA);
                drawTextAlpha(ctx, @"x = 1 ,     y = 2 ,     z = 3", CGPointMake(1395, 305), @"Menlo-Bold", 32, col_text, NSTextAlignmentCenter, solA);
            }
        }
    }
    // =========================================================================
    // SCENE 5: GEOMETRIC INTERPRETATION & DIRECT VERIFICATION (265.3s - 306.5s)
    // =========================================================================
    else if (t < 306.5) {
        if (t < 270.3) sub = @"Let's connect this algebra back to our geometry.";
        else if (t < 281.5) sub = @"When we plot the three original equations in 3D space, they meet at a single unique point: (1, 2, 3).";
        else if (t < 290.0) sub = @"Gaussian elimination transformed three tilted planes into three coordinate-aligned boundaries without moving this point.";
        else sub = @"We verify by checking all three original equations: 1 + 2 + 3 = 6; 2 − 2 + 3 = 3; and 1 + 4 − 3 = 2. Every equation holds perfectly.";
        
        double sAlpha = smoothstep(t, 265.3, 266.3) * (1.0 - smoothstep(t, 305.5, 306.5));
        drawTextAlpha(ctx, @"Geometric Interpretation & Direct Verification", CGPointMake(960, 955), @"HelveticaNeue-Bold", 32, col_text, NSTextAlignmentCenter, sAlpha);
        
        // Left 3D Plot inside bounded panel: morphs to orthogonal planes 284.0s -> 289.2s!
        CGRect geoCard = CGRectMake(70, 140, 880, 765);
        drawRoundedRect(ctx, geoCard, 18, colorWithAlpha(col_panel, sAlpha * 0.45), colorWithAlpha(col_panel_border, sAlpha * 0.6), 1.5);
        double morph = smoothstep(t, 284.0, 289.2);
        double dropP = smoothstep(t, 276.0, 280.5);
        CGRect clip3D = CGRectMake(85, 150, 850, 745);
        draw3DPlanesScene(ctx, CGPointMake(500, 545), 82.0, clip3D, t - 265.3, 1.0, morph, dropP, YES, sAlpha);
        
        // Right Verification Panel (290.2s+)
        double vA = smoothstep(t, 290.2, 291.4) * sAlpha;
        if (vA > 0.01) {
            CGRect vCard = CGRectMake(1000, 210, 840, 690);
            drawRoundedRect(ctx, vCard, 18, colorWithAlpha(col_panel, vA), colorWithAlpha(col_success, vA), 2.5);
            drawTextAlpha(ctx, @"Direct Substitution Verification", CGPointMake(1420, 845), @"HelveticaNeue-Bold", 26, col_text, NSTextAlignmentCenter, vA);
            
            double c1A = smoothstep(t, 293.5, 294.7) * vA;
            if (c1A > 0.01) {
                drawRoundedRect(ctx, CGRectMake(1045, 680, 750, 105), 12, RGBA(0, 212, 255, 0.12 * c1A), colorWithAlpha(col_x, c1A), 1.5);
                drawTextAlpha(ctx, @"Equation 1:   x + y + z = 6", CGPointMake(1075, 747), @"HelveticaNeue-Bold", 19, col_x, NSTextAlignmentLeft, c1A);
                drawTextAlpha(ctx, @"(1) + (2) + (3) = 6   ⇒   6 = 6   ✓ Verified", CGPointMake(1075, 703), @"HelveticaNeue-Bold", 21, col_success, NSTextAlignmentLeft, c1A);
            }
            
            double c2A = smoothstep(t, 296.5, 297.7) * vA;
            if (c2A > 0.01) {
                drawRoundedRect(ctx, CGRectMake(1045, 535, 750, 105), 12, RGBA(0, 230, 118, 0.12 * c2A), colorWithAlpha(col_y, c2A), 1.5);
                drawTextAlpha(ctx, @"Equation 2:   2x − y + z = 3", CGPointMake(1075, 602), @"HelveticaNeue-Bold", 19, col_y, NSTextAlignmentLeft, c2A);
                drawTextAlpha(ctx, @"2(1) − (2) + (3) = 3  ⇒   3 = 3   ✓ Verified", CGPointMake(1075, 558), @"HelveticaNeue-Bold", 21, col_success, NSTextAlignmentLeft, c2A);
            }
            
            double c3A = smoothstep(t, 299.4, 300.6) * vA;
            if (c3A > 0.01) {
                drawRoundedRect(ctx, CGRectMake(1045, 390, 750, 105), 12, RGBA(255, 82, 82, 0.12 * c3A), colorWithAlpha(col_pivot, c3A), 1.5);
                drawTextAlpha(ctx, @"Equation 3:   x + 2y − z = 2", CGPointMake(1075, 457), @"HelveticaNeue-Bold", 19, col_pivot, NSTextAlignmentLeft, c3A);
                drawTextAlpha(ctx, @"(1) + 2(2) − (3) = 2  ⇒   2 = 2   ✓ Verified", CGPointMake(1075, 413), @"HelveticaNeue-Bold", 21, col_success, NSTextAlignmentLeft, c3A);
            }
            
            double okA = smoothstep(t, 302.0, 303.2) * vA;
            if (okA > 0.01) {
                drawRoundedRect(ctx, CGRectMake(1045, 250, 750, 88), 12, RGBA(105, 240, 174, 0.18 * okA), colorWithAlpha(col_success, okA), 2.0);
                drawTextAlpha(ctx, @"✓  All Three Equations Satisfied Simultaneously at (1, 2, 3)!", CGPointMake(1420, 285), @"HelveticaNeue-Bold", 21, col_success, NSTextAlignmentCenter, okA);
            }
        }
    }
    // =========================================================================
    // SCENE 6: SUMMARY & CLOSING CREDITS (306.5s - 333.204s)
    // =========================================================================
    else {
        if (t < 313.0) sub = @"To summarize: first, augmented matrices strip away notations to expose pure structure.";
        else if (t < 319.0) sub = @"Second, elementary row operations simplify equations while preserving the exact same solution set.";
        else if (t < 326.8) sub = @"And third, reaching row echelon form unleashes a cascade of back-substitution to solve the system.";
        else sub = @"That is the elegance of Gaussian elimination. I'm Meka Vikas. Thank you for watching.";
        
        if (t < 326.8) {
            double sAlpha = smoothstep(t, 306.5, 307.5) * (1.0 - smoothstep(t, 326.0, 326.8));
            drawTextAlpha(ctx, @"Key Conceptual Takeaways", CGPointMake(960, 950), @"HelveticaNeue-Bold", 34, col_text, NSTextAlignmentCenter, sAlpha);
            
            CGFloat cardW = 1440, cardH = 140;
            double c1A = smoothstep(t, 308.5, 310.0) * sAlpha;
            double c2A = smoothstep(t, 313.5, 315.0) * sAlpha;
            double c3A = smoothstep(t, 319.2, 320.5) * sAlpha;
            
            if (c1A > 0.01) {
                drawRoundedRect(ctx, CGRectMake(240, 680, cardW, cardH), 14, colorWithAlpha(col_panel, c1A), colorWithAlpha(col_x, c1A), 2.0);
                drawTextAlpha(ctx, @"1. Compact Structure via Augmented Matrices", CGPointMake(290, 772), @"HelveticaNeue-Bold", 24, col_x, NSTextAlignmentLeft, c1A);
                drawTextAlpha(ctx, @"Strips away variable letters to isolate numerical coefficients and constants [A | b].", CGPointMake(290, 720), @"HelveticaNeue", 19, col_text, NSTextAlignmentLeft, c1A);
            }
            if (c2A > 0.01) {
                drawRoundedRect(ctx, CGRectMake(240, 495, cardW, cardH), 14, colorWithAlpha(col_panel, c2A), colorWithAlpha(col_y, c2A), 2.0);
                drawTextAlpha(ctx, @"2. Invariance Under Row Operations", CGPointMake(290, 587), @"HelveticaNeue-Bold", 24, col_y, NSTextAlignmentLeft, c2A);
                drawTextAlpha(ctx, @"Reversible swaps, scalings, and replacements simplify planes while preserving the unique solution (1, 2, 3).", CGPointMake(290, 535), @"HelveticaNeue", 19, col_text, NSTextAlignmentLeft, c2A);
            }
            if (c3A > 0.01) {
                drawRoundedRect(ctx, CGRectMake(240, 310, cardW, cardH), 14, colorWithAlpha(col_panel, c3A), colorWithAlpha(col_pivot, c3A), 2.0);
                drawTextAlpha(ctx, @"3. Systematic Back-Substitution from Echelon Form", CGPointMake(290, 402), @"HelveticaNeue-Bold", 24, col_pivot, NSTextAlignmentLeft, c3A);
                drawTextAlpha(ctx, @"Creating zeros beneath pivots isolates variables one by one, yielding x = 1, y = 2, z = 3 effortlessly.", CGPointMake(290, 350), @"HelveticaNeue", 19, col_text, NSTextAlignmentLeft, c3A);
            }
        } else {
            // Closing Academic Credits Sequence (326.8s - 333.204s)
            double cAlpha = smoothstep(t, 326.8, 327.6) * (1.0 - smoothstep(t, 332.4, 333.2));
            CGRect credBox = CGRectMake(180, 295, 1560, 490);
            drawRoundedRect(ctx, credBox, 24, colorWithAlpha(col_panel, cAlpha), colorWithAlpha(col_x, cAlpha), 3.0);
            
            drawTextAlpha(ctx, @"LINEAR ALGEBRA AND CALCULUS (M3)  •  CONCLUSION & CREDITS", CGPointMake(960, 710), @"HelveticaNeue-Bold", 20, col_x, NSTextAlignmentCenter, cAlpha);
            drawTextAlpha(ctx, @"GAUSSIAN ELIMINATION: SOLVING A 3×3 SYSTEM STEP BY STEP", CGPointMake(960, 642), @"HelveticaNeue-Bold", 34, col_text, NSTextAlignmentCenter, cAlpha);
            
            // Solution & Key Takeaways summary bar
            CGRect solStrip = CGRectMake(250, 505, 1420, 78);
            drawRoundedRect(ctx, solStrip, 12, RGBA(105, 240, 174, 0.14 * cAlpha), colorWithAlpha(col_success, cAlpha), 1.5);
            drawTextAlpha(ctx, @"Verified Solution: (x = 1, y = 2, z = 3)   |   Takeaways: Augmented Form • Solution Invariance • Back-Substitution", CGPointMake(960, 535), @"HelveticaNeue-Bold", 19, col_success, NSTextAlignmentCenter, cAlpha);
            
            // Student Details
            drawTextAlpha(ctx, @"Student: Meka Vikas   |   URN: E25B070539   |   GitHub: https://github.com/MEKAVIKAS", CGPointMake(960, 395), @"HelveticaNeue-Bold", 23, col_gold, NSTextAlignmentCenter, cAlpha);
        }
    }
    
    // Draw Subtitles cleanly at bottom
    drawSubtitlePill(ctx, sub);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        initColors();
        
        NSString *rawVideoPath = @"/tmp/raw_video_v3.mp4";
        NSString *audioPath = @"Audio/original_voiceover.m4a";
        NSString *finalVideoPath = @"Video/M3_Gaussian_Elimination.mp4";
        
        [[NSFileManager defaultManager] removeItemAtPath:rawVideoPath error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:finalVideoPath error:nil];
        
        int width = 1920, height = 1080, fps = 30;
        double duration = 333.204;
        int totalFrames = (int)(duration * fps) + 1;
        
        NSLog(@"Rendering Synchronized 1080p Motion Graphics: %d frames (%.3f s @ %d fps)", totalFrames, duration, fps);
        
        NSError *error = nil;
        AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:rawVideoPath] fileType:AVFileTypeMPEG4 error:&error];
        if (error) { NSLog(@"Writer Error: %@", error); return 1; }
        
        NSDictionary *videoSettings = @{
            AVVideoCodecKey: AVVideoCodecTypeH264,
            AVVideoWidthKey: @(width),
            AVVideoHeightKey: @(height),
            AVVideoCompressionPropertiesKey: @{
                AVVideoAverageBitRateKey: @(8000000),
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoMaxKeyFrameIntervalKey: @(fps)
            }
        };
        
        AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        writerInput.expectsMediaDataInRealTime = NO;
        
        NSDictionary *bufAttr = @{
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
            (id)kCVPixelBufferWidthKey: @(width),
            (id)kCVPixelBufferHeightKey: @(height)
        };
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:bufAttr];
        
        [videoWriter addInput:writerInput];
        [videoWriter startWriting];
        [videoWriter startSessionAtSourceTime:kCMTimeZero];
        
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        NSDate *startTime = [NSDate date];
        
        for (int frame = 0; frame < totalFrames; frame++) {
            @autoreleasepool {
                while (!writerInput.readyForMoreMediaData) [NSThread sleepForTimeInterval:0.004];
                double t = (double)frame / (double)fps;
                
                CVPixelBufferRef pb = NULL;
                if (CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &pb) != kCVReturnSuccess || !pb) break;
                
                CVPixelBufferLockBaseAddress(pb, 0);
                CGContextRef ctx = CGBitmapContextCreate(
                    CVPixelBufferGetBaseAddress(pb), width, height, 8, CVPixelBufferGetBytesPerRow(pb), cs,
                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst
                );
                renderFrameAtTime(ctx, t);
                CGContextRelease(ctx);
                CVPixelBufferUnlockBaseAddress(pb, 0);
                
                [adaptor appendPixelBuffer:pb withPresentationTime:CMTimeMake(frame, fps)];
                CVPixelBufferRelease(pb);
                
                if (frame % 2000 == 0 || frame == totalFrames - 1) {
                    NSTimeInterval el = -[startTime timeIntervalSinceNow];
                    NSLog(@"Progress: %d / %d (%.1f%%) - %.1f fps", frame + 1, totalFrames, (double)(frame+1)/totalFrames*100.0, (frame+1)/el);
                }
            }
        }
        CGColorSpaceRelease(cs);
        
        [writerInput markAsFinished];
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [videoWriter finishWritingWithCompletionHandler:^{ dispatch_semaphore_signal(sema); }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        // Multiplex Audio & Video
        NSLog(@"Multiplexing exact human voiceover audio...");
        AVMutableComposition *comp = [AVMutableComposition composition];
        AVURLAsset *vAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:rawVideoPath] options:nil];
        AVURLAsset *aAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:audioPath] options:nil];
        
        AVMutableCompositionTrack *vTrack = [comp addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack *aTrack = [comp addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAssetTrack *srcV = [vAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *srcA = [aAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        if (!srcV || !srcA) {
            NSLog(@"ERROR: Missing video (%@) or audio (%@) track!", srcV, srcA);
            return 1;
        }
        
        CMTime minDur = CMTimeMinimum(vAsset.duration, aAsset.duration);
        [vTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, minDur) ofTrack:srcV atTime:kCMTimeZero error:&error];
        [aTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, minDur) ofTrack:srcA atTime:kCMTimeZero error:&error];
        
        AVAssetExportSession *exp = [[AVAssetExportSession alloc] initWithAsset:comp presetName:AVAssetExportPresetHighestQuality];
        exp.outputURL = [NSURL fileURLWithPath:finalVideoPath];
        exp.outputFileType = AVFileTypeMPEG4;
        exp.shouldOptimizeForNetworkUse = YES;
        
        dispatch_semaphore_t expSema = dispatch_semaphore_create(0);
        [exp exportAsynchronouslyWithCompletionHandler:^{
            NSLog(@"Export status: %ld, error: %@", (long)exp.status, exp.error);
            dispatch_semaphore_signal(expSema);
        }];
        dispatch_semaphore_wait(expSema, DISPATCH_TIME_FOREVER);
        
        [[NSFileManager defaultManager] removeItemAtPath:rawVideoPath error:nil];
        if (exp.status != AVAssetExportSessionStatusCompleted) {
            NSLog(@"ERROR: Export failed with status %ld", (long)exp.status);
            return 1;
        }
        NSLog(@"SUCCESS! Rendered to %@", finalVideoPath);
    }
    return 0;
}

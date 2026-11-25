# Mathematical Verification Sheet
## Project: How Gaussian Elimination Solves a 3 × 3 System of Linear Equations
**Course:** Linear Algebra and Calculus (M3) — Internal Assessment  
**Student Name:** Meka Vikas  
**URN:** E25B070539  
**GitHub:** https://github.com/MEKAVIKAS  

---

### 1. The Given System of Linear Equations

We are given the following system of three linear equations in three unknowns ($x, y, z \in \mathbb{R}$):

$$\begin{aligned}
(1) \quad & x + y + z = 6 \\
(2) \quad & 2x - y + z = 3 \\
(3) \quad & x + 2y - z = 2
\end{aligned}$$

---

### 2. Matrix Representation ($Ax = b$)

The system can be expressed compactly in matrix vector form:

$$A \mathbf{x} = \mathbf{b}$$

where:
$$A = \begin{bmatrix} 1 & 1 & 1 \\ 2 & -1 & 1 \\ 1 & 2 & -1 \end{bmatrix}, \quad \mathbf{x} = \begin{bmatrix} x \\ y \\ z \end{bmatrix}, \quad \mathbf{b} = \begin{bmatrix} 6 \\ 3 \\ 2 \end{bmatrix}$$

The **Augmented Matrix** $[A \mid \mathbf{b}]$ combines the coefficient matrix $A$ and the constant vector $\mathbf{b}$ into a single $3 \times 4$ array:

$$[A \mid \mathbf{b}] = \left[\begin{array}{ccc|c}
1 & 1 & 1 & 6 \\
2 & -1 & 1 & 3 \\
1 & 2 & -1 & 2
\end{array}\right]$$

---

### 3. Existence and Uniqueness of Solution (Determinant Check)

Before performing elimination, we verify that the coefficient matrix $A$ is non-singular ($\det(A) \neq 0$), ensuring a unique solution exists:

$$\begin{aligned}
\det(A) &= \begin{vmatrix} 1 & 1 & 1 \\ 2 & -1 & 1 \\ 1 & 2 & -1 \end{vmatrix} \\
&= 1 \cdot \begin{vmatrix} -1 & 1 \\ 2 & -1 \end{vmatrix} - 1 \cdot \begin{vmatrix} 2 & 1 \\ 1 & -1 \end{vmatrix} + 1 \cdot \begin{vmatrix} 2 & -1 \\ 1 & 2 \end{vmatrix} \\
&= 1 \cdot [(-1)(-1) - (1)(2)] - 1 \cdot [(2)(-1) - (1)(1)] + 1 \cdot [(2)(2) - (-1)(1)] \\
&= 1 \cdot [1 - 2] - 1 \cdot [-2 - 1] + 1 \cdot [4 + 1] \\
&= 1(-1) - 1(-3) + 1(5) \\
&= -1 + 3 + 5 = 7
\end{aligned}$$

Since $\det(A) = 7 \neq 0$:
1. Matrix $A$ is invertible ($\operatorname{rank}(A) = 3$).
2. The three planes intersect at exactly **one unique point** in $\mathbb{R}^3$.
3. The system is consistent with no free variables.

---

### 4. Step-by-Step Elementary Row Operations

Gaussian elimination transforms $[A \mid \mathbf{b}]$ into an upper-triangular **Row Echelon Form** (REF) using three allowable elementary row operations:
- **Row Replacement:** $R_i \to R_i + k R_j$
- **Row Interchange:** $R_i \leftrightarrow R_j$
- **Row Scaling:** $R_i \to c R_i$ ($c \neq 0$)

These operations correspond to multiplication by elementary invertible matrices, preserving the exact solution set.

#### Initial Augmented Matrix:
$$M_0 = \left[\begin{array}{ccc|c}
\mathbf{1} & 1 & 1 & 6 \\
2 & -1 & 1 & 3 \\
1 & 2 & -1 & 2
\end{array}\right]$$
**Pivot 1:** Located at position $(1, 1)$, value $= 1$.

---

#### Operation 1: Eliminate $x$ from Row 2 ($R_2 \to R_2 - 2R_1$)
- **Purpose:** Create a zero in column 1 beneath the first pivot.
- **Elementary Matrix:** 
  $$E_1 = \begin{bmatrix} 1 & 0 & 0 \\ -2 & 1 & 0 \\ 0 & 0 & 1 \end{bmatrix}$$
- **Detailed Arithmetic:**
  $$\begin{aligned}
  R_2 &: [2, \quad -1, \quad 1 \quad \mid \quad 3] \\
  -2 R_1 &: [-2, \quad -2, \quad -2 \quad \mid \quad -12] \\
  \hline
  \text{New } R_2 &: [2-2, \quad -1-2, \quad 1-2 \quad \mid \quad 3-12] \\
  &= [0, \quad -3, \quad -1 \quad \mid \quad -9]
  \end{aligned}$$
- **Resulting Matrix:**
  $$M_1 = \left[\begin{array}{ccc|c}
  \mathbf{1} & 1 & 1 & 6 \\
  \mathbf{0} & -3 & -1 & -9 \\
  1 & 2 & -1 & 2
  \end{array}\right]$$

---

#### Operation 2: Eliminate $x$ from Row 3 ($R_3 \to R_3 - R_1$)
- **Purpose:** Create a zero in column 1, row 3.
- **Elementary Matrix:**
  $$E_2 = \begin{bmatrix} 1 & 0 & 0 \\ 0 & 1 & 0 \\ -1 & 0 & 1 \end{bmatrix}$$
- **Detailed Arithmetic:**
  $$\begin{aligned}
  R_3 &: [1, \quad 2, \quad -1 \quad \mid \quad 2] \\
  -1 R_1 &: [-1, \quad -1, \quad -1 \quad \mid \quad -6] \\
  \hline
  \text{New } R_3 &: [1-1, \quad 2-1, \quad -1-1 \quad \mid \quad 2-6] \\
  &= [0, \quad 1, \quad -2 \quad \mid \quad -4]
  \end{aligned}$$
- **Resulting Matrix:**
  $$M_2 = \left[\begin{array}{ccc|c}
  \mathbf{1} & 1 & 1 & 6 \\
  \mathbf{0} & -3 & -1 & -9 \\
  \mathbf{0} & 1 & -2 & -4
  \end{array}\right]$$

---

#### Operation 3: Row Interchange ($R_2 \leftrightarrow R_3$)
- **Purpose:** In column 2, Row 3 has a leading coefficient of $1$, whereas Row 2 has $-3$. Swapping $R_2$ and $R_3$ brings the convenient pivot $1$ into position $(2, 2)$, avoiding fractions and simplifying subsequent elimination.
- **Elementary Matrix:**
  $$P_{23} = \begin{bmatrix} 1 & 0 & 0 \\ 0 & 0 & 1 \\ 0 & 1 & 0 \end{bmatrix}$$
- **Resulting Matrix:**
  $$M_3 = \left[\begin{array}{ccc|c}
  \mathbf{1} & 1 & 1 & 6 \\
  \mathbf{0} & \mathbf{1} & -2 & -4 \\
  \mathbf{0} & -3 & -1 & -9
  \end{array}\right]$$
**Pivot 2:** Located at position $(2, 2)$, value $= 1$.

---

#### Operation 4: Eliminate $y$ from Row 3 ($R_3 \to R_3 + 3R_2$)
- **Purpose:** Create a zero in column 2 beneath the second pivot to achieve upper-triangular echelon form.
- **Elementary Matrix:**
  $$E_4 = \begin{bmatrix} 1 & 0 & 0 \\ 0 & 1 & 0 \\ 0 & 3 & 1 \end{bmatrix}$$
- **Detailed Arithmetic:**
  $$\begin{aligned}
  R_3 &: [0, \quad -3, \quad -1 \quad \mid \quad -9] \\
  +3 R_2 &: [0, \quad 3, \quad -6 \quad \mid \quad -12] \\
  \hline
  \text{New } R_3 &: [0+0, \quad -3+3, \quad -1+(-6) \quad \mid \quad -9+(-12)] \\
  &= [0, \quad 0, \quad -7 \quad \mid \quad -21]
  \end{aligned}$$
- **Resulting Matrix (Row Echelon Form):**
  $$M_{\text{REF}} = \left[\begin{array}{ccc|c}
  \mathbf{1} & 1 & 1 & 6 \\
  0 & \mathbf{1} & -2 & -4 \\
  0 & 0 & \mathbf{-7} & -21
  \end{array}\right]$$
**Pivot 3:** Located at position $(3, 3)$, value $= -7$.

---

### 5. Determinant Consistency Check from REF
The determinant of an upper-triangular matrix is the product of its diagonal elements:
$$\det(U) = 1 \times 1 \times (-7) = -7$$
Since we performed exactly one row swap ($P_{23}$), which multiplies the determinant by $-1$:
$$\det(A) = (-1)^1 \times \det(U) = -(-7) = 7$$
This matches our direct determinant calculation, proving algebraic consistency.

---

### 6. Back-Substitution Step-by-Step

From the Row Echelon Form, we rewrite the matrix into algebraic equations:

$$\begin{aligned}
(1') \quad & x + y + z = 6 \\
(2') \quad & y - 2z = -4 \\
(3') \quad & -7z = -21
\end{aligned}$$

#### Step 1: Solve for $z$ using Equation $(3')$
$$-7z = -21 \implies z = \frac{-21}{-7} = 3$$
$$\mathbf{z = 3}$$

#### Step 2: Substitute $z = 3$ into Equation $(2')$ to solve for $y$
$$\begin{aligned}
y - 2(3) &= -4 \\
y - 6 &= -4 \\
y &= -4 + 6 \\
\mathbf{y = 2}
\end{aligned}$$

#### Step 3: Substitute $y = 2$ and $z = 3$ into Equation $(1')$ to solve for $x$
$$\begin{aligned}
x + (2) + (3) &= 6 \\
x + 5 &= 6 \\
x &= 6 - 5 \\
\mathbf{x = 1}
\end{aligned}$$

#### Summary of Computed Values:
$$\mathbf{x = 1}, \quad \mathbf{y = 2}, \quad \mathbf{z = 3}$$
Ordered triple: $(x, y, z) = (1, 2, 3)$.

---

### 7. Verification by Direct Substitution into Original System

We substitute $(x, y, z) = (1, 2, 3)$ into the original equations:

1. **Equation 1:**
   $$\text{LHS} = x + y + z = 1 + 2 + 3 = 6 = \text{RHS} \quad \checkmark \quad (\text{TRUE})$$

2. **Equation 2:**
   $$\text{LHS} = 2x - y + z = 2(1) - 2 + 3 = 2 - 2 + 3 = 3 = \text{RHS} \quad \checkmark \quad (\text{TRUE})$$

3. **Equation 3:**
   $$\text{LHS} = x + 2y - z = 1 + 2(2) - 3 = 1 + 4 - 3 = 2 = \text{RHS} \quad \checkmark \quad (\text{TRUE})$$

All three equations are satisfied simultaneously. The solution is verified.

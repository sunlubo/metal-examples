//
//  SIMD.playground
//
//  Copyright © 2018 sunlubo. All rights reserved.
//

import Cocoa
import QuartzCore
import simd

// 数量积/内积/点乘/dot product
// 向量积/外积/叉乘/cross product

// scalar
let s1 = Float(2)
let s2 = Float(3)
s1 + s2
s1 - s2
s1 * s2
s1 / s2

// vector
let v1 = float2(1, 2)
let v2 = float2(3, 4)
let v3 = float3(1, 2, 3)
let v4 = float4(1, 2, 3, 4)
// Vector (elementwise) sum of `lhs` and `rhs`.
v1 + v2
// Vector (elementwise) difference of `lhs` and `rhs`.
v1 - v2
// Elementwise product of `lhs` and `rhs` (A.k.a. the Hadamard or Schur vector product).
v1 * v2
// Elementwise quotient of `lhs` and `rhs`.
v1 / v2
// Scalar-Vector product.
v1 * s1
// Divide vector by scalar.
v1 / s1
// Dot product of `x` and `y`.
dot(v1, v2)
// Interprets two two-dimensional vectors as three-dimensional vectors in the
// xy-plane and computes their cross product, which lies along the z-axis.
cross(v1, v2)
// Distance between `x` and `y`.
distance(v1, v2)
// Distance between `x` and `y`, squared.
distance_squared(v1, v2)
// Length (two-norm or "Euclidean norm") of `x`.
length(v1)
// Length of `x`, squared.
length_squared(v1)
// Linear interpolation between `x` (at `t=0`) and `y` (at `t=1`).  May be used with `t` outside of [0, 1] as well.
// v1 + (v2 - v1) * s1
mix(v1, v2, t: s1)
// 0.0 if `x < edge`, and 1.0 otherwise.
step(v1, edge: v2)
// Projection of `x` onto `y`.
project(v1, v2)

let m1 = float2x2(rows: [v1, v2])
let m2 = float2x2(rows: [v1, v2])
let m3 = float2x3(rows: [v2, v2, v2])
let m4 = float2x4(rows: [v2, v2, v2, v2])
let m5 = float3x2(rows: [v3, v3])
let m6 = float3x3(rows: [v3, v3, v3])
let m7 = float3x4(rows: [v3, v3, v3, v3])
let m8 = float4x2(rows: [v4, v4])
let m9 = float4x3(rows: [v4, v4, v4])
let m0 = float4x4(rows: [v4, v4, v4, v4])
// col 0
m1[0]
// col 0, row 1
m1[0, 1]
// Sum of two matrices.
m1 + m2
// Difference of two matrices.
m1 - m2
// Scalar-Matrix multiplication.
m1 * s1
// Matrix-Vector multiplication. Keep in mind that matrix types are named
// `FloatNxM` where `N` is the number of *columns* and `M` is the number of
// *rows*, so we multiply a `Float3x2 * Float3` to get a `Float2`, for
// example.
m1 * v1
// Matrix multiplication (the "usual" matrix product, not the elementwise product).
m1 * m2
// Transpose of the matrix.
m1.transpose
// Inverse of the matrix if it exists, otherwise the contents of the resulting matrix are undefined. (逆矩阵)
m1.inverse
// Determinant of the matrix. (特征值)
m1.determinant

// http://metalbyexample.com/linear-algebra/
// http://www.songho.ca/opengl/gl_projectionmatrix.html

// 3D
cross(float2(1, 0), float2(0, 1))
cross(float3(1, 0, 0), float3(0, 1, 0))

// MARK: - Linear Transformations

// Identity
let identity = matrix_identity_float3x3

// Scale
let scaleM = float3x3(rows: [
    float3(0.5, 0.0, 0.0),
    float3(0.0, 0.5, 0.0),
    float3(0.0, 0.0, 0.5)
])
scaleM * v3

// Rotate around Z-axis
let rotateM = float3x3(rows: [
    float3(cos(.pi), -sin(.pi), 0.0),
    float3(sin(.pi), cos(.pi), 0.0),
    float3(0.0, 0.0, 1.0)
])
rotateM * v3

// Shear

// MARK: - Affine Transformations

// Translation
let translationM = float4x4(rows: [
    float4(1.0, 0.0, 0.0, 0.5),
    float4(0.0, 1.0, 0.0, 0.5),
    float4(0.0, 0.0, 1.0, 0.5),
    float4(0.0, 0.0, 0.0, 1.0)
])
translationM * float4(1, 2, 3, 1)

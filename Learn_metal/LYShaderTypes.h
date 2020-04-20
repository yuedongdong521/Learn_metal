//
//  LYShaderTypes.h
//  LearnMetal
//
//  Created by loyinglin on 2018/6/21.
//  Copyright © 2018年 loyinglin. All rights reserved.
//

#ifndef LYShaderTypes_h
#define LYShaderTypes_h

#include <simd/simd.h>

/** 顶点shader 函数名 */
#define kMTLFUC_vertexShader @"vertexShader"
/** 片元shder 函数名 */
#define kMTLFUC_samplingShader @"samplingShader"
#define kMTLFUC_yuv_samplingShader @"yuv_samplingShader"

typedef struct
{
    vector_float4 position;
    vector_float2 textureCoordinate;
} LYVertex;

typedef struct {
    matrix_float3x3 matrix;
    vector_float3 offset;
} LYConvertMatrix;



typedef enum LYVertexInputIndex
{
    LYVertexInputIndexVertices     = 0,
} LYVertexInputIndex;


typedef enum LYFragmentBufferIndex
{
    LYFragmentInputIndexMatrix     = 0,
} LYFragmentBufferIndex;


typedef enum LYFragmentTextureIndex
{
    LYFragmentTextureIndexTextureY     = 0,
    LYFragmentTextureIndexTextureUV     = 1,
} LYFragmentTextureIndex;



#endif /* LYShaderTypes_h */

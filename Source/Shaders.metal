#include <metal_stdlib>
using namespace metal;

typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef float f32;
typedef float2 f32x2;
typedef float3 f32x3;
typedef float4 f32x4;

struct Arguments
{
	f32x2 resolution;
	f32x4 color;
	f32 pointSize;
	device f32x2 *positions;
};

struct RasterizerData
{
	f32x4 positionNDC [[position]];
	f32x2 position;
	f32x2 center;
};

constant f32x2 rectVertices[] = {
	f32x2(0,0),
	f32x2(1,0),
	f32x2(0,1),
	f32x2(0,1),
	f32x2(1,1),
	f32x2(1,0),
};

vertex RasterizerData
VertexMain(u32 vertexID [[vertex_id]], u32 instanceID [[instance_id]], constant Arguments &arguments)
{
	f32x2 center = arguments.positions[instanceID];
	f32x2 position = center + arguments.pointSize * (rectVertices[vertexID] - 0.5f);

	RasterizerData output = {0};
	output.positionNDC.xy = position;
	output.positionNDC.xy /= arguments.resolution;
	output.positionNDC.xy = 2 * output.positionNDC.xy - 1;
	output.positionNDC.w = 1;
	output.position = position;
	output.center = center;
	return output;
}

fragment f32x4
FragmentMain(RasterizerData input [[stage_in]], constant Arguments &arguments)
{
	f32x4 result = 0;

	f32 distanceToCenter = length(abs(input.position - input.center));
	f32 pointRadius = arguments.pointSize/2;
	if (distanceToCenter < pointRadius)
	{
		result = arguments.color;
		result.rgb *= result.a;
	}

	return result;
}

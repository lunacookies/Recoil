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

struct PointsArguments
{
	f32x2 resolution;
	f32 pointSize;
	device f32x2 *positions;
};

struct ColorizeArguments
{
	f32x4 backgroundColor;
	f32x4 pointColor;
};

struct PointsRasterizerData
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

vertex PointsRasterizerData
PointsVertex(u32 vertexID [[vertex_id]], u32 instanceID [[instance_id]], constant PointsArguments &arguments)
{
	f32x2 center = arguments.positions[instanceID];
	f32 padding = 1; // stop anti-aliased edges from being cut off
	f32x2 p0 = center - arguments.pointSize / 2 - padding;
	f32x2 p1 = center + arguments.pointSize / 2 + padding;
	p0 = floor(p0);
	p1 = ceil(p1);

	f32x2 position = p0 + rectVertices[vertexID] * (p1 - p0);

	PointsRasterizerData output = {0};
	output.positionNDC.xy = position;
	output.positionNDC.xy /= arguments.resolution;
	output.positionNDC.xy = 2 * output.positionNDC.xy - 1;
	output.positionNDC.w = 1;
	output.position = position;
	output.center = center;
	return output;
}

fragment f32x4
PointsFragment(PointsRasterizerData input [[stage_in]], constant PointsArguments &arguments)
{
	f32 distanceToCenter = length(abs(input.position - input.center));
	f32 pointRadius = arguments.pointSize / 2;
	f32 distanceToEdge =  distanceToCenter - pointRadius;
	return 1 - clamp(distanceToEdge, 0.f, 1.f);
}

fragment f32x4
Colorize(constant ColorizeArguments &arguments, f32x4 color [[color(0)]])
{
	return mix(arguments.backgroundColor, arguments.pointColor, color.a);
}

#pragma header

uniform vec4 uFrameBounds;

uniform float ang;
uniform float dist;
uniform float str;
uniform float thr;

uniform float angOffset;

uniform vec3 dropColor;

uniform float hue;
uniform float saturation;
uniform float brightness;
uniform float contrast;

uniform float AA_STAGES;


const vec3 grayscaleValues =
    vec3(
        0.3098039215686275,
        0.607843137254902,
        0.0823529411764706
    );

const float e = 2.718281828459045;


// =================================================
// HUE
// =================================================

vec3 applyHueRotate(
    vec3 aColor,
    float aHue
)
{
    float angle = radians(aHue);

    mat3 m1 = mat3(
        0.213, 0.213, 0.213,
        0.715, 0.715, 0.715,
        0.072, 0.072, 0.072
    );

    mat3 m2 = mat3(
        0.787, -0.213, -0.213,
        -0.715, 0.285, -0.715,
        -0.072, -0.072, 0.928
    );

    mat3 m3 = mat3(
        -0.213, 0.143, -0.787,
        -0.715, 0.140, 0.715,
        0.928, -0.283, 0.072
    );

    mat3 m =
        m1 +
        cos(angle) * m2 +
        sin(angle) * m3;

    return m * aColor;
}


// =================================================
// SATURATION
// =================================================

vec3 applySaturation(
    vec3 aColor,
    float value
)
{
    if (value > 0.0)
    {
        value *= 3.0;
    }

    value =
        1.0 +
        value / 100.0;

    vec3 grayscale =
        vec3(
            dot(
                aColor,
                grayscaleValues
            )
        );

    return clamp(
        mix(
            grayscale,
            aColor,
            value
        ),
        0.0,
        1.0
    );
}


// =================================================
// CONTRAST
// =================================================

vec3 applyContrast(
    vec3 aColor,
    float value
)
{
    value =
        1.0 +
        value / 100.0;

    if (value > 1.0)
    {
        value =
            (
                (
                    0.00852259 *
                    pow(
                        e,
                        4.76454 *
                        (value - 1.0)
                    )
                ) *
                1.01 -
                0.0086078159
            ) *
            10.0;

        value += 1.0;
    }

    return clamp(
        (aColor - 0.25) *
        value +
        0.25,
        0.0,
        1.0
    );
}


// =================================================
// ADJUST COLOR
// =================================================

vec3 applyHSBCEffect(
    vec3 color
)
{
    color +=
        brightness / 255.0;

    color =
        applyHueRotate(
            color,
            hue
        );

    color =
        applyContrast(
            color,
            contrast
        );

    color =
        applySaturation(
            color,
            saturation
        );

    return color;
}


// =================================================
// RANDOM AA
// =================================================

vec2 hash22(vec2 p)
{
    vec3 p3 =
        fract(
            vec3(p.xyx) *
            vec3(
                0.1031,
                0.1030,
                0.0973
            )
        );

    p3 +=
        dot(
            p3,
            p3.yzx + 33.33
        );

    return fract(
        (p3.xx + p3.yz) *
        p3.zy
    );
}


// =================================================
// INTENSITY
// =================================================

float intensityPass(
    vec2 fragCoord
)
{
    vec4 col =
        flixel_texture2D(
            bitmap,
            fragCoord
        );

    if (col.a == 0.0)
    {
        return 0.0;
    }

    float intensity =
        dot(
            col.rgb,
            vec3(
                0.3098,
                0.6078,
                0.0823
            )
        );

    return float(
        intensity > thr
    );
}


// =================================================
// ANTIALIAS
// =================================================

float antialias(
    vec2 fragCoord
)
{
    if (AA_STAGES == 0.0)
    {
        return intensityPass(
            fragCoord
        );
    }

    const int MAX_AA = 8;

    float AA_TOTAL_PASSES =
        AA_STAGES *
        AA_STAGES +
        1.0;

    const float AA_JITTER = 0.5;

    float result =
        intensityPass(
            fragCoord
        );

    for (
        int i = 0;
        i < MAX_AA * MAX_AA;
        i++
    )
    {
        int x =
            i / MAX_AA;

        int y =
            i -
            (
                MAX_AA *
                int(i / MAX_AA)
            );

        if (
            float(x) >= AA_STAGES ||
            float(y) >= AA_STAGES
        )
        {
            continue;
        }

        vec2 offset =
            AA_JITTER *
            (
                2.0 *
                hash22(
                    vec2(
                        float(x),
                        float(y)
                    )
                ) -
                1.0
            ) /
            openfl_TextureSize.xy;

        result +=
            intensityPass(
                fragCoord +
                offset
            );
    }

    return result /
        AA_TOTAL_PASSES;
}


// =================================================
// DROP SHADOW / RIM LIGHT
// =================================================

vec3 createDropShadow(
    vec3 col
)
{
    float intensity =
        antialias(
            openfl_TextureCoordv
        );

    vec2 imageRatio =
        vec2(
            1.0 / openfl_TextureSize.x,
            1.0 / openfl_TextureSize.y
        );

    vec2 checkedPixel =
        vec2(
            openfl_TextureCoordv.x +
            (
                dist *
                cos(
                    ang +
                    angOffset
                ) *
                imageRatio.x
            ),

            openfl_TextureCoordv.y -
            (
                dist *
                sin(
                    ang +
                    angOffset
                ) *
                imageRatio.y
            )
        );

    float dropShadowAmount =
        0.0;

    if (
        checkedPixel.x > uFrameBounds.x &&
        checkedPixel.y > uFrameBounds.y &&
        checkedPixel.x < uFrameBounds.z &&
        checkedPixel.y < uFrameBounds.w
    )
    {
        dropShadowAmount =
            flixel_texture2D(
                bitmap,
                checkedPixel
            ).a;
    }

    col.rgb +=
        dropColor.rgb *
        (
            (
                1.0 -
                (
                    dropShadowAmount *
                    str
                )
            ) *
            intensity
        );

    return col;
}


// =================================================
// MAIN
// =================================================

void main()
{
    vec4 col =
        flixel_texture2D(
            bitmap,
            openfl_TextureCoordv
        );

    vec3 unpremultipliedColor =
        col.a > 0.0
            ? col.rgb / col.a
            : col.rgb;

    vec3 outColor =
        applyHSBCEffect(
            unpremultipliedColor
        );

    outColor =
        createDropShadow(
            outColor
        );

    gl_FragColor =
        vec4(
            outColor.rgb * col.a,
            col.a
        );
}
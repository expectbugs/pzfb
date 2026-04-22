/*
 * Decompiled with CFR 0.152.
 */
package zombie.core;

import java.io.IOException;
import java.io.Serializable;
import java.nio.ByteBuffer;
import zombie.UsedFromLua;
import zombie.core.Colors;
import zombie.core.math.PZMath;
import zombie.core.textures.ColorInfo;
import zombie.core.utils.Bits;

@UsedFromLua
public final class Color
implements Serializable {
    private static final long serialVersionUID = 1393939L;
    public static final Color transparent = new Color(0.0f, 0.0f, 0.0f, 0.0f);
    public static final Color white = new Color(1.0f, 1.0f, 1.0f, 1.0f);
    public static final Color yellow = new Color(1.0f, 1.0f, 0.0f, 1.0f);
    public static final Color red = new Color(1.0f, 0.0f, 0.0f, 1.0f);
    public static final Color purple = new Color(196.0f, 0.0f, 171.0f);
    public static final Color blue = new Color(0.0f, 0.0f, 1.0f, 1.0f);
    public static final Color green = new Color(0.0f, 1.0f, 0.0f, 1.0f);
    public static final Color black = new Color(0.0f, 0.0f, 0.0f, 1.0f);
    public static final Color gray = new Color(0.5f, 0.5f, 0.5f, 1.0f);
    public static final Color cyan = new Color(0.0f, 1.0f, 1.0f, 1.0f);
    public static final Color darkGray = new Color(0.3f, 0.3f, 0.3f, 1.0f);
    public static final Color lightGray = new Color(0.7f, 0.7f, 0.7f, 1.0f);
    public static final Color pink = new Color(255, 175, 175, 255);
    public static final Color orange = new Color(255, 200, 0, 255);
    public static final Color magenta = new Color(255, 0, 255, 255);
    public static final Color darkGreen = new Color(22, 113, 20, 255);
    public static final Color lightGreen = new Color(55, 148, 53, 255);
    public float a = 1.0f;
    public float b;
    public float g;
    public float r;

    public float getR() {
        return this.r;
    }

    public float getG() {
        return this.g;
    }

    public float getB() {
        return this.b;
    }

    public Color() {
    }

    public Color(Color color) {
        if (color == null) {
            this.r = 0.0f;
            this.g = 0.0f;
            this.b = 0.0f;
            this.a = 1.0f;
            return;
        }
        this.r = color.r;
        this.g = color.g;
        this.b = color.b;
        this.a = color.a;
    }

    public Color(float r, float g, float b) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = 1.0f;
    }

    public Color(float r, float g, float b, float a) {
        this.r = PZMath.clamp(r, 0.0f, 1.0f);
        this.g = PZMath.clamp(g, 0.0f, 1.0f);
        this.b = PZMath.clamp(b, 0.0f, 1.0f);
        this.a = PZMath.clamp(a, 0.0f, 1.0f);
    }

    public Color(Color colorA, Color colorB, float delta) {
        float r = (colorB.r - colorA.r) * delta;
        float g = (colorB.g - colorA.g) * delta;
        float b = (colorB.b - colorA.b) * delta;
        float a = (colorB.a - colorA.a) * delta;
        this.r = colorA.r + r;
        this.g = colorA.g + g;
        this.b = colorA.b + b;
        this.a = colorA.a + a;
    }

    public void setColor(Color colorA, Color colorB, float delta) {
        float r = (colorB.r - colorA.r) * delta;
        float g = (colorB.g - colorA.g) * delta;
        float b = (colorB.b - colorA.b) * delta;
        float a = (colorB.a - colorA.a) * delta;
        this.r = colorA.r + r;
        this.g = colorA.g + g;
        this.b = colorA.b + b;
        this.a = colorA.a + a;
    }

    public Color(int r, int g, int b) {
        this.r = (float)r / 255.0f;
        this.g = (float)g / 255.0f;
        this.b = (float)b / 255.0f;
        this.a = 1.0f;
    }

    public Color(int r, int g, int b, int a) {
        this.r = (float)r / 255.0f;
        this.g = (float)g / 255.0f;
        this.b = (float)b / 255.0f;
        this.a = (float)a / 255.0f;
    }

    public Color(int value) {
        int b = (value & 0xFF0000) >> 16;
        int g = (value & 0xFF00) >> 8;
        int r = value & 0xFF;
        int a = (value & 0xFF000000) >> 24;
        if (a < 0) {
            a += 256;
        }
        if (a == 0) {
            a = 255;
        }
        this.r = (float)r / 255.0f;
        this.g = (float)g / 255.0f;
        this.b = (float)b / 255.0f;
        this.a = (float)a / 255.0f;
    }

    @Deprecated
    public void fromColor(int valueABGR) {
        int b = (valueABGR & 0xFF0000) >> 16;
        int g = (valueABGR & 0xFF00) >> 8;
        int r = valueABGR & 0xFF;
        int a = (valueABGR & 0xFF000000) >> 24;
        if (a < 0) {
            a += 256;
        }
        if (a == 0) {
            a = 255;
        }
        this.r = (float)r / 255.0f;
        this.g = (float)g / 255.0f;
        this.b = (float)b / 255.0f;
        this.a = (float)a / 255.0f;
    }

    public void setABGR(int valueABGR) {
        Color.abgrToColor(valueABGR, this);
    }

    public static Color abgrToColor(int valueABGR, Color result) {
        int a = valueABGR >> 24 & 0xFF;
        int b = valueABGR >> 16 & 0xFF;
        int g = valueABGR >> 8 & 0xFF;
        int r = valueABGR & 0xFF;
        float byteToFloatChannel = 0.003921569f;
        float rc = 0.003921569f * (float)r;
        float gc = 0.003921569f * (float)g;
        float bc = 0.003921569f * (float)b;
        float ac = 0.003921569f * (float)a;
        result.r = rc;
        result.g = gc;
        result.b = bc;
        result.a = ac;
        return result;
    }

    public static int colorToABGR(Color val) {
        return Color.colorToABGR(val.r, val.g, val.b, val.a);
    }

    public static int colorToABGR(ColorInfo val) {
        return Color.colorToABGR(val.r, val.g, val.b, val.a);
    }

    public static int colorToABGR(float r, float g, float b, float a) {
        r = PZMath.clamp(r, 0.0f, 1.0f);
        g = PZMath.clamp(g, 0.0f, 1.0f);
        b = PZMath.clamp(b, 0.0f, 1.0f);
        a = PZMath.clamp(a, 0.0f, 1.0f);
        float floatChannelToByte = 255.0f;
        int byteR = (int)(r * 255.0f);
        int byteG = (int)(g * 255.0f);
        int byteB = (int)(b * 255.0f);
        int byteA = (int)(a * 255.0f);
        return (byteA & 0xFF) << 24 | (byteB & 0xFF) << 16 | (byteG & 0xFF) << 8 | byteR & 0xFF;
    }

    public static int multiplyABGR(int valueABGR, int multiplierABGR) {
        float rc = Color.getRedChannelFromABGR(valueABGR);
        float gc = Color.getGreenChannelFromABGR(valueABGR);
        float bc = Color.getBlueChannelFromABGR(valueABGR);
        float ac = Color.getAlphaChannelFromABGR(valueABGR);
        float mrc = Color.getRedChannelFromABGR(multiplierABGR);
        float mgc = Color.getGreenChannelFromABGR(multiplierABGR);
        float mbc = Color.getBlueChannelFromABGR(multiplierABGR);
        float mac = Color.getAlphaChannelFromABGR(multiplierABGR);
        return Color.colorToABGR(rc * mrc, gc * mgc, bc * mbc, ac * mac);
    }

    public static int multiplyBGR(int valueABGR, int multiplierABGR) {
        float rc = Color.getRedChannelFromABGR(valueABGR);
        float gc = Color.getGreenChannelFromABGR(valueABGR);
        float bc = Color.getBlueChannelFromABGR(valueABGR);
        float ac = Color.getAlphaChannelFromABGR(valueABGR);
        float mrc = Color.getRedChannelFromABGR(multiplierABGR);
        float mgc = Color.getGreenChannelFromABGR(multiplierABGR);
        float mbc = Color.getBlueChannelFromABGR(multiplierABGR);
        return Color.colorToABGR(rc * mrc, gc * mgc, bc * mbc, ac);
    }

    public static int blendBGR(int valueABGR, int targetABGR) {
        float r = Color.getRedChannelFromABGR(valueABGR);
        float g = Color.getGreenChannelFromABGR(valueABGR);
        float b = Color.getBlueChannelFromABGR(valueABGR);
        float a = Color.getAlphaChannelFromABGR(valueABGR);
        float tr = Color.getRedChannelFromABGR(targetABGR);
        float tg = Color.getGreenChannelFromABGR(targetABGR);
        float tb = Color.getBlueChannelFromABGR(targetABGR);
        float ta = Color.getAlphaChannelFromABGR(targetABGR);
        return Color.colorToABGR(r * (1.0f - ta) + tr * ta, g * (1.0f - ta) + tg * ta, b * (1.0f - ta) + tb * ta, a);
    }

    public static int blendABGR(int valueABGR, int targetABGR) {
        float r = Color.getRedChannelFromABGR(valueABGR);
        float g = Color.getGreenChannelFromABGR(valueABGR);
        float b = Color.getBlueChannelFromABGR(valueABGR);
        float a = Color.getAlphaChannelFromABGR(valueABGR);
        float tr = Color.getRedChannelFromABGR(targetABGR);
        float tg = Color.getGreenChannelFromABGR(targetABGR);
        float tb = Color.getBlueChannelFromABGR(targetABGR);
        float ta = Color.getAlphaChannelFromABGR(targetABGR);
        return Color.colorToABGR(r * (1.0f - ta) + tr * ta, g * (1.0f - ta) + tg * ta, b * (1.0f - ta) + tb * ta, a * (1.0f - ta) + ta * ta);
    }

    public static int tintABGR(int targetABGR, int tintABGR) {
        float r = Color.getRedChannelFromABGR(tintABGR);
        float g = Color.getGreenChannelFromABGR(tintABGR);
        float b = Color.getBlueChannelFromABGR(tintABGR);
        float a = Color.getAlphaChannelFromABGR(tintABGR);
        float tr = Color.getRedChannelFromABGR(targetABGR);
        float tg = Color.getGreenChannelFromABGR(targetABGR);
        float tb = Color.getBlueChannelFromABGR(targetABGR);
        float ta = Color.getAlphaChannelFromABGR(targetABGR);
        return Color.colorToABGR(r * a + tr * (1.0f - a), g * a + tg * (1.0f - a), b * a + tb * (1.0f - a), ta);
    }

    public static int lerpABGR(int colA, int colB, float alpha) {
        float r = Color.getRedChannelFromABGR(colA);
        float g = Color.getGreenChannelFromABGR(colA);
        float b = Color.getBlueChannelFromABGR(colA);
        float a = Color.getAlphaChannelFromABGR(colA);
        float tr = Color.getRedChannelFromABGR(colB);
        float tg = Color.getGreenChannelFromABGR(colB);
        float tb = Color.getBlueChannelFromABGR(colB);
        float ta = Color.getAlphaChannelFromABGR(colB);
        return Color.colorToABGR(r * (1.0f - alpha) + tr * alpha, g * (1.0f - alpha) + tg * alpha, b * (1.0f - alpha) + tb * alpha, a * (1.0f - alpha) + ta * alpha);
    }

    public static float getAlphaChannelFromABGR(int valueABGR) {
        int a = valueABGR >> 24 & 0xFF;
        float byteToFloatChannel = 0.003921569f;
        return 0.003921569f * (float)a;
    }

    public static float getBlueChannelFromABGR(int valueABGR) {
        int b = valueABGR >> 16 & 0xFF;
        float byteToFloatChannel = 0.003921569f;
        return 0.003921569f * (float)b;
    }

    public static float getGreenChannelFromABGR(int valueABGR) {
        int g = valueABGR >> 8 & 0xFF;
        float byteToFloatChannel = 0.003921569f;
        return 0.003921569f * (float)g;
    }

    public static float getRedChannelFromABGR(int valueABGR) {
        int r = valueABGR & 0xFF;
        float byteToFloatChannel = 0.003921569f;
        return 0.003921569f * (float)r;
    }

    public static int setAlphaChannelToABGR(int valueABGR, float a) {
        a = PZMath.clamp(a, 0.0f, 1.0f);
        float floatChannelToByte = 255.0f;
        int byteA = (int)(a * 255.0f);
        return (byteA & 0xFF) << 24 | valueABGR & 0xFFFFFF;
    }

    public static int setBlueChannelToABGR(int valueABGR, float b) {
        b = PZMath.clamp(b, 0.0f, 1.0f);
        float floatChannelToByte = 255.0f;
        int byteB = (int)(b * 255.0f);
        return (byteB & 0xFF) << 16 | valueABGR & 0xFF00FFFF;
    }

    public static int setGreenChannelToABGR(int valueABGR, float g) {
        g = PZMath.clamp(g, 0.0f, 1.0f);
        float floatChannelToByte = 255.0f;
        int byteG = (int)(g * 255.0f);
        return (byteG & 0xFF) << 8 | valueABGR & 0xFFFF00FF;
    }

    public static int setRedChannelToABGR(int valueABGR, float r) {
        r = PZMath.clamp(r, 0.0f, 1.0f);
        float floatChannelToByte = 255.0f;
        int byteR = (int)(r * 255.0f);
        return byteR & 0xFF | valueABGR & 0xFFFFFF00;
    }

    public static Color random() {
        return Colors.GetRandomColor();
    }

    public static Color decode(String nm) {
        return new Color(Integer.decode(nm));
    }

    public void add(Color c) {
        this.r += c.r;
        this.g += c.g;
        this.b += c.b;
        this.a += c.a;
    }

    public Color addToCopy(Color c) {
        Color copy = new Color(this.r, this.g, this.b, this.a);
        copy.r += c.r;
        copy.g += c.g;
        copy.b += c.b;
        copy.a += c.a;
        return copy;
    }

    public Color brighter() {
        return this.brighter(0.2f);
    }

    public Color brighter(float scale) {
        this.r += scale;
        this.g += scale;
        this.b += scale;
        return this;
    }

    public Color darker() {
        return this.darker(0.5f);
    }

    public Color darker(float scale) {
        this.r -= scale;
        this.g -= scale;
        this.b -= scale;
        return this;
    }

    public boolean equals(Object other) {
        if (other instanceof Color) {
            Color o = (Color)other;
            return o.r == this.r && o.g == this.g && o.b == this.b && o.a == this.a;
        }
        return false;
    }

    public boolean equalBytes(Color other) {
        if (other == null) {
            return false;
        }
        return this.getRedByte() == other.getRedByte() && this.getBlueByte() == other.getBlueByte() && this.getGreenByte() == other.getGreenByte() && this.getAlphaByte() == other.getAlphaByte();
    }

    public Color set(Color other) {
        this.r = other.r;
        this.g = other.g;
        this.b = other.b;
        this.a = other.a;
        return this;
    }

    public Color set(float r, float g, float b) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = 1.0f;
        return this;
    }

    public Color set(float r, float g, float b, float a) {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
        return this;
    }

    public void save(ByteBuffer output) {
        output.putFloat(this.r);
        output.putFloat(this.g);
        output.putFloat(this.b);
        output.putFloat(this.a);
    }

    public void load(ByteBuffer input, int worldVersion) {
        this.r = input.getFloat();
        this.g = input.getFloat();
        this.b = input.getFloat();
        this.a = input.getFloat();
    }

    public int getAlpha() {
        return (int)(this.a * 255.0f);
    }

    public float getAlphaFloat() {
        return this.a;
    }

    public float getRedFloat() {
        return this.r;
    }

    public float getGreenFloat() {
        return this.g;
    }

    public float getBlueFloat() {
        return this.b;
    }

    public int getAlphaByte() {
        return (int)(this.a * 255.0f);
    }

    public int getBlue() {
        return (int)(this.b * 255.0f);
    }

    public int getBlueByte() {
        return (int)(this.b * 255.0f);
    }

    public int getGreen() {
        return (int)(this.g * 255.0f);
    }

    public int getGreenByte() {
        return (int)(this.g * 255.0f);
    }

    public int getRed() {
        return (int)(this.r * 255.0f);
    }

    public int getRedByte() {
        return (int)(this.r * 255.0f);
    }

    public int hashCode() {
        return (int)(this.r + this.g + this.b + this.a) * 255;
    }

    public Color multiply(Color c) {
        return new Color(this.r * c.r, this.g * c.g, this.b * c.b, this.a * c.a);
    }

    public Color scale(float value) {
        this.r *= value;
        this.g *= value;
        this.b *= value;
        this.a *= value;
        return this;
    }

    public Color scaleCopy(float value) {
        Color copy = new Color(this.r, this.g, this.b, this.a);
        copy.r *= value;
        copy.g *= value;
        copy.b *= value;
        copy.a *= value;
        return copy;
    }

    public String toString() {
        return "Color (" + this.r + "," + this.g + "," + this.b + "," + this.a + ")";
    }

    public void interp(Color to, float delta, Color dest) {
        float r = to.r - this.r;
        float g = to.g - this.g;
        float b = to.b - this.b;
        float a = to.a - this.a;
        dest.r = this.r + (r *= delta);
        dest.g = this.g + (g *= delta);
        dest.b = this.b + (b *= delta);
        dest.a = this.a + (a *= delta);
    }

    public void changeHSBValue(float hFactor, float sFactor, float bFactor) {
        float[] hsb = java.awt.Color.RGBtoHSB(this.getRedByte(), this.getGreenByte(), this.getBlueByte(), null);
        int newValue = java.awt.Color.HSBtoRGB(hsb[0] * hFactor, hsb[1] * sFactor, hsb[2] * bFactor);
        this.r = (float)(newValue >> 16 & 0xFF) / 255.0f;
        this.g = (float)(newValue >> 8 & 0xFF) / 255.0f;
        this.b = (float)(newValue & 0xFF) / 255.0f;
    }

    public static Color HSBtoRGB(float hue, float saturation, float brightness, Color result) {
        int r = 0;
        int g = 0;
        int b = 0;
        if (saturation == 0.0f) {
            g = b = (int)(brightness * 255.0f + 0.5f);
            r = b;
        } else {
            float h = (hue - (float)Math.floor(hue)) * 6.0f;
            float f = h - (float)Math.floor(h);
            float p = brightness * (1.0f - saturation);
            float q = brightness * (1.0f - saturation * f);
            float t = brightness * (1.0f - saturation * (1.0f - f));
            switch ((int)h) {
                case 0: {
                    r = (int)(brightness * 255.0f + 0.5f);
                    g = (int)(t * 255.0f + 0.5f);
                    b = (int)(p * 255.0f + 0.5f);
                    break;
                }
                case 1: {
                    r = (int)(q * 255.0f + 0.5f);
                    g = (int)(brightness * 255.0f + 0.5f);
                    b = (int)(p * 255.0f + 0.5f);
                    break;
                }
                case 2: {
                    r = (int)(p * 255.0f + 0.5f);
                    g = (int)(brightness * 255.0f + 0.5f);
                    b = (int)(t * 255.0f + 0.5f);
                    break;
                }
                case 3: {
                    r = (int)(p * 255.0f + 0.5f);
                    g = (int)(q * 255.0f + 0.5f);
                    b = (int)(brightness * 255.0f + 0.5f);
                    break;
                }
                case 4: {
                    r = (int)(t * 255.0f + 0.5f);
                    g = (int)(p * 255.0f + 0.5f);
                    b = (int)(brightness * 255.0f + 0.5f);
                    break;
                }
                case 5: {
                    r = (int)(brightness * 255.0f + 0.5f);
                    g = (int)(p * 255.0f + 0.5f);
                    b = (int)(q * 255.0f + 0.5f);
                }
            }
        }
        return result.set((float)r / 255.0f, (float)g / 255.0f, (float)b / 255.0f);
    }

    public static Color HSBtoRGB(float hue, float saturation, float brightness) {
        return Color.HSBtoRGB(hue, saturation, brightness, new Color());
    }

    public void saveCompactNoAlpha(ByteBuffer output) throws IOException {
        this.saveCompact(output, false);
    }

    public void loadCompactNoAlpha(ByteBuffer input) throws IOException {
        this.loadCompact(input, false);
    }

    public void saveCompact(ByteBuffer output) throws IOException {
        this.saveCompact(output, true);
    }

    public void loadCompact(ByteBuffer input) throws IOException {
        this.loadCompact(input, true);
    }

    private void saveCompact(ByteBuffer output, boolean saveAlpha) throws IOException {
        output.put(Bits.packFloatUnitToByte(this.r));
        output.put(Bits.packFloatUnitToByte(this.g));
        output.put(Bits.packFloatUnitToByte(this.b));
        if (saveAlpha) {
            output.put(Bits.packFloatUnitToByte(this.a));
        }
    }

    private void loadCompact(ByteBuffer input, boolean loadAlpha) throws IOException {
        this.r = Bits.unpackByteToFloatUnit(input.get());
        this.g = Bits.unpackByteToFloatUnit(input.get());
        this.b = Bits.unpackByteToFloatUnit(input.get());
        if (loadAlpha) {
            this.a = Bits.unpackByteToFloatUnit(input.get());
        }
    }

    // === PZFB — Video Framebuffer Extension ===
    // Multi-framebuffer support. All GL calls via RenderThread.queueInvokeOnRenderContext().
    // No reflection. No manual glGenTextures. Uses PZ's own Texture GL allocation.
    // Thread-safe: fresh ByteBuffer per update (copy-on-queue).

    private static final java.util.concurrent.ConcurrentHashMap<zombie.core.textures.Texture, Boolean> _fbState =
        new java.util.concurrent.ConcurrentHashMap<>();
    private static final String PZFB_VERSION = "1.7.0";

    public static String fbPing() {
        return "PZFB " + PZFB_VERSION;
    }

    public static String fbVersion() {
        return PZFB_VERSION;
    }

    public static zombie.core.textures.Texture fbCreate(int width, int height) {
        // flags=3: bit 0 = min nearest, bit 1 = mag nearest (pixel-perfect for emulators)
        zombie.core.textures.Texture tex = new zombie.core.textures.Texture(width, height, 3);
        _fbState.put(tex, Boolean.TRUE);
        return tex;
    }

    public static zombie.core.textures.Texture fbCreateLinear(int width, int height) {
        // flags=0: linear filtering (smoother, better for video playback)
        zombie.core.textures.Texture tex = new zombie.core.textures.Texture(width, height, 0);
        _fbState.put(tex, Boolean.TRUE);
        return tex;
    }

    public static boolean fbIsReady(zombie.core.textures.Texture tex) {
        if (tex == null) return false;
        if (!Boolean.TRUE.equals(_fbState.get(tex))) return false;
        // TextureID.getID() returns -1 until the render thread allocates the GL texture.
        // The Texture constructor queues GL allocation; our check runs after.
        return tex.getTextureId().getID() != -1;
    }

    public static void fbFill(zombie.core.textures.Texture tex, int r, int g, int b, int a) {
        if (!fbIsReady(tex)) return;
        final int w = tex.getWidth();
        final int h = tex.getHeight();
        final java.nio.ByteBuffer buf = java.nio.ByteBuffer.allocateDirect(w * h * 4);
        for (int i = 0; i < w * h; i++) {
            buf.put((byte) r);
            buf.put((byte) g);
            buf.put((byte) b);
            buf.put((byte) a);
        }
        buf.flip();
        final int glId = tex.getTextureId().getID();
        zombie.core.opengl.RenderThread.queueInvokeOnRenderContext(new Runnable() {
            public void run() {
                org.lwjgl.opengl.GL11.glBindTexture(0x0DE1, glId);
                org.lwjgl.opengl.GL11.glTexSubImage2D(
                    0x0DE1, 0, 0, 0, w, h, 0x1908, 0x1401, buf
                );
            }
        });
    }

    public static boolean fbLoadRaw(zombie.core.textures.Texture tex, String path) {
        if (!fbIsReady(tex)) return false;
        try {
            java.io.File file = new java.io.File(path);
            if (!file.exists()) return false;
            final int w = tex.getWidth();
            final int h = tex.getHeight();
            byte[] data = java.nio.file.Files.readAllBytes(file.toPath());
            if (data.length != w * h * 4) return false;
            final java.nio.ByteBuffer buf = java.nio.ByteBuffer.allocateDirect(w * h * 4);
            buf.put(data);
            buf.flip();
            final int glId = tex.getTextureId().getID();
            zombie.core.opengl.RenderThread.queueInvokeOnRenderContext(new Runnable() {
                public void run() {
                    org.lwjgl.opengl.GL11.glBindTexture(0x0DE1, glId);
                    org.lwjgl.opengl.GL11.glTexSubImage2D(
                        0x0DE1, 0, 0, 0, w, h, 0x1908, 0x1401, buf
                    );
                }
            });
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static boolean fbLoadRawFrame(zombie.core.textures.Texture tex, String path, int frameIndex) {
        if (!fbIsReady(tex)) return false;
        try {
            final int w = tex.getWidth();
            final int h = tex.getHeight();
            final int frameSize = w * h * 4;
            final long offset = (long) frameIndex * frameSize;
            java.io.RandomAccessFile raf = new java.io.RandomAccessFile(path, "r");
            if (offset + frameSize > raf.length()) {
                raf.close();
                return false;
            }
            byte[] data = new byte[frameSize];
            raf.seek(offset);
            raf.readFully(data);
            raf.close();
            final java.nio.ByteBuffer buf = java.nio.ByteBuffer.allocateDirect(frameSize);
            buf.put(data);
            buf.flip();
            final int glId = tex.getTextureId().getID();
            zombie.core.opengl.RenderThread.queueInvokeOnRenderContext(new Runnable() {
                public void run() {
                    org.lwjgl.opengl.GL11.glBindTexture(0x0DE1, glId);
                    org.lwjgl.opengl.GL11.glTexSubImage2D(
                        0x0DE1, 0, 0, 0, w, h, 0x1908, 0x1401, buf
                    );
                }
            });
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static long fbFileSize(String path) {
        try {
            java.io.File file = new java.io.File(path);
            if (!file.exists()) return -1;
            return file.length();
        } catch (Exception e) {
            return -1;
        }
    }

    public static void fbDestroy(zombie.core.textures.Texture tex) {
        if (tex == null) return;
        _fbState.remove(tex);
        if (tex.getTextureId().getID() != -1) {
            zombie.core.opengl.RenderThread.queueInvokeOnRenderContext(new Runnable() {
                public void run() {
                    tex.getTextureId().destroy();
                }
            });
        }
    }
    // === PZFB Audio — Direct FMOD playback (bypasses sound bank system) ===

    private static long _fbAudioSound = 0;
    private static long _fbAudioChannel = 0;

    public static boolean fbAudioLoad(String path) {
        fbAudioStop();
        try {
            java.io.File f = new java.io.File(path);
            if (!f.exists()) return false;
            // flags: FMOD_LOOP_OFF(0x1) | FMOD_2D(0x8) | FMOD_CREATESTREAM(0x80) | FMOD_ACCURATETIME(0x2000)
            // CREATESTREAM: plays from disk without loading entire file into memory
            // ACCURATETIME: enables seeking within streamed sounds
            long sound = fmod.javafmod.FMOD_System_CreateSound(path, 0x2089);
            if (sound == 0) return false;
            _fbAudioSound = sound;
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static boolean fbAudioPlay() {
        if (_fbAudioSound == 0) return false;
        try {
            if (_fbAudioChannel != 0) {
                try { fmod.javafmod.FMOD_Channel_Stop(_fbAudioChannel); } catch (Exception ignore) {}
                _fbAudioChannel = 0;
            }
            long channel = fmod.javafmod.FMOD_System_PlaySound(_fbAudioSound, false);
            if (channel == 0) return false;
            _fbAudioChannel = channel;
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static void fbAudioPause() {
        if (_fbAudioChannel != 0) {
            try { fmod.javafmod.FMOD_Channel_SetPaused(_fbAudioChannel, true); } catch (Exception ignore) {}
        }
    }

    public static void fbAudioResume() {
        if (_fbAudioChannel != 0) {
            try { fmod.javafmod.FMOD_Channel_SetPaused(_fbAudioChannel, false); } catch (Exception ignore) {}
        }
    }

    public static void fbAudioStop() {
        if (_fbAudioChannel != 0) {
            try { fmod.javafmod.FMOD_Channel_Stop(_fbAudioChannel); } catch (Exception ignore) {}
            _fbAudioChannel = 0;
        }
        if (_fbAudioSound != 0) {
            try { fmod.javafmod.FMOD_Sound_Release(_fbAudioSound); } catch (Exception ignore) {}
            _fbAudioSound = 0;
        }
    }

    public static void fbAudioSetVolume(float volume) {
        if (_fbAudioChannel != 0) {
            try { fmod.javafmod.FMOD_Channel_SetVolume(_fbAudioChannel, volume); } catch (Exception ignore) {}
        }
    }

    public static void fbAudioSeek(long positionMs) {
        if (_fbAudioChannel != 0) {
            try { fmod.javafmod.FMOD_Channel_SetPosition(_fbAudioChannel, positionMs); } catch (Exception ignore) {}
        }
    }

    // Reliable seek: stop current channel, play fresh from position (paused), then unpause.
    // Avoids issues with SetPosition on active channels.
    public static boolean fbAudioPlayFrom(long positionMs) {
        if (_fbAudioSound == 0) return false;
        try {
            // Stop current channel
            if (_fbAudioChannel != 0) {
                try { fmod.javafmod.FMOD_Channel_Stop(_fbAudioChannel); } catch (Exception ignore) {}
                _fbAudioChannel = 0;
            }
            // Create new channel, start paused
            long channel = fmod.javafmod.FMOD_System_PlaySound(_fbAudioSound, true);
            if (channel == 0) return false;
            _fbAudioChannel = channel;
            // Seek while paused
            if (positionMs > 0) {
                fmod.javafmod.FMOD_Channel_SetPosition(channel, positionMs);
            }
            // Unpause
            fmod.javafmod.FMOD_Channel_SetPaused(channel, false);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // Diagnostic: test what SetPosition actually does
    public static String fbAudioSeekDiag(long positionMs) {
        if (_fbAudioChannel == 0) return "no_channel";
        try {
            long beforeMs = fmod.javafmod.FMOD_Channel_GetPosition(_fbAudioChannel, 1);
            int result = fmod.javafmod.FMOD_Channel_SetPosition(_fbAudioChannel, positionMs);
            long afterMs = fmod.javafmod.FMOD_Channel_GetPosition(_fbAudioChannel, 1);
            return "before=" + beforeMs + " target=" + positionMs + " result=" + result + " after=" + afterMs;
        } catch (Exception e) {
            return "error=" + e.getMessage();
        }
    }

    public static long fbAudioGetPosition() {
        if (_fbAudioChannel == 0) return 0;
        try {
            return fmod.javafmod.FMOD_Channel_GetPosition(_fbAudioChannel, 1); // FMOD_TIMEUNIT_MS
        } catch (Exception e) {
            return 0;
        }
    }

    public static long fbAudioGetLength() {
        if (_fbAudioSound == 0) return 0;
        try {
            return fmod.javafmod.FMOD_Sound_GetLength(_fbAudioSound, 1); // FMOD_TIMEUNIT_MS
        } catch (Exception e) {
            return 0;
        }
    }

    public static boolean fbAudioIsPlaying() {
        if (_fbAudioChannel == 0) return false;
        try {
            return fmod.javafmod.FMOD_Channel_IsPlaying(_fbAudioChannel);
        } catch (Exception e) {
            return false;
        }
    }

    // === PZFB Convert — FFmpeg video conversion via ProcessBuilder ===

    // If true, we're inside a pressure-vessel container and must use flatpak-spawn --host
    private static boolean _fbUseHostSpawn = false;
    private static boolean _fbHostSpawnChecked = false;

    private static boolean useHostSpawn() {
        if (!_fbHostSpawnChecked) {
            _fbHostSpawnChecked = true;
            _fbUseHostSpawn = new java.io.File("/usr/bin/flatpak-spawn").exists()
                && System.getenv("PRESSURE_VESSEL_RUNTIME") != null;
        }
        return _fbUseHostSpawn;
    }

    // Create a ProcessBuilder that works inside pressure-vessel containers.
    // Uses host dynamic linker + LD_LIBRARY_PATH for host lib directories.
    // mergeStderr: true for commands where we read text output (ffprobe, ffmpeg -version)
    //             false for streaming where stdout carries binary data (raw video/audio)
    private static ProcessBuilder buildHostProcess(boolean mergeStderr, String... args) {
        ProcessBuilder pb;
        if (useHostSpawn()) {
            String hostLinker = "/run/host/lib64/ld-linux-x86-64.so.2";
            // Absolute paths (e.g. game binaries) use as-is; relative names resolve on host
            String hostBin = args[0].startsWith("/") ? args[0] : "/run/host/usr/bin/" + args[0];
            String[] cmd = new String[args.length + 1];
            cmd[0] = hostLinker;
            cmd[1] = hostBin;
            for (int i = 1; i < args.length; i++) {
                cmd[i + 1] = args[i];
            }
            pb = new ProcessBuilder(cmd);
            pb.environment().put("LD_LIBRARY_PATH", buildHostLibPath());
        } else {
            pb = new ProcessBuilder(args);
        }
        pb.environment().remove("LD_PRELOAD");
        if (mergeStderr) {
            pb.redirectErrorStream(true);
        } else {
            // Discard stderr so it doesn't block the process
            pb.redirectError(ProcessBuilder.Redirect.DISCARD);
        }
        return pb;
    }

    // Convenience: merge stderr (for text commands like ffprobe, ffmpeg -version)
    private static ProcessBuilder buildHostProcess(String... args) {
        return buildHostProcess(true, args);
    }

    // Split a command-line string by whitespace, respecting "..." quoted tokens.
    // Backward compatible: unquoted strings split identically to String.split("\\s+").
    private static java.util.List<String> splitQuotedArgs(String s) {
        java.util.ArrayList<String> args = new java.util.ArrayList<>();
        int len = s.length();
        int i = 0;
        while (i < len) {
            while (i < len && Character.isWhitespace(s.charAt(i))) i++;
            if (i >= len) break;
            StringBuilder arg = new StringBuilder();
            if (s.charAt(i) == '"') {
                i++; // skip opening quote
                while (i < len && s.charAt(i) != '"') { arg.append(s.charAt(i)); i++; }
                if (i < len) i++; // skip closing quote
            } else {
                while (i < len && !Character.isWhitespace(s.charAt(i))) { arg.append(s.charAt(i)); i++; }
            }
            if (arg.length() > 0) args.add(arg.toString());
        }
        return args;
    }

    // Read last N non-empty lines from a file (for stderr diagnostics).
    private static String readLastLines(java.io.File f, int maxLines) {
        if (f == null || !f.exists() || f.length() == 0) return "";
        try {
            byte[] data = java.nio.file.Files.readAllBytes(f.toPath());
            if (data.length > 8192) {
                byte[] tail = new byte[8192];
                System.arraycopy(data, data.length - 8192, tail, 0, 8192);
                data = tail;
            }
            String text = new String(data, java.nio.charset.StandardCharsets.UTF_8);
            String[] lines = text.split("\\r?\\n");
            StringBuilder sb = new StringBuilder();
            int start = Math.max(0, lines.length - maxLines);
            for (int j = start; j < lines.length; j++) {
                String line = lines[j].trim();
                if (!line.isEmpty()) {
                    if (sb.length() > 0) sb.append("; ");
                    sb.append(line);
                }
            }
            return sb.toString();
        } catch (Exception e) {
            return "";
        }
    }

    // Build comprehensive LD_LIBRARY_PATH from host's /etc/ld.so.conf + common dirs
    private static String _cachedHostLibPath = null;
    private static String buildHostLibPath() {
        if (_cachedHostLibPath != null) return _cachedHostLibPath;
        java.util.LinkedHashSet<String> paths = new java.util.LinkedHashSet<>();
        // Read host's ld.so.conf
        try {
            readLdConf("/run/host/etc/ld.so.conf", paths);
        } catch (Exception ignore) {}
        // Always include standard paths
        String[] standard = {"/lib64", "/usr/lib64", "/usr/lib", "/lib",
            "/usr/local/lib64", "/usr/local/lib"};
        for (String s : standard) paths.add("/run/host" + s);
        // Common private library subdirectories
        String[] privDirs = {"pulseaudio", "pipewire-0.3", "alsa-lib"};
        for (String d : privDirs) {
            String p = "/run/host/usr/lib64/" + d;
            if (new java.io.File(p).isDirectory()) paths.add(p);
        }
        StringBuilder sb = new StringBuilder();
        for (String p : paths) {
            if (sb.length() > 0) sb.append(":");
            sb.append(p);
        }
        _cachedHostLibPath = sb.toString();
        return _cachedHostLibPath;
    }

    // Parse ld.so.conf, following includes
    private static void readLdConf(String path, java.util.LinkedHashSet<String> paths) {
        try {
            java.io.File f = new java.io.File(path);
            if (!f.exists()) return;
            java.io.BufferedReader br = new java.io.BufferedReader(new java.io.FileReader(f));
            String line;
            while ((line = br.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty() || line.startsWith("#")) continue;
                if (line.startsWith("include ")) {
                    String pattern = line.substring(8).trim();
                    // Resolve relative to the conf file's directory
                    String dir = f.getParent();
                    if (!pattern.startsWith("/")) pattern = dir + "/" + pattern;
                    // Simple glob: only handle *.conf in a directory
                    java.io.File globDir = new java.io.File(pattern).getParentFile();
                    if (globDir != null && globDir.isDirectory()) {
                        java.io.File[] files = globDir.listFiles();
                        if (files != null) {
                            for (java.io.File cf : files) {
                                if (cf.getName().endsWith(".conf")) {
                                    readLdConf(cf.getAbsolutePath(), paths);
                                }
                            }
                        }
                    }
                } else {
                    // It's a library path — prefix with /run/host
                    paths.add("/run/host" + line);
                }
            }
            br.close();
        } catch (Exception ignore) {}
    }

    private static volatile int _fbConvertStatus = 0; // 0=idle 1=running 2=done 3=error
    private static volatile String _fbConvertError = "";

    public static boolean fbConvertStart(String inputPath, String outputDir, int width, int height) {
        if (_fbConvertStatus == 1) return false;
        java.io.File inFile = new java.io.File(inputPath);
        if (!inFile.exists()) {
            _fbConvertError = "Input file not found: " + inputPath;
            _fbConvertStatus = 3;
            return false;
        }
        _fbConvertStatus = 1;
        _fbConvertError = "";
        final String inPath = inputPath;
        final String outDir = outputDir;
        final int w = width;
        final int h = height;
        new Thread(new Runnable() {
            public void run() {
                try {
                    java.io.File dir = new java.io.File(outDir);
                    dir.mkdirs();
                    String rawPath = outDir + java.io.File.separator + "video.raw";
                    String audioPath = outDir + java.io.File.separator + "audio.ogg";

                    // Convert video to raw RGBA
                    ProcessBuilder pb1 = buildHostProcess(
                        "ffmpeg", "-y", "-i", inPath,
                        "-vf", "scale=" + w + ":" + h,
                        "-pix_fmt", "rgba", "-f", "rawvideo", rawPath
                    );
                    Process p1 = pb1.start();
                    // Drain output to prevent blocking
                    java.io.InputStream is1 = p1.getInputStream();
                    byte[] drain = new byte[4096];
                    while (is1.read(drain) != -1) {}
                    int exit1 = p1.waitFor();
                    if (exit1 != 0) {
                        _fbConvertError = "ffmpeg video conversion failed (exit " + exit1 + ")";
                        _fbConvertStatus = 3;
                        return;
                    }

                    // Extract audio (non-fatal if fails — video may have no audio)
                    boolean hasAudio = false;
                    try {
                        ProcessBuilder pb2 = buildHostProcess(
                            "ffmpeg", "-y", "-i", inPath,
                            "-vn", "-acodec", "libvorbis", "-q:a", "5", audioPath
                        );
                        Process p2 = pb2.start();
                        java.io.InputStream is2 = p2.getInputStream();
                        while (is2.read(drain) != -1) {}
                        int exit2 = p2.waitFor();
                        hasAudio = (exit2 == 0) && new java.io.File(audioPath).length() > 0;
                    } catch (Exception ignore) {}

                    // Get FPS via ffprobe
                    String fpsStr = "24";
                    try {
                        ProcessBuilder pb3 = buildHostProcess(
                            "ffprobe", "-v", "0", "-select_streams", "v",
                            "-of", "csv=p=0", "-show_entries", "stream=r_frame_rate", inPath
                        );
                        Process p3 = pb3.start();
                        java.io.BufferedReader br = new java.io.BufferedReader(
                            new java.io.InputStreamReader(p3.getInputStream())
                        );
                        String line = br.readLine();
                        p3.waitFor();
                        if (line != null && !line.trim().isEmpty()) {
                            // May have multiple streams, take first; may be "24000/1001"
                            String raw = line.trim().split(",")[0].trim();
                            if (raw.contains("/")) {
                                String[] parts = raw.split("/");
                                double num = Double.parseDouble(parts[0]);
                                double den = Double.parseDouble(parts[1]);
                                if (den > 0) fpsStr = String.valueOf(num / den);
                            } else {
                                fpsStr = raw;
                            }
                        }
                    } catch (Exception ignore) {}

                    // Calculate frame count
                    java.io.File rawFile = new java.io.File(rawPath);
                    long frames = rawFile.length() / ((long) w * h * 4);

                    // Write meta.txt
                    java.io.FileWriter fw = new java.io.FileWriter(
                        outDir + java.io.File.separator + "meta.txt"
                    );
                    fw.write("width=" + w + "\n");
                    fw.write("height=" + h + "\n");
                    fw.write("frames=" + frames + "\n");
                    fw.write("fps=" + fpsStr + "\n");
                    fw.write("audio=" + (hasAudio ? audioPath : "") + "\n");
                    fw.write("raw=" + rawPath + "\n");
                    fw.close();

                    _fbConvertStatus = 2;
                } catch (Exception e) {
                    _fbConvertError = e.getMessage();
                    _fbConvertStatus = 3;
                }
            }
        }).start();
        return true;
    }

    public static int fbConvertStatus() {
        return _fbConvertStatus;
    }

    public static String fbConvertError() {
        return _fbConvertError;
    }

    public static void fbConvertReset() {
        if (_fbConvertStatus != 1) {
            _fbConvertStatus = 0;
            _fbConvertError = "";
        }
    }

    public static boolean fbFFmpegAvailable() {
        try {
            ProcessBuilder pb = buildHostProcess("ffmpeg", "-version");
            Process p = pb.start();
            java.io.InputStream is = p.getInputStream();
            byte[] drain = new byte[4096];
            while (is.read(drain) != -1) {}
            int exit = p.waitFor();
            return exit == 0;
        } catch (Exception e) {
            return false;
        }
    }

    public static String fbFFmpegDiag() {
        StringBuilder sb = new StringBuilder();
        sb.append("pv=").append(useHostSpawn()).append("; ");
        try {
            ProcessBuilder pb = buildHostProcess("ffmpeg", "-version");
            Process p = pb.start();
            java.io.InputStream is = p.getInputStream();
            byte[] buf = new byte[200];
            int n = is.read(buf);
            int exit = p.waitFor();
            String out = n > 0 ? new String(buf, 0, Math.min(n, 80)).split("\n")[0] : "";
            sb.append("exit=").append(exit).append("; out=").append(out);
        } catch (Exception e) {
            sb.append("err=").append(e.getClass().getSimpleName()).append(": ").append(e.getMessage());
        }
        return sb.toString();
    }

    // === PZFB Stream — Streaming video/audio playback ===

    // Stream state
    private static Process _fbStreamVideoProc = null;
    private static Process _fbStreamAudioProc = null;
    private static Thread _fbStreamVideoThread = null;
    private static Thread _fbStreamAudioThread = null;
    private static volatile int _fbStreamStatus = 0; // 0=idle 1=probing 2=buffering 3=ready 4=done 5=error
    private static volatile String _fbStreamError = "";
    private static String _fbStreamInputPath = null;

    // Video info (from ffprobe)
    private static int _fbStreamWidth = 0;
    private static int _fbStreamHeight = 0;
    private static double _fbStreamFps = 24;
    private static double _fbStreamDuration = 0;

    // Video ring buffer
    private static final Object _fbStreamLock = new Object();
    private static byte[][] _fbStreamBuffer = null;
    private static int _fbStreamBufCapacity = 300;
    private static volatile int _fbStreamBufStart = 0;
    private static volatile int _fbStreamBufCount = 0;
    private static int _fbStreamFrameSize = 0;
    private static volatile boolean _fbStreamVideoStop = false; // signal writer thread to exit

    // Audio
    private static String _fbStreamAudioPath = null;
    private static volatile boolean _fbStreamAudioReady = false;
    private static volatile boolean _fbStreamAudioDone = false;

    public static void fbStreamStart(String inputPath, double qualityScale, int bufferFrames) {
        fbGameStop();
        fbStreamStop();
        _fbStreamInputPath = inputPath;
        _fbStreamBufCapacity = (bufferFrames > 10) ? bufferFrames : 60;
        _fbStreamStatus = 1; // probing
        _fbStreamError = "";

        new Thread(new Runnable() {
            public void run() {
                try {
                    // 1. Probe source video with ffprobe
                    ProcessBuilder pbProbe = buildHostProcess(
                        "ffprobe", "-v", "0", "-select_streams", "v:0",
                        "-show_entries", "stream=width,height,r_frame_rate",
                        "-of", "csv=p=0", inputPath
                    );
                    Process probeProc = pbProbe.start();
                    java.io.BufferedReader probeReader = new java.io.BufferedReader(
                        new java.io.InputStreamReader(probeProc.getInputStream())
                    );
                    String probeLine = probeReader.readLine();
                    probeProc.waitFor();

                    if (probeLine == null || probeLine.trim().isEmpty()) {
                        _fbStreamError = "ffprobe returned no data";
                        _fbStreamStatus = 5;
                        return;
                    }

                    // Parse: "1920,1080,24000/1001"
                    String[] parts = probeLine.trim().split(",");
                    if (parts.length < 3) {
                        _fbStreamError = "ffprobe unexpected format: " + probeLine;
                        _fbStreamStatus = 5;
                        return;
                    }
                    int srcW = Integer.parseInt(parts[0].trim());
                    int srcH = Integer.parseInt(parts[1].trim());
                    String fpsRaw = parts[2].trim();

                    // Parse FPS (may be fraction)
                    double fps = 24;
                    if (fpsRaw.contains("/")) {
                        String[] fp = fpsRaw.split("/");
                        double num = Double.parseDouble(fp[0]);
                        double den = Double.parseDouble(fp[1]);
                        if (den > 0) fps = num / den;
                    } else {
                        fps = Double.parseDouble(fpsRaw);
                    }

                    // 2. Get duration
                    ProcessBuilder pbDur = buildHostProcess(
                        "ffprobe", "-v", "0",
                        "-show_entries", "format=duration",
                        "-of", "csv=p=0", inputPath
                    );
                    Process durProc = pbDur.start();
                    java.io.BufferedReader durReader = new java.io.BufferedReader(
                        new java.io.InputStreamReader(durProc.getInputStream())
                    );
                    String durLine = durReader.readLine();
                    durProc.waitFor();
                    double duration = 0;
                    if (durLine != null && !durLine.trim().isEmpty()) {
                        try { duration = Double.parseDouble(durLine.trim()); } catch (Exception ignore) {}
                    }

                    // 3. Compute scaled dimensions from source * quality scale
                    double scale = Math.max(0.1, Math.min(1.0, qualityScale));
                    int scaledW = (int) Math.round(srcW * scale);
                    int scaledH = (int) Math.round(srcH * scale);
                    // Ensure even (ffmpeg requires even dimensions)
                    scaledW = scaledW + (scaledW % 2);
                    scaledH = scaledH + (scaledH % 2);

                    _fbStreamWidth = scaledW;
                    _fbStreamHeight = scaledH;
                    _fbStreamFps = fps;
                    _fbStreamDuration = duration;
                    _fbStreamFrameSize = scaledW * scaledH * 4;

                    // 4. Allocate ring buffer
                    synchronized (_fbStreamLock) {
                        _fbStreamBuffer = new byte[_fbStreamBufCapacity][];
                        _fbStreamBufStart = 0;
                        _fbStreamBufCount = 0;
                    }

                    _fbStreamStatus = 2; // buffering

                    // 5. Start audio streaming (WAV temp file)
                    _fbStreamAudioReady = false;
                    _fbStreamAudioDone = false;
                    _fbStreamAudioPath = System.getProperty("java.io.tmpdir")
                        + java.io.File.separator + "pzvp_audio_" + System.currentTimeMillis() + ".wav";

                    _fbStreamAudioThread = new Thread(new Runnable() {
                        public void run() {
                            try {
                                // Write WAV header
                                java.io.RandomAccessFile wavFile = new java.io.RandomAccessFile(_fbStreamAudioPath, "rw");
                                int sampleRate = 48000;
                                int channels = 2;
                                int bitsPerSample = 16;
                                int byteRate = sampleRate * channels * bitsPerSample / 8;
                                int blockAlign = channels * bitsPerSample / 8;
                                int dataSize = 0x7FFFFFFF; // streaming placeholder

                                // RIFF header
                                wavFile.writeBytes("RIFF");
                                wavFile.writeInt(Integer.reverseBytes(dataSize + 36)); // file size - 8
                                wavFile.writeBytes("WAVE");
                                // fmt chunk
                                wavFile.writeBytes("fmt ");
                                wavFile.writeInt(Integer.reverseBytes(16)); // chunk size
                                wavFile.writeShort(Short.reverseBytes((short) 1)); // PCM format
                                wavFile.writeShort(Short.reverseBytes((short) channels));
                                wavFile.writeInt(Integer.reverseBytes(sampleRate));
                                wavFile.writeInt(Integer.reverseBytes(byteRate));
                                wavFile.writeShort(Short.reverseBytes((short) blockAlign));
                                wavFile.writeShort(Short.reverseBytes((short) bitsPerSample));
                                // data chunk
                                wavFile.writeBytes("data");
                                wavFile.writeInt(Integer.reverseBytes(dataSize));

                                // Start ffmpeg for audio (mergeStderr=false: stdout carries binary PCM)
                                ProcessBuilder pbAudio = buildHostProcess(false,
                                    "ffmpeg", "-i", inputPath,
                                    "-vn", "-ac", String.valueOf(channels),
                                    "-ar", String.valueOf(sampleRate),
                                    "-f", "s16le", "pipe:1"
                                );
                                _fbStreamAudioProc = pbAudio.start();
                                java.io.InputStream audioIn = _fbStreamAudioProc.getInputStream();

                                byte[] audioBuf = new byte[8192];
                                long totalWritten = 0;
                                int n;
                                while ((n = audioIn.read(audioBuf)) != -1) {
                                    wavFile.write(audioBuf, 0, n);
                                    totalWritten += n;
                                    if (!_fbStreamAudioReady && totalWritten >= sampleRate * channels * 2 * 2) {
                                        // ~2 seconds of audio data
                                        _fbStreamAudioReady = true;
                                    }
                                }

                                // Update WAV header with actual size
                                long actualDataSize = totalWritten;
                                wavFile.seek(4);
                                wavFile.writeInt(Integer.reverseBytes((int)(actualDataSize + 36)));
                                wavFile.seek(40);
                                wavFile.writeInt(Integer.reverseBytes((int) actualDataSize));
                                wavFile.close();

                                _fbStreamAudioDone = true;
                                if (!_fbStreamAudioReady) _fbStreamAudioReady = true;
                            } catch (Exception e) {
                                // Audio failure is non-fatal
                                _fbStreamAudioDone = true;
                            }
                        }
                    });
                    _fbStreamAudioThread.setDaemon(true);
                    _fbStreamAudioThread.start();

                    // 6. Start video streaming
                    startVideoStream(inputPath, scaledW, scaledH, 0);

                } catch (Exception e) {
                    _fbStreamError = "Stream start failed: " + e.getMessage();
                    _fbStreamStatus = 5;
                }
            }
        }).start();
    }

    private static void startVideoStream(String inputPath, int w, int h, double seekSec) {
        // Signal old writer thread to exit
        _fbStreamVideoStop = true;
        if (_fbStreamVideoProc != null) {
            _fbStreamVideoProc.destroyForcibly();
            _fbStreamVideoProc = null;
        }
        if (_fbStreamVideoThread != null) {
            try { _fbStreamVideoThread.join(2000); } catch (Exception ignore) {}
            _fbStreamVideoThread = null;
        }
        _fbStreamVideoStop = false;

        try {
            // Build ffmpeg command
            java.util.ArrayList<String> args = new java.util.ArrayList<>();
            if (seekSec > 0) {
                args.add("ffmpeg");
                args.add("-ss");
                args.add(String.valueOf(seekSec));
                args.add("-i");
                args.add(inputPath);
            } else {
                args.add("ffmpeg");
                args.add("-i");
                args.add(inputPath);
            }
            args.add("-vf");
            args.add("scale=" + w + ":" + h);
            args.add("-pix_fmt");
            args.add("rgba");
            args.add("-f");
            args.add("rawvideo");
            args.add("pipe:1");

            // mergeStderr=false: stdout carries binary RGBA frames
            ProcessBuilder pbVideo = buildHostProcess(false, args.toArray(new String[0]));
            _fbStreamVideoProc = pbVideo.start();

            final Process proc = _fbStreamVideoProc;
            final int frameSize = w * h * 4;
            final int seekFrame = (seekSec > 0) ? (int) Math.floor(seekSec * _fbStreamFps) : 0;

            _fbStreamVideoThread = new Thread(new Runnable() {
                public void run() {
                    try {
                        java.io.InputStream videoIn = proc.getInputStream();
                        int frameIndex = seekFrame;

                        while (!_fbStreamVideoStop && (proc.isAlive() || videoIn.available() > 0)) {
                            // Wait if buffer is full — throttles ffmpeg to playback speed
                            while (_fbStreamBufCount >= _fbStreamBufCapacity) {
                                if (_fbStreamVideoStop) return;
                                try { Thread.sleep(5); } catch (Exception ignore) {}
                            }
                            if (_fbStreamVideoStop) return;

                            byte[] frame = new byte[frameSize];
                            int read = 0;
                            while (read < frameSize) {
                                int n = videoIn.read(frame, read, frameSize - read);
                                if (n == -1) break;
                                read += n;
                            }
                            if (read != frameSize) break; // EOF or incomplete

                            synchronized (_fbStreamLock) {
                                int slot = (_fbStreamBufStart + _fbStreamBufCount) % _fbStreamBufCapacity;
                                _fbStreamBuffer[slot] = frame;
                                _fbStreamBufCount++;
                            }

                            frameIndex++;

                            // Transition to ready when enough frames buffered
                            int threshold = (_fbStreamStatus == 2 && seekFrame > 0) ? 30 : 60;
                            if (_fbStreamBufCount >= threshold && _fbStreamStatus == 2) {
                                _fbStreamStatus = 3; // ready
                            }
                        }

                        // EOF — all frames decoded
                        if (_fbStreamStatus == 3 || _fbStreamStatus == 2) {
                            _fbStreamStatus = 4; // done
                        }
                    } catch (Exception e) {
                        if (_fbStreamStatus != 0) { // not stopped
                            _fbStreamError = "Video read error: " + e.getMessage();
                            _fbStreamStatus = 5;
                        }
                    }
                }
            });
            _fbStreamVideoThread.setDaemon(true);
            _fbStreamVideoThread.start();

        } catch (Exception e) {
            _fbStreamError = "Video stream start failed: " + e.getMessage();
            _fbStreamStatus = 5;
        }
    }

    public static boolean fbStreamFrame(zombie.core.textures.Texture tex, int frameIndex) {
        if (!fbIsReady(tex)) return false;
        // Copy data out of the synchronized block — keep lock time minimal
        byte[] data;
        synchronized (_fbStreamLock) {
            if (_fbStreamBuffer == null || _fbStreamBufCount == 0) return false;
            if (frameIndex < _fbStreamBufStart || frameIndex >= _fbStreamBufStart + _fbStreamBufCount) {
                return false;
            }
            int slot = frameIndex % _fbStreamBufCapacity;
            data = _fbStreamBuffer[slot];
            if (data == null) return false;

            // Advance buffer start — discard frames we've passed (keep 10 behind for safety)
            int behind = frameIndex - _fbStreamBufStart;
            if (behind > 10) {
                int discard = behind - 10;
                _fbStreamBufStart += discard;
                _fbStreamBufCount -= discard;
            }
        }
        // GL upload — same pattern as fbLoadRawFrame (proven to work)
        final int w = tex.getWidth();
        final int h = tex.getHeight();
        final java.nio.ByteBuffer buf = java.nio.ByteBuffer.allocateDirect(data.length);
        buf.put(data);
        buf.flip();
        final int glId = tex.getTextureId().getID();
        zombie.core.opengl.RenderThread.queueInvokeOnRenderContext(new Runnable() {
            public void run() {
                org.lwjgl.opengl.GL11.glBindTexture(0x0DE1, glId);
                org.lwjgl.opengl.GL11.glTexSubImage2D(
                    0x0DE1, 0, 0, 0, w, h, 0x1908, 0x1401, buf
                );
            }
        });
        return true;
    }

    public static void fbStreamSeek(double timeSec) {
        if (_fbStreamInputPath == null || _fbStreamWidth == 0) return;
        int newStart = (int) Math.floor(timeSec * _fbStreamFps);
        synchronized (_fbStreamLock) {
            _fbStreamBufStart = newStart;
            _fbStreamBufCount = 0;
        }
        _fbStreamStatus = 2; // buffering
        startVideoStream(_fbStreamInputPath, _fbStreamWidth, _fbStreamHeight, timeSec);
    }

    public static void fbStreamStop() {
        _fbStreamStatus = 0;
        _fbStreamVideoStop = true;
        if (_fbStreamVideoProc != null) {
            _fbStreamVideoProc.destroyForcibly();
            _fbStreamVideoProc = null;
        }
        if (_fbStreamAudioProc != null) {
            _fbStreamAudioProc.destroyForcibly();
            _fbStreamAudioProc = null;
        }
        if (_fbStreamVideoThread != null) {
            try { _fbStreamVideoThread.join(2000); } catch (Exception ignore) {}
            _fbStreamVideoThread = null;
        }
        if (_fbStreamAudioThread != null) {
            try { _fbStreamAudioThread.join(2000); } catch (Exception ignore) {}
            _fbStreamAudioThread = null;
        }
        synchronized (_fbStreamLock) {
            _fbStreamBuffer = null;
            _fbStreamBufCount = 0;
            _fbStreamBufStart = 0;
        }
        if (_fbStreamAudioPath != null) {
            try { new java.io.File(_fbStreamAudioPath).delete(); } catch (Exception ignore) {}
            _fbStreamAudioPath = null;
        }
        _fbStreamAudioReady = false;
        _fbStreamAudioDone = false;
        _fbStreamInputPath = null;
        _fbStreamWidth = 0;
        _fbStreamHeight = 0;
        _fbStreamError = "";
    }

    public static int fbStreamStatus() { return _fbStreamStatus; }
    public static String fbStreamError() { return _fbStreamError; }
    public static int fbStreamWidth() { return _fbStreamWidth; }
    public static int fbStreamHeight() { return _fbStreamHeight; }
    public static double fbStreamFps() { return _fbStreamFps; }
    public static double fbStreamDuration() { return _fbStreamDuration; }
    public static String fbStreamAudioPath() { return _fbStreamAudioReady ? _fbStreamAudioPath : ""; }
    public static boolean fbStreamAudioReady() { return _fbStreamAudioReady; }
    public static boolean fbStreamAudioDone() { return _fbStreamAudioDone; }
    public static int fbStreamTotalFrames() { return (int) Math.floor(_fbStreamDuration * _fbStreamFps); }
    public static int fbStreamBufferStart() {
        synchronized (_fbStreamLock) { return _fbStreamBufStart; }
    }
    public static int fbStreamBufferCount() {
        synchronized (_fbStreamLock) { return _fbStreamBufCount; }
    }

    // === PZFB Utilities ===

    public static String fbListDir(String dirPath) {
        try {
            java.io.File dir = new java.io.File(dirPath);
            if (!dir.exists() || !dir.isDirectory()) return "";
            java.io.File[] files = dir.listFiles();
            if (files == null || files.length == 0) return "";
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < files.length; i++) {
                if (files[i].isFile()) {
                    if (sb.length() > 0) sb.append("\n");
                    sb.append(files[i].getName());
                }
            }
            return sb.toString();
        } catch (Exception e) {
            return "";
        }
    }

    public static String fbReadTextFile(String path) {
        try {
            java.io.File f = new java.io.File(path);
            if (!f.exists()) return "";
            byte[] data = java.nio.file.Files.readAllBytes(f.toPath());
            return new String(data, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            return "";
        }
    }

    /** Copy a file from src to dst. Creates parent directories if needed. Returns true on success. */
    public static boolean fbCopyFile(String src, String dst) {
        try {
            java.io.File srcFile = new java.io.File(src);
            java.io.File dstFile = new java.io.File(dst);
            if (!srcFile.exists()) return false;
            java.io.File parent = dstFile.getParentFile();
            if (parent != null && !parent.exists()) parent.mkdirs();
            java.nio.file.Files.copy(srcFile.toPath(), dstFile.toPath(),
                java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // === PZFB Game — Bidirectional process I/O for interactive applications ===

    // Game process state
    private static Process _fbGameProc = null;
    private static Thread _fbGameReaderThread = null;
    private static java.io.OutputStream _fbGameStdin = null;
    private static volatile int _fbGameStatus = 0; // 0=idle 1=starting 2=running 3=exited 4=error
    private static volatile String _fbGameError = "";
    private static volatile boolean _fbGameStop = false;
    private static java.io.File _fbGameStderrLog = null;
    private static volatile boolean _fbShutdownHookRegistered = false;

    /**
     * Register a JVM shutdown hook the first time a game process is launched.
     * Ensures fbGameStop() runs on normal JVM exit (and SIGTERM), preventing
     * orphaned child processes when consumer mods forget to call gameStop().
     *
     * Limitation: shutdown hooks do NOT run on SIGKILL, power loss, or Windows
     * "End task" — those still require the user to clean up manually (or a
     * future orphan-scan feature).
     */
    private static void ensureShutdownHookRegistered() {
        if (_fbShutdownHookRegistered) return;
        synchronized (Color.class) {
            if (_fbShutdownHookRegistered) return;
            try {
                Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
                    public void run() {
                        try { fbGameStop(); } catch (Throwable ignore) {}
                    }
                }, "PZFB-GameShutdown"));
                _fbShutdownHookRegistered = true;
            } catch (Throwable ignore) {
                // JVM already shutting down — best effort
            }
        }
    }

    /**
     * Launch a game process with bidirectional I/O. Legacy string-based overload.
     * Accepts a single whitespace-separated args string; arguments containing
     * spaces MUST be wrapped in double quotes. Only simple `"..."` quoting is
     * supported — no nested quotes, no backslash escapes.
     *
     * For any args derived from user input (paths that may contain spaces,
     * apostrophes, Unicode, OneDrive redirects, etc.), prefer
     * fbGameStartArgv(...) instead, which bypasses parsing entirely.
     *
     * stdout: read into ring buffer as raw RGBA frames (reuses fbStreamFrame for upload)
     * stdin: writable via fbGameSendInput for keyboard events
     * Shares the stream ring buffer — cannot run simultaneously with fbStreamStart.
     *
     * @param binaryPath Absolute path to the game binary
     * @param width      Frame width in pixels
     * @param height     Frame height in pixels
     * @param extraArgs  Additional command line arguments (space-separated; use "quotes" for paths with spaces)
     */
    public static void fbGameStart(String binaryPath, int width, int height, String extraArgs) {
        java.util.ArrayList<String> parsed = new java.util.ArrayList<String>();
        if (extraArgs != null && !extraArgs.trim().isEmpty()) {
            parsed.addAll(splitQuotedArgs(extraArgs));
        }
        fbGameStartInternal(binaryPath, width, height, parsed);
    }

    /**
     * Launch a game process with bidirectional I/O. Argv-array overload (1.7.0+).
     * Each element of extraArgv is passed verbatim to the child process — no
     * string splitting, no quote parsing, no escaping. Recommended for any
     * paths that may contain spaces, quotes, backslashes, or Unicode.
     *
     * @param binaryPath Absolute path to the game binary
     * @param width      Frame width in pixels
     * @param height     Frame height in pixels
     * @param extraArgv  Additional command-line arguments as a String[] (null elements skipped)
     */
    public static void fbGameStartArgv(String binaryPath, int width, int height, String[] extraArgv) {
        java.util.ArrayList<String> parsed = new java.util.ArrayList<String>();
        if (extraArgv != null) {
            for (String a : extraArgv) {
                if (a != null) parsed.add(a);
            }
        }
        fbGameStartInternal(binaryPath, width, height, parsed);
    }

    /**
     * Shared implementation — called by both the legacy string overload and
     * the new array overload. Registers the JVM shutdown hook on first call.
     */
    private static void fbGameStartInternal(String binaryPath, int width, int height,
                                             java.util.List<String> extraArgs) {
        ensureShutdownHookRegistered();

        // Clean up any existing stream or game process
        fbGameStop();
        fbStreamStop();

        _fbGameError = "";
        _fbGameStatus = 1; // starting

        // Fix permissions (Workshop may strip +x)
        try { new java.io.File(binaryPath).setExecutable(true); } catch (Exception ignore) {}

        // Build args: [binaryPath, ...extraArgs]
        java.util.ArrayList<String> argList = new java.util.ArrayList<>();
        argList.add(binaryPath);
        if (extraArgs != null) {
            for (String a : extraArgs) argList.add(a);
        }

        try {
            // mergeStderr=false: stdout carries binary RGBA frames
            ProcessBuilder pb = buildHostProcess(false, argList.toArray(new String[0]));

            // Set working directory to binary's parent (ensures DLLs are found,
            // config files can be written, and avoids UAC issues on Windows)
            java.io.File binDir = new java.io.File(binaryPath).getParentFile();
            if (binDir != null && binDir.isDirectory()) {
                pb.directory(binDir);
            }

            // Capture stderr to temp file for diagnostics (overrides DISCARD from buildHostProcess)
            try {
                _fbGameStderrLog = java.io.File.createTempFile("pzfb_game_", ".log");
                _fbGameStderrLog.deleteOnExit();
                pb.redirectError(_fbGameStderrLog);
            } catch (Exception ignore) {
                // Fall through with DISCARD if temp file creation fails
            }

            _fbGameProc = pb.start();
            _fbGameStdin = _fbGameProc.getOutputStream();

            // Set up frame dimensions (reuse stream infrastructure)
            _fbStreamWidth = width;
            _fbStreamHeight = height;
            _fbStreamFrameSize = width * height * 4;

            // Allocate ring buffer
            int capacity = 60; // ~2 seconds at 35fps
            _fbStreamBufCapacity = capacity;
            synchronized (_fbStreamLock) {
                _fbStreamBuffer = new byte[capacity][];
                _fbStreamBufStart = 0;
                _fbStreamBufCount = 0;
            }
            _fbGameStop = false;

            // Start reader thread — reads frames from stdout into ring buffer
            final Process proc = _fbGameProc;
            final int frameSize = _fbStreamFrameSize;

            _fbGameReaderThread = new Thread(new Runnable() {
                public void run() {
                    try {
                        java.io.InputStream in = proc.getInputStream();
                        int frameIndex = 0;

                        while (!_fbGameStop && (proc.isAlive() || in.available() > 0)) {
                            // Wait if buffer is full
                            while (_fbStreamBufCount >= _fbStreamBufCapacity) {
                                if (_fbGameStop) return;
                                try { Thread.sleep(5); } catch (Exception ignore) {}
                            }
                            if (_fbGameStop) return;

                            // Read one complete frame
                            byte[] frame = new byte[frameSize];
                            int read = 0;
                            while (read < frameSize) {
                                int n = in.read(frame, read, frameSize - read);
                                if (n == -1) break;
                                read += n;
                            }
                            if (read != frameSize) break; // EOF or incomplete

                            // Push to ring buffer
                            synchronized (_fbStreamLock) {
                                int slot = (_fbStreamBufStart + _fbStreamBufCount) % _fbStreamBufCapacity;
                                _fbStreamBuffer[slot] = frame;
                                _fbStreamBufCount++;
                            }
                            frameIndex++;

                            // Transition to running after first frame
                            if (_fbGameStatus == 1 && frameIndex >= 1) {
                                _fbGameStatus = 2; // running
                            }
                        }

                        // Process exited
                        if (_fbGameStatus != 0) {
                            if (frameIndex == 0) {
                                // Never produced a frame — report as error with diagnostics
                                int exitCode = -1;
                                try { exitCode = proc.waitFor(); } catch (Exception ignore) {}
                                String detail = readLastLines(_fbGameStderrLog, 5);
                                _fbGameError = "Process exited immediately (code " + exitCode + ")";
                                if (!detail.isEmpty()) _fbGameError += ": " + detail;
                                _fbGameStatus = 4; // error
                            } else {
                                _fbGameStatus = 3; // normal exit
                            }
                        }
                    } catch (Exception e) {
                        if (_fbGameStatus != 0) {
                            _fbGameError = "Game read error: " + e.getMessage();
                            _fbGameStatus = 4; // error
                        }
                    }
                }
            });
            _fbGameReaderThread.setDaemon(true);
            _fbGameReaderThread.start();

        } catch (Exception e) {
            _fbGameError = "Game start failed: " + e.getMessage();
            _fbGameStatus = 4;
        }
    }

    /**
     * Send a key event to the running game process via stdin.
     * Protocol: 2 bytes [pressed, keycode]
     */
    public static void fbGameSendInput(int keycode, int pressed) {
        java.io.OutputStream os = _fbGameStdin;
        if (os == null) return;
        try {
            synchronized (os) {
                os.write(pressed & 0xFF);
                os.write(keycode & 0xFF);
                os.flush();
            }
        } catch (Exception ignore) {
            // Process may have exited — silently ignore
        }
    }

    /** Check if the game process is still alive. */
    public static boolean fbGameIsRunning() {
        return _fbGameProc != null && _fbGameProc.isAlive();
    }

    /** Get game process status: 0=idle 1=starting 2=running 3=exited 4=error */
    public static int fbGameStatus() { return _fbGameStatus; }

    /** Get error message (empty string if no error). */
    public static String fbGameError() { return _fbGameError; }

    /** Stop the game process and clean up all resources. */
    public static void fbGameStop() {
        _fbGameStop = true;
        _fbGameStatus = 0;
        if (_fbGameStdin != null) {
            try { _fbGameStdin.close(); } catch (Exception ignore) {}
            _fbGameStdin = null;
        }
        if (_fbGameProc != null) {
            _fbGameProc.destroyForcibly();
            _fbGameProc = null;
        }
        if (_fbGameReaderThread != null) {
            try { _fbGameReaderThread.join(2000); } catch (Exception ignore) {}
            _fbGameReaderThread = null;
        }
        synchronized (_fbStreamLock) {
            _fbStreamBuffer = null;
            _fbStreamBufCount = 0;
            _fbStreamBufStart = 0;
        }
        _fbStreamWidth = 0;
        _fbStreamHeight = 0;
        _fbGameError = "";
        if (_fbGameStderrLog != null) {
            try { _fbGameStderrLog.delete(); } catch (Exception ignore) {}
            _fbGameStderrLog = null;
        }
    }

    // === END PZFB EXTENSION ===
}

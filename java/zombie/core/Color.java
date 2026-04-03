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
    private static final String PZFB_VERSION = "1.0.0";

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
    // === END PZFB EXTENSION ===
}

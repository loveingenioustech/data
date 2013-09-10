create or replace and compile java source named IDEA as
public class IDEA
{
    public static final int KEY_LENGTH = 16;
    public static final int BLOCKLENGTH = 8;
    private static final int INTERNAL_KEY_LENGTH = 104;
    private static final int KEYS_PER_ROUND = 6;
    private static final int ROUNDS = 8;
    private static  int ks[];
    private  static int dks[] = null;
    private static boolean native_link_ok = false;
    final static String mCipherKeyStr = "12dc427f09a81e293d43db3b2378491d";
    public static byte userKey[] = fromString(mCipherKeyStr);
        private static void java_ks(byte userKey[])
    {
        int i, j;

        ks = new int[INTERNAL_KEY_LENGTH / 2];

        for (i = 0; i < KEY_LENGTH / 2; i++)
        {
            ks[i] = (((userKey[i * 2] & 0xff) << 8) |
                     (userKey[i * 2 + 1] & 0xff));
        }

        j = 0;
        int koff = 0;
        for (; i < INTERNAL_KEY_LENGTH / 2; i++)
        {
            j++;
            ks[koff + j +
                    7] = ((ks[koff + (j & 7)] << 9) |
                          (ks[koff + ((j + 1) & 7)] >>> 7)) & 0xffff;
            koff += j & 8;
            j &= 7;
        }
    }
        public  static void native_ks(byte userKey[])
    {
        java_ks(userKey);
    }
    private static int
            asciiToHex(char c)
    {
        if ((c >= 'a') && (c <= 'f'))
        {
            return (c - 'a' + 10);
        }
        if ((c >= 'A') && (c <= 'F'))
        {
            return (c - 'A' + 10);
        }
        if ((c >= '0') && (c <= '9'))
        {
            return (c - '0');
        }
        throw new Error(c+"");
    }

        public static byte[]
            fromString(String inHex)
    {
        int len = inHex.length();
        int pos = 0;
        byte buffer[] = new byte[((len + 1) / 2)];
        if ((len % 2) == 1)
        {
            buffer[0] = (byte) asciiToHex(inHex.charAt(0));
            pos = 1;
            len--;
        }

        for (int ptr = pos; len > 0; len -= 2)
        {
            buffer[pos++] = (byte) (
                    (asciiToHex(inHex.charAt(ptr++)) << 4) |
                    (asciiToHex(inHex.charAt(ptr++)))
                            );
        }
        return buffer;

    }
        private static char
            hexToAscii(int h)
    {
        if ((h >= 10) && (h <= 15))
        {
            return (char) ('A' + (h - 10));
        }
        if ((h >= 0) && (h <= 9))
        {
            return (char) ('0' + h);
        }
        throw new Error("hex to ascii failed");
    }
        private static String
            toString(byte buffer[])
    {
        StringBuffer returnBuffer = new StringBuffer();
        for (int pos = 0, len = buffer.length; pos < len; pos++)
        {
            returnBuffer.append(hexToAscii((buffer[pos] >>> 4) & 0x0F))
                    .append(hexToAscii(buffer[pos] & 0x0F));
        }
        return returnBuffer.toString();

    }
        static private int mul(int a, int b)
    {
        int p;

        a &= 0xffff;
        b &= 0xffff;
        if (a != 0)
        {
            if (b != 0)
            {
                p = a * b;
                b = p & 0xffff;
                a = p >>> 16;
                return (b - a + ((b < a) ? 1 : 0)) & 0xffff;
            }
            else
            {
                return (1 - a) & 0xffff;
            }
        }
        return (1 - b) & 0xffff;
    }
    
    private static void java_encrypt(byte in[], int in_offset, byte out[],
                                     int out_offset,
                                     int[] key)
    {
        int k = 0;
        int t0, t1;

        int x0 = in[in_offset++] << 8;
        x0 |= in[in_offset++] & 0xff;
        int x1 = in[in_offset++] << 8;
        x1 |= in[in_offset++] & 0xff;
        int x2 = in[in_offset++] << 8;
        x2 |= in[in_offset++] & 0xff;
        int x3 = in[in_offset++] << 8;
        x3 |= in[in_offset] & 0xff;

        for (int i = 0; i < ROUNDS; ++i)
        {
            x0 = mul(x0, key[k++]);
            x1 += key[k++];
            x2 += key[k++];
            x3 = mul(x3, key[k++]);

            t0 = x2;
            x2 = mul(x0 ^ x2, key[k++]);
            t1 = x1;
            x1 = mul((x1 ^ x3) + x2, key[k++]);
            x2 += x1;

            x0 ^= x1;
            x3 ^= x2;
            x1 ^= t0;
            x2 ^= t1;
        }

        x0 = mul(x0, key[k++]);
        t0 = x1;
        x1 = x2 + key[k++];
        x2 = t0 + key[k++];
        x3 = mul(x3, key[k]);

        out[out_offset++] = (byte) (x0 >>> 8);
        out[out_offset++] = (byte) (x0);
        out[out_offset++] = (byte) (x1 >>> 8);
        out[out_offset++] = (byte) (x1);
        out[out_offset++] = (byte) (x2 >>> 8);
        out[out_offset++] = (byte) (x2);
        out[out_offset++] = (byte) (x3 >>> 8);
        out[out_offset] = (byte) (x3);
    }

    
        public static void native_encrypt(byte in[], int in_offset, byte out[],
                               int out_offset, int[] key)
    {}
        public static void blockEncrypt(byte in[], int in_offset, byte out[],
                                int out_offset)
    {
        if (ks == null)
        {
        throw new Error("Idea: User key not set.");
        }

        if (native_link_ok)
        {
//            System.out.println("native_link_ok");
            native_encrypt(in, in_offset, out, out_offset, ks);
        }
        else
        {
//            System.out.println("java_encrypt");
            java_encrypt(in, in_offset, out, out_offset, ks);
        }
    }
    
    public final static void
            encrypt(byte in[], int in_offset, byte out[], int out_offset)
    {
        int blkLength = BLOCKLENGTH;

        if (in_offset < 0 || out_offset < 0)
        {
            throw new ArrayIndexOutOfBoundsException(
                    " Negative offset not allowed");
        }

        if ((in_offset + blkLength) > in.length ||
            (out_offset + blkLength) > out.length)
        {
            throw new ArrayIndexOutOfBoundsException(
                    " Offset past end of array");
        }
        blockEncrypt(in, in_offset, out, out_offset);
    }
    

        public final static void
            encrypt(byte in[], byte out[])
    {
        int len =BLOCKLENGTH;

        if ((in.length != len) || (out.length != len))
            throw new Error("hex to ascii failed");
        encrypt(in, 0, out, 0);
    }
        public final void
            decrypt(byte in[], byte out[])
    {
        int len = BLOCKLENGTH;
        if ((in.length != len) || (out.length != len))
            throw new Error(" decrypt buffers must be the same size as cipher length");
        decrypt(in, 0, out, 0);
    }
        public final void
            decrypt(byte in[], int in_offset, byte out[], int out_offset)
    {
        int blkLength = BLOCKLENGTH;

        if (in_offset < 0 || out_offset < 0)
        {
            throw new ArrayIndexOutOfBoundsException(
                    getClass().getName() +
                    ": Negative offset not allowed");
        }

        if ((in_offset + blkLength) > in.length ||
            (out_offset + blkLength) > out.length)
        {
            throw new ArrayIndexOutOfBoundsException(
                    getClass().getName() +
                    ": Offset past end of array");
        }
        blockDecrypt(in, in_offset, out, out_offset);
    }
        static private int inv(int x)
    {
        int t0, t1, q, y;

        x &= 0xffff;

        if (x <= 1)
        {
            return x;
        }

        t1 = 0x10001 / x;
        y = 0x10001 % x;
        if (y == 1)
        {
            return ((1 - t1) & 0xffff);
        }

        t0 = 1;
        do
        {
            q = x / y;
            x %= y;
            t0 = (t0 + q * t1) & 0xffff;
            if (x == 1)
            {
                return t0;
            }
            q = y / x;
            y %= x;
            t1 += q * t0;
        }
        while (y != 1);

        return (1 - t1) & 0xffff;
    }

        public static void native_dks()
    {
        java_dks();
    }
        private static void java_dks()
    {
        int i;
        int j = 0;

        dks = new int[INTERNAL_KEY_LENGTH / 2];

        dks[KEYS_PER_ROUND * ROUNDS + 0] = inv(ks[j++]);
        dks[KEYS_PER_ROUND * ROUNDS + 1] = -ks[j++];
        dks[KEYS_PER_ROUND * ROUNDS + 2] = -ks[j++];
        dks[KEYS_PER_ROUND * ROUNDS + 3] = inv(ks[j++]);

        for (i = KEYS_PER_ROUND * (ROUNDS - 1); i >= 0; i -= KEYS_PER_ROUND)
        {
            dks[i + 4] = ks[j++];
            dks[i + 5] = ks[j++];
            dks[i + 0] = inv(ks[j++]);
            if (i > 0)
            {
                dks[i + 2] = -ks[j++];
                dks[i + 1] = -ks[j++];
            }
            else
            {
                dks[i + 1] = -ks[j++];
                dks[i + 2] = -ks[j++];
            }
            dks[i + 3] = inv(ks[j++]);
        }
    }
    
        protected void blockDecrypt(byte in[], int in_offset, byte out[],
                                int out_offset)
    {
        if (dks == null)
        {
            dks = new int[INTERNAL_KEY_LENGTH / 2];
            if (native_link_ok)
            {
                native_dks();
            }
            else
            {
                java_dks();
            }
        }

        if (native_link_ok)
        {
            native_encrypt(in, in_offset, out, out_offset, dks);
        }
        else
        {
            java_encrypt(in, in_offset, out, out_offset, dks);
        }
    }
    
        public String decryptString(String encryptStr)
    {
        String hexEncryptStr = encryptStr;
        byte key[] = fromString(mCipherKeyStr);
        byte encP[] = fromString(hexEncryptStr);
        byte decC[] = new byte[encP.length];
        decrypt(encP, decC);
        String hexDecryptStr = toString(decC);
        return hexStringToString(hexDecryptStr);
    }
        private static String
            hexStringToString(String hexString)
    {
        String resultString = "";
        int hexLen = hexString.length();
        for (int pos = 0; pos < hexLen; pos += 2)
        {
            char c1 = hexString.charAt(pos);
            char c2 = hexString.charAt(pos + 1);
            int hexvalue1 = asciiToHex(c1);
            int hexvalue2 = asciiToHex(c2);
            char c = (char) (hexvalue1 | hexvalue2 << 4);
            resultString += c;
        }

        return resultString.trim();
    }
    
    public static String encrypt(String plainStr)
  {
  
        try
        {
        if (userKey.length != KEY_LENGTH)
        {
            return userKey.length+"!="+KEY_LENGTH;
        }

        if (native_link_ok)
        {
            native_ks(userKey);
        }
        else
        {
            java_ks(userKey);
        }
        
        byte plain[] = fromString(plainStr);
        byte encP[] = new byte[plain.length];
        encrypt(plain, encP);
        String hexEncryptString = toString(encP);
        return hexEncryptString;   
        }
        catch (Exception e)
        {
        return e.toString();
        }   
  }
}
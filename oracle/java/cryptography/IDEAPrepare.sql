create or replace and compile java source named ideaprepare as
public class IDEAPrepare
{
    final  static int mStrLen = 8;
    public static String prepareString(String plainStr)
    {
        String tplainStr = "";
        int len = plainStr.length();
        if (len <= mStrLen)
        {
            for (int i = 0; i < len; i++)
            {
                tplainStr += plainStr.charAt(i);
            }
            for (int i = 0; i < mStrLen - len; i++)
            {
                tplainStr += " ";
            }
        }
        else
        {
            for (int i = 0; i < mStrLen; i++)
            {
                tplainStr += plainStr.charAt(i);
            }
        }
        String hexPlainStr = stringToHexString(tplainStr);
        return hexPlainStr;

    }
        public static int
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
        throw new Error("ascii to hex failed");
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

    public static String
            stringToHexString(String srcString)
    {
        String resultString = "";
        int srcLen = srcString.length();
        for (int pos = 0; pos < srcLen; pos++)
        {
            byte b = (byte) srcString.charAt(pos);
            int hexValue = (b & 0x0F);
            resultString += hexToAscii(hexValue);
            hexValue = ((b >> 4) & 0x0F);
            resultString += hexToAscii(hexValue);
        }
        return resultString;
    }
 }


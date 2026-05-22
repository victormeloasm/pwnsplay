import java.math.BigInteger;
import java.util.Locale;

public class FactJava {
    static BigInteger prodRange(int lo, int hi) {
        if (lo > hi) return BigInteger.ONE;
        if (lo == hi) return BigInteger.valueOf(lo);
        if (hi - lo <= 16) {
            BigInteger r = BigInteger.ONE;
            for (int i = lo; i <= hi; i++) r = r.multiply(BigInteger.valueOf(i));
            return r;
        }
        int mid = lo + (hi - lo) / 2;
        return prodRange(lo, mid).multiply(prodRange(mid + 1, hi));
    }
    static long trailingZeroes(long n) {
        long z = 0;
        while (n > 0) { n /= 5; z += n; }
        return z;
    }
    public static void main(String[] args) {
        int n = args.length > 0 ? Integer.parseInt(args[0]) : 99999;
        long t0 = System.nanoTime();
        BigInteger fact = prodRange(1, n);
        long t1 = System.nanoTime();
        double ms = (t1 - t0) / 1_000_000.0;
        System.out.printf(Locale.ROOT, "Java|%.3f|%d|%d|BigInteger product tree%n", ms, fact.toString().length(), trailingZeroes(n));
    }
}

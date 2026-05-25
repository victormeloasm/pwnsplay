import java.util.Locale;

public class MatrixBench {
    static final int N = 1000;
    static final int BS = 32;

    static double aval(int i, int j) {
        return ((i * 131 + j * 17 + 13) % 1000) * 0.001 - 0.5;
    }

    static double bval(int i, int j) {
        return ((i * 19 + j * 137 + 7) % 1000) * 0.001 - 0.5;
    }

    public static void main(String[] args) {
        Locale.setDefault(Locale.US);
        double[] A = new double[N*N];
        double[] BT = new double[N*N];
        double[] C = new double[N*N];

        for (int i = 0; i < N; i++) {
            for (int j = 0; j < N; j++) {
                A[i*N+j] = aval(i,j);
                BT[j*N+i] = bval(i,j);
            }
        }

        long t0 = System.nanoTime();

        for (int ii = 0; ii < N; ii += BS) {
            int iimax = Math.min(ii + BS, N);
            for (int jj = 0; jj < N; jj += BS) {
                int jjmax = Math.min(jj + BS, N);
                for (int i = ii; i < iimax; i++) {
                    int abase = i*N;
                    for (int j = jj; j < jjmax; j++) {
                        int bbase = j*N;
                        double s = 0.0;
                        for (int k = 0; k < N; k++) {
                            s += A[abase+k] * BT[bbase+k];
                        }
                        C[abase+j] = s;
                    }
                }
            }
        }

        long t1 = System.nanoTime();
        double chk = 0.0;
        for (int idx = 0; idx < N*N; idx += 97) chk += C[idx];

        System.out.println("language Java pure");
        System.out.printf("time_ms %.6f%n", (t1 - t0) / 1e6);
        System.out.printf("checksum %.17g%n", chk);
    }
}

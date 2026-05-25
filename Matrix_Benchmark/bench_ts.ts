declare const process: any;

const N: number = 1000;
const BS: number = 32;

function aval(i: number, j: number): number {
  return ((i * 131 + j * 17 + 13) % 1000) * 0.001 - 0.5;
}

function bval(i: number, j: number): number {
  return ((i * 19 + j * 137 + 7) % 1000) * 0.001 - 0.5;
}

const A: Float64Array = new Float64Array(N*N);
const BT: Float64Array = new Float64Array(N*N);
const C: Float64Array = new Float64Array(N*N);

for (let i = 0; i < N; i++) {
  for (let j = 0; j < N; j++) {
    A[i*N+j] = aval(i,j);
    BT[j*N+i] = bval(i,j);
  }
}

const t0: bigint = process.hrtime.bigint();

for (let ii = 0; ii < N; ii += BS) {
  const iimax = Math.min(ii + BS, N);
  for (let jj = 0; jj < N; jj += BS) {
    const jjmax = Math.min(jj + BS, N);
    for (let i = ii; i < iimax; i++) {
      const abase = i*N;
      for (let j = jj; j < jjmax; j++) {
        const bbase = j*N;
        let s = 0.0;
        for (let k = 0; k < N; k++) s += A[abase+k] * BT[bbase+k];
        C[abase+j] = s;
      }
    }
  }
}

const t1: bigint = process.hrtime.bigint();

let chk = 0.0;
for (let idx = 0; idx < N*N; idx += 97) chk += C[idx];

console.log('language TypeScript compiled to Node pure');
console.log(`time_ms ${(Number(t1 - t0) / 1e6).toFixed(6)}`);
console.log(`checksum ${chk.toPrecision(17)}`);

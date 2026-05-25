program BenchPascal;

uses SysUtils, DateUtils;

const
  N = 1000;
  CblasColMajor = 102;
  CblasNoTrans = 111;

{$linklib openblas}

type
  TMatrix = array of Double;

procedure cblas_dgemm(layout, transa, transb, m, n, k: LongInt;
  alpha: Double; A: PDouble; lda: LongInt; B: PDouble; ldb: LongInt;
  beta: Double; C: PDouble; ldc: LongInt); cdecl; external;

var
  A, B, C: TMatrix;
  t0, t1: TDateTime;
  i, j, idx, row, colidx: LongInt;
  chk: Double;

function Aval(i, j: LongInt): Double;
begin
  Aval := ((i * 131 + j * 17 + 13) mod 1000) * 0.001 - 0.5;
end;

function Bval(i, j: LongInt): Double;
begin
  Bval := ((i * 19 + j * 137 + 7) mod 1000) * 0.001 - 0.5;
end;

begin
  SetLength(A, N*N);
  SetLength(B, N*N);
  SetLength(C, N*N);

  for i := 0 to N-1 do
    for j := 0 to N-1 do
    begin
      A[i + j*N] := Aval(i,j);
      B[i + j*N] := Bval(i,j);
    end;

  cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, N, N, N,
              1.0, @A[0], N, @B[0], N, 0.0, @C[0], N);

  t0 := Now;
  cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, N, N, N,
              1.0, @A[0], N, @B[0], N, 0.0, @C[0], N);
  t1 := Now;

  chk := 0.0;
  idx := 0;
  while idx < N*N do
  begin
    row := idx div N;
    colidx := idx mod N;
    chk := chk + C[row + colidx*N];
    idx := idx + 97;
  end;

  Writeln('language Pascal OpenBLAS');
  Writeln('time_ms ', MilliSecondsBetween(t1, t0));
  Writeln('checksum ', chk:0:17);
end.

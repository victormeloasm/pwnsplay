Const N As Integer = 1000

Extern "C"
Declare Sub cblas_dgemm Alias "cblas_dgemm" ( _
    ByVal layout As Integer, _
    ByVal transa As Integer, _
    ByVal transb As Integer, _
    ByVal m As Integer, _
    ByVal n As Integer, _
    ByVal k As Integer, _
    ByVal alpha As Double, _
    ByVal A As Double Ptr, _
    ByVal lda As Integer, _
    ByVal B As Double Ptr, _
    ByVal ldb As Integer, _
    ByVal beta As Double, _
    ByVal C As Double Ptr, _
    ByVal ldc As Integer)
End Extern

Const CblasColMajor As Integer = 102
Const CblasNoTrans As Integer = 111

Dim Shared As Double A(0 To N*N-1)
Dim Shared As Double B(0 To N*N-1)
Dim Shared As Double C(0 To N*N-1)

Function aval(ByVal i As Integer, ByVal j As Integer) As Double
    Return ((i * 131 + j * 17 + 13) Mod 1000) * 0.001 - 0.5
End Function

Function bval(ByVal i As Integer, ByVal j As Integer) As Double
    Return ((i * 19 + j * 137 + 7) Mod 1000) * 0.001 - 0.5
End Function

For i As Integer = 0 To N-1
    For j As Integer = 0 To N-1
        A(i + j*N) = aval(i,j)
        B(i + j*N) = bval(i,j)
    Next
Next

cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, N, N, N, 1.0, @A(0), N, @B(0), N, 0.0, @C(0), N)

Dim As Double t0 = Timer
cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans, N, N, N, 1.0, @A(0), N, @B(0), N, 0.0, @C(0), N)
Dim As Double t1 = Timer

Dim As Double chk = 0.0
For idx As Integer = 0 To N*N-1 Step 97
    Dim As Integer row = idx \ N
    Dim As Integer colidx = idx Mod N
    chk += C(row + colidx*N)
Next

Print "language FreeBASIC OpenBLAS"
Print "time_ms "; (t1 - t0) * 1000.0
Print "checksum "; chk

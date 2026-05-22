Declare Function bench_basic CDecl Alias "bench_basic" (ByVal n As ULong) As Integer

Dim As ULong n = 99999
If Command(1) <> "" Then n = ValULng(Command(1))
End bench_basic(n)

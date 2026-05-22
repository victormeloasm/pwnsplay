program FactPascal;

{$mode objfpc}{$H+}
{$linklib c}
{$linklib gmp}
{$linklib rt}

uses
  SysUtils, ctypes;

function bench_pascal(n: culong): cint; cdecl; external name 'bench_pascal';

var
  n: culong = 99999;
begin
  if ParamCount >= 1 then
    n := culong(StrToQWordDef(ParamStr(1), 99999));
  Halt(bench_pascal(n));
end.

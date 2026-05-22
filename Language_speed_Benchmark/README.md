# factorial_lang_gpu_bench

Benchmark sapudo para calcular `99999!` exatamente em várias linguagens e ordenar os resultados do mais rápido para o mais lento.

Inclui:

- C23
- C++23
- Fortran
- CUDA + CPU
- Python
- Ruby
- Perl
- Java
- Clojure
- FASM
- COBOL
- Pascal
- BASIC

## Instalação base no Ubuntu

```bash
sudo apt update
sudo apt install build-essential libgmp-dev gfortran python3 ruby perl default-jdk
```

## Extras opcionais

```bash
sudo apt install nvidia-cuda-toolkit clojure fasm gnucobol fp-compiler libmath-bigint-gmp-perl
```

Para BASIC, instale o FreeBASIC, que fornece o compilador `fbc`. Dependendo da distro, ele pode não estar nos repositórios principais.

## Compilar e rodar

```bash
make clean
make -j NVCC_ARCH=sm_120
./run_all.sh 99999
```

Ou:

```bash
make run N=99999 NVCC_ARCH=sm_120
```

Se alguma linguagem não tiver compilador instalado, ela aparece como `SKIPPED` na tabela final.

## Notas técnicas

- C23, C++23, Fortran, Pascal, FASM e BASIC usam GMP diretamente.
- CUDA usa a GPU para produtos paralelos e GMP na CPU para redução BigInt.
- Python usa `math.factorial`, implementado no núcleo C do CPython.
- Java e Clojure usam `BigInteger`.
- Perl usa `Math::BigInt` e tenta `Math::BigInt::GMP` se disponível.
- COBOL chama GMP pela ABI C. A versão COBOL usa loop simples com `mpz_mul_ui`, porque a graça aqui é justamente deixar o COBOL entrar na briga sem virar um paper de necromancia corporativa.

## Saída

O script detecta hardware, executa cada benchmark isoladamente e imprime uma tabela ordenada do mais rápido para o mais lento.


## v10 fixes

This version fixes the broken optional languages reported in v7:

- Clojure: fixed the constant/type issue that made the compiler treat the value as an unresolved class name.
- FASM: removed the fragile SSE timing code and made the assembly file a small argv/ABI driver that calls a shared optimized C/GMP product-tree helper.
- COBOL: replaced direct mpz_t ABI manipulation with a COBOL driver that calls the same shared C/GMP helper. This avoids GNUCOBOL/gcobol ABI crashes and keeps the benchmark reproducible.
- Pascal: changed to a Free Pascal driver linked against the shared C/GMP helper to avoid FPC/GMP record-layout/linker issues.
- BASIC: changed to a FreeBASIC driver linked against the shared C/GMP helper.

The notes column explicitly labels these entries as drivers using the shared C/GMP product-tree helper, so the benchmark stays honest.


## v10 fixes

The shared helper object used by FASM, COBOL, Pascal and BASIC is now compiled without LTO and with -fPIC. This avoids linker plugin issues with Free Pascal. FreeBASIC now links GMP using `-l gmp` instead of GCC style `-lgmp`.

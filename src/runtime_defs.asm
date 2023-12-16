; Fixes undefined reference errors that LD gives when we try to use
; gfortran to compile our kernel. Also provides definitions for
; some functions that our Fortran kernel uses.

section .text:
global halt_cpu_
global __stack_chk_fail
global _gfortran_set_args
global _gfortran_set_options

halt_cpu_:
    cli
    hlt
    jmp short halt_cpu_

__stack_chk_fail: ret
_gfortran_set_args: ret
_gfortran_set_options: ret
BRK equ 12
SPACE equ (64*64)

; using r10 as threading reg

%macro PUSH_RET 1
	lea rbp, [rbp - 8]
	mov [rbp], %1
%endmacro

%macro POP_RET 1
	mov %1, [rbp]
	lea rbp, [rbp + 8]
%endmacro

%macro NEXT 0
	mov rax, [r10]
        lea r10, [r10 + 8]
	jmp rax
%endmacro


%define latest 0

; defcode : len , string_name, label
%macro defcode 3
	name_%3:
	dq latest
	dw %1
	dq %2
	align 8
	%3:
        %define latest name_%3
%endmacro

DOCOL:
	PUSH_RET r10
	mov r10, rax
	NEXT

; defword : len , string_name, label
%macro defword 3
	name_%3:
	dq latest
	dw %1
	dq %2
	align 8
        %define latest name_%3
        dq DOCOL
%endmacro

exit:
	POP_RET r10
	jmp r10


defcode 3, "LIT", LIT
        mov  rax, [r10]
	lea r10, [r10 + 8]
        push rax
        NEXT
       
defcode 3, "dup", dup
	mov rax, [rsp]
	push rax
	NEXT

defcode 3, "add", add
	pop rax
	pop rdi
	add rax, rdi
	push rax
	NEXT

defcode 4, "emit", emit
	mov rax, 1
	mov rdi, 1
	mov rsi, rsp
	mov rdx, 1
	syscall
        NEXT

defcode 4, "drop", drop
	pop rax
	NEXT

defword 1, "a", a
        dq LIT
        dq 30
        dq LIT
        dq 35
        dq add
        dq exit

defword 1, "b", b
        dq emit 
        dq drop
        dq exit

defword 4, "test", test
	dq a
	dq b
	dq exit

global _start
section .text

_start:
	; push current break into rax
	mov rax, BRK
	xor rdi, rdi
	syscall

	; increase break by alloc space
	add rax, SPACE

	; set new space break
	mov rdi, rax
	mov rax, BRK
	syscall

	; set base pointer to new location
	mov rbp, rax
          
        lea r10, end
        mov rax, test
        jmp DOCOL_test

end: 
	mov rax, 60
	xor rdi, rdi
	syscall


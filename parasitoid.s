global main
extern printf
extern atoi
extern kill
extern strtol
extern ptrace
extern waitpid
extern process_vm_writev

section .data
; -- ALIAS -- ;
%define argc         r12
%define pid          r13
%define syscall_addr r14
%define payload_addr r14
%define temp         r15
%define i            rbx

%define func rax
%define arg1 rdi
%define arg2 rsi
%define arg3 rdx
%define arg4 rcx
%define arg5 r8
%define arg6 r9
%define out  rax

; -- SYSCALL -- ;
%define mmap   9
%define clone  56
%define exit   60

; -- CONSTANTS -- ;
%define PTRACE_ATTACH     16
%define PTRACE_DETACH     17
%define PTRACE_GETREGS    12
%define PTRACE_SETREGS    13
%define PTRACE_SINGLESTEP 9
%define PTRACE_CONT       7
%define NULL              0

%define TARGET_R15      0
%define TARGET_R14      8
%define TARGET_R13      16
%define TARGET_R12      24
%define TARGET_RBP      32
%define TARGET_RBX      40
%define TARGET_R11      48
%define TARGET_R10      56
%define TARGET_R9       64
%define TARGET_R8       72
%define TARGET_RAX      80
%define TARGET_RCX      88
%define TARGET_RDX      96
%define TARGET_RSI      104
%define TARGET_RDI      112
%define TARGET_ORIG_RAX 120
%define TARGET_RIP      128
%define TARGET_CS       136
%define TARGET_EFLAGS   144
%define TARGET_RSP      152
%define TARGET_SS       160
%define TARGET_FS_BASE  168
%define TARGET_GS_BASE  176
%define TARGET_DS       184
%define TARGET_ES       192
%define TARGET_FS       200
%define TARGET_GS       208

%define THREAD_SIZE 0x1000

line_feed: db 10, 0

argv1_error_message:  db "[-] Aucun pid renseigné.", 10, 0
argv2_error_message:  db "[-] Aucune adresse pour le syscall renseigné.", 10, 0
argv_success_message: db "[*] Attachement au processus en cours...", 10, 0

argv1_invalid_message: db "[-] Le pid renseigné n'existe pas.", 10, 0
argv2_invalid_message: db "[-] L'adresse du syscall est invalide.", 10, 0

ptrace_error_message:   db "[-] ptrace n'as pas réussit à s'attacher.", 10, 0
ptrace_success_message: db "[+] Attaché au processus pid = %d", 10, 0

getregs_error_message:  db "[-] ptrace n'as pas réussit a lire les registres.", 10, 0
getregs_succes_message: db "[ ] Valeur du registre regs + %2d : 0x%lx", 10, 0

setregs_succes_message: db "[+] Registre regs + %2d modifé par : 0x%lx", 10, 0

save_regs_message:       db "[*] Sauvegarde des registres utilisé par mmap...", 10, 0
save_regs_saved_message: db "[ ] Registre regs + %2d sauvegardé. - 0x%lx", 10, 0

restore_regs_message:         db "[*] Restauration des registres utilisé par mmap...", 10, 0

mmap_message: db "[+] Adresse donnée par mmap : 0x%lx", 10, 0

clone_error_message: db "[-] clone a échoué.", 10, 0

debug_message: db "[ DEBUG ]", 10, 0

payload:      db 0x55, 0x48, 0x89, 0xe5, 0xbf, 0x00, 0x00, 0x00, 0x00, 0xe8, 0x00, 0x00, 0x00, 0x00, 0xb8, 0x00, 0x00, 0x00, 0x00, 0x5d, 0xc3
payload_size: equ $ - payload

section .bss
regs:       resq 27
regs_saved: resq 7

local_iov:  resq 2
remote_iov: resq 2

tid: resq 1

section .text
main:
  ; Sauvegarde argc/argv
  mov     argc, rdi
  mov     temp, rsi
  
  ; Vérifie que le pid est passé en argument
  mov     arg1, argv1_error_message
  cmp     argc, 2 ;
  jl      error   ; if (argc < 2) error

  ; Vérifie que l'adresse du syscall est passé en argument
  mov     arg1, argv2_error_message
  cmp     argc, 3 ;
  jl      error   ; if (argc < 3) error

  ; Convertit les chaînes en un entier et les stock
  mov     arg1, [temp + 8] ; argv[1]
  mov     arg2, NULL
  mov     arg3, 0
  call    strtol
  mov     pid, out

  mov     arg1, [temp + 16] ; argv[2]
  mov     arg2, NULL
  mov     arg3, 0
  call    strtol
  mov     syscall_addr, out

  ; Vérifie que le pid est valide
  mov     arg1, pid
  mov     arg2, 0
  call    kill

  mov     arg1, argv1_invalid_message
  cmp     out, 0
  jne     error

  ; Vérifie que l'adresse est valide
  mov     arg1, argv2_invalid_message
  cmp     syscall_addr, 0
  jle     error

  ; Les arguments sont valide
  mov     arg1, argv_success_message
  xor     rax, rax
  call    printf

  ; Attache au processus PID
  mov     arg1, PTRACE_ATTACH
  mov     arg2, pid
  mov     arg3, NULL
  mov     arg4, NULL
  call    ptrace

  ; Vérifie les erreurs
  mov     arg1, ptrace_error_message
  cmp     out, 0 ; 
  jl      error  ; ptrace(...) < 0

  ; Attend que le processus soit arrêté
  mov     arg1, pid
  mov     arg2, NULL
  mov     arg3, NULL
  call    waitpid

  ; Le processus est attaché
  mov     arg1, ptrace_success_message
  mov     arg2, pid
  xor     rax, rax
  call    printf
  
  call new_line

  call    get_regs
  call    save_regs

  ; Test pour debug
  mov     arg1, TARGET_R13
  mov     arg2, 0x42424242
  call    set_reg

  ; Modifier les registres pour forcer la cible a exécuter mmap
  mov     arg1, payload_size
  call    target_mmap

  mov     arg1, PTRACE_SINGLESTEP
  call    target_exec

  ; Affiche l'adresse donné par mmap
  mov     arg1, TARGET_RAX
  call    display_reg
  call    new_line

  mov     payload_addr, [regs + TARGET_RAX]

  ; Place le payload a l'adresse donné
  mov     arg1, pid
  mov     arg2, payload
  mov     arg3, payload_addr
  mov     arg4, payload_size
  call    write_payload

  ; Exécute le payload en arrière plan
  call    target_thread

  ; Replace les bonnes valeurs dans le registre pour que le programme continue correctement
  call    restore_regs

  ; Rend la main au programme cible
  mov     arg1, PTRACE_DETACH
  mov     arg2, pid
  mov     arg3, NULL
  mov     arg4, NULL
  call    ptrace

  ; Pause
  ;mov     func, 34
  ;syscall

  jmp     quit

target_thread:
  ; Crée un thread en fond dans le processus cible

  ; Crée une zone mémoire pour le thread
  mov     arg1, THREAD_SIZE
  call    target_mmap

  mov     arg1, PTRACE_SINGLESTEP
  call    target_exec

  ; Affiche l'adresse donné par mmap
  mov     arg1, TARGET_RAX
  call    display_reg
  call    new_line

  ; Récupère l'adresse du mmap
  mov     arg2, [regs + TARGET_RAX]

  ; Ajoute THREAD_SIZE
  add     arg2, THREAD_SIZE ;
                            ;
  ; Aligne à 16 bytes       ;
  and     arg2, -16         ; lea rsi, [rax, THREAD_SIZE]
                            ; and rsi, -16
  mov     arg1, TARGET_RSI  ;
  ; arg2 déjà pret          ;
  call    set_reg           ;  

  ; Clone
  mov     arg1, TARGET_RAX                                                     ;
  mov     arg2, clone                                                          ;
  call    set_reg                                                              ;
                                                                               ;
  mov     arg1, TARGET_RDI                                                     ;
  mov     arg2, 0x00000100 | 0x00000200 | 0x00000400 | 0x00000800 | 0x00010000 ;
  call    set_reg                                                              ;
                                                                               ;
  ; rsi déjà bon                                                               ;
                                                                               ;
  mov     arg1, TARGET_RDX                                                     ;
  mov     arg2, 0                                                              ;
  call    set_reg                                                              ; clone(addr, stack_top, CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD, NULL)
                                                                               ;
  mov     arg1, TARGET_R10                                                     ;
  mov     arg2, 0                                                              ;
  call    set_reg                                                              ;
                                                                               ;
  mov     arg1, TARGET_R8                                                      ;
  mov     arg2, 0                                                              ;
  call    set_reg                                                              ;
                                                                               ;
  mov     arg1, TARGET_RIP                                                     ;
  mov     arg2, syscall_addr                                                   ;
  call    set_reg                                                              ;

  mov     arg1, PTRACE_SINGLESTEP
  call    target_exec

  mov     temp, [regs + TARGET_RAX]

  mov     arg1, clone_error_message
  cmp     temp, 0
  jl      error

  mov     arg1, TARGET_RAX
  call    display_reg

  ret

write_payload:
  ; Ecrit un payload a l'adresse spécifier
  ; IN  : pid, payload, adresse de sortie, la taille du payload
  ; OUT :

  ; Le payload
  mov     [local_iov], arg2
  mov     [local_iov + 8], arg4

  ; La sortie
  mov     [remote_iov], arg3
  mov     [remote_iov+ 8], arg4

  ; Ecrit le payload
  ; arg1 est déjà bon
  lea     arg2, [local_iov]
  mov     arg3, 1
  lea     arg4, [remote_iov]
  mov     arg5, 1
  mov     arg6, 0
  call    process_vm_writev

  ret

target_exec:
  ; Exécute les instructions placé dans les registres du process cible
  ; IN  : mode
  ; OUT :

  ; Exécute le mmap dans le processus cible
  ; arg1 déjà bon
  mov     arg2, pid
  mov     arg3, NULL
  mov     arg4, NULL
  call    ptrace

  ; Attend que mmap se termine
  mov     arg1, pid
  mov     arg2, NULL
  mov     arg3, NULL
  call    waitpid

  ; Lit les nouveaux registres
  call    get_regs

  ret

target_mmap:
  ; Modifie les registre de la cible pour mettre un mmap
  ; IN  : taille voulu
  ; OUT :

  mov     temp, arg1

  mov     arg1, TARGET_RAX   ;
  mov     arg2, mmap         ;
  call    set_reg            ;
                             ;
  mov     arg1, TARGET_RDI   ;
  mov     arg2, NULL         ;
  call    set_reg            ;
                             ;
  mov     arg1, TARGET_RSI   ;
  mov     arg2, temp         ;
  call    set_reg            ;
                             ;
  mov     arg1, TARGET_RDX   ;
  mov     arg2, 7            ;
  call    set_reg            ;
                             ; mmap(NULL, 0x1000, PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)
  mov     arg1, TARGET_R10   ;
  mov     arg2, 0x22         ;
  call    set_reg            ;
                             ;
  mov     arg1, TARGET_R8    ;
  mov     arg2, -1           ;
  call    set_reg            ;
                             ;
  mov     arg1, TARGET_R9    ;
  mov     arg2, 0            ;
  call    set_reg            ;
                             ;
  mov     arg1, TARGET_RIP   ;
  mov     arg2, syscall_addr ;
  call    set_reg            ;

  call    new_line

  ret

restore_regs:
  ; Réstaure les registres utilisé par le processus
  ; IN  :
  ; OUT :

  ; Affichage
  mov     arg1, restore_regs_message
  xor     rax, rax
  call    printf
  
  push    i ; Sauvegarde la valeur de i de l'appellant
  xor     i, i
.loop:
  ; Restaure la valeur
  mov     arg1, i
  mov     arg2, [regs_saved + i]
  call    set_reg

  ; Prend tout les argument utilisé
  add     i, 8
  cmp     i, TARGET_GS
  jne     .loop

  call    new_line

  pop     i ; Restaure la valeur de i
  ret

save_regs:
  ; Sauvegarde les registres utilisé par le processus
  ; IN  :
  ; OUT :

  ; Affichage
  mov     arg1, save_regs_message
  xor     rax, rax
  call    printf

  push    i ; Sauvegarde la valeur de i de l'appellant
  xor     i, i
.loop:
  mov     temp, [regs + i]       ; 
  mov     [regs_saved + i], temp ; Sauvegarde dans regs_saved tout les registres utilisé par mmap
  
  ; Affiche l'avancement
  mov     arg1, save_regs_saved_message
  mov     arg2, i
  mov     arg3, [regs_saved + i]
  xor     rax, rax
  call    printf

  ; Prend tout les argument utilisé
  add     i, 8
  cmp     i, TARGET_GS ; mmap utilise jusqu'au registre r9
  jne     .loop

  call new_line

  pop     i ; Restaure la valeur de i
  ret

set_reg:
  ; Modifie la valeur du registre demandé
  ; IN  : registre cible, la valeur souhaité
  ; OUT :

  push    r14
  mov     temp, arg1 ;
  mov     r14, arg2  ; Save les arguments

  ; Modifier un registre
  mov     qword [regs + arg1], arg2
  mov     arg1, PTRACE_SETREGS
  mov     arg2, pid
  mov     arg3, NULL
  lea     arg4, [regs]
  call    ptrace

  ; Affiche l'information
  mov     arg1, setregs_succes_message
  mov     arg2, temp
  mov     arg3, r14
  xor     rax, rax
  call    printf
  
  pop     r14
  ret

display_all_regs:
  ; Affiche le contenu de tout les registres
  ; IN  :
  ; OUT :

  push    i ; Sauvegarde la valeur de i de l'appelant
  xor     i, i
.loop:
  mov     arg1, i
  call    display_reg

  add     i, 8
  cmp     i, TARGET_GS
  jne     .loop

  call    new_line

  pop     i ; Restaure la valeur de i
  ret

display_reg:
  ; Affiche le contenu du registre demandé
  ; IN  : registre
  ; OUT :

  mov     temp, arg1

  ; Affiche le registre
  mov     arg1, getregs_succes_message
  mov     arg2, temp
  mov     arg3, [regs + temp]
  xor     rax, rax
  call    printf

  ret

get_regs:
  ; Récupère les registres
  ; IN  :
  ; OUT :

  ; Récupèration des registres
  mov     arg1, PTRACE_GETREGS
  mov     arg2, pid
  mov     arg3, NULL
  lea     arg4, [regs]
  call    ptrace

  ; Vérifie les erreurs a la lecture
  mov     arg1, getregs_error_message
  cmp     out, 0
  jne     error

  ret

new_line:
  ; Affiche un \n
  ; IN  :
  ; OUT :

  ; Affiche le \n
  mov     arg1, line_feed
  xor     rax, rax
  call    printf

  ret

error:
  ; Quitte avec une erreur et un message
  ; IN  : message
  ; OUT :

  ; Affiche le message
  ; Le message se trouve déjà dans arg1
  xor     rax, rax
  call    printf

  ; Quitte avec une erreur
  mov     func, exit
  mov     arg1, 1
  syscall

quit:
  ; Quitte sans erreur
  ; IN  :
  ; OUT :
  mov     func, exit
  xor     arg1, arg1
  syscall

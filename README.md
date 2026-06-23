# Parasitoid

Le principe de ce projet est de crée une injection de code dans un processus actif en assembleur. De la même manière que les **Ravasides Parasitoïdes**, le programme va s'attacher au processus cible, placer un code malveillant en lui et l'exécuter avant de se détacher. De cette manière le code malveillant parait légétime au yeux de tout le monde puisqu'il se trouve dans un processus légitime.

# Avancement
Actuellement le programme arrive correctement a s'attacher, modifie les registres de la cible pour lui faire exécuter un ```mmap``` afin d'obtenir une zone mémoire pour placer le payload (interne au programme pour l'instant) et place le payload au bon endroit.

Pour vérifier :
```bash
./legit-process
# Dans une autre fenêtre
gdb -p $(pgrep legit-process) -batch -ex 'find /b 0x7fbde9f16000, 0x7fbdea085000, 0x0f, 0x05' 2>/dev/null # Récuperer l'adresse a la ligne 0x7f5e12981bbc <__internal_syscall_cancel+124>:	syscall
./parasitoid $(pgrep legit-process) 0x7f5e12981bbc
# Pour vérifier que le paylod est bien présent, regarder les 21 octets présents dans l'adresse donné par le mmap
# Dans la sortie de ./parasitoid, ex : [ ] Valeur du registre regs + 80 : 0x7f5e12b22000
pwndbg> x/21bx 0x7f5e12b22000
0x7f5e12b22000:	0x55	0x48	0x89	0xe5	0xbf	0x00	0x00	0x00
0x7f5e12b22008:	0x00	0xe8	0x00	0x00	0x00	0x00	0xb8	0x00
0x7f5e12b22010:	0x00	0x00	0x00	0x5d	0xc3
pwndbg> 
```

# Prérequis
nasm
gcc

# Installation
```bash
git clone https://github.com/IAidenI/Parasitoid
cd Parasitoid
make all
```

# Utilisation
```bash
./parasitoid <pid> <syscall_addr>
```

Pour récupèrer le pid : ```$(pgrep legit-process)```
Pour récupèrer l'adresse d'un syscall : ```gdb -p $(pgrep legit-process) -batch -ex 'find /b 0x7fbde9f16000, 0x7fbdea085000, 0x0f, 0x05' 2>/dev/null```

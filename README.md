# Parasitoid

Le principe de ce projet est de crée une injection de code dans un processus actif en assembleur. De la même manière que les **Ravasides Parasitoïdes**, le programme va s'attacher au processus cible, placer un code malveillant en lui et l'exécuter avant de se détacher. De cette manière le code malveillant parait légétime au yeux de tout le monde puisqu'il se trouve dans un processus légitime.

# Installation
```bash
git clone XXXX
cd Parasitoid
make all
```

# Utilisation
```bash
./parasitoid <pid> <syscall_addr>
```

Pour récupèrer le pid : ```$(pgrep legit-process)```
Pour récupèrer l'adresse d'un syscall : ```gdb -p $(pgrep legit-process) -batch -ex 'find /b 0x7fbde9f16000, 0x7fbdea085000, 0x0f, 0x05' 2>/dev/null```

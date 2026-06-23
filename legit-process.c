#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

void secret();
void secret() {
  printf("=== SECRET AREA ===\n");
  printf("Bien jouer tu a trouvé la section secret.");
  printf("===================\n");
}

void monitoring();
void monitoring() {
  unsigned long rax;
  unsigned long rdi;
  unsigned long rsi;
  unsigned long rdx;
  unsigned long r10;
  unsigned long r8;
  unsigned long r9;
  unsigned long rip;

  unsigned long r13;

  int i = 0;
  while (1) {
    system("clear");
    printf("=== SYSTEM MONITOR ===\n");
    system("uptime");
    system("free -h | head -2");
    
    __asm__("mov %%r13, %0" : "=r"(r13));
    printf("r13 = 0x%lx\n", r13);

    __asm__("mov %%rax, %0" : "=r"(rax));
    printf("rax = 0x%lx\n", rax);

    __asm__("mov %%rdi, %0" : "=r"(rdi));
    printf("rdi = 0x%lx\n", rdi);

    __asm__("mov %%rsi, %0" : "=r"(rsi));
    printf("rsi = 0x%lx\n", rsi);

    __asm__("mov %%rdx, %0" : "=r"(rdx));
    printf("rdx = 0x%lx\n", rdx);

    __asm__("mov %%r10, %0" : "=r"(r10));
    printf("r10 = 0x%lx\n", r10);

    __asm__("mov %%r8, %0" : "=r"(r8));
    printf("r8  = 0x%lx\n", r8);

    __asm__("mov %%r9, %0" : "=r"(r9));
    printf("r9  = 0x%lx\n", r9);

    __asm__("lea (%%rip), %0" : "=r"(rip));
    printf("rip = 0x%lx\n", rip);

    printf("======================\n");
    sleep(1);

    if (i++ == 300) break;
  }
}

int main() {
  __asm__("mov $0x41414141, %r13");
  monitoring();
  return 0;
}

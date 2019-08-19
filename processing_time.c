#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
  int clock_cycles;
  double fmax, time;

  // input clock cycles & Fmax
  if (argc == 3) {
    clock_cycles = strtol(argv[1],NULL,10);
    fmax         = strtod(argv[2],NULL);
  }
  else {
    printf("input clock_cycles: ");
    scanf("%d",&clock_cycles);

    printf("input Fmax[MHz]: ");
    scanf("%lf",&fmax);
  }

  time = clock_cycles / (fmax);

  printf("processing time: %lf[us]\n",time);

  return 0;
}

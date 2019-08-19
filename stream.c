#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ARRAY_SIZE 9
#define FIFO_SIZE 124

typedef enum state_t {
  S0,
  S1,
  S2,
  S3,
  S4,
  S5,
  S6,
  S7,
  S_INIT
} state_t;

typedef struct shift_reg{
  int a, b, c, d, e, f, g, h, i, j, k, l;
  int FIFO_0[FIFO_SIZE], FIFO_1[FIFO_SIZE];
  int ld_addr;
  int *input;
} shift_reg;

typedef struct reg_9 {
  int *p[ARRAY_SIZE];
} reg_9;

typedef struct sort_reg {
  int s0[ARRAY_SIZE];
  int s1[ARRAY_SIZE];
  int s2[ARRAY_SIZE];
  int s3[ARRAY_SIZE];
  int s4[ARRAY_SIZE];
  int s5[ARRAY_SIZE];
  int s6[ARRAY_SIZE];
  int s7[ARRAY_SIZE];
  int s8[ARRAY_SIZE];
  int s9[ARRAY_SIZE];
  int sa[ARRAY_SIZE];
} sort_reg;

void median_filter(int *input, int *output);
void stream_shift(shift_reg *shift);
void state_machine(state_t *state, int ld_addr);
void init_sort_reg(sort_reg *sort, reg_9 process_reg, state_t state);
void hardware_sort(sort_reg *sort);
void odd_even_sort(sort_reg *sort);
void median_sort(sort_reg *sort);
void sort2(int *a, int *b);
void sort3(int *a, int *b, int *c);
void swap2(int *a, int *b);
int min2(int a, int b);
int max2(int a, int b);

int main (int argc, char *argv[]) {
  int i,j,k;

  FILE *fp;
  char filename[256];
  char period[] = "@ ";
  char readline[256];
  char *addr_char, *data_char[8];
  int addr;
  int input[0x4000], output[0x4000];

  if (argc == 3) {
    strcpy(filename,argv[1]);
  }
  else {
    printf("file open error\n");
    return 0;
  }

  // input img
  fp = fopen(filename,"r");
  while (fgets(readline,256,fp) != NULL) {
    addr_char = strtok(readline,period);
    addr = strtol(addr_char,NULL,16);
    for (i=0;i<8;i++) {
      data_char[i] = strtok(NULL,period);
      input[addr-0x8000+i] = strtol(data_char[i],NULL,16);
    }
  }
  fclose(fp);

  // median_filter
  median_filter(input,output);

  // output img
  strcpy(filename,argv[2]);
  fp = fopen(filename,"w");
  for (i=0;i<0x4000;i+=8) {
    for (j=0;j<7;j++) {
      fprintf(fp,"%02x ",output[i+j]);
    }
    fprintf(fp,"%02x\n",output[i+7]);
  }
  fclose(fp);

  return 0;
}

void median_filter (int *input, int *output) {
  int i, j, k;
  int clock_cycles = 0;
  short finish = 0, out_flag = 0;
  state_t state = S_INIT;

  int ld_addr = 0x0000, st_addr = 0x0000; // addr
  shift_reg shift;
  sort_reg sort_0, sort_1;
  reg_9 process_0, process_1;
  FILE *fp;

  // initialize
  shift.input = input;
  shift.a = 0;
  shift.b = 0;
  shift.c = 0;
  shift.d = 0;
  shift.e = 0;
  shift.f = 0;
  shift.g = 0;
  shift.h = 0;
  shift.i = 0;
  shift.j = 0;
  shift.k = 0;
  shift.l = 0;
  shift.ld_addr = ld_addr;
  for (i=0;i<FIFO_SIZE;i++) {
    shift.FIFO_0[i] = 0;
    shift.FIFO_1[i] = 0;
  }
  
  for (i=0;i<ARRAY_SIZE;i++) {
    sort_0.s0[i] = 0;
    sort_0.s1[i] = 0;
    sort_0.s2[i] = 0;
    sort_0.s3[i] = 0;
    sort_0.s4[i] = 0;
    sort_0.s5[i] = 0;
    sort_0.s6[i] = 0;
    sort_0.s7[i] = 0;
    sort_0.s8[i] = 0;
    sort_0.s9[i] = 0;
    sort_0.sa[i] = 0;

    sort_1.s0[i] = 0;
    sort_1.s1[i] = 0;
    sort_1.s2[i] = 0;
    sort_1.s3[i] = 0;
    sort_1.s4[i] = 0;
    sort_1.s5[i] = 0;
    sort_1.s6[i] = 0;
    sort_1.s7[i] = 0;
    sort_1.s8[i] = 0;
    sort_1.s9[i] = 0;
    sort_1.sa[i] = 0;
  }
  process_0.p[0] = &shift.a;
  process_0.p[1] = &shift.b;
  process_0.p[2] = &shift.c;
  process_0.p[3] = &shift.e;
  process_0.p[4] = &shift.f;
  process_0.p[5] = &shift.g;
  process_0.p[6] = &shift.i;
  process_0.p[7] = &shift.j;
  process_0.p[8] = &shift.k;

  process_1.p[0] = &shift.b;
  process_1.p[1] = &shift.c;
  process_1.p[2] = &shift.d;
  process_1.p[3] = &shift.f;
  process_1.p[4] = &shift.g;
  process_1.p[5] = &shift.h;
  process_1.p[6] = &shift.j;
  process_1.p[7] = &shift.k;
  process_1.p[8] = &shift.l;

  // ----- hardware impl ----- //
  fp = fopen("./stream.log","w");
  do {
    fprintf(fp,"# ==== clock: %d ==== \n",clock_cycles);
    fprintf(fp,"# state:%d ld_addr:%04x st_addr:%04x ddout:%02x%02x\n",state,ld_addr+0x8000,st_addr+0xc000,sort_1.sa[4],sort_0.s9[4]);
    fprintf(fp,"# a:%02x b:%02x c:%02x d:%02x <- [FIFO_1] <-\n",shift.a, shift.b, shift.c, shift.d);
    fprintf(fp,"# e:%02x f:%02x g:%02x h:%02x <- [FIFO_0] <-\n",shift.e, shift.f, shift.g, shift.h);
    fprintf(fp,"# i:%02x j:%02x k:%02x l:%02x\n",shift.i, shift.j, shift.k, shift.l);
    fprintf(fp,"# \n");

    // break
    if (finish) {
      break;
    }

    // output
    output[st_addr] = sort_1.sa[4];
    output[st_addr + 1] = sort_0.s9[4];

    // hardware sort
    hardware_sort(&sort_1);
    hardware_sort(&sort_0);
    printf("@%04x ",st_addr + 0x8000);
    init_sort_reg(&sort_1, process_1, state);
    printf("@%04x ",st_addr - 1 + 0x8000);
    init_sort_reg(&sort_0, process_0, state);
    for (i=0;i<9;i++) {
      printf("%02x ",sort_1.s7[i]);
    }
    printf("\n");

    // state_machine
    state_machine(&state, ld_addr);

    // stream shift reg
    stream_shift(&shift);

    // addr_& finish manage
    finish = (st_addr == 0x3ffe);
    st_addr = (st_addr < 0x3ffe) ? st_addr + (out_flag*2) : -0xc000;
    out_flag = (ld_addr == 0x96) ? 1 : out_flag;
    ld_addr = (ld_addr < 0x7ffe) ? ld_addr + 2 : -0x8000;

    shift.ld_addr = ld_addr;

    clock_cycles++;
  } while (1);
}

void stream_shift(shift_reg *shift) {
  int i,j,k;

  shift->a = shift->c;
  shift->b = shift->d;

  shift->c = shift->FIFO_1[0];
  shift->d = shift->FIFO_1[1];
  for (i=0;i<FIFO_SIZE-2;i+=2) {
    shift->FIFO_1[i]   = shift->FIFO_1[i+2];
    shift->FIFO_1[i+1] = shift->FIFO_1[i+3];
  }
  shift->FIFO_1[FIFO_SIZE-2] = shift->e;
  shift->FIFO_1[FIFO_SIZE-1] = shift->f; 
  shift->e = shift->g;
  shift->f = shift->h;

  shift->g = shift->FIFO_0[0];
  shift->h = shift->FIFO_0[1];
  for (i=0;i<FIFO_SIZE-2;i+=2) {
    shift->FIFO_0[i]   = shift->FIFO_0[i+2];
    shift->FIFO_0[i+1] = shift->FIFO_0[i+3];
  }
  shift->FIFO_0[FIFO_SIZE-2] = shift->i;
  shift->FIFO_0[FIFO_SIZE-1] = shift->j;

  shift->i = shift->k;
  shift->j = shift->l;

  shift->k = shift->input[shift->ld_addr];
  shift->l = shift->input[shift->ld_addr+1];
}

void state_machine(state_t *state, int ld_addr) {
  switch (*state) {
    case S0:
      *state = S1;
      break;
    case S1:
      if (ld_addr % 0x80 == 0) {
        *state = S2;
      }
      break;
    case S2:
      *state = S3;
      break;
    case S3:
      if (ld_addr % 0x80 == 0) {
        *state = (ld_addr==0x4000) ? S5 : S4;
      }
      break;
    case S4:
      *state = S3;
      break;
    case S5:
      *state = S6;
      break;
    case S6:
      if (ld_addr % 0x80 == 0) {
        *state = S7;
      }
      break;
    case S7:
      *state = S_INIT;
      break;
    case S_INIT:
      if (ld_addr == 0x0080) {
        *state = S0;
      }
      break;
    default :
      *state = S_INIT;
      break;
  }
}

void init_sort_reg(sort_reg *sort, reg_9 process_reg, state_t state) {
  int i;

  switch (state) {
    case S0:
      sort->s0[0] = 0x00;
      sort->s0[1] = 0x00;
      sort->s0[2] = 0x00;
      sort->s0[3] = 0x00;
      sort->s0[4] = *process_reg.p[4];
      sort->s0[5] = 0xff;
      sort->s0[6] = 0xff;
      sort->s0[7] = 0xff;
      sort->s0[8] = 0xff;
      break;
    case S1:
      sort->s0[0] = 0x00;
      sort->s0[1] = 0x00;
      sort->s0[2] = 0x00;
      sort->s0[3] = 0x00;
      sort->s0[4] = *process_reg.p[4];
      sort->s0[5] = 0xff;
      sort->s0[6] = 0xff;
      sort->s0[7] = 0xff;
      sort->s0[8] = 0xff;
      break;
    case S2:
      sort->s0[0] = 0x00;
      sort->s0[1] = 0x00;
      sort->s0[2] = 0x00;
      sort->s0[3] = 0x00;
      sort->s0[4] = *process_reg.p[4];
      sort->s0[5] = 0xff;
      sort->s0[6] = 0xff;
      sort->s0[7] = 0xff;
      sort->s0[8] = 0xff;
      break;
    case S3:
      for (i=0;i<ARRAY_SIZE;i++) {
        sort->s0[i] = *process_reg.p[i];
      }
      break;
    case S4:
      sort->s0[0] = 0x00;
      sort->s0[1] = 0x00;
      sort->s0[2] = 0x00;
      sort->s0[3] = 0x00;
      sort->s0[4] = *process_reg.p[4];
      sort->s0[5] = 0xff;
      sort->s0[6] = 0xff;
      sort->s0[7] = 0xff;
      sort->s0[8] = 0xff;
      break;
    case S5:
      sort->s0[0] = 0x00;
      sort->s0[1] = 0x00;
      sort->s0[2] = 0x00;
      sort->s0[3] = 0x00;
      sort->s0[4] = *process_reg.p[4];
      sort->s0[5] = 0xff;
      sort->s0[6] = 0xff;
      sort->s0[7] = 0xff;
      sort->s0[8] = 0xff;
      break;
    case S6:
      sort->s0[0] = 0x00;
      sort->s0[1] = 0x00;
      sort->s0[2] = 0x00;
      sort->s0[3] = 0x00;
      sort->s0[4] = *process_reg.p[4];
      sort->s0[5] = 0xff;
      sort->s0[6] = 0xff;
      sort->s0[7] = 0xff;
      sort->s0[8] = 0xff;
      break;
    case S7:
      sort->s0[0] = 0x00;
      sort->s0[1] = 0x00;
      sort->s0[2] = 0x00;
      sort->s0[3] = 0x00;
      sort->s0[4] = *process_reg.p[4];
      sort->s0[5] = 0xff;
      sort->s0[6] = 0xff;
      sort->s0[7] = 0xff;
      sort->s0[8] = 0xff;
      break;
    default:
      sort->s0[0] = 0x00;
      sort->s0[1] = 0x00;
      sort->s0[2] = 0x00;
      sort->s0[3] = 0x00;
      sort->s0[4] = *process_reg.p[4];
      sort->s0[5] = 0xff;
      sort->s0[6] = 0xff;
      sort->s0[7] = 0xff;
      sort->s0[8] = 0xff;
      break;
  }
  //printf("%02x\n",sort->s0[4]);
}

void hardware_sort(sort_reg *sort) {
  int i;

  for (i=0;i<ARRAY_SIZE;i++) {
    sort->sa[i] = sort->s9[i];
    sort->s9[i] = sort->s8[i];
    sort->s8[i] = sort->s7[i];
    sort->s7[i] = sort->s6[i];
    sort->s6[i] = sort->s5[i];
    sort->s5[i] = sort->s4[i];
    sort->s4[i] = sort->s3[i];
    sort->s3[i] = sort->s2[i];
    sort->s2[i] = sort->s1[i];
    sort->s1[i] = sort->s0[i];
  }

  //odd_even_sort(sort);
  median_sort(sort);

  //for (i=0;i<9;i++) {
  //  printf(" %02x", sort->sa[i]);
  //}
}

void odd_even_sort(sort_reg *sort) {
  // s9
  sort2(&sort->s9[0], &sort->s9[1]);
  sort2(&sort->s9[2], &sort->s9[3]);
  sort2(&sort->s9[4], &sort->s9[5]);
  sort2(&sort->s9[6], &sort->s9[7]);

  // s8
  sort2(&sort->s8[1], &sort->s8[2]);
  sort2(&sort->s8[3], &sort->s8[4]);
  sort2(&sort->s8[5], &sort->s8[6]);
  sort2(&sort->s8[7], &sort->s8[8]);

  // s7
  sort2(&sort->s7[0], &sort->s7[1]);
  sort2(&sort->s7[2], &sort->s7[3]);
  sort2(&sort->s7[4], &sort->s7[5]);
  sort2(&sort->s7[6], &sort->s7[7]);

  // s6
  sort2(&sort->s6[1], &sort->s6[2]);
  sort2(&sort->s6[3], &sort->s6[4]);
  sort2(&sort->s6[5], &sort->s6[6]);
  sort2(&sort->s6[7], &sort->s6[8]);

  // s5
  sort2(&sort->s5[0], &sort->s5[1]);
  sort2(&sort->s5[2], &sort->s5[3]);
  sort2(&sort->s5[4], &sort->s5[5]);
  sort2(&sort->s5[6], &sort->s5[7]);

  // s4
  sort2(&sort->s4[1], &sort->s4[2]);
  sort2(&sort->s4[3], &sort->s4[4]);
  sort2(&sort->s4[5], &sort->s4[6]);
  sort2(&sort->s4[7], &sort->s4[8]);

  // s3
  sort2(&sort->s3[0], &sort->s3[1]);
  sort2(&sort->s3[2], &sort->s3[3]);
  sort2(&sort->s3[4], &sort->s3[5]);
  sort2(&sort->s3[6], &sort->s3[7]);

  // s2
  sort2(&sort->s2[1], &sort->s2[2]);
  sort2(&sort->s2[3], &sort->s2[4]);
  sort2(&sort->s2[5], &sort->s2[6]);
  sort2(&sort->s2[7], &sort->s2[8]);

  // s1
  sort2(&sort->s1[0], &sort->s1[1]);
  sort2(&sort->s1[2], &sort->s1[3]);
  sort2(&sort->s1[4], &sort->s1[5]);
  sort2(&sort->s1[6], &sort->s1[7]);
}

void median_sort(sort_reg *sort) {
  // s1
  sort2(&sort->s1[0], &sort->s1[1]);
  sort2(&sort->s1[2], &sort->s1[3]);

  sort2(&sort->s1[5], &sort->s1[6]);
  sort2(&sort->s1[7], &sort->s1[8]);

  // s2
  sort2(&sort->s2[0], &sort->s2[2]);
  sort2(&sort->s2[1], &sort->s2[3]);

  sort2(&sort->s2[5], &sort->s2[7]);
  sort2(&sort->s2[6], &sort->s2[8]);

  // s3
  sort2(&sort->s3[0], &sort->s3[5]); // min

  sort2(&sort->s3[1], &sort->s3[2]);
  sort2(&sort->s3[6], &sort->s3[7]);

  sort2(&sort->s3[3], &sort->s3[8]); // max

  // s4
  sort2(&sort->s4[1], &sort->s4[6]);
  sort2(&sort->s4[2], &sort->s4[7]);
  sort2(&sort->s4[3], &sort->s4[5]);

  // s5
  sort2(&sort->s5[1], &sort->s5[3]); // min
  sort2(&sort->s5[2], &sort->s5[6]);
  sort2(&sort->s5[5], &sort->s5[7]); // max

  // s6
  sort2(&sort->s6[2], &sort->s6[3]);
  sort2(&sort->s6[5], &sort->s6[6]);

  // s7
  sort2(&sort->s7[2], &sort->s7[5]); // min
  sort2(&sort->s7[3], &sort->s7[6]); // max

  // s8
  sort->s8[4] = max2(sort->s8[3],sort->s8[4]);

  // s9
  sort->s9[4] = min2(sort->s9[4],sort->s9[5]);
}

int min2(int a, int b) {
  int min;
  min = (a < b) ? a : b;
  return min;
}

int max2(int a, int b) {
  int max;
  max = (a < b) ? b : a;
  return max;
}

void sort2(int *a, int *b) {
  int temp;

  if (*a > *b) {
    temp = *a;
    *a = *b;
    *b = temp;
  }
}

void sort3(int *a, int *b, int *c) {
  sort2(a,b);
  sort2(b,c);
  sort2(a,b);
}

void swap2(int *a, int *b) {
  int temp;

  temp = *a;
  *a = *b;
  *b = temp;
}

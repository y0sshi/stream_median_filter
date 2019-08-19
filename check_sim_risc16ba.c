/*
 *  dump2pgm
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#define BUF_SIZE         80
#define ROW_SIZE         128     /* 縦の画像サイズ */
#define COLUMN_SIZE      128     /* 横の画像サイズ */
#define DEPTH            256     /* 階調 */
#define ITEMS_PER_LINE   8       /* ログファイル1行の画素数 */
#define PGM_MAGIC1       'P'       /* PGMヘッダのマジックナンバー #1 */
#define PGM_MAGIC2       '5'       /* PGMヘッダのマジックナンバー #2 */

typedef unsigned char uchar;

int  convert(FILE *rp, FILE *wp);
void usage(char *name);
void cantopen(char *name);

int main(int argc, char **argv)
{
  FILE *rp, *wp;
  int  r;
  
  if (argc != 3)
    usage(*argv); /* no return */
  if ((rp = fopen(argv[1], "rb")) == NULL)
    cantopen(argv[1]);
  if ((wp = fopen(argv[2], "wb")) == NULL)
    cantopen(argv[2]);
  r = convert(rp, wp);
  fclose(rp);
  fclose(wp);
  return (r);
}

int convert(FILE *rp, FILE *wp)
{
  uchar pixel;
  char  buf[BUF_SIZE];
  char  *p;
  int   line;
  int   i;
  
  /* PGMへッダ */
  fprintf(wp, "%c%c\n", PGM_MAGIC1, PGM_MAGIC2);
  fprintf(wp, "%d %d\n", ROW_SIZE, COLUMN_SIZE);
  fprintf(wp, "%d\n", DEPTH - 1);
  /* 画素データ */
  line = 1;
  while (fgets(buf, BUF_SIZE, rp) != NULL) {
    p = buf;
    for (i = 0; i < ITEMS_PER_LINE; i++) {
      while (isspace(*(uchar *)p))
	++p;
      if (*p == 'x' || *(p + 1)== 'x') {
	fprintf(stderr, "%d行目に不定値があります: %s\n", line, p);
	return (-1);
      }
      else if (!isxdigit(*(uchar *)p) && !isxdigit(*((uchar *)p + 1))) {
	fprintf(stderr, "入力ファイルのフォーマットエラー\n");
	return (-1);
      }
      pixel = strtol(p, (char **)NULL, 16);
      fputc(pixel, wp);
      p += 2;
    }
    line++;
  }
  return (0);
}


void usage(char *name)
{
  fprintf(stderr, "使用法: %s <メモリダンプファイル> <出力ファイル>\n", name);
  exit(1);
}


void cantopen(char *name)
{
  fprintf(stderr, "ファイルをオープンできません: %s\n", name);
  exit(1);
}

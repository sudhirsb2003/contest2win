/*  POTM ENTRY:  crucigramista			*/
/*  Your Name:   Andre' Wilhelmus		*/
/*  Your email:  awilhelm@hvsag01.att.com	*/

/*  Version:	 5 (960122)			*/

#define DEBUG 0
#define TEST 0

#include <stdio.h>
#if __MWERKS__
#include <stdlib.h>
#include <math.h>
#else
#ifdef __APPLE_CC__
#include "sys/malloc.h" // mac os x
#else
#include "malloc.h" // linux, windows
#endif

#include <signal.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <memory.h>
#endif
#include <string.h>

#define false 0
#define true 1

typedef int bool;

#define MAX_TIME 597

extern char *optarg;		/* The address of the option argument */
extern int errno;		/* The error number */
extern int optind;		/* The index to the next argument */
	
static unsigned int max_time = MAX_TIME;
static bool time_out = false;

extern void exit();
long random();

#define HOR 1
#define VERT 2
#define CROSS 3

typedef struct Word
{
  struct Word *next;
  int len;
  bool busy;
  int x;
  int y;
  int orient;
  unsigned char word[21];
} Word;

typedef struct Used
{
  int x;
  int y;
  int orient;
} Used;

typedef struct Letter
{
  struct Letter *next;
  Word *word;
  int pos;
} Letter;

typedef struct Connector
{
  unsigned char letter;
  int pos;
} Connector;

typedef struct Fit
{
  int begin;
  int end;
  int nr_left;
  Connector left[15];
  int nr_right;
  Connector right[15];
} Fit;

Word *headlen[21];
Word *taillen[21];
Word *head_word;
unsigned char puzzle[22][22];
unsigned char best_puzzle[22][22];
Used used[225];			/* occupied squares */
int hv[22][22];			/* horizontal and/or vertical */
int word_count;
int connectors;
int filled_squares;
int best_word_count = 0;
int best_connectors = 0;
int best_filled_squares = 0;
int better_word_count = 0;
int better_connectors = 0;
int better_filled_squares = 0;
Letter *head_letter[128];
Letter *head_letter2[128][128];
Letter *tail_letter2[128][128];
Used pending[225];
int nr_pending;
int current_pending;
bool trigger = false;
static char hv_char[] = " -|+";
static bool fit_words2();

/* time's up */

#if __MWERKS__
#else
static void
alarm_signal(i)
int i;
{
  struct rusage rusage;
  long time_left = 0;

  i = i;
  if (getrusage(0, &rusage) == 0) /* get used cpu time */
    time_left = max_time - rusage.ru_utime.tv_sec - rusage.ru_stime.tv_sec;
  if (time_left > 0)		/* still some time left? */
  {
    (void) signal(SIGALRM, alarm_signal);
    (void) alarm((unsigned int) time_left);
  }
  else				/* time's really up */
    time_out = true;
}
#endif

/* allocate memory */

static char *my_malloc(bytes)
int bytes;
{
  char *p;
  p = malloc(bytes);
  if (p == 0)
  {
    fprintf(stdout, "malloc(%d) failed\n", bytes);
    exit(1);
  }
  return p;
}

static void
init_word()
{
  int i;
  
  for (i = 0; i <= 15; i++)
    headlen[i] = 0;
}

static void
read_words(filename)
char *filename;
{
  FILE *fp;
  char a_word[21];
  Word *new_word;
  Word *nexthead = 0;
  int i;

  init_word();
  if ((fp = fopen(filename, "r")) == 0)
  {
    fprintf(stderr, "Error on fopen(%s)\n",
	    filename);
    exit(1);
  }
  while (fscanf(fp, "%s", a_word) == 1)
  {
    new_word = (Word *) my_malloc(sizeof(Word));
    (void) strcpy((char *) new_word->word, (char *) a_word);
    new_word->len = strlen(a_word);
    new_word->next = headlen[new_word->len];
    headlen[new_word->len] = new_word;
    if (!taillen[new_word->len])
      taillen[new_word->len] = new_word;
  }

  for (i = 15; i >= 2; --i)	/* make one list with increasing length */
  {
    if (taillen[i])
    {
      taillen[i]->next = nexthead;
      nexthead = headlen[i];
    }
  }
  head_word = nexthead;
}

static void
init_board()
{
  register int h;
  register int v;

  for (v = 0; v < 22; v++)
  {
    for (h = 0; h < 22; h++)
    {
      puzzle[h][v] = '\0';
      hv[h][v] = 0;
    }
  }
}

static void
init()
{
  register Word *word;

  for (word = head_word; word; word = word->next)
    word->busy = false;
  init_board();
  filled_squares = 0;
  word_count = 0;
  connectors = 0;
}

static void
init_letter()
{
  register int i;
  int j;
  Letter *tail_letter[128];
  Letter *new_letter;
  Word *word;
  unsigned char *a_word;

  for (i = 'a'; i <= 'z'; i++)
  {
    head_letter[i] = 0;
    tail_letter[i] = 0;
  }
  for (word = head_word; word; word = word->next)
  {
    a_word = word->word;
    for (i = 0; a_word[i]; i++)
    {
      j = a_word[i];
      new_letter = (Letter *) my_malloc(sizeof(Letter));
      new_letter->word = word;
      new_letter->pos = i;
      new_letter->next = 0;
      if (head_letter[j])
	tail_letter[j]->next = new_letter;
      else
	head_letter[j] = new_letter;
      tail_letter[j] = new_letter;
    }
  }
}

static void
init_letter2()
{
  register int i;
  int j;
  int k;
  Letter *new_letter;
  Word *word;
  unsigned char *a_word;

  for (i = 'a'; i <= 'z'; i++)
  {
    for (j = 'a'; j <= 'z'; j++)
    {
      head_letter2[i][j] = 0;
      tail_letter2[i][j] = 0;
    }
  }
  for (word = head_word; word; word = word->next)
  {
    a_word = word->word;
    for (i = 0; i < word->len-1; i++)
    {
      j = a_word[i];
      k = a_word[i+1];
      new_letter = (Letter *) my_malloc(sizeof(Letter));
      new_letter->word = word;
      new_letter->pos = i;
      new_letter->next = 0;
      if (head_letter2[j][k])
	tail_letter2[j][k]->next = new_letter;
      else
	head_letter2[j][k] = new_letter;
      tail_letter2[j][k] = new_letter;
    }
  }
}

static void
print_board(board)
unsigned char board[22][22];
{
  register int h;
  register int v;

  for (v = 1; v <= 15; v++)
  {
    for (h = 1; h <= 15; h++)
    {
      if (board[h][v])
	fprintf(stdout, "%c", board[h][v]);
      else
#if DEBUG
	fprintf(stdout, " ");
#else
	fprintf(stdout, "-");
#endif
    }
#if DEBUG
    fprintf(stdout, "   ");
    for (h = 1; h <= 15; h++)
      fprintf(stdout, "%c", hv_char[hv[h][v]]);
#endif    
    fprintf(stdout, "\n");
  }
#if TEST
  fprintf(stdout, "\n");
#endif
  fflush(stdout);
}

static bool
save_puzzle()
{
  register int h;
  register int v;
  bool saved = false;

#if DEBUG
  if (trigger)
    fprintf(stderr, "save_puzzle\n");
#endif
  if (word_count > best_word_count ||
      word_count == best_word_count &&
      (connectors > best_connectors ||
       connectors == best_connectors && filled_squares > best_filled_squares))
  {
#if TEST
    fprintf(stderr, "%d words, %d connectors, %d filled squares\n",
            word_count, connectors, filled_squares);
    print_board(puzzle);
#endif
    for (v = 1; v <= 15; v++)
    {
      for (h = 1; h <= 15; h++)
        best_puzzle[h][v] = puzzle[h][v];
    }
    best_word_count = word_count;
    best_connectors = connectors;
    best_filled_squares = filled_squares;
    saved = true;
  }
#if DEBUG
  if (trigger)
    fprintf(stderr, "save_puzzle: %d\n", saved);
#endif
  return saved;
}

#if DEBUG
static void
check_pending()
{
  int i;
  
  for (i = 0; i < nr_pending; i++)
  {
    if (pending[i].x < 1 || pending[i].x > 15 || pending[i].y < 1 || pending[i].y > 15 ||
        pending[i].orient > 3)
    {
      fprintf(stderr, "check_pending %d %d %d\n", pending[i].x, pending[i].y, pending[i].orient);
      exit(1);
    }
  }
}
#endif

static bool
find_pending(a_word, x, y, orient)
Word *a_word;
int x;
int y;
int orient;
{
  register int i;
  unsigned char *word = a_word->word;
  bool side;

#if DEBUG  
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "find_pending error %s %d %d %d\n", word, x, y, orient);
    exit(1);
  }
  if (trigger)
    fprintf(stderr, "find_pending %s %d %d %d %d\n", word, x, y, orient);
#endif
  if (orient == HOR)
  {
    for (i = 0; word[i]; i++)
    {
      if (!puzzle[x+i][y])	/* free? */
      {
        side = false;
        if (hv[x+i][y-1] & HOR)
        {
          side = true;
          if (!head_letter2[puzzle[x+i][y-1]][word[i]])
            return false;
          pending[nr_pending].y = y-1;
        }
        if (hv[x+i][y+1] & HOR)
        {
          side = true;
          if (!head_letter2[word[i]][puzzle[x+i][y+1]])
            return false;
          pending[nr_pending].y = y;
        }
        if (side)
        {
          pending[nr_pending].orient = VERT;
          pending[nr_pending].x = x+i;
#if DEBUG
          if (trigger)
            fprintf(stderr, "pending = %d, x = %d, y = %d\n", nr_pending, x+i, y);
#endif
          nr_pending++;
#if DEBUG 
          if (nr_pending >= 225)
          {
            fprintf(stderr, "nr_pending overflow\n");
            exit(1);
          }
#endif
        }
      }
    }
  }
  else				/* vertical */
  {
    for (i = 0; word[i]; i++)
    {
      if (!puzzle[x][y+i])	/* free? */
      {
        side = false;
        if (hv[x-1][y+i] & VERT)
        {
          side = true;
          if (!head_letter2[puzzle[x-1][y+i]][word[i]])
            return false;
          pending[nr_pending].x = x-1;
        }
        if (hv[x+1][y+i] & VERT)
        {
          side = true;
          if (!head_letter2[word[i]][puzzle[x+1][y+i]])
            return false;
          pending[nr_pending].x = x;
        }
        if (side)
        {
          pending[nr_pending].y = y+i;
          pending[nr_pending].orient = HOR;
#if DEBUG
          if (trigger)
            fprintf(stderr, "pending = %d, x = %d, y = %d\n", nr_pending, x, y+i);
#endif
          nr_pending++;
#if DEBUG 
          if (nr_pending >= 225)
          {
            fprintf(stderr, "nr_pending overflow\n");
            exit(1);
          }
#endif
        }
      }
    }
  }
#if DEBUG
  check_pending();
#endif
  return true;
}

static void
put_word(a_word, x, y, orient)
Word *a_word;
int x;
int y;
int orient;
{
  register int i;
  unsigned char *word = a_word->word;
#if DEBUG
  bool error = false;

  if (a_word->busy)
    error = true;
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "put_word error %s %d %d %d\n", word, x, y, orient);
    exit(1);
  }
  if (trigger)
    fprintf(stderr, "put_word %s %d %d %d\n", word, x, y, orient);
#endif
  a_word->x = x;
  a_word->y = y;
  a_word->orient = orient;
  a_word->busy = true;
  word_count++;
#if DEBUG
  if (word_count >= 200)
  {
    fprintf(stderr, "word_count overflow\n");
    exit(1);
  }
#endif
  if (orient == HOR)
  {
#if DEBUG
    if (puzzle[x-1][y] || puzzle[x+a_word->len][y])
      error = true;
#endif
    for (i = 0; word[i]; i++)
    {
      if (!puzzle[x+i][y])	/* free? */
      {
	used[filled_squares].x = x+i;
	used[filled_squares].y = y;
	used[filled_squares].orient = orient;
	filled_squares++;
#if DEBUG
	if (filled_squares >= 225)
	{
	  fprintf(stderr, "filled_squares overflow\n");
	  exit(1);
	}
#endif
	puzzle[x+i][y] = word[i];
      }
      else			/* occupied */
      {
#if DEBUG
        if (puzzle[x+i][y] != word[i])
          error = true;
#endif
	connectors++;
      }
      hv[x+i][y] |= orient;
/*      fprintf(stderr, "put letter %c, orient %d\n", puzzle[x+i][y], hv[x+i][y]);*/
    }
  }
  else				/* vertical */
  {
#if DEBUG
    if (puzzle[x][y-1] || puzzle[x][y+a_word->len])
      error = true;
#endif
    for (i = 0; word[i]; i++)
    {
      if (!puzzle[x][y+i])	/* free? */
      {
	used[filled_squares].x = x;
	used[filled_squares].y = y+i;
	used[filled_squares].orient = orient;
	filled_squares++;
#if DEBUG
	if (filled_squares >= 225)
	{
	  fprintf(stderr, "filled_squares overflow\n");
	  exit(1);
	}
#endif
	puzzle[x][y+i] = word[i];
      }
      else			/* occupied */
      {
#if DEBUG
        if (puzzle[x][y+i] != word[i])
          error = true;
#endif
	connectors++;
      }
      hv[x][y+i] |= orient;
/*      fprintf(stderr, "put letter %c, orient %d\n", puzzle[x][y+i], hv[x][y+i]);*/
    }
  }
#if DEBUG
  if (error)
  {
    fprintf(stderr, "put_word error %s %d %d %d\n", word, x, y, orient);
    print_board(puzzle);
    exit(1);
  }
  if (trigger)
    print_board(puzzle);
#endif
}

static void
remove_word(a_word, x, y, orient)
Word *a_word;
int x;
int y;
int orient;
{
  register int i;

#if DEBUG
  bool error = false;
  
  if (!a_word->busy)
    error = true;
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "remove_word error %d %d %d\n", x, y, orient);
    exit(1);
  }
  if (trigger)
    fprintf(stderr, "remove %s %d %d %d\n", a_word->word, x, y, orient);
#endif
  a_word->busy = false;
  --word_count;
  if (orient == HOR)
  {
    for (i = x; puzzle[i][y]; i++)
    {
#if DEBUG
      if (a_word->word[i-x] != puzzle[i][y])
        error = true;
#endif
      if (hv[i][y] == CROSS)	/* connector? */
	--connectors;
      else
      {
	--filled_squares;
	puzzle[i][y] = '\0';
      }
      hv[i][y] &= ~orient;
    }
  }
  else				/* vertical */
  {
    for (i = y; puzzle[x][i]; i++)
    {
#if DEBUG
      if (a_word->word[i-y] != puzzle[x][i])
        error = true;
#endif
      if (hv[x][i] == CROSS)	/* connector? */
	--connectors;
      else
      {
	--filled_squares;
	puzzle[x][i] = '\0';
      }
      hv[x][i] &= ~orient;
    }
  }
#if DEBUG
  if (error)
  {
    fprintf(stderr, "remove_word error %s %d %d %d\n", a_word->word, x, y, orient);
    print_board(puzzle);
    exit(1);
  }
  if (trigger)
    print_board(puzzle);
#endif
}

#if DEBUG
static void
print_fit(fit)
Fit *fit;
{
  int i;

  fprintf(stderr, "begin = %d, end = %d\n", fit->begin, fit->end);
  fprintf(stderr, "nr_left = %d\n", fit->nr_left);
  for (i = 0; i < fit->nr_left; i++)
    fprintf(stderr, "%c %d ", fit->left[i].letter, fit->left[i].pos);
  fprintf(stderr, "\n");
  fprintf(stderr, "nr_right = %d\n", fit->nr_right);
  for (i = 0; i < fit->nr_right; i++)
    fprintf(stderr, "%c %d ", fit->right[i].letter, fit->right[i].pos);
  fprintf(stderr, "\n");
}
#endif

#if DEBUG
static void
check_fit(fit)
Fit *fit;
{
  int i;
  
  if (fit->begin < 1 || fit->end > 15)
  {
    fprintf(stderr, "check_fit error %d %d\n", fit->begin, fit->end);
    exit(1);
  }
  for (i = 0; i < fit->nr_left; i++)
  {
    if (fit->left[i].pos < 1 || fit->left[i].pos > 15)
      fprintf(stderr, "check_fit error left %d\n", fit->left[i].pos);
  }
  for (i = 0; i < fit->nr_right; i++)
  {
    if (fit->right[i].pos < 1 || fit->right[i].pos > 15)
      fprintf(stderr, "check_fit error right %d\n", fit->right[i].pos);
    
  }
}
#endif

static void
fill_fit(x, y, orient, fit)
int x;
int y;
int orient;
Fit *fit;
{
  register int i;

#if DEBUG  
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "fill_fit error %d %d %d\n", x, y, orient);
    exit(1);
  }
#endif
  fit->nr_left = 0;
  fit->nr_right = 0;
  fit->begin = 1;
  fit->end = 15;
  if (orient == HOR)
  {
    for (i = x+1; i <= 15; i++)	/* right */
    {
      if (hv[i][y])		/* occupied */
      {
	if (hv[i][y] == VERT)
	{
	  fit->right[fit->nr_right].letter = puzzle[i][y];
	  fit->right[fit->nr_right].pos = i;
	  fit->nr_right++;
	}
	else
	{
	  fit->end = i-2;
	  break;
	}
      }
      else			/* free */
      {
	if (hv[i][y-1] & VERT || hv[i][y+1] & VERT) /* vertical occupied? */
	{
	  fit->end = i-1;
	  break;
	}
      }
    }

    for (i = x-1; i > 0; --i)	/* left */
    {
      if (hv[i][y])		/* occupied */
      {
	if (hv[i][y] == VERT)
	{
	  fit->left[fit->nr_left].letter = puzzle[i][y];
	  fit->left[fit->nr_left].pos = i;
	  fit->nr_left++;
	}
	else
	{
	  fit->begin = i+2;
	  break;
	}
      }
      else			/* free */
      {
	if (hv[i][y-1] & VERT || hv[i][y+1] & VERT) /* vertical occupied? */
	{
	  fit->begin = i+1;
	  break;
	}
      }
    }
  }
  else				/* vertical */
  {
    for (i = y+1; i <= 15; i++)	/* right */
    {
      if (hv[x][i])		/* occupied */
      {
	if (hv[x][i] == HOR)
	{
	  fit->right[fit->nr_right].letter = puzzle[x][i];
	  fit->right[fit->nr_right].pos = i;
	  fit->nr_right++;
	}
	else
	{
	  fit->end = i-2;
	  break;
	}
      }
      else			/* free */
      {
	if (hv[x-1][i] & HOR || hv[x+1][i] & HOR) /* horizontal occupied? */
	{
	  fit->end = i-1;
	  break;
	}
      }
    }

    for (i = y-1; i > 0; --i)	/* left */
    {
      if (hv[x][i])		/* occupied */
      {
	if (hv[x][i] == HOR)
	{
	  fit->left[fit->nr_left].letter = puzzle[x][i];
	  fit->left[fit->nr_left].pos = i;
	  fit->nr_left++;
	}
	else
	{
	  fit->begin = i+2;
	  break;
	}
      }
      else			/* free */
      {
	if (hv[x-1][i] & HOR || hv[x+1][i] & HOR) /* horizontal occupied? */
	{
	  fit->begin = i+1;
	  break;
	}
      }
    }
  }
#if DEBUG
  check_fit(fit);
  if (trigger)
    print_fit(fit);
#endif
}

static bool
fit_word(fit, word, letter_pos, x, y, orient)
Fit *fit;
Word *word;
int letter_pos;
int x;
int y;
int orient;
{      
  unsigned char *a_word;
  int xs;
  int ys;
  int xe;
  int ye;
  int k;
  int old_pending;
  
#if DEBUG  
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "fit_word error %d %d %d\n", x, y, orient);
    exit(1);
  }
  if (trigger)
    fprintf(stderr, "fit_word %s %d %d %d %d\n", word->word, letter_pos, x, y, orient);
#endif
  old_pending = nr_pending;
  a_word = word->word;
  if (orient == HOR)
  {
    xs = x-letter_pos;
    xe = xs+word->len-1;
    if (xs >= fit->begin && xe <= fit->end && /* fits? */
	!puzzle[xs-1][y] && !puzzle[xe+1][y]) /* before and after empty? */
    {
      for (k = 0; k < fit->nr_right && fit->right[k].pos <= xe; k++)
      {
	if (fit->right[k].letter != a_word[fit->right[k].pos-xs])
	  return false;
      }
      for (k = 0; k < fit->nr_left && fit->left[k].pos >= xs; k++)
      {
       if (fit->left[k].letter != a_word[fit->left[k].pos-xs])
	 return false;
      }
      if (find_pending(word, xs, y, orient))
      {
        put_word(word, xs, y, orient);
	if (current_pending == nr_pending) /* no more pending connectors */
	  return true;
	/* words found for pending connectors */
	if (fit_words2(pending[current_pending].x, pending[current_pending].y,
	               pending[current_pending].orient))
	  return true;
	remove_word(word, xs, y, orient);
      }
      nr_pending = old_pending;
    }
  }
  else			/* vertical */
  {
    ys = y-letter_pos;
    ye = ys+word->len-1;
    if (ys >= fit->begin && ye <= fit->end && /* fits? */
	!puzzle[x][ys-1] && !puzzle[x][ye+1]) /* before and after empty? */
    {
      for (k = 0; k < fit->nr_right && fit->right[k].pos <= ye; k++)
      {
	if (fit->right[k].letter != a_word[fit->right[k].pos-ys])
	    return false;
      }
      for (k = 0; k < fit->nr_left && fit->left[k].pos >= ys; k++)
      {
        if (fit->left[k].letter != a_word[fit->left[k].pos-ys])
	  return false;
      }
      if (find_pending(word, x, ys, orient))
      {
	put_word(word, x, ys, orient);
	if (current_pending == nr_pending) /* no more pending connectors */
	  return true;
	/* words found for pending connectors */
	if (fit_words2(pending[current_pending].x, pending[current_pending].y,
	               pending[current_pending].orient))
	  return true;
	remove_word(word, x, ys, orient);
      }
      nr_pending = old_pending;
    }
  }
  return false;
}

static bool
fit_words2(x, y, orient)
int x;
int y;
int orient;
{
  register Word *word;
  Letter *letter;
  Fit fit;
  int j;
  int m;
  
#if DEBUG  
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "fit_words2 error %d %d %d\n", x, y, orient);
    exit(1);
  }
  if (trigger)
    fprintf(stderr, "fit_words2 %d %d %d\n", x, y, orient);
#endif
  current_pending++;
  if (hv[x][y] == CROSS)	/* pending already done */
  {
    if (current_pending == nr_pending) /* no more pending connectors */
      return true;
    /* words found for pending connectors */
    if (fit_words2(pending[current_pending].x, pending[current_pending].y,
                   pending[current_pending].orient))
      return true;
    --current_pending;
    return false;
  }
  fill_fit(x, y, orient, &fit);
  j = puzzle[x][y];
  if (orient == HOR)
    m = puzzle[x+1][y];
  else
    m = puzzle[x][y+1];
  for (letter = head_letter2[j][m]; letter; letter = letter->next)
  {
    word = letter->word;
    if (fit.begin + word->len - 1 > fit.end)
      break; /* words only get longer */
    if (!word->busy)
    {
      if (fit_word(&fit, word, letter->pos, x, y, orient))
        return true;
    }
  }
  --current_pending;
  return false;
}

static bool
fit_words(x, y, orient)
int x;
int y;
int orient;
{
  register Word *word;
  Letter *letter;
  Fit fit;
  
#if DEBUG  
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "fit_words error %d %d %d\n", x, y, orient);
    exit(1);
  }
  if (trigger)
    fprintf(stderr, "fit_words %d %d %d\n", x, y, orient);
#endif
  current_pending = 0;
  nr_pending = 0;
  fill_fit(x, y, orient, &fit);
  for (letter = head_letter[puzzle[x][y]]; letter; letter = letter->next)
  {
    word = letter->word;
    if (fit.begin + word->len - 1 > fit.end)
      break; /* words only get longer */
    if (!word->busy)
    {
      if (fit_word(&fit, word, letter->pos, x, y, orient))
        return true;
    }
  }
  return false;
}

static void
try_pending(start)
int start;
{
  int i;
  
  for (i = start; i < filled_squares; i++)
    (void) fit_words(used[i].x, used[i].y, used[i].orient ^ CROSS);
}

static int
get_single_cross(x, y, orient)
int x;
int y;
int orient;
{
  int connector = 0;
  
#if DEBUG  
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "get_single_cross error %d %d %d\n", x, y, orient);
    exit(1);
  }
#endif
  if (orient == HOR)
  {
    for (; puzzle[x][y]; x++)
    {
      if (hv[x][y] == CROSS)
      {
        if (connector > 0)
          return 0;
        connector = x;
      }
    }
  }
  else /* vertical */
  {
    for (; puzzle[x][y]; y++)
    {
      if (hv[x][y] == CROSS)
      {
        if (connector > 0)
          return 0;
        connector = y;
      }
    }
  }
  return connector;
}

static bool
fit_single_word(old_word, x, y, orient)
Word *old_word;
int x;
int y;
int orient;
{
  register Word *word;
  Letter *letter;
  Fit fit;
  int old_filled_squares;

#if DEBUG  
  if (x < 1 || x > 15 || y < 1 || y > 15 || orient > 3)
  {
    fprintf(stderr, "fit_single_word error %d %d %d\n", x, y, orient);
    exit(1);
  }
  if (trigger)
    fprintf(stderr, "fit_single_word %s %d %d %d\n", old_word->word, x, y, orient);
#endif
  nr_pending = 0;
  current_pending = 0;
  old_filled_squares = filled_squares;
  better_word_count = word_count;
  better_connectors = connectors;
  better_filled_squares = filled_squares;
  for (letter = head_letter[puzzle[x][y]]; old_word != letter->word;
       letter = letter->next)
  {
  }	/* find old word */
  fill_fit(x, y, orient, &fit);
  for (letter = letter->next; letter; letter = letter->next)
  {
    word = letter->word;
    if (fit.begin + word->len - 1 > fit.end)
      break; /* words only get longer */
    if (!word->busy)
    {
      if (fit_word(&fit, word, letter->pos, x, y, orient))
      {
        try_pending(old_filled_squares);
        if (word_count > better_word_count ||
          word_count == better_word_count &&
          (connectors > better_connectors ||
           connectors == better_connectors && filled_squares > better_filled_squares))
	  return true;
	if (orient == HOR)
	  remove_word(word, x-letter->pos, y, orient);
	else	/* vertical */
	  remove_word(word, x, y-letter->pos, orient);
      }
    }
  }
  return false;
}

static bool
replace_singles()
{
  Word *word;
  int x;
  int y;
  int orient;
  int connector;
  bool retry = false;
  
#if DEBUG
  if (trigger)
    fprintf(stderr, "replace_singles\n");
#endif
  for (word = head_word; word; word = word->next)
  {
    if (word->busy)
    {
      if ((connector = get_single_cross(word->x, word->y, word->orient)) > 0)
      {
        orient = word->orient;
        x = word->x;
        y = word->y;
        remove_word(word, x, y, orient);
        if (orient == HOR)
        {
          if (!fit_single_word(word, connector, y, orient))
            put_word(word, x, y, orient);
          else
            retry = true;
        }
        else
        {
          if (!fit_single_word(word, x, connector, orient))
            put_word(word, x, y, orient);
          else
            retry = true;
        }
      }
    }
  }
  return retry;
}

static void
try_all_words()
{
  int x;
  int y;
  Word *word;
  int good_word_count = 0;
  int good_connectors = 0;
  int good_filled_squares = 0;

  for (word = head_word; word; word = word->next)
  {
    for (x = 1; x <= 21-word->len; x++)
    {
      for (y = 1; y <= 15; y++)
      {
        /*fprintf(stderr, "try_all_words %s (%d,%d)\n", word->word, x, y);*/
	init();
	put_word(word, x, y, HOR);
	try_pending(0);
	do
	{
          good_word_count = word_count;
          good_connectors = connectors;
          good_filled_squares = filled_squares;
          replace_singles();
        }
	while (word_count > good_word_count ||
               word_count == good_word_count &&
               (connectors > good_connectors ||
                connectors == good_connectors && filled_squares > good_filled_squares));
	(void) save_puzzle();
	if (time_out)
	  return;
      }
    }
  }
}

int
#if __MWERKS__
main()
#else
main(argc, argv)
int argc;
char *argv[];
#endif
{
  bool print_score = false;
  char *in_file;
#if __MWERKS__
  in_file = "test2";
#else
  int option;

  while ((option = getopt(argc, argv, "d:st:")) != EOF)
  {
    switch (option)
    {
    case 's':
      print_score = true;
      break;
    case 't':		/* maximum cpu time in seconds, default 600 */
      max_time = atoi(optarg);
      break;
    default:
      fprintf(stderr, "%s: invalid option: %c\n", argv[0], option);
      exit(1);
    }
  }

  in_file = argv[optind];
  (void) signal(SIGALRM, alarm_signal);
  (void) alarm(max_time);
#endif
  read_words(in_file);
  init_letter();
  init_letter2();
  try_all_words();
  if (print_score)
    fprintf(stdout, "%d words, %d connectors, %d filled squares\n",
            best_word_count, best_connectors, best_filled_squares);
  print_board(best_puzzle);
  return 0;
}

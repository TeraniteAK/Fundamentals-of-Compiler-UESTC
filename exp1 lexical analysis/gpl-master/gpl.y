%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* 哈希表 */
#define SIZE 7

/* constant */
#define LAB_MIN 1
#define MODIFIED 1
#define UNMODIFIED 0

/* symbol */
#define SYM_UNDEF 0
#define SYM_VAR 1
#define SYM_FUNC 2
#define SYM_TEXT 3
#define SYM_INT 4
#define SYM_LABEL 5

/* tac */ 
#define TAC_UNDEF 0 /* undefine */
#define TAC_ADD 1 /* a=b+c */
#define TAC_SUB 2 /* a=b-c */
#define TAC_MUL 3 /* a=b*c */
#define TAC_DIV 4 /* a=b/c */
#define TAC_EQ 5 /* a=(b==c) */
#define TAC_NE 6 /* a=(b!=c) */
#define TAC_LT 7 /* a=(b<c) */
#define TAC_LE 8 /* a=(b<=c) */
#define TAC_GT 9 /* a=(b>c) */
#define TAC_GE 10 /* a=(b>=c) */
#define TAC_NEG 11 /* a=-b */
#define TAC_COPY 12 /* a=b */
#define TAC_GOTO 13 /* goto a */
#define TAC_IFZ 14 /* ifz b goto a */
#define TAC_BEGINFUNC 15 /* function begin */
#define TAC_ENDFUNC 16 /* function end */
#define TAC_LABEL 17 /* label a */
#define TAC_VAR 18 /* int a */
#define TAC_FORMAL 19 /* formal a */
#define TAC_ACTUAL 20 /* actual a */
#define TAC_CALL 21 /* a=call b */
#define TAC_RETURN 22 /* return a */

/* register */
#define R_UNDEF -1
#define R_FLAG 0
#define R_IP 1
#define R_BP 2
#define R_JP 3
#define R_TP 4
#define R_GEN 5
#define R_NUM 16

/* frame */
#define FORMAL_OFF -4 	/* first formal parameter */
#define OBP_OFF 0 		/* dynamic chain */
#define RET_OFF 4 		/* ret address */
#define LOCAL_OFF 8 		/* local var */


/*哈希表*/
typedef struct hash_node
{
    int data;
    struct hash_node *next;
}HASH;

/*词汇表*/
typedef struct wordlist
{
    int *p;  //地址
	char m[100];   //字面量
}WORDLIST;

typedef struct symb
{
	/*	
		type:SYM_VAR name:abc value:98 offset:-1
		type:SYM_VAR name:bcd value:99 offset:4
		type:SYM_LABEL name:L1/max			
		type:SYM_INT value:1			
		type:SYM_FUNC name:max address:1234		
		type:SYM_TEXT name:"hello" lable:10
	*/
	int type;
	int store; /* 0:global, 1:local */
	char *name;
	int offset;
	int value;
	int lable;
	struct tac *address; /* SYM_FUNC */	
	struct symb *next;
} SYMB;

typedef struct tac /* TAC instruction node */
{
	struct tac  *next; /* Next instruction */
	struct tac  *prev; /* Previous instruction */
	int op; /* TAC instruction */
	SYMB *a;
	SYMB *b;
	SYMB *c;
} TAC;

typedef struct enode /* Parser expression */
{
	struct enode *next; /* For argument lists */
	TAC *tac; /* The code */
	SYMB *ret; /* Where the result is */
} ENODE;

typedef struct keyw
{
	int id;
	char name[100];
} KEYW;

typedef struct regdesc /* Reg descriptor */
{
	struct symb *name; /* Thing in reg */
	int modified; /* If needs spilling */
} REGDESC;

%}

%union
{
	char character;
	char *string;
	SYMB *symb;
	TAC *tac;
	ENODE	*enode;
}

%token FUNC
%token PRINT
%token RETURN
%token CONTINUE
%token IF
%token THEN
%token ELSE
%token FI
%token WHILE
%token DO
%token DONE
%token INT
%token EQ
%token NE
%token LT
%token LE
%token GT
%token GE
%token UMINUS
%token <string> INTEGER
%token <string> IDENTIFIER
%token <string> TEXT

%type <tac> program
%type <tac> function_declaration_list
%type <tac> function_declaration
%type <tac> function
%type <symb> function_head
%type <tac> parameter_list
%type <tac> variable_list
%type <enode> argument_list
%type <enode> expression_list
%type <tac> statement
%type <tac> assignment_statement
%type <enode> expression
%type <tac> print_statement
%type <tac> print_list
%type <tac> print_item
%type <tac> return_statement
%type <tac> null_statement
%type <tac> if_statement
%type <tac> while_statement
%type <tac> call_statement
%type <enode> call_expression
%type <tac> block
%type <tac> declaration_list
%type <tac> declaration
%type <tac> statement_list
%type <tac> error

%left EQ NE LT LE GT GE
%left '+' '-'
%left '*' '/'
%right UMINUS

%{
int yyerror(char *str);
int main(int argc, char *argv[]);
SYMB *mkconst(int n);
char *mklstr(int i);
SYMB *mklabel(char *name);
SYMB *get_symb(void);
void free_symb(SYMB *s);
ENODE *get_enode(void);
void free_enode(ENODE *e);
void *safe_malloc(int n);
TAC *mktac(int op, SYMB *a, SYMB *b, SYMB *c);
TAC *join_tac(TAC *c1, TAC *c2);
void insert(SYMB **symbtab, SYMB *sym);
SYMB *lookup(SYMB *symbtab, char *name);
SYMB *getvar(char *name); 
TAC *do_func(SYMB *name,    TAC *args, TAC *code);
TAC *declare_var(char *name);
TAC *declare_para(char *name);
SYMB *declare_func(char *name);
TAC *do_assign(SYMB *var, ENODE *expr);
ENODE *do_bin( int binop, ENODE *expr1, ENODE *expr2);
ENODE *do_cmp( int binop, ENODE *expr1, ENODE *expr2);
ENODE *do_un( int unop, ENODE *expr);
ENODE *do_call_ret(char *name, ENODE *arglist);
TAC *do_call(char *name, ENODE *arglist);
TAC *do_lib(char *name, SYMB *arg);
TAC *do_if(ENODE *expr, TAC *stmt);
TAC *do_test(ENODE *expr, TAC *stmt1, TAC *stmt2);
TAC *do_while(ENODE *expr, TAC *stmt);
SYMB *mktext(char *text);
SYMB *mktmp(void);
SYMB *mkvar(char *name);
ENODE *mkenode(ENODE *next, SYMB *ret, TAC *code);
void tac_print(TAC *i);
char *ts(SYMB *s,  char *str);
void error(char *str);
void cg();
void cg_init();
void cg_code(TAC *c);
void cg_bin(char *op, SYMB *a, SYMB *b, SYMB *c);
void cg_cmp(int op, SYMB *a, SYMB *b, SYMB *c);
void cg_copy(SYMB *a, SYMB *b);
void cg_cond(char *op, SYMB *a,  char *l);
void cg_return(SYMB *a);
void cg_data(void);
void cg_str(SYMB *s);
void flush_all(void);
void spill_all(void);
void spill_one(int r);
void load_reg(int r, SYMB *n);
void clear_desc(int r);
void insert_desc(int r, SYMB *n, int mod);
int get_rreg(SYMB *c);
int get_areg(SYMB *b, int cr);
void cg_head();
void cg_lib();
///语法分析
FILE *myfp;
int dot_num_of_nodes=0;

///语法树
typedef struct myvsp
{
    char name[100];    //名字 也就是label
	int old_number;   //应该是的结点编号 也就是老的编号
	int new_number;
}MYVSP;

MYVSP vsp[1000];   //模拟的符号栈 我日哦 关键是我没看懂这个傻逼lex的栈的嘛我艹了都
int vsp_top=0;   //栈顶初始化为0 栈顶会指向元素的后一位

char temp_name[100];
int temp_old;
int temp_new;

MYVSP temp_left; //暂存目前归约式左边的东西

char temp_para[100];  //用于往process函数里面传参数（因为不能直接传字符串）
////
//////词法分析附加问题2
char ls[100000];   //一个超长的字符串 用来实现附加问题2
int ls_pos[100000];   //用来存各个单词的位置的
int num_of_words = 0;  //统计有多少个单词 以便知道ls_pos在哪是最后一个单词 实际指向最后一个有效元素 所以+1才是真实的单词的数量
int ls_point = 0;   //ls的当前指针 指示当前ls的结尾在哪  ls_point指最后一个有效字母的后一位 也就是#
///////词法分析附加问题3 哈希表
HASH table[SIZE];
int inputdata[100];  //记录一下要进来的东西
int inputdata_point=0;    //相应的指针指向 最后一个元素的后一个



int lsc=0;
char *lsp[10000];
WORDLIST wl[10000];
int lenwl=0;
int mode;
TAC *tac_first, *tac_last;
int LocalScope, scope;
SYMB *GlobalSymbolTable, *LocalSymbolTable;
int next_tmp;
int next_label;
SYMB *symb_list;
ENODE *enode_list;
int line;
char character;
char token[1000];
REGDESC rdesc[R_NUM];
int tos; /* top of static */
int tof; /* top of frame */
int oof; /* offset of formal */
int oon; /* offset of next frame */
KEYW keywords[100]=
{
	{INT,"int"},
	{PRINT,"print"},
	{RETURN,"return"},
	{CONTINUE,"continue"},
	{IF,"if"},
	{THEN,"then"},
	{ELSE,"else"},
	{FI,"fi"},
	{WHILE,"while"},
	{DO,"do"},
	{DONE,"done"},
	{0,""}
};

%}

%%
program : function_declaration_list
{
	tac_last=$1;
	
	strcpy(temp_para, "program");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "function_declaration_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
;

function_declaration_list : function_declaration
{
    strcpy(temp_para, "function_declaration_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "function_declaration");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| function_declaration_list function_declaration
{
	$$=join_tac($1, $2);
	
	strcpy(temp_para, "function_declaration_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "function_declaration");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "function_declaration_list");
	process_child(temp_para); 

	myvsp_push();
}
;

function_declaration : function
{
    strcpy(temp_para, "function_declaration");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 

	strcpy(temp_para, "function");
	process_child(temp_para); 

	myvsp_push();
}
| declaration
{
    strcpy(temp_para, "function_declaration");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 

	strcpy(temp_para, "declaration");
	process_child(temp_para); 

	myvsp_push();
}
;
/*规约整个变量定义*/
declaration : INT variable_list ';'
{
	/*************添加了写入文件***********/
	$$=$2;

    strcpy(temp_para, "declaration");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "semicolon");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "variable_list");
	process_child(temp_para); 


	strcpy(temp_para, "INT");
	process_child(temp_para); 

	myvsp_push();
}
;
/*标识符规约为*/
variable_list : IDENTIFIER
{
	$$=declare_var($1);
	/*************添加了写入文件***********/
	strcpy(temp_para, "variable_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}               
| variable_list ',' IDENTIFIER
{
	
	$$=join_tac($1, declare_var($3));
	/*************添加了写入文件***********/
    strcpy(temp_para, "variable_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "comma");
	process_child(temp_para); 


	strcpy(temp_para, "variable_list");
	process_child(temp_para); 

	myvsp_push();

}               
;

function : function_head '(' parameter_list ')' block
{
	$$=do_func($1, $3, $5);
	LocalScope=0; /* Leave local scope. */
	LocalSymbolTable=NULL; /* Clear local symbol table. */

    /****************/
	strcpy(temp_para, "function");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "block");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "right_paren");
	process_child(temp_para); 


	strcpy(temp_para, "parameter_list");
	process_child(temp_para); 

	strcpy(temp_para, "left_paren");
	process_child(temp_para); 

	strcpy(temp_para, "function_head");
	process_child(temp_para); 

	myvsp_push();
}
| error
{
    //?????error规约是什么
	strcpy(temp_para, "function");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "error");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
	
    yyerror("Bad function syntax");
	error("Bad function syntax");
	$$=NULL;

}
;
/*规约函数的名字*/
function_head : IDENTIFIER
{
	$$=declare_func($1);
	LocalScope=1; /* Enter local scope. */     
	LocalSymbolTable=NULL; /* Init local symbol table. */
	
	/****************/
	strcpy(temp_para, "function_head");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
;
/*规约函数的参数列表*/
parameter_list : IDENTIFIER
{
	/*************添加了写入文件***********/
	$$=declare_para($1);
	
	/****************/
	strcpy(temp_para, "parameter_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}               
| parameter_list ',' IDENTIFIER
{
	$$=join_tac($1, declare_para($3));

	strcpy(temp_para, "parameter_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "comma");
	process_child(temp_para); 


	strcpy(temp_para, "parameter_list");
	process_child(temp_para); 

	myvsp_push();
}               
|
{
	$$=NULL;
	//空归约
}
;

statement : assignment_statement ';'
{
    strcpy(temp_para, "statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "semicolon");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "assignment_statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| call_statement ';'
{
    strcpy(temp_para, "statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "semicolon");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "call_statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| return_statement ';'
{
    strcpy(temp_para, "statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "semicolon");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "return_statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| print_statement ';'
{
    strcpy(temp_para, "statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "semicolon");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "print_statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| null_statement ';'
{
    strcpy(temp_para, "statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "semicolon");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "null_statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| if_statement
{
    strcpy(temp_para, "statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "semicolon");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "if_statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| while_statement
{
    strcpy(temp_para, "statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "semicolon");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "while_statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| block
{
    strcpy(temp_para, "statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "block");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| error
{
	strcpy(temp_para, "function");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "error");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
    yyerror("Bad statement syntax");
	error("Bad statement syntax");
	$$=NULL;
}
;

block : '{' declaration_list statement_list '}'
{
	$$=join_tac($2, $3);
	strcpy(temp_para, "block");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "right_curly");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "statement_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "declaration_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "left_curly");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 
	
	myvsp_push();
}               
;
/*定义变量的规约*/
declaration_list        :
{
	$$=NULL;  /*空的不需要什么规约？？？*/
}
| declaration_list declaration
{
    /*************添加了写入文件***********/
	/****************/
	strcpy(temp_para, "declaration_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "declaration");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "declaration_list");
	process_child(temp_para); 

	myvsp_push();
}
;

statement_list : statement
{
	strcpy(temp_para, "statement_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 
	
	myvsp_push();

}
| statement_list statement
{
	$$=join_tac($1, $2);
	strcpy(temp_para, "statement_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "statement");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "statement_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 
	
	myvsp_push();
}               
;

assignment_statement : IDENTIFIER '=' expression
{
	$$=do_assign(getvar($1), $3);
	strcpy(temp_para, "assignment_statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "EQ");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, yyvsp[-2].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
;

expression : expression '+' expression
{
	$$=do_bin(TAC_ADD, $1, $3);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "PLUS");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| expression '-' expression
{
	$$=do_bin(TAC_SUB, $1, $3);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "MINUS");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| expression '*' expression
{
	$$=do_bin(TAC_MUL, $1, $3);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "MUL");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| expression '/' expression
{
	$$=do_bin(TAC_DIV, $1, $3);
	
	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "DIV");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| '-' expression  %prec UMINUS       
{
	$$=do_un(TAC_NEG, $2);
	///？？？？？这个prec好像是个状态
	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "MINUS");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| expression EQ expression
{
	$$=do_cmp(TAC_EQ, $1, $3);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "EQ");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| expression NE expression
{
	$$=do_cmp(TAC_NE, $1, $3);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "NE");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| expression LT expression
{
	$$=do_cmp(TAC_LT, $1, $3);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "LT");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| expression LE expression
{
	$$=do_cmp(TAC_LE, $1, $3);
	
	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "LE");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| expression GT expression
{
	$$=do_cmp(TAC_GT, $1, $3);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "GT");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| expression GE expression
{
	$$=do_cmp(TAC_GE, $1, $3);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "GE");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| '(' expression ')'
{
	$$=$2;

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "right_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "left_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}               
| INTEGER
{
	$$=mkenode(NULL, mkconst(atoi($1)), NULL);

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| IDENTIFIER
{
	$$=mkenode(NULL, getvar($1), NULL);

    strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| call_expression
{
	$$=$1;

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "call_expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}               
| error
{
	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "error");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
    yyerror("Bad expression syntax");
	error("Bad expression syntax");
	$$=mkenode(NULL, NULL, NULL);
}
;

argument_list           :
{
	$$=NULL;
	///空归约
}
| expression_list
{
	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
;

expression_list : expression
{
	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
|  expression_list ',' expression
{
	$3->next=$1;
	$$=$3;

	strcpy(temp_para, "expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "comma");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
;

print_statement : PRINT '(' print_list ')'
{
	$$=$3;

	strcpy(temp_para, "print_statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "right_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "print_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "left_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "PRINT");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}               
;

print_list : print_item
{
	strcpy(temp_para, "print_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "print_item");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| print_list ',' print_item
{
	$$=join_tac($1, $3);

	strcpy(temp_para, "print_list");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "print_item");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "comma");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "print_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}               
;

print_item : expression
{
	$$=join_tac($1->tac,
	do_lib("PRINTN", $1->ret));

	strcpy(temp_para, "print_item");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
| TEXT
{
	$$=do_lib("PRINTS", mktext($1));

	strcpy(temp_para, "print_item");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
;

return_statement : RETURN expression
{
	TAC *t=mktac(TAC_RETURN, $2->ret, NULL, NULL);
	t->prev=$2->tac;
	free_enode($2);
	$$=t;

	strcpy(temp_para, "return_statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "RETURN");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}               
;

null_statement : CONTINUE
{
	$$=NULL;
	strcpy(temp_para, "null_statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "CONTINUE");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}               
;

if_statement : IF '(' expression ')' block
{
	$$=do_if($3, $5);
	
	strcpy(temp_para, "if_statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 
	
	strcpy(temp_para, "block");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "right_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "left_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "IF");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
| IF '(' expression ')' block ELSE block
{
	$$=do_test($3, $5, $7);

	strcpy(temp_para, "if_statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 

	strcpy(temp_para, "block");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "ELSE");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 
	
	strcpy(temp_para, "block");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "right_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "left_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "IF");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();
}
;

while_statement : WHILE '(' expression ')' block
{
	$$=do_while($3, $5);

	strcpy(temp_para, "while_statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 

	strcpy(temp_para, "block");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "right_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 
	
	strcpy(temp_para, "expression");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "left_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "WHILE");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 
	
	myvsp_push();

}               
;

call_statement : IDENTIFIER '(' argument_list ')'
{
	$$=do_call($1, $3);
	
	strcpy(temp_para, "call_statement");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 

	strcpy(temp_para, "right_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "argument_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 
	
	strcpy(temp_para, "left_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
;

call_expression : IDENTIFIER '(' argument_list ')'
{
	$$=do_call_ret($1, $3);

	strcpy(temp_para, "call_expression");   //注意一点就是从右往左操作 然后最后要入栈
	process_root(temp_para); 

	strcpy(temp_para, "right_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, "argument_list");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 
	
	strcpy(temp_para, "left_paren");    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	strcpy(temp_para, yyvsp[0].string);    //只有遇到红色才调yyvsp栈顶
	process_child(temp_para); 

	myvsp_push();

}
;


%%

TAC *do_func(SYMB *func, TAC *args, TAC *code) 
{
	TAC *tlist; /* The backpatch list */

	TAC *tlab; /* Label at start of function */
	TAC *tbegin; /* BEGINFUNC marker */
	TAC *tend; /* ENDFUNC marker */

	tlab=mktac(TAC_LABEL, mklabel(func->name), NULL, NULL);
	tbegin=mktac(TAC_BEGINFUNC, NULL, NULL, NULL);
	tend=mktac(TAC_ENDFUNC,   NULL, NULL, NULL);

	tbegin->prev=tlab;
	code=join_tac(args, code);
	tend->prev=join_tac(tbegin, code);

	return tend;
}

SYMB *mktmp(void)
{
	SYMB *sym;
	char *name;

	name=safe_malloc(12);
	sprintf(name, "t%d", next_tmp++); /* Set up text */
	return mkvar(name);
}

SYMB *mkvar(char *name)
{
	SYMB *sym=NULL;

	if(LocalScope)  
		sym=lookup(LocalSymbolTable,name);
	else
		sym=lookup(GlobalSymbolTable,name);

	/* var already declared */
	if(sym!=NULL)
	{
		error("variable already declared");
		return NULL;
	}

	/* var unseen before, set up a new symbol table node, insert it into the symbol table. */
	sym=get_symb();
	sym->type=SYM_VAR;
	sym->name=name; /* ysj */
	sym->offset=-1; /* Unset address */

	if(LocalScope)  
		insert(&LocalSymbolTable,sym);
	else
		insert(&GlobalSymbolTable,sym);

	return sym;
}

TAC *declare_var(char *name)
{
	return mktac(TAC_VAR,mkvar(name),NULL,NULL);
}

TAC *declare_para(char *name)
{
	return mktac(TAC_FORMAL,mkvar(name),NULL,NULL);
}

SYMB *declare_func(char *name)
{
	SYMB *sym=NULL;

	sym=lookup(GlobalSymbolTable,name);

	/* name used before declared */
	if(sym!=NULL)
	{
		if(sym->type==SYM_FUNC)
		{
			error("func already declared");
			return NULL;
		}

		if(sym->type !=SYM_UNDEF)
		{
			error("func name already used");
			return NULL;
		}

		return sym;
	}
	
	
	sym=get_symb();
	sym->type=SYM_FUNC;
	sym->name=name;
	sym->address=NULL;

	insert(&GlobalSymbolTable,sym);
	return sym;
}

TAC *do_assign(SYMB *var, ENODE *expr)
{
	TAC *code;

	if(var->type !=SYM_VAR) error("assignment to non-variable");

	code=mktac(TAC_COPY, var, expr->ret, NULL);
	code->prev=expr->tac;
	free_enode(expr); /* Expression now finished with */

	return code;
}

ENODE *do_bin( int binop, ENODE *expr1, ENODE *expr2)
{
	TAC *temp; /* TAC code for temp symbol */
	TAC *ret; /* TAC code for result */

	if((expr1->ret->type==SYM_INT) && (expr2->ret->type==SYM_INT))
	{
		int newval; /* The result of constant folding */

		switch(binop) /* Chose the operator */
		{
			case TAC_ADD:
			newval=expr1->ret->value + expr2->ret->value;
			break;

			case TAC_SUB:
			newval=expr1->ret->value - expr2->ret->value;
			break;

			case TAC_MUL:
			newval=expr1->ret->value * expr2->ret->value;
			break;

			case TAC_DIV:
			newval=expr1->ret->value / expr2->ret->value;
			break;
		}

		expr1->ret=mkconst(newval); /* New space for result */
		free_enode(expr2); /* Release space in expr2 */

		return expr1; /* The new expression */
	}

	temp=mktac(TAC_VAR, mktmp(), NULL, NULL);
	temp->prev=join_tac(expr1->tac, expr2->tac);
	ret=mktac(binop, temp->a, expr1->ret, expr2->ret);
	ret->prev=temp;

	expr1->ret=temp->a;
	expr1->tac=ret;
	free_enode(expr2);

	return expr1;  
}   

ENODE *do_cmp( int binop, ENODE *expr1, ENODE *expr2)
{
	TAC *temp; /* TAC code for temp symbol */
	TAC *ret; /* TAC code for result */

	if((expr1->ret->type==SYM_INT) && (expr2->ret->type==SYM_INT))
	{
		int newval; /* The result of constant folding */

		switch(binop) /* Chose the operator */
		{
			case TAC_EQ:
			newval=(expr1->ret->value==expr2->ret->value);
			break;
			
			case TAC_NE:
			newval=(expr1->ret->value !=expr2->ret->value);
			break;
			
			case TAC_LT:
			newval=(expr1->ret->value < expr2->ret->value);
			break;
			
			case TAC_LE:
			newval=(expr1->ret->value <=expr2->ret->value);
			break;
			
			case TAC_GT:
			newval=(expr1->ret->value > expr2->ret->value);
			break;
			
			case TAC_GE:
			newval=(expr1->ret->value >=expr2->ret->value);
			break;
		}

		expr1->ret=mkconst(newval); /* New space for result */
		free_enode(expr2); /* Release space in expr2 */
		return expr1; /* The new expression */
	}

	temp=mktac(TAC_VAR, mktmp(), NULL, NULL);
	temp->prev=join_tac(expr1->tac, expr2->tac);
	ret=mktac(binop, temp->a, expr1->ret, expr2->ret);
	ret->prev=temp;

	expr1->ret=temp->a;
	expr1->tac=ret;
	free_enode(expr2);

	return expr1;  
}   

ENODE *do_un( int unop, ENODE *expr) 
{
	TAC *temp; /* TAC code for temp symbol */
	TAC *ret; /* TAC code for result */

	/* Do constant folding if possible. Calculate the constant into expr */
	if(expr->ret->type==SYM_INT)
	{
		switch(unop) /* Chose the operator */
		{
			case TAC_NEG:
			expr->ret->value=- expr->ret->value;
			break;
		}

		return expr; /* The new expression */
	}

	temp=mktac(TAC_VAR, mktmp(), NULL, NULL);
	temp->prev=expr->tac;
	ret=mktac(unop, temp->a, expr->ret, NULL);
	ret->prev=temp;

	expr->ret=temp->a;
	expr->tac=ret;

	return expr;   
}

TAC *do_call(char *name, ENODE *arglist)
{
	ENODE  *alt; /* For counting args */
	TAC *code; /* Resulting code */
	TAC *temp; /* Temporary for building code */

	code=NULL;
	for(alt=arglist; alt !=NULL; alt=alt->next) code=join_tac(code, alt->tac);

	while(arglist !=NULL) /* Generate ARG instructions */
	{
		temp=mktac(TAC_ACTUAL, arglist->ret, NULL, NULL);
		temp->prev=code;
		code=temp;

		alt=arglist->next;
		free_enode(arglist); /* Free the space */
		arglist=alt;
	};

	temp=mktac(TAC_CALL, NULL, (SYMB *)strdup(name), NULL);
	temp->prev=code;
	code=temp;

	return code;
}

ENODE *do_call_ret(char *name, ENODE *arglist)
{
	ENODE  *alt; /* For counting args */
	SYMB *ret; /* Where function result will go */
	TAC *code; /* Resulting code */
	TAC *temp; /* Temporary for building code */

	ret=mktmp(); /* For the result */
	code=mktac(TAC_VAR, ret, NULL, NULL);

	for(alt=arglist; alt !=NULL; alt=alt->next) code=join_tac(code, alt->tac);

	while(arglist !=NULL) /* Generate ARG instructions */
	{
		temp=mktac(TAC_ACTUAL, arglist->ret, NULL, NULL);
		temp->prev=code;
		code=temp;

		alt=arglist->next;
		free_enode(arglist); /* Free the space */
		arglist=alt;
	};

	temp=mktac(TAC_CALL, ret, (SYMB *)strdup(name), NULL);
	temp->prev=code;
	code=temp;

	return mkenode(NULL, ret, code);
}

TAC *do_lib(char *name, SYMB *arg)
{
        TAC *a=mktac(TAC_ACTUAL, arg, NULL, NULL);
        TAC *c=mktac(TAC_CALL, NULL, (SYMB *)strdup(name), NULL);
        c->prev=a;
        return c;
}

TAC *do_if(ENODE *expr, TAC *stmt)
{
	TAC *label=mktac(TAC_LABEL, mklabel(mklstr(next_label++)), NULL, NULL);
	TAC *code=mktac(TAC_IFZ, label->a, expr->ret, NULL);

	code->prev=expr->tac;
	code=join_tac(code, stmt);
	label->prev=code;

	free_enode(expr); /* Expression finished with */

	return label;
}

TAC *do_test(ENODE *expr, TAC *stmt1, TAC *stmt2)
{
	TAC *label1=mktac(TAC_LABEL, mklabel(mklstr(next_label++)), NULL, NULL);
	TAC *label2=mktac(TAC_LABEL, mklabel(mklstr(next_label++)), NULL, NULL);
	TAC *code1=mktac(TAC_IFZ, label1->a, expr->ret, NULL);
	TAC *code2=mktac(TAC_GOTO, label2->a, NULL, NULL);

	code1->prev=expr->tac; /* Join the code */
	code1=join_tac(code1, stmt1);
	code2->prev=code1;
	label1->prev=code2;
	label1=join_tac(label1, stmt2);
	label2->prev=label1;

	free_enode(expr); /* Free the expression */

	return label2;
}

TAC *do_while(ENODE *expr, TAC *stmt) 
{
	TAC *label=mktac(TAC_LABEL, mklabel(mklstr(next_label++)), NULL, NULL);
	TAC *code=mktac(TAC_GOTO, label->a, NULL, NULL);

	code->prev=stmt; /* Bolt on the goto */

	return join_tac(label, do_if(expr, code));
}

SYMB *getvar(char *name)
{
	SYMB *sym=NULL; /* Pointer to looked up symbol */

	if(LocalScope) sym=lookup(LocalSymbolTable,name);

	if(sym==NULL) sym=lookup(GlobalSymbolTable,name);

	if(sym==NULL)
	{
		error("name not declared as local/global variable");
		return NULL;
	}

	if(sym->type!=SYM_VAR)
	{
		error("not a variable");
		return NULL;
	}

	return sym;
} 

ENODE *mkenode(ENODE *next, SYMB *ret, TAC *code)
{
	ENODE *expr=get_enode();

	expr->next=next;
	expr->ret=ret;
	expr->tac=code;

	return expr;
}

SYMB *mktext(char *text)
{
	SYMB *sym=NULL; /* Pointer to looked up symbol */

	sym=lookup(GlobalSymbolTable,text);

	/* text already used */
	if(sym!=NULL)
	{
		return sym;
	}

	/* text unseen before, set up a new symbol table node, insert it into the symbol table. */
	sym=get_symb();
	sym->type=SYM_TEXT;
	sym->name=text; /* ysj */
	sym->lable=next_label++; /* ysj */

	insert(&GlobalSymbolTable,sym);
	return sym;
}

SYMB *mkconst(int n)
{
	SYMB *c=get_symb(); /* Create a new node */

	c->type=SYM_INT;
	c->value=n; /* ysj */
	return c;
}     

char *mklstr(int i)
{
	char lstr[100]="L";
	sprintf(lstr,"L%d",i);
	return(strdup(lstr));	
}

SYMB *mklabel(char *name)
{
	SYMB *t=get_symb();

	t->type=SYM_LABEL;
	t->name=strdup(name);

	return t;
}  

SYMB *get_symb(void)
{
	SYMB *t;

	if(symb_list !=NULL)
	{
		t=symb_list;
		symb_list=symb_list->next;
	}
	else t=(SYMB *)safe_malloc(sizeof(SYMB));

	return t;
}     


void free_symb(SYMB *s)
{
	s->next=symb_list;
	symb_list=s;
} 


ENODE *get_enode(void)
{
	if(enode_list !=NULL)
	{
		ENODE *expr;
		expr=enode_list;
		enode_list=expr->next;
		return expr;
	}
	else return (ENODE *)safe_malloc(sizeof(ENODE));
}  

void free_enode(ENODE *expr)
{
	expr->next=enode_list;
	enode_list=expr;
} 

void *safe_malloc(int n)
{
	void *t=(void *)malloc(n);

	if(t==NULL)
	{
		/* We can't use printf to put the message out here, since it calls malloc, which will fail because that's why we're here... */
		error("malloc() failed");
		exit(0);
	}

	return t;
}      

TAC *mktac(int op, SYMB *a, SYMB *b, SYMB *c)
{
	TAC *t=(TAC *)safe_malloc(sizeof(TAC));

	t->next=NULL; /* Set these for safety */
	t->prev=NULL;
	t->op=op;
	t->a=a;
	t->b=b;
	t->c=c;

	return t;
}  

TAC *join_tac(TAC *c1, TAC *c2)
{
	TAC *t;

	/* If either list is NULL return the other */
	if(c1==NULL) return c2;
	if(c2==NULL) return c1;

	/* Run down c2, until we get to the beginning and then add c1 */
	t=c2;
	while(t->prev !=NULL) 
		t=t->prev;

	t->prev=c1;
	return c2;
}   
			   
void insert(SYMB **symbtab, SYMB *sym)
{
	sym->next=*symbtab; /* Insert at head */
	*symbtab=sym;
}


SYMB *lookup(SYMB *symbtab, char *name)
{
	SYMB *t=symbtab;

	while(t !=NULL)
	{
		if(strcmp(t->name, name)==0) break; 
		else t=t->next;
	}
	
	return t; /* NULL if not found */
}

void tac_print(TAC *i)
{
	char sa[12]; /* For text of TAC args */
	char sb[12];
	char sc[12];

	switch(i->op)
	{
		case TAC_UNDEF:
		printf("undef");
		break;

		case TAC_ADD:
		printf("%s = %s + %s", ts(i->a, sa), ts(i->b, sb),
		ts(i->c, sc));
		break;

		case TAC_SUB:
		printf("%s = %s - %s", ts(i->a, sa), ts(i->b, sb),
		ts(i->c, sc));
		break;

		case TAC_MUL:
		printf("%s = %s * %s", ts(i->a, sa), ts(i->b, sb),
		ts(i->c, sc));
		break;

		case TAC_DIV:
		printf("%s = %s / %s", ts(i->a, sa), ts(i->b, sb),
		ts(i->c, sc));
		break;

		case TAC_EQ:
		printf("%s = (%s == %s)", ts(i->a, sa), ts(i->b, sb), ts(i->c, sc));
		break;

		case TAC_NE:
		printf("%s = (%s != %s)", ts(i->a, sa), ts(i->b, sb), ts(i->c, sc));
		break;

		case TAC_LT:
		printf("%s = (%s < %s)", ts(i->a, sa), ts(i->b, sb), ts(i->c, sc));
		break;

		case TAC_LE:
		printf("%s = (%s <= %s)", ts(i->a, sa), ts(i->b, sb), ts(i->c, sc));
		break;

		case TAC_GT:
		printf("%s = (%s > %s)", ts(i->a, sa), ts(i->b, sb), ts(i->c, sc));
		break;

		case TAC_GE:
		printf("%s = (%s >= %s)", ts(i->a, sa), ts(i->b, sb), ts(i->c, sc));
		break;

		case TAC_NEG:
		printf("%s = - %s", ts(i->a, sa), ts(i->b, sb));
		break;

		case TAC_COPY:
		printf("%s = %s", ts(i->a, sa), ts(i->b, sb));
		break;

		case TAC_GOTO:
		printf("goto %s", i->a->name);
		break;

		case TAC_IFZ:
		printf("ifz %s goto %s", ts(i->b, sb), i->a->name);
		break;

		case TAC_ACTUAL:
		printf("actual %s", ts(i->a, sa));
		break;

		case TAC_FORMAL:
		printf("formal %s", ts(i->a, sa));
		break;

		case TAC_CALL:
		if(i->a==NULL) printf("call %s", (char *)i->b);
		else printf("%s = call %s", ts(i->a, sa), (char *)i->b);
		break;

		case TAC_RETURN:
		printf("return %s", ts(i->a, sa));
		break;

		case TAC_LABEL:
		printf("label %s", i->a->name);
		break;

		case TAC_VAR:
		printf("var %s", ts(i->a, sa));
		break;

		case TAC_BEGINFUNC:
		printf("begin");
		break;

		case TAC_ENDFUNC:
		printf("end");
		break;

		default:
		error("unknown TAC opcode");
		break;
	}

	fflush(stdout);

}


char *ts(SYMB *s, char *str) 
{
	/* Check we haven't been given NULL */
	if(s==NULL)	return "NULL";

	/* Identify the type */
	switch(s->type)
	{
		case SYM_FUNC:
		case SYM_VAR:
		/* Just return the name */
		return s->name; /* ysj */

		case SYM_TEXT:
		/* Put the address of the text */
		sprintf(str, "L%d", s->lable);
		return str;

		case SYM_INT:
		/* Convert the number to string */
		sprintf(str, "%d", s->value);
		return str;

		default:
		/* Unknown arg type */
		error("unknown TAC arg type");
		return "?";
	}
} 

void error(char *str)
{
	printf("%s\n", str);
	exit(0);
} 

void cg()
{
	tof=LOCAL_OFF; /* TOS allows space for link info */
	oof=FORMAL_OFF;
	oon=0;

	int r;
	for(r=0; r < R_NUM; r++) 
		rdesc[r].name=NULL;
	insert_desc(0, mkconst(0), UNMODIFIED); /* R0 holds 0 */

	cg_head();

	TAC * cur;
	for(cur=tac_first; cur!=NULL; cur=cur->next)
	{
		printf("\n	# ");
		tac_print(cur);
		printf("\n");
		cg_code(cur);
	}
	cg_lib();
	cg_data();
} 

void tac_tidy()
{
	TAC *c=NULL; 		/* Current TAC */
	TAC *p=tac_last; 	/* Previous TAC */

	while(p !=NULL)
	{
		p->next=c;
		c=p;
		p=p->prev;
	}

	tac_first = c;
} 

void cg_code(TAC *c)
{
	int r;

	switch(c->op)
	{
		case TAC_UNDEF:
		error("cannot translate TAC_UNDEF");
		return;

		case TAC_ADD:
		cg_bin("ADD", c->a, c->b, c->c);
		return;

		case TAC_SUB:
		cg_bin("SUB", c->a, c->b, c->c);
		return;

		case TAC_MUL:
		cg_bin("MUL", c->a, c->b, c->c);
		return;

		case TAC_DIV:
		cg_bin("DIV", c->a, c->b, c->c);
		return;

		case TAC_NEG:
		cg_bin("SUB", c->a, mkconst(0), c->b);
		return;

		case TAC_EQ:
		case TAC_NE:
		case TAC_LT:
		case TAC_LE:
		case TAC_GT:
		case TAC_GE:
		cg_cmp(c->op, c->a, c->b, c->c);
		return;

		case TAC_COPY:
		cg_copy(c->a, c->b);
		return;

		case TAC_GOTO:
		cg_cond("JMP", NULL, c->a->name);
		return;

		case TAC_IFZ:
		cg_cond("JEZ", c->b, c->a->name);
		return;

		case TAC_LABEL:
		flush_all();
		printf("%s:\n", c->a->name);
		return;

		case TAC_ACTUAL:
		r=get_rreg(c->a);
		printf("	STO (R2+%d),R%u\n", tof+oon, r);
		oon += 4;
		return;

		case TAC_CALL:
		flush_all();
		printf("	STO (R2+%d),R2\n", tof+oon);	/* store old bp */
		oon += 4;
		printf("	LOD R4,R1+32\n"); 				/* return addr: 4*8=32 */
		printf("	STO (R2+%d),R4\n", tof+oon);	/* store return addr */
		oon += 4;
		printf("	LOD R2,R2+%d\n", tof+oon-8);	/* load new bp */
		printf("	JMP %s\n", (char *)c->b);	/* jump to new func */
		if(c->a !=NULL) insert_desc(R_TP, c->a, MODIFIED);
		oon=0;
		return;

		case TAC_BEGINFUNC:
		/* We reset the top of stack, since it is currently empty apart from the link information. */
		LocalScope=1;
		tof=LOCAL_OFF;
		oof=FORMAL_OFF;
		oon=0;
		return;

		case TAC_FORMAL:
		c->a->store=1; /* parameter is special local var */
		c->a->offset=oof;
		oof -=4;
		return;

		case TAC_VAR:
		if(LocalScope)
		{
			c->a->store=1; /* local var */
			c->a->offset=tof;
			tof +=4;
		}
		else
		{
			c->a->store=0; /* global var */
			c->a->offset=tos;
			tos +=4;
		}
		return;

		case TAC_RETURN:
		cg_return(c->a);
		return;

		case TAC_ENDFUNC:
		cg_return(NULL);
		LocalScope=0;
		return;

		default:
		/* Don't know what this one is */
		error("unknown TAC opcode to translate");
		return;
	}
}

void cg_bin(char *op, SYMB *a, SYMB *b, SYMB *c)
{
	int rreg=get_rreg(b); /* Result register */
	int areg=get_areg(c, rreg); /* One more register */

	printf("	%s R%u,R%u\n", op, rreg, areg);

	/* Delete c from the descriptors and insert a */
	clear_desc(rreg);
	insert_desc(rreg, a, MODIFIED);
}   

void cg_cmp(int op, SYMB *a, SYMB *b, SYMB *c)
{
	int rreg=get_rreg(b); /* Result register */
	int areg=get_areg(c, rreg); /* One more register */

	printf("	SUB R%u,R%u\n", rreg, areg);
	printf("	TST R%u\n", rreg);

	switch(op)
	{		
		case TAC_EQ:
		printf("	LOD R3,R1+40\n");
		printf("	JEZ R3\n");
		printf("	LOD R%u,0\n", rreg);
		printf("	LOD R3,R1+24\n");
		printf("	JMP R3\n");
		printf("	LOD R%u,1\n", rreg);
		break;
		
		case TAC_NE:
		printf("	LOD R3,R1+40\n");
		printf("	JEZ R3\n");
		printf("	LOD R%u,1\n", rreg);
		printf("	LOD R3,R1+24\n");
		printf("	JMP R3\n");
		printf("	LOD R%u,0\n", rreg);
		break;
		
		case TAC_LT:
		printf("	LOD R3,R1+40\n");
		printf("	JLZ R3\n");
		printf("	LOD R%u,0\n", rreg);
		printf("	LOD R3,R1+24\n");
		printf("	JMP R3\n");
		printf("	LOD R%u,1\n", rreg);
		break;
		
		case TAC_LE:
		printf("	LOD R3,R1+40\n");
		printf("	JGZ R3\n");
		printf("	LOD R%u,1\n", rreg);
		printf("	LOD R3,R1+24\n");
		printf("	JMP R3\n");
		printf("	LOD R%u,0\n", rreg);
		break;
		
		case TAC_GT:
		printf("	LOD R3,R1+40\n");
		printf("	JGZ R3\n");
		printf("	LOD R%u,0\n", rreg);
		printf("	LOD R3,R1+24\n");
		printf("	JMP R3\n");
		printf("	LOD R%u,1\n", rreg);
		break;
		
		case TAC_GE:
		printf("	LOD R3,R1+40\n");
		printf("	JLZ R3\n");
		printf("	LOD R%u,1\n", rreg);
		printf("	LOD R3,R1+24\n");
		printf("	JMP R3\n");
		printf("	LOD R%u,0\n", rreg);
		break;
	}

	/* Delete c from the descriptors and insert a */
	clear_desc(rreg);
	insert_desc(rreg, a, MODIFIED);
}   

void cg_copy(SYMB *a, SYMB *b)
{
	int rreg=get_rreg(b); /* Load b into a register */
	insert_desc(rreg, a, MODIFIED); /* Indicate a is there */
}    

void cg_cond(char *op, SYMB *a,  char *l)
{
	spill_all();

	if(a !=NULL)
	{
		int r;

		for(r=R_GEN; r < R_NUM; r++) /* Is it in reg? */
		{
			if(rdesc[r].name==a) break;
		}

		if(r < R_NUM) printf("	TST R%u\n", r);
		else printf("	TST R%u\n", get_rreg(a)); /* Load into new register */
	}

	printf("	%s %s\n", op, l); 
} 
			   
void cg_return(SYMB *a)
{
	if(a !=NULL)					/* return value */
	{
		spill_one(R_TP);
		load_reg(R_TP, a);
	}

	printf("	LOD R3,(R2+4)\n");	/* return address */
	printf("	LOD R2,(R2)\n");	/* restore bp */
	printf("	JMP R3\n");		/* return */
}   

void cg_head()
{
	char head[]=
	"	# head\n"
	"	LOD R2,STACK\n"
	"	STO (R2),0\n"
	"	LOD R4,EXIT\n"
	"	STO (R2+4),R4";

	puts(head);
}

void cg_lib()
{
	char lib[]=
	"\nPRINTN:\n"
	"	LOD R7,(R2-4) # 789\n"
	"	LOD R15,R7 # 789 \n"
	"	DIV R7,10 # 78\n"
	"	TST R7\n"
	"	JEZ PRINTDIGIT\n"
	"	LOD R8,R7 # 78\n"
	"	MUL R8,10 # 780\n"
	"	SUB R15,R8 # 9\n"
	"	STO (R2+8),R15 # local 9 store\n"
	"\n	# out 78\n"
	"	STO (R2+12),R7 # actual 78 push\n"
	"\n	# call PRINTN\n"
	"	STO (R2+16),R2\n"
	"	LOD R4,R1+32\n"
	"	STO (R2+20),R4\n"
	"	LOD R2,R2+16\n"
	"	JMP PRINTN\n"
	"\n	# out 9\n"
	"	LOD R15,(R2+8) # local 9 \n"
	"\nPRINTDIGIT:\n"
	"	ADD  R15,48\n"
	"	OUT\n"
	"\n	# ret\n"
	"	LOD R3,(R2+4)\n"
	"	LOD R2,(R2)\n"
	"	JMP R3\n"
	"\nPRINTS:\n"
	"	LOD R7,(R2-4)\n"
	"\nPRINTC:\n"
	"	LOD R15,(R7)\n"
	"	DIV R15,16777216\n"
	"	TST R15\n"
	"	JEZ PRINTSEND\n"
	"	OUT\n"
	"	ADD R7,1\n"
	"	JMP PRINTC\n"	
	"\nPRINTSEND:\n"
	"	# ret\n"
	"	LOD R3,(R2+4)\n"
	"	LOD R2,(R2)\n"
	"	JMP R3\n"

	"\n"
	"EXIT:\n"
	"	END\n";

	puts(lib);
}

void cg_data(void)
{
	int i;

	SYMB *sl;

	for(sl=GlobalSymbolTable; sl !=NULL; sl=sl->next)
	{
		if(sl->type==SYM_TEXT) cg_str(sl);
	}

	printf("STATIC:\n");
	printf("	DBN 0,%u\n", tos);				
	printf("STACK:\n");
}

void cg_str(SYMB *s)
{
	char *t=s->name; /* The text */
	int i;

	printf("L%u:\n", s->lable); /* Label for the string */
	printf("	DBS "); /* Label for the string */

	for(i=1; t[i + 1] !=0; i++)
	{
		if(t[i]=='\\')
		{
			switch(t[++i])
			{
				case 'n':
				printf("%u,", '\n');
				break;

				case '\"':
				printf("%u,", '\"');
				break;
			}
		}
		else printf("%u,", t[i]);
	}

	printf("0\n"); /* End of string */
}

void flush_all(void)
{
	int r;

	spill_all();

	for(r=R_GEN; r < R_NUM; r++) clear_desc(r);

	clear_desc(R_TP); /* Clear result register */
}

void spill_all(void)
{
	int r;
	for(r=R_GEN; r < R_NUM; r++) spill_one(r);
} 

void spill_one(int r)
{
	if((rdesc[r].name !=NULL) && rdesc[r].modified)
	{
		if(rdesc[r].name->store==1) /* local var */
		{
			printf("	STO (R%u+%u),R%u\n", R_BP, rdesc[r].name->offset, r);
		}
		else /* global var */
		{
			printf("	LOD R%u,STATIC\n", R_TP);
			printf("	STO (R%u+%u),R%u\n", R_TP, rdesc[r].name->offset, r);
		}
		rdesc[r].modified=UNMODIFIED;
	}
}


void load_reg(int r, SYMB *n) 
{
	int s;

	/* Look for a register */
	for(s=0; s < R_NUM; s++)  
	{
		if(rdesc[s].name==n)
		{
			printf("	LOD R%u,R%u\n", r, s);
			insert_desc(r, n, rdesc[s].modified);
			return;
		}
	}
	
	/* Not in a reg. Load appropriately */
	switch(n->type)
	{
		case SYM_INT:
		printf("	LOD R%u,%u\n", r, n->value);
		break;

		case SYM_VAR:
		if(n->store==1) /* local var */
		{
			if((n->offset)>=0) printf("	LOD R%u,(R%u+%d)\n", r, R_BP, n->offset);
			else printf("	LOD R%u,(R%u-%d)\n", r, R_BP, -(n->offset));
		}
		else /* global var */
		{
			printf("	LOD R%u,STATIC\n", R_TP);
			printf("	LOD R%u,(R%u+%d)\n", r, R_TP, n->offset);
		}
		break;

		case SYM_TEXT:
		printf("	LOD R%u,L%u\n", r, n->lable);
		break;
	}

	insert_desc(r, n, UNMODIFIED);
}   
	
void clear_desc(int r)    
{
        rdesc[r].name=NULL;
}    

void insert_desc(int r, SYMB *n, int mod)
{
	int or; /* Old register counter */

	/* Search through each register in turn looking for "n". There should be at most one of these. */
	for(or=R_GEN; or < R_NUM; or++)
	{
	if(rdesc[or].name==n)
	{
	/* Found it, clear it and break out of the loop. */

	clear_desc(or);
	break;
	}
	}

	/* We should not find any duplicates, but check, just in case. */

	for(or++; or < R_NUM; or++)

	if(rdesc[or].name==n)
	{
	error("Duplicate slave found");
	clear_desc(or);
	}

	/* Finally insert the name in the new descriptor */

	rdesc[r].name=n;
	rdesc[r].modified=mod;
}     

int get_rreg(SYMB *c)
{
	int r; /* Register for counting */

	for(r=R_GEN; r < R_NUM; r++) /* Already in a register */
	{
		if(rdesc[r].name==c)
		{
			spill_one(r);
			return r;
		}
	}

	for(r=R_GEN; r < R_NUM; r++)
	{
		if(rdesc[r].name==NULL) /* Empty register */
		{
			load_reg(r, c);
			return r;
		}

	}
	
	for(r=R_GEN; r < R_NUM; r++)
	{
		if(!rdesc[r].modified) /* Unmodifed register */
		{
			clear_desc(r);
			load_reg(r, c);
			return r;
		}
	}

	spill_one(R_GEN); /* Modified register */
	clear_desc(R_GEN);
	load_reg(R_GEN, c);
	return R_GEN;
} 

int get_areg(SYMB *b, int cr)             
{
	int r; /* Register for counting */

	for(r=R_GEN; r < R_NUM; r++)
	{
		if(rdesc[r].name==b) /* Already in register */
		return r;
	}

	for(r=R_GEN; r < R_NUM; r++)
	{
		if(rdesc[r].name==NULL) /* Empty register */
		{
			load_reg(r, b);
			return r;
		}
	}

	for(r=R_GEN; r < R_NUM; r++)
	{
		if(!rdesc[r].modified && (r !=cr)) /* Unmodifed register */
		{
			clear_desc(r);
			load_reg(r, b);
			return r;
		}
	}

	for(r=R_GEN; r < R_NUM; r++)
	{
		if(r !=cr) /* Modified register */
		{
			spill_one(r);
			clear_desc(r);
			load_reg(r, b);
			return r;
		}
	}
}      

int main(int argc,   char *argv[])
{

    /////输出draw.txt文件

	myfp = fopen("draw.dot","w");
	fprintf(myfp, "digraph G{\n");
	fprintf(myfp, "graph[ordering=out];\n");
	/////
	int i; /* General counter */
	char *ifile;
	char *ofile;

	if(argc==2)
	{
		mode=0;
	}
	else if(argc==3)
	{
		if(!strcmp(argv[2],"-lex"))
			mode=1;
		else if(!strcmp(argv[2],"-syn"))
			mode=2;
		else if(!strcmp(argv[2],"-tac"))
			mode=3;
		else
		{
			printf("error: argument %s\n", argv[2]);
			exit(0);
		}			
	}
	else
	{
		printf("usage: %s name [-lex/-syn/-tac]\n", argv[0]);
		exit(0);
	}

	ifile=(char *)malloc(strlen(argv[1]) + 10);
	strcpy(ifile,argv[1]);
	strcat(ifile,".gpl");
	
	if(freopen(ifile, "r", stdin)==NULL)
	{
		printf("error: open %s failed\n", ifile);
		exit(0);
	}
	
	ofile=(char *)malloc(strlen(argv[1]) + 10);
	strcpy(ofile,argv[1]);
	
	if(mode==1)
		strcat(ofile,".lex");
	else if(mode==2)
		strcat(ofile,".syn");
	else if(mode==3)
		strcat(ofile,".tac");
	else
		strcat(ofile,".gal");
										   
	if(freopen(ofile, "w", stdout)==NULL)
	{
		printf("error: open %s failed\n", ofile);
		exit(0);
	}

	/* Give values to global variables */
	line=1;
	character=0;
	token[0]=0;
	LocalScope=0;
	GlobalSymbolTable=NULL;
	LocalSymbolTable=NULL;	
	tos=0;
	symb_list=NULL; /* Freelists */
	enode_list=NULL;
	next_tmp=0; /* No temporaries used */
	next_label=LAB_MIN;

	/* parse */
	yyparse();   //yyparse: 语法分析
	if(mode==1)
	{
	    init_hash();
		yylex();   //yylex：词法分析
		////打印wordlist
        printf("\n\n\nWORDLIST:\n");
		//printf("%p, %s", wl[0].p, wl[0].m);
		int i;
		for(i=0;i<lenwl;i++)
		{
		    printf("%p: %s\n", wl[i].p, wl[i].m);
		}
		//////
        printf("\n\n\n");
		/////打印ls
        ////打印ls看看
		i = 0;
		printf("the long string is:\n");
        while(1)
        {
            if(ls[i]=='\0')
            {
                 //什么都不做
            }
            else
            {
                printf("%c", ls[i]);
            }
			i++;
			if(i==ls_point)
			{
			    break;
			}
        }
		printf("\n");
		/////分隔开的
		printf("separated:\n");
		i=0;
		while(1)
        {
            if(ls[i]=='\0')
            {
                printf(" ");
				
                 //什么都不做
            }
            else
            {
                printf("%c", ls[i]);
            }
			i++;
			if(i==ls_point)
			{
			    break;
			}
        }
		printf("\n");
		/////打印位置表lspos
		printf("the positions are: \n");
		i = 0;
		while(1)
		{
		    printf("%d ", ls_pos[i]);
			insert_hash(ls_pos[i]);
			i++;
			if(i==num_of_words)
			{
			    printf("\n");
			    break;
			}
		}
		printf("\n");
		///打印字面量的个数
		printf("num of lexeme = %d\n", num_of_words+1);


		print_hash();
			

		/////
		exit(0);    
		
	}



	/* tac */
	tac_tidy();   //整理tac
	if(mode==3)
	{
		TAC * cur;
		for(cur = tac_first; cur !=NULL; cur=cur->next)
		{
			tac_print(cur);
			printf("\n");
		}
		exit (0);
	}

	/* code generate */
	cg();


	////关闭我的文件指针
	fprintf(myfp, "}");
    fclose(myfp);
	//////
	return 0;
}

int yyerror(char *str)
{
	fprintf(stderr, "yyerror: %s at line %d\n", str, line);
	return 0;
}

void getch()
{
	character=getchar();
	if(character=='#') 
	{
		while(1)
		{
			character=getchar();
			if(character=='\n' || character==EOF) break;
		}
	}
	/*
	if(character=='/')   
	{
	    character=getchar();
		if(character=='*')
		{
		    while(1)
		    {
		        character=getchar();
				if(character=='\n') line++;
		    	if(character=='*')
				{
					character=getchar();
				    if(character=='/')
					{
					    break;
					}
				}
				if(character==EOF) break;
		    }
		}
		else
		{
		    retract();
		}
	}
	*/
	if(character=='\n') line++;
}

void getnbc()
{
	while((character==' ') || (character=='\t') || (character=='\r') || (character=='\n')) 
		character=getchar();	
}

void concat()
{
	int len=strlen(token);
	token[len]=character;
	token[len+1]='\0';	
}

int letter()
{
	if(((character>='a') && (character<='z')) || ((character>='A') && (character<='Z')))
		return 1;
	else 
		return 0;
}

int digit()
{
	if((character>='0') && (character<='9'))
		return 1;
	else 
		return 0;
}

void retract()
{
	ungetc(character,stdin);
	character='\0';
}

int keyword()
{
	int i=0;
	while(strcmp(keywords[i].name,""))
	{
		if(!strcmp(keywords[i].name,token)) 
			return keywords[i].id;
		i++;
	}
	return 0;
}

/* 不需要判断在不在 直接进就完事了
int isexist(char *a, char*b)   //a:ls b:lexeme 判断lexeme是不是在ls中
{
    int i;
	int j;
	int k;
	for(i=0;;i++)  //外层循环ls
	{
	    if(a[i]==b[0])  //找到第一个一样的 就开始内层
	    {
	        for(j=i,k=0;;j++,k++)   //
	        	{
	        	    if(a[j]==b[k])
	        	    {
	        	        continue;
	        	    }
					if(a[j]!=b[k])
					{
					    if(a[j]=='\0' || b[k]=='\0')   //任何一个单词提前走到了结尾 都是子集问题
					    {
					        return 0;
					    }
					    else
					    {
					        return 1;    //1表示存在
					    }
					}
	        	}
	    }
		if(a[i]!=b[0])   //退出条件 到lspoint这个尾部了 就退出
		{
		    if(i==ls_point)  //不用#判断了 不需要初始化#
		    {
		        return 0;   //0表示不存在
		    }
		}
	}
}
*/

int add_ls(char *a, char *b)       //用于在ls长字符串里面添加字面量 并改变指针 a:ls b:lexeme
{
    int i=ls_point;
	int j=0;
	ls_pos[num_of_words]=ls_point;  //在记录表中添加这个单词的位置
    while(1)
    {
        if(b[j]=='\0')    //走到结尾了
        {
            a[i]='\0';   //让\0作为ls的分隔符 方便打印和解决子集问题
            i++;
            break;
        }
		a[i] = b[j];
		i++;
		j++;
    }
	ls_point=i;  //更新两个指针
	num_of_words ++;
	return 0;
}


////////与语法树生成相关的 比较label与已规约符号的
void myvsp_push()  //a: temp_left 骂人了额
{
    vsp[vsp_top]=temp_left;
	vsp_top++;
}

void myvsp_pop()       //用一下弹一个
{
   if(vsp_top==0)
   	{
   	    printf("error!Stack is empty");
		exit(0);    //强制退出
   	}
   else vsp_top --;
}


int cmp_label(char *a)   //a:label 查找最后栈顶是不是label（因为我们改成从右边开始算了 这样才不会把前面的元素搞错）
{
    if(vsp_top==0) return 0;   //如果栈顶都是0 肯定没东西
    if(strcmp(vsp[vsp_top-1].name, a)==0) return 1;  //1:栈顶是    //注意 top-1才是真正的元素 top是一个空的东西
	else return 0;  //0：栈顶不是
}

void process_root(char *a)   //包括暂存 声明左边的这个结点  处理根
{
    strcpy(temp_name, a);     //第一个必定要新建结点 所以不用判断
	temp_new=dot_num_of_nodes;
	temp_old=dot_num_of_nodes;  
	 
	strcpy(temp_left.name, temp_name);    //暂存左边这个结点
	temp_left.new_number=temp_new;
	temp_left.old_number=temp_old;  
	
	fprintf(myfp, "n%d[label=%s];\n",dot_num_of_nodes,a);   //声明结点
	
	dot_num_of_nodes++;
}

void process_child(char *a)
{
    strcpy(temp_name, a);  //暂存信息
	temp_new=dot_num_of_nodes;
	temp_old=dot_num_of_nodes;
	
	if((cmp_label(temp_name)==1) && (vsp_top>0))    //存在的话就不用定义 直接加边 出栈  或者如果栈空了 肯定也不是把
	{
	    fprintf(myfp, "n%d->n%d;\n",temp_left.old_number,vsp[vsp_top-1].old_number);
	    myvsp_pop();
	    dot_num_of_nodes++;
	}
	else                         //不存在 需要声明结点 再写边
	{
	    
	    fprintf(myfp, "n%d[label=%s];\n",dot_num_of_nodes,a);
	    fprintf(myfp, "n%d->n%d;\n",temp_left.old_number,dot_num_of_nodes);
		dot_num_of_nodes++;
	}  
	
}

/*以下是哈希表相关函数*/
void init_hash()
{
    int i;
    for(i=0;i<SIZE;i++)
    {
        table[i].data=-1;   //-1表示无元素
        table[i].next=NULL;
    }
}
int hash_calc(int a)
{
    return a % 7;
}

int search(int a)   // 1:找到 0：没找到
{

    int hash_val = hash_calc(a);
    HASH *next_node=&table[hash_val];
    if(next_node->data==a)
    {
        return 1;//找到就return1
    }
    else
    {
        while(next_node->next!=NULL)
        {
            next_node = next_node->next;
            if(next_node->data==a) return 1;
        }
        return 0;
    }
}
int insert_hash(int a)   //1:成功插入 0：已经有了，不需要插入（因为这里肯定知道数据一定是唯一的 不会有重复的
{
    if(search(a)==0)
    {
        int hash_val = hash_calc(a);
        HASH *first_node=&table[hash_val];
        if(first_node->next==NULL&&first_node->data==-1)
        {
            first_node->data = a;
            return 1;
        }
        else if(first_node->next==NULL&&first_node->data!=-1)
        {
            HASH *newnode = (HASH*)malloc(sizeof(HASH));
            newnode->data = a;
            newnode->next = NULL;
            first_node->next = newnode;
            return 1;
        }
        else
        {
            while(first_node->next!=NULL)
            {
                first_node = first_node->next;
            }
            HASH *newnode = (HASH*)malloc(sizeof(HASH));
            newnode->data = a;
            newnode->next = NULL;
            first_node->next = newnode;
            return 1;
        }

    }
    else
    {
        return 0;
    }
}

void print_hash()
{
    int i;
    HASH *temp;
    printf("hash_table:\n");
    for(i=0;i<SIZE;i++)
    {
        temp = &table[i];
        while(temp->next!=NULL)
        {
            printf("%d->",temp->data);
            temp = temp->next;
        }
        printf("%d\n",temp->data);
    }
    printf("\n");
}


int yylex()
{
	int num;
	char *lexeme;
		
	strcpy(token,"");
	getch();
	getnbc();

	if(letter())
	{
		while(letter() || digit())
		{
			concat();
			getch();
		}
		retract();
		num=keyword();
		if(num!=0)        //识别关键字
		{
			printf("(%d, -) //KEYWORD\n", num);
			return num; // return keyword
		}
		else       //识别标识符
		{
			lexeme=malloc(strlen(token+1));
			strcpy(lexeme,token);
			yylval.string=lexeme;
			////添加到长字符串中
            add_ls(ls, lexeme);
			
			////
			wl[lenwl].p = (int*)lexeme;
			strcpy(wl[lenwl].m, token);
			lenwl++;
			printf("(%d, %p) //IDENTIFIER\n", IDENTIFIER, lexeme);
			return IDENTIFIER;
		}
	}

	if(digit())   //识别整数
	{
		while(digit())
		{
			concat();
			getch();
		}
		retract();
		lexeme=malloc(strlen(token+1));
		strcpy(lexeme,token);
		yylval.string=lexeme;
		int *p = malloc(4);
		*p = atoi(lexeme);   // *p is an int
		wl[lenwl].p = (int*)p;
		strcpy(wl[lenwl].m, token);
		lenwl++;
		printf("(%d, %p) //INTEGER\n", INTEGER, p);
		return INTEGER;	
	}

	if(character=='"')    //识别字符串
	{
		concat();
		getch();
		while(character!='"' && character!=EOF)
		{
			concat();
			getch();
		}
		if(character==EOF)
		{
			printf("lex error: \" expected\n");
			exit(1);
		}
		concat();
		lexeme=malloc(strlen(token+1));
		strcpy(lexeme,token);
		yylval.string=lexeme;
		////添加到长字符串中
        add_ls(ls, lexeme);
		/////
		wl[lenwl].p = (int*) lexeme;
		strcat(wl[lenwl].m, token);
		lenwl++;
		printf("(%d, %p) //TEXT\n", TEXT, lexeme);
		return TEXT;			
	}

	if(character=='=')
	{
		concat();
		getch();
		if(character=='=') 
		{
			concat();
			printf("(%d, -) //EQ\n", EQ);
			return EQ;
		}
		else
		{
			retract();
			printf("(%d, -) //'='\n", '=');
			return '=';
		}		
	}

	if(character=='!')
	{
		concat();
		getch();
		if(character=='=') 
		{
			concat();
			printf("(%d, -) //NE\n", NE);
			return NE;
		}
		else if(!digit()||!letter())
		{
		    yyerror("invalid symbol combination");
			exit(1);
		}
		else
		{
			retract();
			printf("(%d, -) //'!'\n", '!');
			return '!';
		}		
	}

	if(character=='<')
	{
		concat();
		getch();
		if(character=='=') 
		{
			concat();
			printf("(%d, -) //LE\n", LE);
			return LE;
		}
		else
		{
			retract();
			printf("(%d, -) //LT\n", LT);
			return LT;
		}		
	}

	if(character=='>')
	{
		concat();
		getch();
		if(character=='=') 
		{
			concat();
			printf("(%d, -) //GE\n", GE);
			return GE;
		}
		else
		{
			retract();
			printf("(%d, -) //GT\n", GT);
			return GT;
		}
	}
	
	if(character=='(')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //'('\n", '(');
		return '(';		
	}

	if(character==')')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //')'\n", ')');
		return ')';		
	}

	if(character=='{')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //'{'\n", '{');
		return '{';		
	}

	if(character=='}')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //'}'\n", '}');
		return '}';		
	}

	if(character==';')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //';'\n", ';');
		return ';';		
	}

	if(character==':')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //':'\n", ':');
		return ':';		
	}

	if(character=='\'')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //'''\n", '\'');
		return '\'';		
	}

	if(character==',')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //','\n", ',');
		return ',';		
	}

	if(character=='+')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //'+'\n", '+');
		return '+';		
	}

	if(character=='-')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //'-'\n", '-');
		return '-';		
	}

	if(character=='*')
	{
	    concat();
		getch();
		retract();
		printf("(%d, -) //'*'\n", '*');
		return '*';		
	}

	if(character=='/')    
	{
	    concat();
		getch();
	    retract();
	    printf("(%d, -) //'/'\n", '/');
	    return '/';	
	}

	if(character=='<')
	{
		concat();
		getch();
		if(character=='=') 
		{
			concat();
			printf("(%d, -) //LE\n", LE);
			return LE;
		}
		else
		{
			retract();
			printf("(%d, -) //LT\n", LT);
			return LT;
		}		
	}

	
	return character;	
}


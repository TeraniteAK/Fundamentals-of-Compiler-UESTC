# Fundamentals-of-Compiler-UESTC
This is my course expriment of Fundamentals of Compiler in 2 semester 2018-2019 in UESTC. 这是我在电子科技大学2018-2019下学期课程编译原理的课程实验。

***实验1：词法分析***

***实验要求：***

词法分析实验评分标准

1.输出单词，以二元式形式（5\*6=30分）

（关键字的编码，-）

（标识符的编码，字面量的地址）

（整型常数的编码，整数值的地址）

（字符串型常数的编码，字面量的地址）

（运算符的编码，-）

（介符的编码，-）

2.出错处理（5\*2=10分）

非法字符错误

非法组合错误

3.符号表管理（10\*3=30分）

输出每个符号的地址和值。

标识符：地址、字面量（abc）

整数：地址、值（10000）

字符串：地址、字面量（"abc"）

4.现场提问（3\*10=30分）

问题1：你的代码用于存放3种符号的值的代码位置在哪里？

问题2：是否能重新实现存放字面量字符串？

问题3：是否能重新实现一个hash表，名字域为指针？


***实验2：语法分析***

***实验要求：***

语法分析实验评分标准

1.输出语法树（50分）

对于语法正确的输入串，生成相应的语法树，保存到输出文件，文件格式不限。(10分）

语法树正确，语法树的根节点为文法的开始符号，语法树的边缘为输入串。（10分）

语法树的展示效果好，直观、美观（用户体验：非常好21~30分、比较好11~20分、比较差1~10分）。

2.出错处理（10分）

对于语法错误的输入串，给出出错提示（5分）

在出错提示中指出错误的位置。（5分）

3.符号表管理（10分）

能够区分同名的全局变量和不同函数中同名的局部变量。

4.现场提问（30分）

问题1：你的代码中是如何区分同名的全局变量和不同函数中同名的局部变量的？

问题2：是否提供了足够的测试用例（至少5个）证明你的程序实现了相关功能？

问题3：是否能够详细说明你的代码中最具有特色或个性化的功能的实现方法？


***实验3：中间代码生成***

***实验要求：***

中间代码生成实验评分标准

1.输出三地址码（60分）

对于语义正确的输入串，输出正确的三地址码。(20分）

按照源代码中顺序说明三地址码中形参。（10分）

支持for语句。（20分）

支持变量（包括局部变量、全局变量）的初始化操作。（10分）

2.出错处理（10分）

对于语义错误的输入串，给出出错提示（5分）

在出错提示中指出错误原因。（5分）

3.现场提问（30分）

问题1：你的三地址码中是如何表示变量的初始化操作的？

问题2：是否提供了足够的测试用例（至少5个）证明你的程序实现了相关功能？

问题3：是否能够详细说明你的代码中最具有特色或个性化的功能的实现方法？


***实验4：目标代码生成***

***实验要求：***

目标代码生成实验评分标准

1.输出目标代码（70分）

对于语义正确的输入串，输出正确的目标代码（汇编代码）。(20分）

按照活动记录中各个字段的先后顺序按照课堂上的顺序排列。（20分）

按照源代码中顺序传递形参的值。（10分）

支持变量（包括局部变量、全局变量）的初始化操作。（20分）

3.现场提问（30分）

问题1：你的目标代码是如何访问参数、局部变量和全局变量的？

问题2：是否提供了足够的测试用例（至少5个）证明你的程序实现了相关功能？

问题3：是否能够详细说明你的代码中最具有特色或个性化的功能的实现方法？


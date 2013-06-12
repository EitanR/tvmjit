
# Table Processing

##

### ; comment

### number

### string

### table

    (1 4 9 16)
    (-100: "min" 100: "max")
    (0: "zero" "one")
    ("zero": 0 "one": 1)

### identifier

    Foo
    Foo-Bar
    Foo\:Bar
    Foo\(Bar\)
    Foo\ Bar
    Foo$Bar
    Foo%Bar
    Foo@Bar



## Specials

* !false

* !nil

* !true

* !vararg

* (!assign var expr)

assignment
(could be used as expression, not like in Lua)

* (!add expr1 expr2)

addition

* (!and expr1 expr2)

logical and

* (!break)

* (!call fct prm1 ... prmn)

* (!call1 fct prm1 ... prmn )

* (!callmeth obj meth prm1 ... prmn)

* (!callmeth1 obj meth prm1 ... prmn )

* (!concat expr1 expr2)

concatenation

* (!cond (expr1 (stmt1 ... stmtm)) ... (exprn (stmt1 ... stmtm)))

* (!define var [expr])

define a local variable

* (!div expr1 expr2)

division

* (!do stmt1 ... stmtn)

block

* (!eq expr1 expr2)

relational equal

* (!for (var1 ... varn) (expr1 ... exprm) stmt1 ... stmtn)

* (!ge expr1 expr2)

relational great or equal

* (!goto lbl)

* (!gt expr1 exrp2)

relational great than

* (!if expr stmt-then [stmt-else])

* (!index var expr)

* (!label lbl)

* (!lambda (prm1 ... prmn) (stmt1 ... stmtn))

* (!le expr1 expr2)

relational less or equal

* (!len expr)

length

* (!let var expr)

define a local variable which could not be re-assigned

* (!letrec var expr)

* (!line "filename" lineno)
* (!line lineno)

annotation

* (!loop init limit step stmt1 ... stmtn)

* (!lt expr1 expr2)

relational less then

* (!massign (var1 ... varn) (expr1 ... exprm))

multiple assignment

* (!mconcat expr1 ... exprn)

concatenation

* (!mod expr1 expr2)

modulo

* (!mul expr1 expr2)

multiplication

* (!ne expr1 expr2)

relational not equal

* (!neg expr)

negation

* (!not expr)

logical not

* (!or expr1 expr2)

logical or

* (!pow expr1 expr2)

exponentiation

* (!repeat stmt1 ... stmtn expr)

* (!return expr1 ... exprn)

* (!sub expr1 expr2)

subtraction

* (!while expr stmt1 ... stmtn)



## TVM Library

In addition to the Lua standard libraries.

* tvm.dofile ([filename])

like `dofile` but for TP chunk.

* tvm.escape (s)

returns a escaped string (`(`, `)`, `:`, and space) suitable to be safely read back by the TP interpreter.

* tvm.load (ld [, source [, mode]])

like `load` (5.2) but for TP chunk (includes 5.1 `loadstring`).

* tvm.loadfile (filename [, mode])

like `loadfile` (5.2) but for TP chunk.

* tvm.quote (s)

returns a quoted (and escaped) string suitable to be safely read back by the TP interpreter.

* tvm.unpack (list [, i [, j ]])

`tvm.unpack` accept `nil` as parameter,
so `tvm.unpack(t)` is equivalent to `unpack(t or {})`.

* tvm.wchar (...)

like `string.char` but returns a string which is the concatenation of the UTF-8 representation of each integer.


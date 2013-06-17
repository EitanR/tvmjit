
# Table Processing

## Tokens

#### ; comment

#### number

    0
    42

    3.14
    +.314e+1
    .314e1
    -31.4e-1

    0x7E
    -0X7e

    0x0.1E
    0xA23p-4

#### string

    "text"
    "tab\t"
    "quote\""
    "\x3A"      ; hexadecimal 8-bits character
    "\u20AC"    ; unicode char UTF-8 encoded

#### table

    (1 4 9 16)
    (-100: "min" 100: "max")
    (0: "zero" "one")
    ("zero": 0 "one": 1)

#### identifier

    Foo
    Foo-Bar
    Foo\:Bar
    Foo\(Bar\)
    Foo\ Bar
    !Foo$Bar?



## Specials

#### `!false`

#### `!nil`

#### `!true`

#### `!vararg`

#### `(!assign var expr)`

assignment
(could be used as expression, not like in Lua)

#### `(!add expr1 expr2)`

addition

#### `(!and expr1 expr2)`

logical and

#### `(!break)`

break statement

#### `(!call fct prm1 ... prmn)`

function call

#### `(!call1 fct prm1 ... prmn)`

function call with results adjusted to 1

#### `(!callmeth obj meth prm1 ... prmn)`

method call

#### `(!callmeth1 obj meth prm1 ... prmn)`

method call with results adjusted to 1

#### `(!concat expr1 expr2)`

concatenation

#### `(!cond (expr1 (stmt1 ... stmtm)) ... (exprn (stmt1 ... stmtm)))`

cond statement

#### `(!define var [expr])` or `(!define (var1 ... varn) (expr1 ... exprm))`

define local variables

#### `(!div expr1 expr2)`

division

#### `(!do stmt1 ... stmtn)`

block

#### `(!eq expr1 expr2)`

relational equal

#### `(!for (var1 ... varn) (expr1 ... exprm) stmt1 ... stmtn)`

for statement

#### `(!ge expr1 expr2)`

relational great or equal

#### `(!goto lbl)`

goto statement

#### `(!gt expr1 exrp2)`

relational great than

#### `(!if expr stmt-then [stmt-else])`

if statement

#### `(!index var expr)`

#### `(!label lbl)`

#### `(!lambda (prm1 ... prmn) stmt1 ... stmtn)`

#### `(!le expr1 expr2)`

relational less or equal

#### `(!len expr)`

length

#### `(!let var expr)` or `(!let (var1 ... varn) (expr1 ... exprm))`

define local variables which could not be re-assigned

#### `(!letrec var lambda)`

define a local variable which could used in recursive call

#### `(!line "filename" lineno)` or `(!line lineno)`

annotation

#### `(!loop init limit step stmt1 ... stmtn)`

loop statement

#### `(!lt expr1 expr2)`

relational less then

#### `(!massign (var1 ... varn) (expr1 ... exprm))`

multiple assignment

#### `(!mconcat expr1 ... exprn)`

concatenation

#### `(!mod expr1 expr2)`

modulo

#### `(!mul expr1 expr2)`

multiplication

#### `(!ne expr1 expr2)`

relational not equal

#### `(!neg expr)`

negation

#### `(!not expr)`

logical not

#### `(!or expr1 expr2)`

logical or

#### `(!pow expr1 expr2)`

exponentiation

#### `(!repeat stmt1 ... stmtn expr)`

repeat statement

#### `(!return expr1 ... exprn)`

return statement

#### `(!sub expr1 expr2)`

subtraction

#### `(!while expr stmt1 ... stmtn)`

while statement



## TVM Library

In addition to the Lua standard libraries.

#### `tvm.dofile ([filename])`

like `dofile` but for TP chunk.

#### `tvm.escape (s)`

returns a escaped string (`(`, `)`, `:`, and space) suitable to be safely read back by the TP interpreter.

#### `tvm.load (ld [, source [, mode]])`

like `load` (5.2) but for TP chunk (includes 5.1 `loadstring`).

#### `tvm.loadfile (filename [, mode])`

like `loadfile` (5.2) but for TP chunk.

#### `tvm.quote (s)`

returns a quoted string (not printable character are escaped) suitable to be safely read back by the TP interpreter.

#### `tvm.unpack (list [, i [, j ]])`

`tvm.unpack` accept `nil` as parameter,
so `tvm.unpack(t)` is equivalent to `unpack(t or {})`.

#### `tvm.wchar (...)`

like `string.char` but returns a string which is the concatenation of the UTF-8 representation of each integer.

## Code Generation

Here, an example of code generation library :

    $ cat ost.tp

    (!let pairs pairs)
    (!let setmetatable setmetatable)
    (!let tostring tostring)
    (!let type type)
    (!let tconcat (!index table "concat"))

    (!let op_mt ("__tostring": (!lambda (o)
                    (!let t ())
                    (!if (!index o 0)
                         (!assign (!index t 1) (!concat "0: " (!call1 tostring (!index o 0)))))
                    (!loop i 1 (!len o) 1
                            (!assign (!index t (!add (!len t) 1)) (!call1 tostring (!index o i))))
                    (!for (k v) ((!call pairs o))
                            (!if (!or (!or (!ne (!call1 type k) "number") (!lt k 0)) (!gt k (!len o)))
                                 (!assign (!index t (!add (!len t) 1)) (!mconcat (!call1 tostring k) ": " (!call1 tostring v)))))
                    (!return (!mconcat (!or (!and (!or (!eq (!index o 1) "!line") (!eq (!index o 1) "!do")) "\n(") "(") (!call1 tconcat t " ") ")"))) ))
    (!let op (!call1 setmetatable (
            "push": (!lambda (self v)
                    (!assign (!index self (!add (!len self) 1)) v)
                    (!return self))
            "addkv": (!lambda (self k v)
                    (!assign (!index self k) v)
                    (!return self))
            ) ("__call": (!lambda (func t)
                    (!return (!call1 setmetatable t op_mt))) )))
    (!assign (!index op_mt "__index") op)

    (!let ops_mt ("__tostring": (!lambda (o)
                    (!let t ())
                    (!loop i 1 (!len o) 1
                            (!assign (!index t (!add (!len t) 1)) (!call1 tostring (!index o i))))
                    (!return (!call1 tconcat t))) ))
    (!let ops (!call1 setmetatable (
            "push": (!lambda (self v)
                    (!assign (!index self (!add (!len self) 1)) v)
                    (!return self))
            ) ("__call": (!lambda (func t)
                    (!return (!call1 setmetatable t ops_mt))))))
    (!assign (!index ops_mt "__index") ops)

    (!return ("op": op "ops": ops ))


    $ cat ost.t

    (!let _ (!call1 (!index tvm "dofile") "ost.tp"))
    (!let op (!index _ "op"))
    (!let ops (!index _ "ops"))
    (!let quote (!index tvm "quote"))

    (!let o (!call1 ops (
        (!call1 op ("!line" 1))
        (!call1 op ("!call" "print" (!call1 quote "hello")))
        (!call1 op ("!line" 2))
        (!call1 op ("!let" "h" (!call1 op ((!call1 quote "no"): 0 (!call1 quote "yes"): 1))))
        (!call1 op ("!line" 3))
        (!call1 op ("!let" "a" (!call1 op (0: (!call1 quote "zero") (!call1 quote "one") (!call1 quote "two")))))
        (!callmeth1 (!call1 op ("!line"))
                    push 4)
        (!call1 op ("!let" "h" (!callmeth1 (!call1 op ())
                                           addkv (!call1 quote "key") (!call1 quote "value"))))
    )))
    (!callmeth o push (!call1 op ("!line" 5)))
    (!callmeth o push (!call1 op ("!call" "print" (!call1 op ("!index" "h" (!call1 quote "key"))))))
    (!call print o)


    $ ./tvmjit ost.t

    (!line 1)(!call print "hello")
    (!line 2)(!let h ("no": 0 "yes": 1))
    (!line 3)(!let a (0: "zero" "one" "two"))
    (!line 4)(!let h ("key": "value"))
    (!line 5)(!call print (!index h "key"))

    $ ./tvmjit ost.t | ./tvmjit
    hello
    value

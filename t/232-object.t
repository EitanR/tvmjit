#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let setmetatable setmetatable)

(!call plan 18)

;   object
(!define Account ("balance": 0))

(!assign (!index Account "withdraw") (!lambda (self v)
                (!assign (!index self "balance") (!sub (!index self "balance") v))))

(!define a1 Account)(!assign Account !nil)
(!call (!index a1 "withdraw") a1 100.00)
(!call is (!index a1 "balance") -100 "object")

(!define a2 ("balance": 0 "withdraw": (!index a1 "withdraw")))
(!call (!index a2 "withdraw") a2 260.00)
(!call is (!index a2 "balance") -260)

;   object
(!define Account ("balance": 0))

(!assign (!index Account "withdraw") (!lambda (self v)
                (!assign (!index self "balance") (!sub (!index self "balance") v))))

(!define a Account)
(!callmeth  a withdraw 100.00)
(!call is (!index a "balance") -100 "object")

(!define Account ("balance": 0
                  "withdraw": (!lambda (self v)
                                (!assign (!index self "balance") (!sub (!index self "balance") v)))))
(!assign (!index Account "deposit") (!lambda (self v)
                (!assign (!index self "balance") (!add (!index self "balance") v))))

(!call (!index Account "deposit") Account 200.00)
(!call is (!index Account "balance") 200 "object")
(!callmeth Account withdraw 100.00)
(!call is (!index Account "balance") 100)

;   classe
(!define Account ("balance": 0))

(!assign (!index Account "new") (!lambda (self o)
                (!let o (!or o ()))
                (!call setmetatable o self)
                (!assign (!index self "__index") self)
                (!return o)))

(!assign (!index Account "deposit") (!lambda (self v)
                (!assign (!index self "balance") (!add (!index self "balance") v))))

(!assign (!index Account "withdraw") (!lambda (self v)
                (!assign (!index self "balance") (!sub (!index self "balance") v))))

(!let a (!callmeth Account new ("balance": 0)))
(!callmeth a deposit 100.00)
(!call is (!index a "balance") 100 "classe")

(!let b (!callmeth Account new))
(!call is (!index b "balance") 0)
(!callmeth b deposit 200.00)
(!call is (!index b "balance") 200)

;   inheritance
(!define Account ("balance": 0))

(!assign (!index Account "new") (!lambda (self o)
                ; (!call println "Account:new")
                (!let o (!or o ()))
                (!call setmetatable o self)
                (!assign (!index self "__index") self)
                (!return o)))

(!assign (!index Account "deposit") (!lambda (self v)
                ; (!call println "Account:deposit")
                (!assign (!index self "balance") (!add (!index self "balance") v))))

(!assign (!index Account "withdraw") (!lambda (self v)
                (!call println "Account:withdraw")
                (!if (!gt v (!index self "balance"))
                     (!call error "insuficient funds"))
                (!assign (!index self "balance") (!sub (!index self "balance") v))))

(!define a (!callmeth Account new))
(!call is (!index a "balance") 0 "inheritance")
; (!define (r msg) ((!call pcall (!index Account "withdraw") a 100)))
; (!call println msg)

(!define SpecialAccount (!callmeth Account new))

(!assign (!index SpecialAccount "withdraw") (!lambda (self v)
                ; (!call println "SpecialAccount:withdraw")
                (!if (!le (!sub (!index self "balance") v) (!neg (!callmeth self getLimit)))
                     (!call error "insuficient funds"))
                (!assign (!index self "balance") (!sub (!index self "balance") v))))

(!assign (!index SpecialAccount "getLimit") (!lambda (self)
                ; (!call println "SpecialAccount:getLimit")
                (!return (!or (!index self "limit") 0))))

(!define s (!callmeth SpecialAccount new ("limit":1000.00)))

(!callmeth s deposit 100.00)
(!call is (!index s "balance") 100)

(!callmeth s withdraw 200.00)
(!call is (!index s "balance") -100)

;   multiple inheritance
; look up for 'k' in list of tables 'plist'
(!let search (!lambda (k plist)
                (!loop i 0 (!sub (!len plist) 1) 1
                        (!let v (!index (!index plist i) k))    ; try 'i'-th superclass
                        (!if v (!return v)))))

(!let createClass (!lambda (!vararg)
                (!let c ())  ; new class
                (!let arg (!vararg))
                ; class will search for each method in the list of its
                ; parents ('arg' is the list of parents)
                (!call setmetatable c ("__index": (!lambda (t k)
                                                (!return (!call search k arg)))))
                ; prepare 'c' to be the metatable of its instance
                (!assign (!index c "__index") c)
                ; define a new constructor for this new class
                (!assign (!index c "new") (!lambda (self o)
                                                (!let o (!or o ()))
                                                (!call setmetatable o c)
                                                (!return o)))
                ; return new class
                (!return c)))

(!define Account ("balance": 0))
(!assign (!index Account "deposit") (!lambda (self v)
                (!assign (!index self "balance") (!add (!index self "balance") v))))
(!assign (!index Account "withdraw") (!lambda (self v)
                (!assign (!index self "balance") (!sub (!index self "balance") v))))

(!define Named ())
(!assign (!index Named "getname") (!lambda (self)
                (!return (!index self "name"))))
(!assign (!index Named "setname") (!lambda (self n)
                (!assign (!index self name) n)))

(!define NamedAccount (!call createClass Account Named))

(!define account (!callmeth NamedAccount new ("name": "Paul")))
(!call is (!callmeth account getname) "Paul" "multiple inheritance")
(!callmeth account deposit 100.00)
(!call is (!index account "balance") 100)


;   multiple inheritance (patched)
; look up for 'k' in list of tables 'plist'
(!let search (!lambda (k plist)
                (!loop i 0 (!sub (!len plist) 1) 1
                        (!let v (!index (!index plist i) k))   ; try 'i'-th superclass
                        (!if v (!return v)))))

(!let createClass (!lambda (!vararg)
                (!let c ())  ; new class
                (!let arg (!vararg))
                ; class will search for each method in the list of its
                ; parents ('arg' is the list of parents)
                (!call setmetatable c ("__index": (!lambda (t k)
                                                ; return search(k, arg)
                                                (!return (!call search k arg)))))
                ; prepare 'c' to be the metatable of its instance
                (!assign (!index c "__index") c)
                ; define a new constructor for this new class
                (!assign (!index c "new") (!lambda (self o)
                                                (!let o (!or o ()))
                                                (!call setmetatable o c)
                                                (!return o)))
                ; return new class
                (!return c)))

(!define Account ("balance": 0))
(!assign (!index Account "deposit") (!lambda (self v)
                (!assign (!index self "balance") (!add (!index self "balance") v))))
(!assign (!index Account "withdraw") (!lambda (self v)
                (!assign (!index self "balance") (!sub (!index self "balance") v))))

(!define Named ())
(!assign (!index Named "getname") (!lambda (self)
                (!return (!index self "name"))))
(!assign (!index Named "setname") (!lambda (self n)
                (!assign (!index self "name") n)))

(!define NamedAccount (!call createClass Account Named))

(!define account (!callmeth NamedAccount new ("name": "Paul")))
(!call is (!callmeth account getname) "Paul" "multiple inheritance (patched)")
(!callmeth account deposit 100.00)
(!call is (!index account "balance") 100)

;   privacy
(!let newAccount (!lambda (initialBalance)
                (!let self ("balance": initialBalance))
                (!let withdraw (!lambda (v)
                                (!assign (!index self "balance") (!sub (!index self "balance") v))))
                (!let deposit (!lambda (v)
                                (!assign (!index self "balance") (!add (!index self "balance") v))))
                (!let getBalance (!lambda () (!return (!index self "balance"))))
                (!return ("withdraw": withdraw
                          "deposit": deposit
                          "getBalance": getBalance))))

(!define acc1 (!call newAccount 100.00))
(!call (!index acc1 "withdraw") 40.00)
(!call is (!call (!index acc1 "getBalance")) 60 "privacy")

;   single-method approach
(!let newObject (!lambda (value)
                (!return (!lambda (action v)
                                (!if (!eq action "get") (!return value)
                                     (!if (!eq action "set") (!assign value v)
                                          (!call error "invalid action")))))))

(!define d (!call newObject 0))
(!call is (!call d "get") 0 "single-method approach")
(!call d "set" 10)
(!call is (!call d "get") 10)


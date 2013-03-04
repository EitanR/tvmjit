#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!call plan 5)

(!assign factorial (!lambda (n)
                            (!if (!eq n 0)
                                 (!return 1)
                                 (!return (!mul n (!call factorial (!sub n 1)))))))
(!call is (!call factorial 7) 5040 "factorial (recursive)")

(!letrec local_factorial (!lambda (n)
                                  (!if (!eq n 0)
                                       (!return 1)
                                       (!return (!mul n (!call local_factorial (!sub n 1)))))))
(!call is (!call local_factorial 7) 5040 "factorial (recursive)")

(!let loop_factorial (!lambda (n)
                              (!define a 1)
                              (!loop i 1 n 1
                                     (!assign a (!mul a i)))
                              (!return a)))
(!call is (!call loop_factorial 7) 5040 "factorial (loop)")

(!let iter_factorial (!lambda (n)
                              (!letrec iter (!lambda (product counter)
                                                     (!if (!gt counter n)
                                                          (!return product)
                                                          (!return (!call iter (!mul counter product) (!add counter 1))))))
                              (!return (!call iter 1 1))))
(!call is (!call iter_factorial 7) 5040 "factorial (iter)")

;
;   Knuth's "man or boy" test.
;   See http://en.wikipedia.org/wiki/Man_or_boy_test
;

(!letrec A (!lambda (k x1 x2 x3 x4 x5)
                    (!letrec B (!lambda ()
                                        (!assign k (!sub k 1))
                                        (!return (!call A k B x1 x2 x3 x4))))
                    (!if (!le k 0)
                         (!return (!add (!call x4) (!call x5)))
                         (!return (!call B)))))

(!call is (!call A 10
                   (!lambda () (!return 1))
                   (!lambda () (!return -1))
                   (!lambda () (!return -1))
                   (!lambda () (!return 1))
                   (!lambda () (!return 0)))
          -67
          "man or boy")


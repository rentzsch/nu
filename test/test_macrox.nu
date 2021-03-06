;; test_macrox.nu
;;  tests for Nu macro-expand operator.
;;
;;  Copyright (c) 2008 Jeff Buck

(class TestMacrox is NuTestCase
     
     (imethod (id) testIncMacro is
          (macro-1 inc! (n)
               `(set ,n (+ ,n 1)))
          
          ;; Test the macro evaluation
          (set a 0)
          (inc! a)
          (assert_equal 1 a)
          
          ;; Test the expansion
          (set newBody (macrox (inc! a)))
          (assert_equal "(set a (+ a 1))" (newBody stringValue)))
     
     (imethod (id) testNestedMacro is
          (macro-1 inc! (n)
               `(set ,n (+ ,n 1)))
          
          (macro-1 inc2! (n)
               `(progn
                      (inc! ,n)
                      (inc! ,n)))
          
          (set a 0)
          (inc2! a)
          (assert_equal 2 a)
          
          (set newBody (macrox (inc2! a)))
          (assert_equal "(progn (inc! a) (inc! a))" (newBody stringValue)))
     
     
     (imethod (id) testFactorialMacro is
          (macro-1 mfact (n)
               `(if (== ,n 0)
                    (then 1)
                    (else (* (mfact (- ,n 1)) ,n))))
          
          (set newBody (macrox (mfact x)))
          (assert_equal "(if (== x 0) (then 1) (else (* (mfact (- x 1)) x)))" (newBody stringValue))
          
          (set x 4)
          
          (assert_equal 24 (mfact x)))
     
     (imethod (id) testCallingContextForMacro is
          ;; Make sure we didn't ruin our calling context
          (macro-1 mfact (n)
               `(if (== ,n 0)
                    (then 1)
                    (else (* (mfact (- ,n 1)) ,n))))
          (set n 10)
          (mfact 4)
          (assert_equal 10 n))
     
     
     (imethod (id) testRestMacro is
          (macro-1 myfor ((var start stop) *body)
               `(let ((,var ,start))
                     (while (<= ,var ,stop)
                            ,@*body
                            (set ,var (+ ,var 1)))))
          
          (set var 0)
          (myfor (i 1 10)
                 (set var (+ var i)))
          (assert_equal 55 var)
          
          ;; Make sure we didn't pollute our context
          (assert_throws "NuUndefinedSymbol"
               (puts "#{i}")))
     
     (imethod (id) testNullArgMacro is
          ;; Make sure *args is set correctly with a null arg macro
          (macro-1 set-a-to-1 ()
               (set a 1))
          
          (set-a-to-1)
          (assert_equal 1 a))
     
     (imethod (id) testBadArgsNullMacro is
          (macro-1 nullargs ()
               nil)
          
          (assert_throws "NuDestructureException" (nullargs 1 2)))
     
     (imethod (id) testNoBindingsMacro is
          (macro-1 no-bindings (_)
               nil)
          
          (assert_equal nil (no-bindings 1)))
     
     (imethod (id) testMissingSequenceArgument is
          (macro-1 missing-sequence (_ b)
               b)
          
          (assert_throws "NuDestructureException" (missing-sequence 1)))
     
     (imethod (id) testSkipBindingsMacro is
          (macro-1 skip-bindings (_ b)
               b)
          
          (assert_equal 2 (skip-bindings 1 2)))
     
     (imethod (id) testSingleCatchAllArgMacro is
          (macro-1 single-arg (*rest)
               (cons '+ *rest))
          
          (assert_equal 6 (single-arg 1 2 3)))
     
     (imethod (id) testDoubleCatchAllArgMacro is
          (macro-1 double-catch-all ((a *b) (c *d))
               `(append (quote ,*b) (quote ,*d)))
          
          (assert_equal '(2 3 4 12 13 14) (double-catch-all (1 2 3 4) (11 12 13 14))))
     
     (imethod (id) testRestoreImplicitArgsExceptionMacro is
          (macro-1 concat ()
               (cons '+ *args))
          
          (assert_throws "NuDestructureException" (concat 1 2 3))
          
          ;; We're in a block, so *args is defined
          ;; but should be nil since our block takes
          ;; no arguments.
          
          ;; Don't pass *args to another macro
          (set defaultargs *args)
          (assert_equal nil defaultargs))
     
     (imethod (id) testRestoreArgsExceptionMacro is
          ;; Intentionally refer to undefined symbol
          (macro-1 x (a b)
               c)
          
          (set a 0)
          (assert_throws "NuUndefinedSymbol" (x 1 2))
          
          ;; Don't pass *args to another macro
          (set defaultargs *args)
          (assert_equal nil defaultargs)
          (assert_equal 0 a)
          (assert_throws "NuUndefinedSymbol" b))
     
     (imethod (id) testEvalExceptionMacro is
          ;; Make sure a runtime exception is properly caught
          (set code '(+ 2 x))
          
          (macro-1 eval-it (sexp) `(eval ,sexp))
          (assert_throws "NuUndefinedSymbol" (eval-it code)))
     
     (imethod (id) testMaskedVariablesMacro is
          (macro-1 x (a b)
               `(+ ,a ,b))
          
          (set a 1)
          (assert_equal 5 (x 2 3))
          (assert_equal 1 a))
     
     (imethod (id) testEmptyListArgsMacro is
          (macro-1 donothing (a b)
               b)
          
          (assert_equal 2 (donothing 1 2))
          (assert_equal 2 (donothing () 2))
          (assert_equal 2 (donothing nil 2)))
     
     (imethod (id) testEmptyListArgsRecursiveMacro is
          (macro-1 let* (bindings *body)
               (if (null? *body)
                   (then
                        (throw* "LetException"
                                "An empty body was passed to let*")))
               (if (null? bindings)
                   (then
                        `(progn
                               ,@*body))
                   (else
                        (set __nextcall `(let* ,(cdr bindings) ,@*body))
                        `(let (,(car bindings))
                              ,__nextcall))))
          
          (assert_equal 3
               (let* ((a 1)
                      (b (+ a a)))
                     (+ a b)))
          
          (assert_equal 3
               (let* ()
                     (+ 2 1)))
          
          (assert_throws "LetException"
               (let* () )))
     
     (imethod (id) testDisruptCallingContextMacro is
          (macro-1 leaky-macro (a b)
               `(set c (+ ,a ,b)))
          
          (assert_equal 5 (leaky-macro 2 3))
          (assert_equal 5 c)))

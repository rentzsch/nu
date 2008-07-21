;; test_destructuring.nu
;;  tests for Nu destructuring macros.
;;
;;  Copyright (c) 2008 Issac Trotts

(load "destructuring")

(class TestDestructuring is NuTestCase

     ;; match
     (imethod (id) testMatch is
         (function people-to-string (people)
             (match people
                    (() "no people")
                    ((p1) "one person: #{p1}")
                    ((p1 p2) "two people: #{p1} and #{p2}")
                    (else "too many people: #{(people length)}")))
         (assert_equal "no people" (people-to-string '()))
         (assert_equal "one person: Tim" (people-to-string '(Tim)))
         (assert_equal "two people: Tim and Matz" (people-to-string '(Tim Matz)))
         (assert_equal "too many people: 3" (people-to-string '(Tim Guido Matz))))

     (imethod (id) testCheckBindings is
         (check-bindings '())  ;; empty set of bindings should not throw
         (check-bindings '((a 1)))
         (check-bindings '((a 1) (a 1)))  ;; consistent
         (assert_throws "NuDestructuringException"
                        (do () (check-bindings '((a 1) (a 2))))))  ;; inconsistent

     ;; dbind
     (imethod (id) testDbind is
         (assert_equal 3 (dbind a 3
                                a))
         (assert_equal 3 (dbind (a) '(3)
                                   a))
         (assert_equal '(1 2 3)
                       (dbind (a b c) '(1 2 3)
                              (list a b c)))
         (assert_equal '(1 2 3 4)
                       (dbind (a (b c) d) '(1 (2 3) 4)
                              (list a b c d)))
         (assert_throws "NuCarCalledOnAtom"
                        (do () (dbind (a) ()
                                      nil)))
         (assert_throws "NuCarCalledOnAtom"
                        (do () (dbind (a b) (1)
                                      (list a b))))
         (assert_equal '(1 2)
                       (dbind a '(1 2)
                              a))
         (assert_equal '(1 (2 3))
                       (dbind (a b) '(1 (2 3))
                              (list a b)))

         ;; Test it with expressions on the right.
         (assert_equal (list 3 12)
                       (dbind (a b) (list (+ 1 2) (* 3 4))
                              (list a b)))

         ;; Test it with symbols on the right.
         (assert_equal '(bottle rum)
                       (dbind (yo ho) '(bottle rum)
                              (list yo ho)))

         ;; The same symbol can show up twice in the LHS (left hand side) as long as it
         ;; binds to eq things on the RHS (right hand side).
         (assert_equal '(bottle rum)
                       (dbind (yo ho ho) '(bottle rum rum)
                              (list yo ho)))

         ;; An error occurs if we try to match the same symbol to two different things on
         ;; the right.
         (assert_throws "NuDestructuringException"
                        (dbind (a a) '(1 2)
                               nil)))

     ;; dset
     (imethod (id) testDset is
         (dset a 3)
         (assert_equal 3 a)

         (dset a '(3))
         (assert_equal '(3) a)

         (dset (a) '(3))
         (assert_equal 3 a)

         (dset a '(1 2))
         (assert_equal '(1 2) a)

         (dset (a (b c) d) '(1 (2 3) 4))
         (assert_equal '(1 2 3 4)
                       (list a b c d))

         (assert_throws "NuCarCalledOnAtom"
                        (do () (dset (a) ())))

         (assert_throws "NuCarCalledOnAtom"
                        (do () (dset (a b) (1))))

         (dset (a b) '(1 (2 3)))
         (assert_equal '(1 (2 3)) (list a b))

         (assert_throws "NuDestructuringException"
                        (dset (a a) '(1 2)))))

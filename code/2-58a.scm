#lang racket

(define (variable? x) (symbol? x))

(define (same-variable? v1 v2)
    (and (variable? v1) (variable? v2) (eq? v1 v2)))

(define (=number? x num) (and (number? x) (= x num)))

;(define (make-sum a1 a2) (list '+ a1 a2))

(define (make-sum a1 a2)
    (cond 
        ((=number? a1 0) a2)
        ((=number? a2 0) a1)
        ((and (number? a1) (number? a2)) (+ a1 a2))
        (else (list a1 '+ a2))))

(define (sum? e) (and (pair? e) (eq? (cadr e) '+)))
(define (addend e) (car e))
(define (augend e) (caddr e))

(define (product? e) (and (pair? e) (eq? (cadr e) '*)))
(define (multiplier e) (car e))
(define (multiplicand e) (caddr e))

;(define (make-product m1 m2) (list '* m1 m2))

(define (make-product a1 a2)
    (cond
        ((or (=number? a1 0) (=number? a2 0)) 0)
        ((=number? a1 1) a2)
        ((=number? a2 1) a1)
        ((and (number? a1) (number? a2)) (* a1 a2))
        (else (list a1 '* a2))))

(define (deriv exp var)
    (cond 
        ((number? exp) 0)
        ((variable? exp) (if (eq? exp var) 1 0))
        ((sum? exp)
            (make-sum
                (deriv (addend exp) var)
                (deriv (augend exp) var)))
        ((product? exp)
            (let ((u (multiplier exp))
                  (v (multiplicand exp)))
                (make-sum
                    (make-product
                        u
                        (deriv v var))
                    (make-product
                        v
                        (deriv u var)))))
        (else (error "unkown type of expression"))))

(deriv '(x + 3) 'x)

(deriv '(x * y) 'x)

(deriv '((x * y) * (x + 3)) 'x)

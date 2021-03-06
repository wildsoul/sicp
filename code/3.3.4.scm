(load "3.3.4-agenda.scm")

(define inverter-delay 2)
(define and-gate-delay 3)
(define or-gate-delay 5)

(define (call-each procs)
    (if (null? procs)
        'done
        (begin
            ((car procs))
            (call-each (cdr procs)))))

(define (make-wire)
    (let ((signal-value 0)
          (action-procedures '()))
        (define (set-my-signal! new-value)
            (if (not (= signal-value new-value))
                (begin
                    (set! signal-value new-value)
                    (call-each action-procedures))
                'done))
        (define (accept-action-procedure! proc)
            (set! action-procedures (cons proc action-procedures))
            (proc)
            )
        (define (dispatch m)
            (cond
                ((eq? m 'get-signal) signal-value)
                ((eq? m 'set-signal!) set-my-signal!)
                ((eq? m 'add-action!) accept-action-procedure!)
                (else (error "unknown operation -- WIRE" m))))
        dispatch))

(define (add-action! wire proc)
    ((wire 'add-action!) proc))

(define (get-signal wire) (wire 'get-signal))
(define (set-signal! wire value) ((wire 'set-signal!) value))
    
#|
;; just ignore my make-wire and after-delay

;; my implementation of make-wire
(define (make-wire) (list 0)) ; value, actions

(define (add-action! wire proc) (set-cdr! wire (cons proc (cdr wire))))
(define (get-action wire) (cdr wire))

(define (get-signal wire) (car wire))
(define (set-signal! wire value)
    (set-car! wire value)
    (letrec
        ((actions (get-action wire))
         (execute
            (lambda (remain)
                (cond
                    ((not (null? remain))
                        ((car remain))
                        (execute (cdr remain)))))))
        (execute actions)))

; my implementation of after-delay
(define (after-delay delay proc)
    (usleep (* delay 1000)) ; milli-seconds
    (proc))
|#

(define (D x) (display (get-signal x)) (newline))
            

(define (logical-not s)
    (cond
        ((= s 0) 1)
        ((= s 1) 0)
        (error "illegal signal")))

(define (inverter input output)
    (define (invert-input)
        (let ((new-value (logical-not (get-signal input))))
            (after-delay
                inverter-delay
                (lambda ()
                    (set-signal! output new-value)))))
    (add-action! input invert-input))

(define (logical-and a b)
    (cond
        ((and (= a 1) (= b 1)) 1)
        (else 0)))

(define (and-gate a1 a2 output)
    (define (and-action-procedure)
        (let ((new-value (logical-and (get-signal a1) (get-signal a2))))
            (after-delay and-gate-delay
                (lambda ()
                    (set-signal! output new-value)))))
    (add-action! a1 and-action-procedure)
    (add-action! a2 and-action-procedure)
    'ok)

;; 3-28
(define (logical-or a b)
    (cond
        ((or (= a 1) (= b 1)) 1)
        (else 0)))

(define (or-gate a1 a2 output)
    (define (or-action-procedure)
        (let ((new-value (logical-or (get-signal a1) (get-signal a2))))
            (after-delay or-gate-delay
                (lambda ()
                    (set-signal! output new-value)))))
    (add-action! a1 or-action-procedure)
    (add-action! a2 or-action-procedure)
    'ok)

;; tests
;#|
(define a (make-wire))
(define b (make-wire))
(define c (make-wire))
(define d (make-wire))
(define e (make-wire))
(define s (make-wire))

#|
(or-gate a b d)
(and-gate a b c)
(inverter c e)
(and-gate d e s)

(set-signal! a 0)
(D c) (D s)
(set-signal! b 1)
(D c) (D s)
(set-signal! a 1)
(D c) (D s)
;|#

;; Half-Adder
;;
;; --a--\
;;       > OR --d------------------\
;; --b--/                           \
;;                                   > AND --s--
;;                                  /
;; --a--\            /-- NOT --e---/
;;       > AND --c--<
;; --b--/            \-----------------------c--
;;
;;
;; ;; in real world, OR/AND will start simultaneosly.
;;
;; ha-delay => (+ (max or-delay (+ and-delay not-delay)) and-delay)

(define (half-adder a b s c)
    (let ((d (make-wire))
          (e (make-wire)))
        (or-gate a b d)
        (and-gate a b c)
        (inverter c e)
        (and-gate d e s)
        'ok))

;; tests
#|
(half-adder a b s c)
(set-signal! a 0)
(D c) (D s)
(set-signal! b 1)
(D c) (D s)
(set-signal! a 1)
(D c) (D s)
;|#


;; Full-Adder:
;;
;; -- a ------------------\      /---sum----------------
;;                         > HA <
;; -- b ---\      /--s----/      \---c2---\
;;          > HA <                         > OR --c_out--
;; --c_in--/      \--c1-------------------/
;;
;; fa-delay => (+ ha-delay ha-delay or-delay)

(define (full-adder a b c-in sum c-out)
    (let ((s (make-wire))
          (c1 (make-wire))
          (c2 (make-wire)))
        (half-adder b c-in s c1)
        (half-adder a s sum c2)
        (or-gate c1 c2 c-out)
        'ok))
;; tests
#|
(full-adder a b c s d)
(set-signal! a 0)
(D d) (D s) (newline)
(set-signal! b 1)
(D d) (D s) (newline)
(set-signal! a 1)
(D d) (D s) (newline)
(set-signal! c 1)
(D d) (D s) (newline)
;|#

(define (probe name wire)
    (add-action! wire
        (lambda ()
            (display name)
            (display "@")
            (display (current-time the-agenda))
            (display ", new-value = ")
            (display (get-signal wire))
            (newline))))

(define input-1 (make-wire))
(define input-2 (make-wire))
(define sum (make-wire))
(define carry (make-wire))
(probe 'sum sum)
(probe 'carry carry)

(half-adder input-1 input-2 sum carry)

(set-signal! input-1 1)
(propagate)

(set-signal! input-2 1)
(propagate)

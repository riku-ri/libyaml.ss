(module (libyaml if) *

(import scheme (chicken base))
(import (chicken condition))

(define (yaml? ?) (let*
	(
		(and* (lambda (L) (foldl (lambda (l r) (and l r)) #t L)))
		(list->index (lambda (L) (map (lambda (?) (- (length L) ?))
			(foldr (lambda (l r) (cons (length (cons l r)) r))
				'() L))))
	)
	(and
		(procedure? ?)
		(handle-exceptions e #f (list? (? -1)))
		(handle-exceptions e #f (if (?) #t))
		; only catch exception here
		; as a predication, exception should return #f but not abort
		(equal? (car (? -1)) (?))
		(and* (map (lambda (di) (equal? (? di) (list-ref (? -1) di)))
			(list->index (? -1))
		))
		(ydoc? (? -1))
	)
))

(define (ydoc? ?) (and
	(procedure? ?)
	(handle-exceptions e #f (? -1))
	(list? (? -1))
	(foldl (lambda (l r) (and l r)) #t
		(map
			((lambda (@) (@ @)) (lambda (@) (lambda (?)
				(or (ymap?? ?) (ylist?? ?) (yscalar? ?)))))
			(? -1)
		)
	)
))

(define (ymap? ?) (and
	(list? ?)
	(= 1 (length ?))
	(list? (car ?))
	(foldl (lambda (l r) (and l r)) #t (map pair? (car ?)))
))
(define (ymap?? ?) (and
	(ymap? ?)
	(let ((?alist (car ?))) (and
		(foldl (lambda (l r) (and l r)) #t (map
			((lambda (@) (@ @)) (lambda (@) (lambda (?)
				(and
					(or (ylist? (car ?)) (ymap? (car ?)) (yscalar? (car ?)))
					(or (ylist? (cdr ?)) (ymap? (cdr ?)) (yscalar? (cdr ?)))
				))))
			?alist
		))
	))
))

(define ylist? vector?)
(define (ylist?? ?) (and
	(ylist? ?)
	(foldl (lambda (l r) (and l r)) #t
		(map
			((lambda (@) (@ @)) (lambda (@) (lambda (?)
				(or (ylist? ?) (ymap? ?) (yscalar? ?)))))
			(vector->list ?)
		)
	)
))

(define (yscalar? ?) (or
	(null? ?)
	(boolean? ?)
	(number? ?)
	(string? ?)
))

) ;module

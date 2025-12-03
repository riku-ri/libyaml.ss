(import
	scheme
	(chicken base)
	(chicken format)
	(chicken string)
	(chicken condition)
)
(import libyaml)

(let* (
	(yaml ((yaml<-)))
	(~S (lambda (?) (sprintf "~S" ?)))
	(and* (lambda (L) (foldl (lambda (l r) (and l r)) #t L)))
	(or* (lambda (L) (foldl (lambda (l r) (or l r)) #f L)))
	(max* (lambda (L) (apply max L)))
	(string+ (lambda (str . ..)
		(apply string-append (map ->string (cons str ..)))
	))
	(assoc* (lambda (key alist) (cdr (assoc key alist))))
	(assoc*y (lambda (key ymap) (let* ((pair (assoc key (car ymap))))
		(if pair
			(cdr pair)
			(abort (condition `(exn message ,(sprintf
				"key is not it the yaml mapping:\n~S\n->\n~S"
				key ymap
			))))
		)
	)))
	(--> (lambda (ymap . /key)
		(define (--> y k) (if (null? k)
			y (--> (assoc*y (car k) y) (cdr k))
		))
		(--> ymap /key)
	))
) (let-syntax (
	(?? (syntax-rules()
		((?? to-check p ...)
			(if (not (and*
					(map (lambda (@) (@ to-check))
						(foldr
							(lambda (l r) (cond
								((and (equal? l not) (not (null? r)))
									(cons (compose not (car r)) (cdr r)))
								(else (cons l r))
							))
							'()
							(list p ...)
						))
				))
				(abort(condition `(exn message
					,(string+ '(p ...) '? " NO:\n" (~S to-check)))))
			)
		)
	))
	(write/ (syntax-rules() ((write/ towrite port ...)
		(begin (write towrite port ...)(newline port ...))
	)))
	(-- (syntax-rules() ((-- .. ...)
		(if (procedure? (car (list .. ...)))
			(- (.. ...) 1) (- .. ... 1)))))
	(++ (syntax-rules() ((++ .. ...)
		(if (procedure? (car (list .. ...)))
			(+ (.. ...) 1) (+ .. ... 1)))))
	(list-ref* (syntax-rules()
		((list-ref /l i) (if (>= i 0)
			(list-ref /l i)
			(list-ref /l (+ (length /l) i))
		))
	))
) (let* (
	(ewrite/ (lambda (towrite) (write/ towrite (current-error-port))))
	(write/ (lambda (towrite) (write/ towrite)))
	(-> (lambda (/l . /i)
		(define (-> /l /i) (if (null? /i) /l (-> (list-ref* /l (car /i)) (cdr /i))))
		(-> /l /i)
	))
	(/ylist (vector->list yaml))
	; col-first
	(/tab/col/row (list
		(map (lambda (?) (--> ? "des" "yaml")) /ylist)
		(map (lambda (?) (--> ? "des" "ss")) /ylist)
		(let ((/e.g. (map vector->list (map (lambda (?) (--> ? "e.g.")) /ylist))))
			(map
				(lambda (e.g.) (list
					(map (lambda (e) (--> e "yaml")) e.g.)
					(map (lambda (e) (--> e "ss")) e.g.)
				))
				/e.g.
			)
		)
	))
	(svg->str (lambda (svg)
		(define (svg->str svg) (let
			(
				(tag (car svg))
				(attr (cadr svg))
				(>< (cddr svg))
			)
			(sprintf "<~A ~A>~A</~A>"
				tag
				(string-intersperse
					(map (lambda (?) (sprintf "~A=~S" (car ?) (cdr ?))) attr)
					" " #t)
				(cond
					((null? ><) "")
					((pair? ><) (string-intersperse (map :svg->str ><) "\n" #t))
					(else ><)
				)
				tag
			)
		))
		(svg->str svg)
	))
	; `("tag" (("k" . "v")) . (("intag" ("ink" . "inv") . "content")))
	; => <tag k="v"><intag ink="inv">content</intag></tag>
)

(print "<svg xmlns=\"http://www.w3.org/2000/svg\">")

(define (string->/tspan ?)
	(define (/line->/tspan /line dy //) (cond
		((null? /line) (reverse //))
		(else (let ((^ (car /line))(.. (cdr /line))) (/line->/tspan
			(cdr /line)
			(+ dy 1)
			(cons
				`(
					"tspan" ; svg tag
					(,(string-length ^) . 1) ; (char-count . line-count)
					( ; svg tag attribute
						(dy . "1em")
					)
					. ,^
				)
				//
			)
		)))
	))
	(/line->/tspan (string-split ? "\n" #t) 0 '())
)

(define (/tab/col/row->//tspan /tab/col/row) (let ((todo /tab/col/row)) (cond
	((list? todo) (map /tab/col/row->//tspan todo))
	((string? todo) (string->/tspan todo))
	(else (abort (condition `(exn message
		,(string+ "not string or list:\n" todo)))))
)))

(define (//tspan->//text //tspan) (cond
	((assoc "tspan" //tspan) (let
		(
			(max-char&sum-line
				(lambda (p P) (cons (max (car p) (car P)) (+ (cdr p) (cdr P)))))
		)
		`(
			"text"
			,(foldl max-char&sum-line '(0 . 0) (map cadr //tspan))
			,(list)
			. ,//tspan
		)
	))
	((list? //tspan) (map //tspan->//text //tspan))
	(else (abort (condition `(exn message
		,(string+ "bad //tspan structure" //tspan)))))
))

(define (pad d)
	(let
		(
			(dir-pad `(
				(l . 0.33) (r . 0.33) ; /ex
				(t . 0.33) (b . 0.33) ; /em
			))
		)
		(assoc* d dir-pad)
	)
)

(define (/tab->h /tab) (?? /tab list?) (apply max (map /col->h /tab)))
(define (/col->h /col) (?? /col list?) (foldl + 0 (map /row->h /col)))
(define (/row->h /row)
	(?? /row not null? list?)
	(cond
		((string? (car /row))
			(?? (car /row) (lambda (?) (string=? ? "text")))
			(cdadr /row))
		(else (/tab->h /row))
	)
)
(define (/tab->w /tab) (?? /tab list?) (foldl + 0 (map /col->w /tab)))
(define (/col->w /col) (?? /col list?) (apply max (map /row->w /col)))
(define (/row->w /row) (?? /row not null? list?)
	(cond
		((string? (car /row))
			(?? (car /row) (lambda (?) (string=? ? "text")))
			(caadr /row))
		(else (/tab->w /row))
	)
)

(define (set-tab-y! /tab pre-y) (?? /tab list?)
	(define (set-col-y! /col) (?? /col list?)
		(define (:set-col-y! /col pre-y)
			(define (set-row-y! /row pre-y) (?? /row not null? list?)
				(cond
					((string? (car /row)) (let ((h (cdadr /row)))
						(?? (car /row) (lambda (?) (string=? ? "text")))
						(set-cdr! (cadr /row) pre-y)
						(+ h pre-y)
					))
					(else (set-tab-y! /row pre-y))
				)
			)
			(if (null? /col)
				pre-y
				(let ((pre-y (set-row-y! (car /col) pre-y)))
					(:set-col-y! (cdr /col) pre-y)))
		)
		(:set-col-y! /col pre-y)
	)
	(let ((in-col-max-y (apply max (map set-col-y! /tab))))
		in-col-max-y
	)
)

(define (transpose list-of-list)
	(if (and* (map null? list-of-list))
		'()
		(cons (map car list-of-list) (transpose (map cdr list-of-list)))
	)
)

(define (|/tab'| /tab) (if (and* (map null? /tab))
	'()
	(cons
		(map
			(lambda (/col) (let ((/row (car /col)))
				(if (string? (car /row)) /row (|/tab'| /row))
			))
			/tab
		)
		(|/tab'| (map cdr /tab))
	)
))

(define (set-t-tab-y! /tab)
	(define (set-t-col-y! /col max-y)
		(define (set-t-row-y! /row max-y) (cond
			((string? (car /row)) (let ((y (cdadr /row)))
				(set-cdr! (cadr /row) max-y)
				y
			))
			(else (max* (set-t-tab-y! /row)))
		))
		(max* (map (lambda (/row) (set-t-row-y! /row max-y)) /col))
	)
	(define (/tab->max-y /tab)
		(define (/col->max-y /col)
			(define (/row->max-y /row) (cond
				((string? (car /row)) (cdadr /row))
				(else (max* (set-t-tab-y! /row)))
			))
			(max* (map /row->max-y /col))
		)
		(map /col->max-y /tab)
	)
	(let* ((/max-y (/tab->max-y /tab)))
		(map
			(lambda (/col--max-y) (apply set-t-col-y! /col--max-y))
			(transpose (list /tab /max-y))
		)
	)
)

(define (set-tab-text-y! /tab)
	(define (set-col-text-y! /col)
		(define (set-row-text-y! /row) (cond
			((string? (car /row))
				(?? (car /row) (lambda (?) (string=? ? "text")))
				(let ((al (caddr /row)))
					(set-car! (cddr /row) (alist-update 'y (string+ (cdadr /row) 'em) al))
				)
			)
			(else (set-tab-text-y! /row))
		))
		(map set-row-text-y! /col)
	)
	(map set-col-text-y! /tab)
)

(define (set-tab-text-x! /tab toset)
	(define (/tab->max-x /tab) (apply + (map /col->max-x /tab)))
	(define (/col->max-x /col)
		(define (/row->max-x /row) (cond
			((string? (car /row)) (caadr /row))
			(else (/tab->max-x /row))
		))
		(max* (map /row->max-x /col))
	)
	(define (set-col-text-x! /col)
		(define (set-row-text-x! /row) (cond
			((string? (car /row))
				(?? (car /row) (lambda (?) (string=? ? "text")))
				(let ((al (caddr /row)))
					(set-car! (cddr /row) (alist-update 'x (string+ toset 'ex) al))
				)
			)
			(else (set-tab-text-x! /row toset))
		))
		(map set-row-text-x! /col)
	)
	(if (null? /tab)
		(void)
		(let ((w (/col->max-x (car /tab))))
			(map set-col-text-x! /tab)
			(set-tab-text-x! (cdr /tab) (+ w toset))
		)
	)
)

(define (set-tspan-x! /tab) (let ((^ (car /tab)))
	(if (and (string? ^) (string=? ^ "text"))
		(let ((x (assoc* 'x (caddr /tab))))
			(define (:set-tspan-x! //tspan) (let ((^ (car //tspan)))
				(if (and (string? ^) (string=? ^ "tspan"))
					(set-car! (cddr //tspan) (alist-update 'x x (caddr //tspan)))
					(map :set-tspan-x! //tspan)
				)
			))
			(:set-tspan-x! (cdddr /tab))
		)
		(map set-tspan-x! /tab)
	)
))

(define (/tab->svg /tab)(if (string? (car /tab))
	(let
		(
			(tag (car /tab))
			(attr (caddr /tab))
			(content (cdddr /tab))
		)
		(string+
			"<" tag " "
			(string-intersperse
				(map (lambda (kv) (string+ (~S (car kv)) "=" (~S (cdr kv)))) attr)
				" ")
			">"
			(if (string? content) content (/tab->svg content))
			"</" tag ">\n"
		)
	)
	(string-intersperse (map /tab->svg /tab) "")
))

(let* (
	(title `(
		"yaml description"
		"scheme description"
		(("yaml e.g.") ("scheme e.g."))
	))
	(/t/r/c (cons title (transpose /tab/col/row)))
	(/t/c/r (transpose /t/r/c))
	(/t/c/r ((compose //tspan->//text /tab/col/row->//tspan) /t/c/r))
)
(set-tab-y! /t/c/r 1)
(let* (
	(/t/r/c (|/tab'| /t/c/r))
)
(set-t-tab-y! /t/r/c)
(let* (
	(/t/c/r (|/tab'| /t/r/c))
)

(set-tab-text-y! /t/c/r)

(set-tab-text-x! /t/c/r 0)

(set-tspan-x! /t/c/r)

(print (/tab->svg /t/c/r))


)))

(print "</svg>")
)))

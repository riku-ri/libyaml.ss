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
			(if (not (foldl (lambda (l r) (and l r)) #t
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
	(->em (syntax-rules() ((->em .. ...)
		(if (procedure? (car (list .. ...)))
			(sprintf "~Aem" (.. ...)) (sprintf "~Aem" .. ...)))))
	(->ex (syntax-rules() ((->ex .. ...)
		(if (procedure? (car (list .. ...)))
			(sprintf "~Aex" (.. ...)) (sprintf "~Aex" .. ...)))))
	(list-ref* (syntax-rules()
		((list-ref i /l) (if (>= i 0)
			(list-ref /l i)
			(list-ref /l (+ (length /l) i))
		))
	))
) (let* (
	(ewrite/ (lambda (towrite) (write/ towrite (current-error-port))))
	(write/ (lambda (towrite) (write/ towrite)))
	(-> (lambda (/l . /i)
		(define (-> /l /i) (if (null? /i) /l (-> (list-ref* (car /i) /l) (cdr /i))))
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
	(/tspan<- (lambda (str) (let ((/l (string-split str "\n" #t)))
		(define (/tspan<- /l dy/em) (if (null? /l)
			'()
			(cons
				`(
					"tspan"
					(
						(x . "0") (dy . ,(->em dy/em))
						(textLength . ,(string-length (car /l)))
					)
					. ,(car /l)
				)
				(/tspan<- (cdr /l) (+ 1 dy/em))
			)
		))
		(/tspan<- /l 0)
	)))
	(text<- (lambda (/tspan) `(
			"text"
			(
				(
					textLength
					.
					,(apply max
					(map (lambda (?) (assoc* 'textLength (cadr ?))) /tspan))
				)
				(x . "0") (y . "0")
			)
			. ,/tspan
		)
	))
)

;(print "<svg xmlns=\"http://www.w3.org/2000/svg\">")

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
						(dx . 0) (y . ,(string+ dy 'em))
						(textLength . "0") ; always set 0 to avoid adjust spacing
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
			. ,//tspan
		)
	))
	((list? //tspan) (map //tspan->//text //tspan))
	(else (abort (condition `(exn message
		,(string+ "bad //tspan structure" //tspan)))))
))

(define pre-h 0)
(define (set-y! //text)
	(cond
		((assoc "text" //text)
			(map
				(lambda (text)
					(set-car! (cdr text) (cons (cadr text) pre-h))
				)
				//text
			)
			;(ewrite/ (apply max (map cdar (map cadr //text))))
			(set! pre-h (+ pre-h (apply max (map cdar (map cadr //text)))))
		)
		((list? //text) (map set-y! //text))
	)
)

(define (/tab->h /tab) (?? /tab list?)
	(define (/col->h /col) (?? /col list?)
		(define (/row->h /row)
			(?? /row not null? list?)
			(cond
				((string? (car /row))
					(?? (car /row) (lambda (?) (string=? ? "text")))
					(cdadr /row))
				(else (/tab->h /row))
			)
		)
		(foldl + 0 (map /row->h /col))
	)
	(apply max (map /col->h /tab))
)

(
write/

;((lambda(@)(@ @))(lambda(@)(lambda(?)(if(assoc"text"?)(write/ ?)
;(begin(write/ #\()(map(@ @)?)(write/ #\)))
;))))

(let
	((// ((compose //tspan->//text /tab/col/row->//tspan) /tab/col/row)))
	//
	(/tab->h //)
)

)

;(print "</svg>")
)))

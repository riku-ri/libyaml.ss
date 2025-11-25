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
	(string+ (lambda (str . ..)
		(apply string-append (map ->string (cons str ..)))
	))
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

(define (line-count->y! //text)
	(define pre-h 0)
	(cond
		((assoc "text" //text)
			(map
				(lambda (text)
					(let* ((size (cadr text)) (h (+ pre-h (cdr size))))
						(ewrite/ h)
						(set-cdr! size h)
						(ewrite/ size)
						(set! pre-h h)
					)
				)
				//text
			)
		)
		((list? //text) (map line-count->y! //text))
	)
)

(
;write/
((lambda(@)(@ @))(lambda(@)(lambda(?)(if(assoc"text"?)(write/ ?)(map(@ @)?)))))

(let
(
	(// (-> ((compose //tspan->//text /tab/col/row->//tspan) /tab/col/row) 2))
)
(line-count->y! //)
//
)

)

;(print "</svg>")
)))

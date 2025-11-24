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
		(define (:--> y k) (if (null? k)
			y (:--> (assoc*y (car k) y) (cdr k))
		))
		(:--> ymap /key)
	))
	(->/line (lambda (str) (list->vector (string-split str "\n" #t))))
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
		((:list-ref i /l) (if (>= i 0)
			(list-ref /l i)
			(list-ref /l (- (length /l) 1))
		))
	))
) (let* (
	(ewrite/ (lambda (towrite) (write/ towrite (current-error-port))))
	(-> (lambda (/l . /i)
		(define (:-> /l /i) (if (null? /i) /l (:-> (list-ref* (car /i) /l) (cdr /i))))
		(:-> /l /i)
	))
	(/ylist (vector->list yaml))
	; col-first
	(/tab/col/row (list
		(map (lambda (?) (--> ? "des" "yaml")) /ylist)
		(map (lambda (?) (--> ? "des" "ss")) /ylist)
		(let ((/e.g. (map vector->list (map (lambda (?) (--> ? "e.g.")) /ylist))))
			(map
				(lambda (e.g.) (cons
					(map (lambda (e) (--> e "yaml")) e.g.)
					(map (lambda (e) (--> e "ss")) e.g.)
				))
				/e.g.
			)
		)
	))
	(svg->str (lambda (svg)
		(define (:svg->str svg) (let
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
		(:svg->str svg)
	))
	; `("tag" (("k" . "v")) . (("intag" ("ink" . "inv") . "content")))
	; => <tag k="v"><intag ink="inv">content</intag></tag>
	(/tspan<- (lambda (str) (let ((/l (string-split str "\n" #t)))
		(define (:/tspan<- /l dy/em) (if (null? /l)
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
				(:/tspan<- (cdr /l) (+ 1 dy/em))
			)
		))
		(:/tspan<- /l 0)
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

(print "<svg xmlns=\"http://www.w3.org/2000/svg\">")

(map ewrite/
	(let
		(
			(string->pos (lambda (str) (vector
					(string-length str)
					(length (string-split str "\n" #t))
			)))
		)
		(list
			(map string->pos (list-ref* 0 /tab/col/row))
			(map string->pos (list-ref* 1 /tab/col/row))
			(map (lambda (e.g.) (let ((ye (car e.g.)) (se (cdr e.g.)))
					(cons
						(map string->pos ye)
						(map string->pos se)
					)
				))
				(list-ref* 2 /tab/col/row)
			)
		)
	)
)

;(let*
;	(
;		(/text (map text<- (map /tspan<- (-> /tab/col/row 0))))
;		(max-textLength (apply max
;			(map (lambda (?) (assoc* 'textLength (cadr ?))) /text)
;		))
;		(textLength->0! (lambda (text) (let*
;			((textLength (assoc 'textLength (cadr text))))
;			(set-cdr! textLength "0")
;		)))
;	)
;	(map
;		(lambda (text) (let*
;			((textLength (assoc 'textLength (cadr text))))
;			(set-cdr! textLength max-textLength)
;		))
;		/text
;	)
;	(map textLength->0! /text)
;	(map (lambda (?) (map textLength->0! (cddr ?))) /text)
;
;	(define (set-y! /text)
;		(define (:set-y! previous-y /text) (cond
;			((null? /text) (void))
;			(else (let
;				(
;					(y (assoc 'y (cadr (car /text))))
;					(em (length (cddr (car /text))))
;				)
;				(set-cdr! y (->em previous-y))
;				(:set-y! (+ previous-y em) (cdr /text))
;			))
;		))
;		(:set-y! 1 /text)
;	)
;
;	(set-y! /text)
;	(map print (map svg->str /text))
;)


(print "</svg>")
)))

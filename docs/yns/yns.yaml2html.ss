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
	(/ylist (vector->list yaml))
	; col-first
	(/t/c/r (list
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
	(--> (lambda (ymap . <key>)
		(define (:--> y k) (if (null? k)
			y (:--> (assoc*y (car k) y) (cdr k))
		))
		(:--> ymap <key>)
	))
	(-> (lambda (/l . /i)
		(define (-> /l /i) (if (null? /i) /l (-> (list-ref* (car /i) /l) (cdr /i))))
		(-> /l /i)
	))
	(string->html (lambda (?) (string-translate* ?
		'(("\n" . "<br/>") ("<" . "&lt;") (">" . "&gt;") ("\"" . "&quot;"))
	)))
) (let* ((<ylist> (vector->list yaml)))

;(printf "
;<style>
;body { display: inline; margin: 0px; padding: 0px; }
;table,tr,th,td { border: 1px solid; }
;tr,th,td { padding: 0.5em; }
;table {border-collapse: collapse; margin: 0px; padding: 0px; }
;pre { display: inline; }
;</style>
;")

;; simpler steps here
;; - no formatting, such as bold the title
;; - no converting particular character like < >
;; - no constructing, treat the input as stream, just output when it meet a line/cell
;(printf "<table>")
;(printf "<tr>
;<th><i>yaml description<i></th>
;<th><i>scheme description<i></th>
;<th><table><tr>
; <th><pre style=\"display: inline\"><i>yaml e.g.</i></pre></th>
; <th><pre style=\"display: inline\"><i>scheme e.g.</i></pre></th>
;</tr></table></th>
;</tr>")
;(map
;	(lambda (l)
;		(printf "<tr>")
;		(printf "<td>~A</td>" (--> l "des" "yaml"))
;		(printf "<td>~A</td>" (--> l "des" "ss"))
;
;		(printf "<td><table>")
;		(let*
;			(
;				(e.g. (vector->list (--> l "e.g.")))
;			)
;			(map
;				(lambda (e)
;					(printf "<tr>")
;					(printf "<td><pre style=\"display: inline\">")
;					(printf "<code>~A</code></pre></td>" (--> e "yaml"))
;					(printf "<td><pre style=\"display: inline;\">")
;					(printf "<code>~A</code></pre></td>" (--> e "ss"))
;					(printf "</tr>")
;				)
;				e.g.
;			)
;		)
;		(printf "</table></td>")
;		(printf "</tr>")
;	)
;	<ylist>
;)
;(printf "</table>")

(printf "<table>")

(define (transpose list-of-list)
	(if (and* (map null? list-of-list))
		'()
		(cons (map car list-of-list) (transpose (map cdr list-of-list)))
	)
)
(define (/tab<-& &string) ((lambda(@)(@ @))(lambda(@)(lambda(/tab)
	(if (string? /tab)
		(&string /tab)
		(map (@ @) /tab)
	)
))))
(define (<> tag-as-symbol)
	(lambda (s) (string-append
		"<" (symbol->string tag-as-symbol) ">"
		s
		"</" (symbol->string tag-as-symbol) ">")))

(let* (
	(title `(
		"yaml description"
		"scheme description"
		(("yaml e.g.") ("scheme e.g."))
	))
	(/t/r/c (cons title (transpose /t/c/r)))
	;
	(/t/r/c (cons
		((/tab<-& (<> 'b)) (car /t/r/c))
		(cdr /t/r/c)
	))
	(/t/c/r (reverse (let
		((R (reverse (transpose /t/r/c))))
		(cons
			((/tab<-& (<> 'pre)) (car R))
			(cdr R)
		)
	)))
	(/t/c/r (reverse (let
		((R (reverse /t/c/r)))
		(cons
			(map transpose (car R))
			(cdr R)
		)
	)))
	(/t/r/c (transpose /t/c/r))
)

(define (/tab->html /tab)
	(define (/row->html /row)
		(define (/col->html /col) (if (string? /col)
			((<> 'td) /col)
			((<> 'td) (/tab->html /col))
		))
		((<> 'tr) (string-intersperse (map /col->html /row) ""))
	)
	((<> 'table) (string-intersperse (map /row->html /tab) ""))
)

(display (/tab->html /t/r/c))
;(display (/tab->html (transpose /t/r/c)))

)

))

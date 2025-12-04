(import
	(chicken format)
	(chicken string)
	(chicken keyword)
	(chicken condition)
)
(import libyaml)

(define (display* ^ . ..) (map display (cons ^ ..)))

(print "\\relax")
; Relax

(display*
	"\\input luaotfload.sty\\relax"
	"\\global\\headline={}"
	"\\global\\footline={}"
	"\\font\\rm={[cmunssdc]} scaled\\magstep2"
	"\\font\\bf={[cmunso]} scaled\\magstep2"
	"\\font\\tt={[MonaspaceArgon-Regular]} scaled\\magstep2"
	"\\rm"
	"\\openup.33em"
	"\\lineskiplimit=0pt"
)
(display "\\setbox0=")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(display "\\hbox{\\maxdepth=0pt\\relax")
(display*
	"\\def\\vlines{"
	"\\parindent=0pt\\relax"
	"\\def\\toset{\\count0}\\toset=0\\relax"
	"\\def\\maxset{\\count1}\\maxset=0\\relax"
	"\\def\\maxwd{\\dimen0}\\maxwd=0ex\\relax"
	"\\csname[vlines back]\\endcsname"
	"}"
	"\\expandafter\\def\\csname[vlines back]\\endcsname{"
	"\\expandafter\\futurelet\\csname[bgroup?]\\expandafter\\endcsname"
	"\\csname[vlines begin rec]\\endcsname"
	"}"
	"\\expandafter\\def\\csname[vlines begin rec]\\endcsname{"
	"\\expandafter\\ifx\\csname[bgroup?]\\endcsname\\bgroup\\relax"
	"\\csname[vlines max wd]\\expandafter\\endcsname"
	"\\else"
	"\\maxset=\\toset\\relax\\toset=0\\relax"
	"\\vbox{\\hsize=\\maxwd\\csname[vlines lines]\\endcsname}"
	"\\fi"
	"}"
	"\\expandafter\\def\\csname[vlines max wd]\\endcsname#1{"
	"\\advance\\toset by 1\\relax"
	"\\toks\\toset={\\null\\strut#1}"
	"\\setbox0=\\hbox{#1}\\ifdim\\maxwd<\\wd0\\relax\\maxwd=\\wd0\\relax\\fi"
	"\\csname[vlines back]\\endcsname"
	"}"
	"\\expandafter\\def\\csname[vlines lines]\\expandafter\\endcsname{"
	"\\advance\\toset by 1\\relax"
	"\\ifnum\\toset=\\maxset\\relax"
	"\\the\\toks\\toset" ;do not \\break the last line
	"\\else"
	"\\the\\toks\\toset\\hfil\\break\\relax"
	"\\csname[vlines lines]\\endcsname"
	"\\fi"
	"}"
)

(set! yaml ((yaml<-)))
(define (~S ?) (sprintf "~S" ?))
(define (list-set! toset /l i) (set-car! (list-tail /l i) toset))
(define (string->/line ?) (string-split ? "\n" #t))
(define (/->string ? . del) (string-intersperse ? (if (null? del) "" (car del))))
(define (and* L) (foldl (lambda (l r) (and l r)) #t L))
(define (or* L) (foldl (lambda (l r) (or l r)) #f L))
(define (string+ str . ..) (apply string-append (map ->string (cons str ..))))
(define (assoc* key alist) (cdr (assoc key alist)))
(define (assoc*y key ymap) (let* ((pair (assoc key (car ymap)))) (if pair (cdr pair) (abort (condition `(exn message ,(sprintf "key is not it the yaml mapping:\n~S\n->\n~S" key ymap)))))))
(define (transpose list-of-list)
	(if (and* (map null? list-of-list))
		'()
		(cons (map car list-of-list) (transpose (map cdr list-of-list)))
	)
)
(define-syntax list-ref* (syntax-rules()
	((list-ref i /l) (if (>= i 0)
		(list-ref /l i)
		(list-ref /l (+ (length /l) i))
	))
))
(define (-> /l . /i)
	(define (-> /l /i) (if (null? /i) /l (-> (list-ref* (car /i) /l) (cdr /i))))
	(-> /l /i)
)
(define (--> ymap . /key) (define (--> y k) (if (null? k) y (--> (assoc*y (car k) y) (cdr k)))) (--> ymap /key))
(define /t/c/r (let ((/ylist (vector->list yaml))) (list
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
)))

(define-syntax ?? (syntax-rules() ((?? to-check p ...)
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
)))

(define (string->tex ?) (string-translate* ? '(
		("\\" . "\\char`\\\\")
		("-" . "\\char`\\-")
		("{"  . "\\char`\\{") ("}"  . "\\char`\\}")
		(" "  . "\\char`\\ ")
		("$"  . "\\$") ("^"  . "\\^") ("_"  . "\\_")
		("&"  . "\\&") ("#"  . "\\#")
		("%"  . "\\%")
		("~"  . "\\char`\\~")
)))

(define (tex-group ?) (string+ "{" ? "}"))

(define (/r->vlines /r)
	(string+
		"{\\vlines"
			(/->string (map tex-group (string->/line (string->tex /r))))
		"}")
)
(define (endpoint->/vlines /t) (map
	((lambda(@)(@ @))(lambda(@)(lambda(?)(cond
		((string? ?) (/r->vlines ?))
		((list? ?) (map (@ @) ?)
	)))))
	/t
))

;get max height among all unit in a row
;if a table contain 10 columns,
;  the max height of the 1st row will be saved in \dimen0
;  the 2nd will be in \dimen1, until \dimen9.
;  And finally \rowdim will be 10.
(define (/c->vbox /c)
	(define (/c->vbox /c index) (cond
		((null? /c) "")
		((string? (car /c))
			(string+
				"\\hrule" "\\hbox{" "\\vrule" "\\vbox{" "\\vskip.33em" "\\hbox{" "\\hskip1.33ex"
				"\\hbox to\\dimen\\rowdim{" "\\strut" "\\vbox to\\dimen" index "{" "\\vfil"
					"\\vbox{"
						"\\hsize=\\dimen\\rowdim" (car /c)
					"}"
				"\\vfil" "}" "\\strut" "}"
				"}" "\\vskip.33em" "}" "\\hskip1.33ex" "\\vrule" "}" "\\hrule"
				(/c->vbox (cdr /c) (+ index 1))
			)
		)
		(else (abort(condition `(exn message "This branch should never be reached"))))
	))
	(string+
		"\\setbox0=\\hbox{" "\\vbox{"
			(/->string /c)
		"}" "}\\dimen\\rowdim=\\wd0\\relax"
		"\\vbox{" (/c->vbox /c 0) "}"
	)
)
(define (/vlines->hbox /vlines)
	(string+ "\\hbox{"
		"\\def\\rowdim{\\count0}\\rowdim=0\\relax"
		(/->string (map
			(lambda (vlines-row) (string+
				"\\setbox0=\\hbox{"
				(/->string vlines-row)
				"}"
				"\\dimen\\rowdim=\\ht0\\advance\\rowdim by 1\\relax"
			))
			(transpose /vlines)
		))
		(/->string (map /c->vbox /vlines))
	"}")
)

(define (endpoint? /t)
	(define (endpoint? /c) (and* (map not (map list? /c))))
	(and
		(list? /t)
		(and* (map list? /t))
		(and* (map endpoint? /t))
	)
)

(define (<-/vlines<-/t/c/r /t/c/r)
	(define internal-table-index 0)
	(define (<-/c /c)
		(define (<-/r /r) (cond
			((endpoint? /r)
				(set! internal-table-index (+ internal-table-index 1))
				(display (string+ "\\toks" internal-table-index "={" (/vlines->hbox (endpoint->/vlines /r)) "}"))
				(string+ "\\the\\toks" internal-table-index)
			)
			((string? /r) (/r->vlines /r))
			(else (<-/vlines<-/t/c/r /r))
		))
		(map <-/r /c)
	)
	(map <-/c /t/c/r)
)

(display (/vlines->hbox
	(let* ((/vlines (<-/vlines<-/t/c/r /t/c/r)))
		(set! /vlines (transpose /vlines))
		(list-set! (map (lambda (?) (string+ "{\\bf{}" ? "}")) (-> /vlines 0)) /vlines 0)
		(set! /vlines (transpose /vlines))
		(list-set! (map (lambda (?) (string+ "{\\tt{}" ? "}")) (-> /vlines 2)) /vlines 2)
		/vlines
	)
))

(display "}")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(display*
	"\\pagewidth=\\wd0"
	"\\pageheight=\\ht0"
	"\\pageleftoffset=0pt"
	"\\pagerightoffset=0pt"
	"\\pagetopoffset=0pt"
	"\\pagebottomoffset=0pt"
	"\\box0"
	"\\bye"
)

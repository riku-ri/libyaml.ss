(import
	scheme
	(chicken base)
	(chicken format)
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
	(--> (lambda (ymap . <key>)
		(define (:--> y k) (if (null? k)
			y (:--> (assoc*y (car k) y) (cdr k))
		))
		(:--> ymap <key>)
	))
) (let* ((<ylist> (vector->list yaml)))

(printf "
<style>
body { display: inline; margin: 0px; padding: 0px; }
table,tr,th,td { border: 1px solid; }
tr,th,td { padding: 0.5em; }
table {border-collapse: collapse; margin: 0px; padding: 0px; }
</style>
")
(printf "<table>")

(printf "<tr>
<th><i>yaml description<i></th>
<th><i>scheme description<i></th>
<th><table><tr>
 <th><pre style=\"display: inline\"><i>yaml e.g.</i></pre></th>
 <th><pre style=\"display: inline\"><i>scheme e.g.</i></pre></th>
</tr></table></th>
</tr>")

(map
	(lambda (l)
		(printf "<tr>")
		(printf "<td>~A</td>" (--> l "des" "yaml"))
		(printf "<td>~A</td>" (--> l "des" "ss"))

		(printf "<td><table>")
		(let*
			(
				(e.g. (vector->list (--> l "e.g.")))
			)
			(map
				(lambda (e)
					(printf "<tr>")
					(printf "<td><pre style=\"display: inline\">")
					(printf "<code>~A</code></pre></td>" (--> e "yaml"))
					(printf "<td><pre style=\"display: inline;\">")
					(printf "<code>~A</code></pre></td>" (--> e "ss"))
					(printf "</tr>")
				)
				e.g.
			)
		)
		(printf "</table></td>")

		(printf "</tr>")
	)
	<ylist>
)

(printf "</table>")

))

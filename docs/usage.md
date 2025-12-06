# libyaml.ss

This is a chicken scheme egg,
section structure will follow
- [http://wiki.call-cc.org/eggs%20tutorial#sections](http://wiki.call-cc.org/eggs%20tutorial#sections)

## Authors

- [riku-ri@outlook.com](riku-ri@outlook.com)

## Repository

[https://github.com/riku-ri/libyaml.ss/](https://github.com/riku-ri/libyaml.ss/)

## Requirements

- varg
  - https://github.com/riku-ri/varg.ss

## API

```
(import libyaml)
```

### Exception

Exceptions is supposed to be compliant with
the module `(chicken condition)` and SRFI-12
- http://wiki.call-cc.org/man/5/Module%20(chicken%20condition)

Find details about exception in
the specific procedure below

#### non-continuable

The non-continuable conditions expand system conditions from:
- http://wiki.call-cc.org/man/5/Module%20(chicken%20condition)#system-conditions

More specifically, they would be:
- be with composite kind `(exn libyaml)`
  - for a condition from a specific procedure `<p>`,
    the composite kind would be `(exn libyaml <p>)`
- in the `exn` field, it will contain properties listed below:
  - `'message`

### Values in `yaml.h`

[libyaml.ss<sub>git</sub>](.) will
export enum members and functions in
[*yaml.h*](https://github.com/yaml/libyaml/blob/master/include/yaml.h) from
[yaml/libyaml<sub>git</sub>](https://github.com/yaml/libyaml).

Functions and enum members can be used in scheme code as
scheme variable or procedure.

> Note that you may install libyaml development package in your system,
> but [libyaml.ss<sub>git</sub>](.) will use the *yaml.h* in
> submodule *src/libyaml* but not the yaml.h in your system

### yaml and scheme

The chart below define mapping between yaml structure and scheme structure.

Note that the top level API did not return the structures here,
but a procedure that generate them.
See *#Read yaml#* section below.

![](yns/yns.svg)

### Read yaml

```lisp
(yaml<- . |Parameters|)
```

#### Return value

`yaml<-` will return a **procedure** that generate yaml-documents:
- the **procedure** take 1 or no parameter
  - if 1 parameter, it must be a non-negative integer or `-1`
    - for `-1`, return a scheme-list of all yaml-document
    - for positive integer ***n***, return the ***n-1***th document.
      Index from `0` but not `1`
  - if no parameter, return the 1st document.
    Equal to parameter is `0`

For example:
- `(yaml<- "--- 1\n--- 2\n...")` will return a procedure
- `((yaml<- "--- 1\n--- 2\n..."))` will return `1`
- `((yaml<- "--- 1\n--- 2\n...") 0)` will return `1`
- `((yaml<- "--- 1\n--- 2\n...") 1)` will return `2`
- `((yaml<- "--- 1\n--- 2\n...") -1)` will return `'(1 2)`
- `((yaml<- "--- 1\n--- 2\n...") 2)` will abort by exception

#### Parameters

Parameters to `yaml<-` can be
a sequence that contain 1 or more element listed below,
order is not sensitive:

- yaml input
  - *format*:
    - String or input port
  - *description*:
    - Read yaml from it.
    - If it was a port and `#:close-input-port` was not set,
      you need to close it manually if necessary.
    - when it was string, it should be yaml content but not file path
  - *if-necessary*:
    - No
  - *if-not-set*:
    - `(current-input-port)` will be used
- `#:close-input-port`
  - *format*:
    - set or not
  - *description*:
    - If finally close the input port when yaml input is a port
  - *if-necessary*:
    - No
  - *if-not-set*:
    - The port will keep opened
- `#:encoding`
  - *format*:
    - `(cons #:encoding ?)`
      - Where `?` should be one of below:
        - `YAML_ANY_ENCODING`
        - `YAML_UTF8_ENCODING`
        - `YAML_UTF16LE_ENCODING`
        - `YAML_UTF16BE_ENCODING`
  - *description*:
    - Set encoding to `?` when reading yaml
  - *if-necessary*:
    - No
  - *if-not-set*:
    - Dependes on the source in [git/yaml/libyaml](git/yaml/libyaml).
      Currently `YAML_ANY_ENCODING` should be used if not set

#### Examples
```lisp
((yaml<- "--- 1\n--- 2\n...") 1)
```

```lisp
(yaml<-
  (open-input-file "/dev/null")
  `(#:encoding . ,YAML_UTF8_ENCODING)
  #:close-input-port
)
```

```lisp
(call-with-input-file "/dev/null"
  ;`call-with-input-file` will close the port,
  ;so don't set `#:close-input-port` in `yaml<-`
  (lambda (file) (display ((yaml<- file) -1)))
)
```

### Dump yaml


```
(<-yaml . |Parameters|)
```

#### Return value

- If `#:close-output-port` was set
  - return result of `close-output-port`
- If `#:close-output-port` was not set
  - return `(void)`

And `<-yaml` will output the yaml content to the output port.

For example:
- `(<-yaml ((yaml<- "1")))` will output `--- 1` to `(current-output-port)`

#### Parameters

Parameters to `<-yaml` can be
a sequence that contain 1 or more element listed below,
order is not sensitive:

- Scheme structure to be output
  - *format*:
    - Refer to *#yaml and scheme#* section,
      Any valid (nested)structure listed in the chart,
      and no need to wrap the scheme structure in a procedure by default.
      See `#:strict-input` below.
  - *description*:
    - Convert the scheme structure to yaml
      according to the definition in *#yaml and scheme#* section
  - *if-necessary*:
    - YES
  - *if-not-set*:
    - Abort a condition
- `#:strict-input`
  - *format*:
    - set or not
  - *description*:
    - As mentioned `yaml<-` return value above,
      it is a procedure to generate yaml structure.
      But generally it makes no sense to wrap a structure to a procedure
      before dumping it.
      So `<-yaml` does not require a procedure,
      but the real structure by default.

      If a strict input formatted like return value of `yaml<-` is necessary,
      set `#:strict-input` and
      `<-yaml` will check if the to be outputed parameter totally match
      the format of `yaml<-` return value
  - *if-necessary*:
    - No
  - *if-not-set*:
    - `yaml<-` will not strictly check
      if the structure to be outputed match the format of `yaml<-` return value
- `#:port`
  - *format*:
    - `(cons #:port ?)`
      - Where `?` should be a output port
  - *description*:
    - Output yaml content to the port
    - If `#:port` was set and `#:close-out-port` was not set,
      you need to close it manually if necessary.
  - *if-necessary*:
    - No
  - *if-not-set*:
    - `(current-output-port)` will be used
- `#:close-output-port`
  - *format*:
    - set or not
  - *description*:
    - If finally close the value of `#:port`
  - *if-necessary*:
    - No
  - *if-not-set*:
    - The port will keep opened
- `#:encoding`
  > The same as `#:encoding` parameter to `yaml<-`

#### Examples

```lisp
(<-yaml #:strict-input (yaml<- "[1]"))
```

```lisp
(<-yaml ((yaml<- "[1]")))
```

```lisp
(<-yaml #("1st" ()))
```

```lisp
(<-yaml `(#:port . ,(current-output-port))
  ((yaml<- "---\n---\n---\n[1,2,3]") 2))
```

### Check the structure

All check are supposed to be based on definition in *#yaml and scheme#* section.

---

```lisp
(yaml? ?)
(ydoc? ?)
```

Check if `?` is a scheme structure that match a yaml-documents

`ydoc?` just check if the procedure valid when take `-1` as parameter.

`yaml?` will check if the to be outputed parameter totally match
the format of `yaml<-` return value

---

```lisp
(ymap? ?)
(ymap?? ?)
```

Check if `?` is a scheme structure that match a yaml-mapping

`ymap?` only check the top level, a list that only contain 1 alist

`ymap??` will recursively check if each part of `?` is a legal structure

---

```lisp
(ylist? ?)
(ylist?? ?)
```

Similar to `ymap?` and `ymap??` but check yaml-list not yaml-mapping

---

```lisp
(yscalar? ?)
```

Check if `?` is a scheme object that match to a yaml-scalar

---

## Examples

[yns/](yns/) provide some example to convert [yns/yns.yaml](yns/yns.yaml)
to different formats.

It was recommended to begin with
[yns/yns.yaml2html.ss](yns/yns.yaml2html.ss)
because it is much simpler than others.

And actually chart in *#yaml and scheme#* section
was from programs in [yns/](yns/) .

For [yns/yns.yaml](yns/yns.yaml), the structure was defined by me,
so I totally know how the structure should be.
The example below shows how to deal with
a yaml content you may not know the structure.

For a yaml content:
```yaml
- replace me: This will be changed
- a internal mapping:
    replace me: This will be changed
- replace me
- - replace me
- ignored
- "3.32" # string , also ignored
- 3.32 # number, also ignored
```

Assuming it was saved in file `/tmp/tmp.yaml`,
we don't know the content of it,
but we need to modify its content:
- if `replace me` is a key of mapping, replace the value to `<HERE>`
- if `replace me` is a member of list, replace itself to `<HERE>`

The scheme program using `libyaml` can be:
```lisp
(import libyaml)

(call-with-input-file "/tmp/tmp.yaml" (lambda (yaml)
  (let*
    (
      (yaml ((yaml<- yaml)))
      ; don't forget to index document from procedure
    )
    (define (replace-replace-me Y) (cond
      ((ymap? Y) (let ((alist (car Y)))
        (list ; Don't forget to wrap alist to match yaml-mapping format here
          (map
            (lambda (pair) (if (equal? (car pair) "replace me")
              (cons (car pair) "<HERE>")
              (cons (replace-replace-me (car pair)) (replace-replace-me (cdr pair)))
            ))
            alist
          )
        )
      ))
      ((ylist? Y) (let ((slist (vector->list Y)))
        (list->vector ; Don't forget to convert back to vector to match yaml-list format here
          (map
            (lambda (list-unit) (if (equal? list-unit "replace me")
              "<HERE>"
              (replace-replace-me list-unit)
            ))
            slist
          )
        )
      ))
      (else Y)
    ))
    (<-yaml (replace-replace-me yaml) #:close-output-port)
  )
))
```

Save the yaml content to `/tmp/tmp.yaml`,
save the scheme program to `/tmp/tmp.ss`,
`csi -s tmp.ss` will generate:
```yaml
---
- replace me: <HERE>
- a internal mapping:
    replace me: <HERE>
- <HERE>
- - <HERE>
- ignored
- '3.32'
- 3.32
...
```

## License

MIT

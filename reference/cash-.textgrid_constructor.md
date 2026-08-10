# \$ method for TextGrid constructor (enables TextGrid\$new(), TextGrid\$create())

\$ method for TextGrid constructor (enables TextGrid\$new(),
TextGrid\$create())

## Usage

``` r
# S3 method for class 'textgrid_constructor'
x$name
```

## Arguments

- x:

  The TextGrid constructor function

- name:

  Name of static method to access

## Value

The requested static method function

## Examples

``` r
create_fn <- TextGrid$create
tg <- create_fn(0, 1, "words")
```

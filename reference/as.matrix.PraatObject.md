# Convert a pladdrr object to a matrix

Fallback [`as.matrix()`](https://rdrr.io/r/base/matrix.html) method for
every pladdrr object class: it returns the numbers of the object's own
`$as_matrix()` method (`frame` x `2` for Pitch and the tiers,
`frequency` x `time` for Spectrogram and the other 2-D objects,
`channel` x `sample` for Sound). Classes without `$as_matrix()`
(Formant, PointProcess, TextGrid, Table, ...) raise a
`pladdrr_input_error` naming the class and the accessor to use instead;
they never silently return a matrix-shaped wrapper. `Matrix` and
`Polygon` keep their own methods.

## Usage

``` r
# S3 method for class 'PraatObject'
as.matrix(x, ...)
```

## Arguments

- x:

  A pladdrr object (any class inheriting from `PraatObject`).

- ...:

  Passed on to the object's `$as_matrix()` method; used by `Spectrogram`
  (`include_dimnames`) and `MelSpectrogram`/`BarkSpectrogram` (`to_db`).

## Value

A numeric matrix. For classes with no `$as_matrix()`, an error of class
`pladdrr_input_error` instead, naming whichever of `as.data.frame(x)`
and `x$as_vector()` that class really offers (`Manipulation` offers
neither and is pointed at its own accessors).

## See also

[`Matrix`](https://humlab-speech.github.io/pladdrr/reference/Matrix.md),
[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md),
[`as.data.frame.Sound`](https://humlab-speech.github.io/pladdrr/reference/as.data.frame.Sound.md)

## Examples

``` r
sound <- Sound$create_tone(frequency = 440, duration = 0.2,
  sampling_rate = 16000)
m <- as.matrix(sound$to_pitch())
dim(m)
#> [1] 17  2
tryCatch(as.matrix(sound$to_point_process_periodic_cc()),
  pladdrr_input_error = function(e) conditionMessage(e))
#> [1] "class PointProcess has no $as_matrix(); use as.data.frame(x) or x$as_vector() instead (see ?PointProcess)"
```

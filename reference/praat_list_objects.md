# List all objects in Praat object list

List all objects in Praat object list

## Usage

``` r
praat_list_objects()
```

## Value

Data frame with columns: id, name, class, selected

## Examples

``` r
objects <- praat_list_objects()
print(objects)
#>   id       name class selected
#> 1  1 Sound tone Sound    FALSE
#> 2  2 Pitch tone Pitch     TRUE
```

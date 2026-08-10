# Get All Labels from TextGrid Tier (Batch)

Extract all interval labels from a tier in a single operation, instead
of calling \`textgrid\$get_interval_text()\` repeatedly.

## Usage

``` r
get_textgrid_labels_all(textgrid, tier)
```

## Arguments

- textgrid:

  A TextGrid object

- tier:

  Tier number (1-based) or tier name

## Value

Character vector of all interval labels

## Examples

``` r
tg <- TextGrid$create(0, 1, "words")
tg$insert_boundary(1, 0.5)
tg$set_interval_text(1, 2, "hello")
labels <- get_textgrid_labels_all(tg, tier = 1)
table(labels)  # Frequency table of labels
#> labels
#>       hello 
#>     1     1 
```

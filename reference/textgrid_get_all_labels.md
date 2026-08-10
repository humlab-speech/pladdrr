# Get All Labels from TextGrid Tier (Batch)

Extract all interval labels from a tier in a single call, instead of
calling \`get_interval_text()\` n times.

## Usage

``` r
textgrid_get_all_labels(textgrid_xptr, tier_number)
```

## Arguments

- textgrid_xptr:

  External pointer to TextGrid object

- tier_number:

  Tier number (1-based)

## Value

Character vector of all interval labels

## Examples

``` r
tg <- textgrid_create(0, 1, "phones")
tg$insert_boundary("phones", 0.4)
tg$set_interval_text("phones", 1, "sil")
tg$set_interval_text("phones", 2, "V")

labels <- textgrid_get_all_labels(tg$.xptr, tier_number = 1)
table(labels)  # Frequency of each label
#> labels
#>   V sil 
#>   1   1 
```

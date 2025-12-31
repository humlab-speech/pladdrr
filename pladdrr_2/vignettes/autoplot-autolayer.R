## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(

  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 4
)

## ----load-packages, message=FALSE---------------------------------------------
library(pladdrr)
library(ggplot2)

## ----concept, eval=FALSE------------------------------------------------------
# autoplot(spectrogram) +
# 
# autolayer(pitch) +
#   autolayer(formant)

## ----load-sound---------------------------------------------------------------
# Load example sound
sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))


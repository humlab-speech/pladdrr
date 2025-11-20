# Quick script to document new VAD functions
library(roxygen2)

# Roxygenize the package to update NAMESPACE and man pages
roxygenize(".", roclets = c("rd", "namespace"))

cat("✅ Documentation updated\n")

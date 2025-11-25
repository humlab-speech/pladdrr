# List actual Praat source files for Makevars
melder <- list.files("melder", pattern = "\\.cpp$", full.names = TRUE)
sys <- list.files("sys", pattern = "\\.cpp$", full.names = TRUE)
stat <- list.files("stat", pattern = "\\.cpp$", full.names = TRUE)
fon <- list.files("fon", pattern = "\\.cpp$", full.names = TRUE)

# Filter out GUI, graphics, network files
is_needed <- function(file) {
  !grepl("(Picture|Editor|Graphics|Network|Recording|MovieWindow|TextEditor|manual|Demo|praat_)", basename(file), ignore.case = TRUE)
}

melder <- melder[sapply(melder, is_needed)]
sys <- sys[sapply(sys, is_needed)]
stat <- stat[sapply(stat, is_needed)]
fon <- fon[sapply(fon, is_needed)]

cat("# MELDER_SRC (", length(melder), " files)\n", sep = "")
cat(paste(melder, collapse = " \\\n             "), "\n\n")

cat("# SYS_SRC (", length(sys), " files)\n", sep = "")
cat(paste(sys, collapse = " \\\n          "), "\n\n")

cat("# STAT_SRC (", length(stat), " files)\n", sep = "")
cat(paste(stat, collapse = " \\\n          "), "\n\n")

cat("# FON_SRC (", length(fon), " files)\n", sep = "")
cat(paste(fon, collapse = " \\\n          "), "\n")

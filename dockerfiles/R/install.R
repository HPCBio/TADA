## install script for R pkgs modified from https://github.com/davismcc/r-tidybioc-img/blob/master/install.R
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
## update installed packages
BiocManager::install(version = "3.22", ask = FALSE)

pkgs <- c(
  "RCurl",
  "tidyverse",
  "pander",
  "phangorn",
  "dplyr",
  "dada2",
  "DECIPHER",
  "digest",
  "biomformat",
  "optparse",
  "yaml"
)

# check that desired packages are available
ap.db <- available.packages(contrib.url(BiocManager::repositories()))
ap <- rownames(ap.db)
pkgs_to_install <- pkgs[pkgs %in% ap]

# do not reinstall packages that are already installed in the image
ip.db <- installed.packages()
ip <- rownames(ip.db)
pkgs_to_install <- pkgs_to_install[!(pkgs_to_install %in% ip)]

BiocManager::install(pkgs_to_install)

## just in case there were warnings, we want to see them
## without having to scroll up:
warnings()

if (!is.null(warnings()))
{
  w <- capture.output(warnings())
  if (length(grep("is not available|had non-zero exit status", w)))
    quit("no", 1L)
}

Sys.setenv("MAKE" = "make -j 2")

packages_to_install <- c(
  "devtools",
  "languageserver",
  "sf",
  "styler",
  "raster",
  "rgrass7",
  "tidyverse"
)

install.packages(packages_to_install)

# install/configure jupyter kernel
remotes::install_github("IRkernel/IRkernel")
IRkernel::installspec()

# install rstan
install.packages("rstan", type = "source")

# configure C++ toolchain
dotR <- file.path(Sys.getenv("HOME"), ".R")
if (!file.exists(dotR)) dir.create(dotR)
M <- file.path(dotR, "Makevars")
if (!file.exists(M)) file.create(M)
cat("\nCXX14FLAGS=-O3 -march=native -mtune=native -fPIC",
    "CXX14=g++", # or clang++ but you may need a version postfix
    file = M, sep = "\n", append = TRUE)

# install brms
install.packages("brms")

# install ST packages
st_packages <- c(
  "landsatviewer",
  "stcore",
  "ts_utils",
  "st_height",
  "st_volume",
  "ts_algo",
  "st_growth",
  "tidyFIA"
)

for (package in st_packages) {
  devtools::install(
    file.path("~/workspace", package),
    quick = FALSE,
    upgrade = TRUE
  )
}

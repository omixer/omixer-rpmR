# General guidelines:

1. Add and document a test case (in tests/runit/runitModules.R, data in tests/data)
2. Implement the function until the test suite has no errors or failures. Please use `make testSuite` to run the test suite (it needs the package installed: `make install`); `R CMD check` runs it too
3. Document the function with roxygen comments (`#'`, Markdown) above it, and `@export` it if it is public. `make doc` regenerates `man/` and `NAMESPACE` from them (roxygen2): never edit those by hand
4. Format the code with `make style` (styler, [tidyverse style](https://style.tidyverse.org/): 2 spaces, `<-`); lines up to 120 characters
5. Commit the changes, including the regenerated `man/` and `NAMESPACE`

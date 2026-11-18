# Contributing

1. Add a test in `tests/runit/` (package: `runitModules.R`, app: `runitShiny.R`; data in `tests/data/`).
2. Implement until `make testSuite` passes (it tests the installed package: `make install` first). `R CMD check` runs
   it too, as does CI on every push.
3. Document with roxygen comments (`#'`, Markdown) and `@export` what is public. `make doc` regenerates `man/` and
   `NAMESPACE`; never edit those by hand.
4. Format with `make style` ([tidyverse style](https://style.tidyverse.org/)); lines up to 120 characters.
5. Commit, including the regenerated `man/` and `NAMESPACE`.

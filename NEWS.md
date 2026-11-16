# omixerRpm (development version)

## Changes

- **Sample names are kept as in the input.** `rpm()` read omixer-rpm's output with `read.table()`'s defaults, which
  rewrite names that are not valid R names: `S-1` became `S.1`, `1A` became `X1A`, `my sample` became `my.sample`.
  Valid names (`S1`, `s06a`) are unchanged. Scripts that used the rewritten names need the original ones now. The
  values are unchanged. When reading your own table into R, use `read.table(..., check.names = FALSE)` too.

## Fixes

- When omixer-rpm fails, the R error now holds its message (e.g. `species_matrix.tsv, line 2: ... is not
  KO<TAB>one abundance per sample`) instead of "non-zero exit status, refer to the exception output". omixer-rpm's
  output is now shown once the run has finished, not while it runs.
- Paths with spaces work (Java is called with `system2()` and one argument per option).
- A clear error when Java is not found, or is older than 21.
- `rpm()` uses `JAVA_HOME/bin/java` when `JAVA_HOME` is set (as Gradle and Maven do), and `java` from the `PATH`
  otherwise.
- `.claude` and `.idea` folders are no longer bundled into the source package.
- `asDataFrame()` on results per taxon kept the Taxon column but named the Module column "Description"; with a
  database made with `ModuleDB()`, the sample columns were shifted under the wrong names. Both give the key columns,
  Description, then the samples now.
- `getNames()` accepts several modules (NA for an unknown one); it gave one NA and a warning before.
- `rpm()` removes its temporary files.
- `loadDB()` reports the loaded database with `message()` (can be silenced with `suppressMessages()`), not `print()`.
- Explicit NAMESPACE exports; help pages for every exported function; `R CMD check` gives no warnings.
- The tests moved to `tests/` (data in `tests/data`) and run in `R CMD check`; `make testSuite` runs them too.
- The documentation is written as roxygen comments next to the code; `man/` and `NAMESPACE` are generated from them
  (`make doc`). All R code follows the tidyverse style (`make style`).

## Web interface

- New tabs, all interactive (values as tooltips, zoom, legend entries that hide a series, image export): a **heatmap**
  of the modules with the highest mean abundance or coverage, the **taxa** of a module (each taxon's share of the
  module's per-taxon abundance, per sample), **taxa × modules** (a chord diagram of the taxa and modules with the
  highest abundance, linked by the module's abundance in the taxon; pointing at a taxon or module highlights its
  links) and the **coverage cutoff** (the module observations each cutoff keeps, with the learned or given cutoff).
  The charts are ggplot2 charts shown with plotly; the chord diagram is d3 (r2d3).
- A **long table** download: one row per sample and reported (taxon,) module, with its abundance and coverage.
- `rpm()` keeps the coverage cutoff of the run in the result (`mods@cutoff`): the given one, or the learned one.

- `runShinyRpm()` starts the Shiny app from R. It needs shiny, bslib, DT, ggplot2, plotly and r2d3 (suggested
  packages, not installed with omixerRpm).
- The app was rewritten: it passes every option to `rpm()` (the estimator, length normalization and `distribute`
  were ignored before), offers the automatic coverage cutoff, `complex.rule` and `ignore.taxonomy`, keeps each
  user's results separate, shows omixer-rpm errors, accepts uploads up to 1 GB, and both downloads work.
- The Docker image uses R 4.6.1 and serves the app at `/rpm/`.

# omixerRpm 0.6.0 (2026-11-03)

Bundles **omixer-rpm 2.0.0-rc.1**, a release candidate of omixer-rpm 2.0.

## HUMAnN tables

`rpm()` now reads [HUMAnN](https://github.com/biobakery/humann) output directly: `annotation = "humann"` takes a
HUMAnN 3 (or 2) gene family table regrouped to KEGG KOs (`humann_regroup_table --groups uniref90_ko`), optionally
renormalized (`humann_renorm_table`) and joined into one table (`humann_join_tables`). No reformatting is needed.

- **Per taxon** (default): modules of every taxon of a sample, from the stratified rows (`KO|taxon`, HUMAnN's
  `unclassified` included).
- **Per sample** with the new argument `ignore.taxonomy = TRUE`: modules of every sample, from the community total
  rows. Totals and strata are never added together, so nothing is counted twice.
- A table without strata (`humann --remove-stratified-output`) gives one result per sample.
- `UNMAPPED`, `UNGROUPED` and the other special rows are skipped, KO names added by `humann_rename_table` are ignored,
  and sample names lose HUMAnN's `_Abundance` suffix (`S1_Abundance-RPKs` becomes `S1`).
- Give the table as a **file path**; `rpm()` refuses a data.frame for HUMAnN input. `read.table()` treats the
  header line (it starts with `#`) as a comment and turns the first row of data into the header, so data would be
  lost without any error.

HUMAnN 4 (still an alpha) has not been checked on real output yet.

## Other changes

- `ignore.taxonomy` also works for taxon-annotated matrices (`annotation = 2`): one result per sample.
- **Java 21 or newer is required** (0.5: Java 17). The Docker image uses `openjdk-21-jre-headless`.
- Same results as 0.5 (omixer-rpm 1.2.1): omixer-rpm 2.0 only fixes edge cases (malformed databases and inputs,
  `-e 1` layout, rare taxon and module names), listed in its
  [changelog](https://github.com/raeslab/omixer-rpm/blob/master/CHANGELOG.md); the package's tests give the same
  values as with 0.5.
- omixer-rpm 2.0 is faster and needs less memory (see its changelog).
- Errors in the input stop `rpm()` with omixer-rpm's message, e.g. a taxon matrix given as `annotation = 1`, or a
  directory given as a HUMAnN table.
- The Shiny app offers the HUMAnN annotation.

# omixerRpm 0.5.1

- GBMs.v1.0: the last module ends with `///`, so omixer-rpm no longer warns about it.

# omixerRpm 0.5.0

- Bundles omixer-rpm 1.2; new argument `complex.rule` (`"any"`, the default, or `"all"`). Requires Java 17.

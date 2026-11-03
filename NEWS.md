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

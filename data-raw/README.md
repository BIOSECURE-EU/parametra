# Maintainer documentation

This workflow maintains PARAMETRA R package and csv data from the source Excel workbook.

1.  Reads the source Excel workbook.
2.  Validates column names and terms against the `LOT` sheet.
3.  Checks required fields and value/year formatting.
4.  Updates DOI metadata from Crossref (resolves PubMed references to DOI where possible).
5.  Checks URL references.
6.  Generates curated tables, package data objects, documentation, and submission templates.

## Main files

| File | Purpose |
|------------------------------------|------------------------------------|
| `data-raw/helpers.R` | Shared helpers for reading, normalising, resolving, and checking references. |
| `data-raw/curate.R` | Main curation and validation pipeline. |
| `data-raw/write_outputs.R` | Writes CSV, `.rda`, Excel, template, and R documentation outputs. |
| `data-raw/update_from_template.R` | Validates a populated submission template, merges it into PARAMETRA, and runs the usual curation/export workflow. |
| `data-raw/parametra.xlsx` | Main editable PARAMETRA workbook. |
| `data-raw/parametra_template.xlsx` | Submission template. |
| `R/data.R` | Auto-generated package data documentation. Do not edit manually. |
| `data/` | Package `.rda` data objects. |
| `data-raw/tables/` | CSV exports of curated tables. |

## Changelog

Every maintenance run that changes PARAMETRA data must be documented in the `CHANGELOG` sheet of `data-raw/parametra.xlsx`.

Add one row before running the final export, or before replacing the source workbook with the curated workbook.

The `CHANGELOG` entry should briefly state what changed, for example new records, corrected values, updated references, removed duplicates, or LOT updates.

## Standard run

From the package root:

``` r
source("data-raw/helpers.R")
source("data-raw/curate.R")
source("data-raw/write_outputs.R")
source("data-raw/update_from_template.R")

path <- "data-raw/parametra.xlsx"

curated <- curate_parametra(
  file = path,
  crossref = NULL,
  url_check = NULL,
  pubmed_resolve = TRUE
)

write_parametra_outputs(
  file = path,
  curated = curated,
  write_excel_updated = TRUE,
  write_template = TRUE
)

devtools::document()
```

## Adding data from a populated submission template

Place the received populated template in:

```         
data-raw/submission/
```

The file name can vary, for example:

```         
data-raw/submission/institution-name.xlsx
data-raw/submission/2026-06-submission.xlsx
```

If there is exactly one `.xlsx` file in `data-raw/submission/`, the workflow will find it automatically. If there is more than one `.xlsx` file, specify the file path explicitly with `template_file`.

Then source the pipeline:

``` r
source("data-raw/helpers.R")
source("data-raw/curate.R")
source("data-raw/write_outputs.R")
source("data-raw/update_from_template.R")
```

First validate the submitted file:

``` r
submission_check <- validate_submission_template(
  master_file = "data-raw/parametra.xlsx",
  template_file = "data-raw/submission/[name].xlsx"
)

submission_check$valid
submission_check$issues
```

If valid, merge, curate, and export:

``` r
submission_update <- update_parametra_from_submission(
  master_file = "data-raw/parametra.xlsx",
  template_file = "data-raw/submission/[name].xlsx",
  crossref = NULL,
  url_check = NULL,
  pubmed_resolve = TRUE
)

submission_update$curated$issues
```

This creates an intermediate merged workbook in:

```         
data-raw/submission/parametra_merged_<timestamp>.xlsx
```

and then runs the standard PARAMETRA curation workflow:

If validation fails, inspect:

``` r
submission_check$issues
```

Common issues are:

-   unknown sheet names
-   columns not present in the master PARAMETRA sheet
-   missing required columns
-   terms not present in `LOT`
-   non-numeric `value` entries
-   invalid `year` values.

## Output files

| Output | Location |
|------------------------------------|------------------------------------|
| Curated CSV tables | `data-raw/tables/` |
| Package `.rda` objects | `data/` |
| Long-format CSV | `data-raw/parametra_long.csv` |
| Crossref CSV | `data-raw/parametra_crossref.csv` |
| Package data documentation | `R/data.R` |
| Curated Excel workbook | `data-raw/parametra_curated_<timestamp>.xlsx` |
| Workbook backup (.gitignore) | `data-raw/backups/` |
| Updated template workbook | `data-raw/parametra_template.xlsx` |


## Submission template maintenance

The file:

```         
data-raw/parametra_template.xlsx
```

is mostly automated. However, the `SUBMISSION` sheet is manual. The R code must not rewrite its instructions.

The script only updates:

| Cell            | Content                                             |
|-----------------|-----------------------------------------------------|
| `SUBMISSION!A1` | PARAMETRA version, read from package `DESCRIPTION`. |
| `SUBMISSION!A2` | Last update timestamp.                              |

All parameter sheets in the template are regenerated as empty sheets with current columns.

`README` and `Crossref` are excluded from the template.

## Package documentation

`R/data.R` is generated from the `LOT` and `README` sheets.

The pipeline assumes:

- every data-table column is described in `LOT`;
- column descriptions are stored as rows where `term_type == "column"`;
- the column name is in `key`;
- the column description is in `description`.
- each table description is stored in `README`, with the table name in column A and the description in column B, starting around rows 7–23;
- the table-description reader checks `README!A7:B100`, so it can still work if more table rows are added later.

After regenerating `R/data.R`, run:

``` r
devtools::document()
```

Then run:

``` r
devtools::check()
```

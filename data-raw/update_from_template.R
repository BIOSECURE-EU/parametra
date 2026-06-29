# PARAMETRA submission-template intake.
#
# Use when a populated submission template has been received and saved as:
# data-raw/submission/[name].xlsx
#
# Source after helpers.R, curate.R and write_outputs.R.
find_submission_file <- function(submission_dir = "data-raw/submission") {
  files <- list.files(
    submission_dir,
    pattern = "\\.xlsx$",
    full.names = TRUE
  )

  files <- files[!grepl("^~\\$", basename(files))]

  if (length(files) == 0) {
    stop("No .xlsx submission file found in: ", submission_dir, call. = FALSE)
  }

  if (length(files) > 1) {
    stop(
      "More than one .xlsx submission file found in ",
      submission_dir,
      ". Specify template_file explicitly.",
      call. = FALSE
    )
  }

  files[[1]]
}

read_submission_tables <- function(
    template_file = NULL,
    submission_dir = "data-raw/submission",
    ignore_sheets = c("SUBMISSION", "README", "CHANGELOG", "crossref", "LOT")
) {
  template_file <- template_file %||% find_submission_file(submission_dir)

  if (!file.exists(template_file)) {
    stop("Template file not found: ", template_file, call. = FALSE)
  }

  template_sheets <- setdiff(readxl::excel_sheets(template_file), ignore_sheets)

  purrr::set_names(template_sheets) %>%
    purrr::map(function(sheet) {
      tbl <- readxl::read_xlsx(template_file, sheet = sheet, col_types = "text")
      names(tbl) <- stringr::str_trim(names(tbl))
      tbl <- tbl[rowSums(is.na(tbl)) != ncol(tbl), , drop = FALSE]

      tbl %>%
        dplyr::select(-dplyr::any_of(c("id", "parameter_type", "ref_status", "ref_last_access")))
    }) %>%
    purrr::keep(~ nrow(.x) > 0)
}

validate_submission_template <- function(
    master_file = "data-raw/parametra.xlsx",
    template_file = NULL,
    submission_dir = "data-raw/submission",
    required_cols = c("parameter", "ref", "filled_by"),
    term_check_cols = c("parameter", "study_type", "pathogen")
) {
  template_file <- template_file %||% find_submission_file(submission_dir)

  lot <- read_lot(master_file)
  master_tables <- read_parametra_tables(master_file)
  submission_tables <- read_submission_tables(template_file = template_file)

  unknown_sheets <- setdiff(names(submission_tables), names(master_tables))
  if (length(unknown_sheets) > 0) {
    stop(
      "Submission template contains unknown sheet(s): ",
      paste(unknown_sheets, collapse = ", "),
      call. = FALSE
    )
  }

  schema_issues <- purrr::imap(submission_tables, function(tbl, sheet) {
    list(
      extra_columns = setdiff(names(tbl), names(master_tables[[sheet]])),
      missing_required_columns = setdiff(required_cols, names(tbl))
    )
  })

  extra_cols <- purrr::map(schema_issues, "extra_columns") %>% purrr::keep(~ length(.x) > 0)
  missing_required <- purrr::map(schema_issues, "missing_required_columns") %>% purrr::keep(~ length(.x) > 0)

  validation_issues <- validate_parametra_tables(
    tables = submission_tables,
    lot = lot,
    required_cols = required_cols,
    term_check_cols = term_check_cols
  )

  validation_issues$unknown_sheets <- unknown_sheets
  validation_issues$submission_extra_columns <- extra_cols
  validation_issues$submission_missing_required_columns <- missing_required

  blocking_issues <- length(unknown_sheets) > 0 ||
    length(extra_cols) > 0 ||
    length(missing_required) > 0 ||
    length(validation_issues$columns_not_in_lot) > 0 ||
    length(validation_issues$terms_not_in_lot) > 0 ||
    length(validation_issues$non_numeric_value) > 0 ||
    length(validation_issues$invalid_year) > 0

  list(
    valid = !blocking_issues,
    tables = submission_tables,
    issues = validation_issues
  )
}

merge_submission_template <- function(
    master_file = "data-raw/parametra.xlsx",
    template_file = NULL,
    submission_dir = "data-raw/submission",
    out_file = file.path(
      "data-raw/submission",
      paste0("parametra_merged_", format(Sys.time(), "%Y%m%d-%H%M%S"), ".xlsx")
    ),
    stop_on_invalid = TRUE
) {
  template_file <- template_file %||% find_submission_file(submission_dir)

  validation <- validate_submission_template(
    master_file = master_file,
    template_file = template_file,
    submission_dir = submission_dir
  )

  if (isTRUE(stop_on_invalid) && !isTRUE(validation$valid)) {
    stop(
      "Submission template is not valid. Inspect validate_submission_template(...)$issues.",
      call. = FALSE
    )
  }

  dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)

  wb <- openxlsx::loadWorkbook(master_file)
  master_sheets <- readxl::excel_sheets(master_file)

  purrr::iwalk(validation$tables, function(submitted, sheet) {
    if (!sheet %in% master_sheets || nrow(submitted) == 0) return(invisible(NULL))

    existing <- readxl::read_xlsx(master_file, sheet = sheet, col_types = "text")

    data_cols <- setdiff(names(existing), c("id", "parameter_type", "ref_status", "ref_last_access"))

    submitted <- submitted[, intersect(data_cols, names(submitted)), drop = FALSE]
    missing_cols <- setdiff(data_cols, names(submitted))
    submitted[missing_cols] <- NA
    submitted <- submitted[, data_cols, drop = FALSE]

    existing_data <- existing %>%
      dplyr::select(dplyr::any_of(data_cols))

    combined <- dplyr::bind_rows(
      coerce_all_character(existing_data),
      coerce_all_character(submitted)
    )

    write_sheet_as_table(wb, sheet, combined)
    invisible(NULL)
  })

  openxlsx::saveWorkbook(wb, file = out_file, overwrite = TRUE)

  list(file = out_file, validation = validation)
}

update_parametra_from_submission <- function(
    master_file = "data-raw/parametra.xlsx",
    template_file = NULL,
    submission_dir = "data-raw/submission",
    crossref = NULL,
    url_check = NULL,
    pubmed_resolve = TRUE,
    write_excel_updated = TRUE,
    write_template = TRUE
) {
  merged <- merge_submission_template(
    master_file = master_file,
    template_file = template_file,
    submission_dir = submission_dir,
    stop_on_invalid = TRUE
  )

  curated <- curate_parametra(
    file = merged$file,
    crossref = crossref,
    url_check = url_check,
    pubmed_resolve = pubmed_resolve
  )

  outputs <- write_parametra_outputs(
    file = merged$file,
    curated = curated,
    write_excel_updated = write_excel_updated,
    write_template = write_template
  )

  invisible(list(
    merged_file = merged$file,
    validation = merged$validation,
    curated = curated,
    outputs = outputs
  ))
}

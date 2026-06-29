# PARAMETRA output writer.
#
# Source this after helpers.R and curate.R.

suppressPackageStartupMessages({
  library(openxlsx)
  library(readxl)
  library(dplyr)
  library(purrr)
  library(stringr)
  library(janitor)
})

auto_widths <- function(wb, sheet, df, min_width = 8, max_width = 60) {
  if (is.null(df) || ncol(df) == 0) return(invisible(NULL))

  widths <- purrr::map_dbl(seq_along(df), function(i) {
    values <- as.character(df[[i]])
    values <- values[!is.na(values)]
    max(nchar(c(names(df)[i], values)), na.rm = TRUE) + 2
  })

  widths <- pmin(pmax(widths, min_width), max_width)
  openxlsx::setColWidths(wb, sheet = sheet, cols = seq_along(widths), widths = widths)

  invisible(NULL)
}

write_sheet_as_table <- function(wb, sheet, df, table_style = "TableStyleMedium1") {
  existing_sheet <- openxlsx::sheets(wb)
  existing_match <- existing_sheet[tolower(existing_sheet) == tolower(sheet)]

  if (length(existing_match) > 0) {
    openxlsx::removeWorksheet(wb, existing_match[[1]])
  }

  openxlsx::addWorksheet(wb, sheet)

  df <- as.data.frame(df)

  if (nrow(df) == 0) {
    openxlsx::writeData(wb, sheet, x = df, startRow = 1, startCol = 1, colNames = TRUE)
  } else {
    openxlsx::writeDataTable(
      wb,
      sheet = sheet,
      x = df,
      startRow = 1,
      startCol = 1,
      tableStyle = table_style,
      withFilter = TRUE
    )
  }

  openxlsx::freezePane(wb, sheet, firstRow = TRUE)
  auto_widths(wb, sheet, df)

  invisible(NULL)
}

update_fixed_cell <- function(wb, sheet, value, row, col) {
  if (!sheet %in% openxlsx::sheets(wb)) return(invisible(NULL))

  openxlsx::writeData(
    wb,
    sheet = sheet,
    x = value,
    startRow = row,
    startCol = col,
    colNames = FALSE
  )

  invisible(NULL)
}

write_csv_outputs <- function(
    curated,
    out_dir = "data-raw/tables",
    out_long = "data-raw/parametra_long.csv",
    out_crossref = "data-raw/parametra_crossref.csv"
) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  purrr::iwalk(curated$tables, function(tbl, sheet) {
    file_name <- janitor::make_clean_names(sheet)

    write.csv(
      tbl,
      file = file.path(out_dir, paste0(file_name, ".csv")),
      row.names = FALSE
    )
  })

  write.csv(curated$parametra_long, out_long, row.names = FALSE)

  if (!is.null(curated$crossref)) {
    write.csv(curated$crossref, out_crossref, row.names = FALSE)
  }

  invisible(NULL)
}

write_rda_outputs <- function(curated, rda_dir = "data", compress = "xz") {
  dir.create(rda_dir, recursive = TRUE, showWarnings = FALSE)

  purrr::iwalk(curated$tables, function(tbl, sheet) {
    object_name <- janitor::make_clean_names(sheet)
    assign(object_name, tbl)
    save(
      list = object_name,
      file = file.path(rda_dir, paste0(object_name, ".rda")),
      compress = compress
    )
  })

  parametra_long <- curated$parametra_long
  save(
    parametra_long,
    file = file.path(rda_dir, "parametra_long.rda"),
    compress = compress
  )

  if (!is.null(curated$crossref)) {
    parametra_crossref <- curated$crossref
    save(
      parametra_crossref,
      file = file.path(rda_dir, "parametra_crossref.rda"),
      compress = compress
    )
  }

  invisible(NULL)
}

write_updated_excel <- function(
    file,
    curated,
    out_file,
    crossref_sheet = "Crossref",
    keep_metadata_sheets = c("README", "CHANGELOG", "LOT")
) {
  existing_sheets <- readxl::excel_sheets(file)
  sheets_to_keep <- intersect(keep_metadata_sheets, existing_sheets)

  wb <- if ("README" %in% sheets_to_keep) {
    openxlsx::loadWorkbook(file)
  } else {
    openxlsx::createWorkbook()
  }

  sheets_to_remove <- setdiff(openxlsx::sheets(wb), "README")
  purrr::walk(sheets_to_remove, ~ openxlsx::removeWorksheet(wb, .x))

  wb$workbook$definedNames <- NULL

  # Assumes README stores Last update value in B3.
  update_fixed_cell(
    wb,
    sheet = "README",
    value = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    row = 3,
    col = 2
  )

  if ("LOT" %in% sheets_to_keep) {
    write_sheet_as_table(wb, "LOT", curated$lot)
  }

  if ("CHANGELOG" %in% sheets_to_keep) {
    changelog <- readxl::read_xlsx(file, sheet = "CHANGELOG", col_names = TRUE)
    write_sheet_as_table(wb, "CHANGELOG", changelog)
  }

  purrr::iwalk(curated$tables, function(tbl, sheet) {
    write_sheet_as_table(wb, sheet, tbl)
  })

  if (!is.null(curated$crossref)) {
    crossref_out <- curated$crossref[
      setdiff(names(curated$crossref), c("reference", "abstract"))
    ]

    write_sheet_as_table(wb, crossref_sheet, crossref_out)
  }

  openxlsx::saveWorkbook(wb, file = out_file, overwrite = TRUE)

  invisible(out_file)
}

create_parametra_template <- function(
    curated,
    template_file = "data-raw/parametra_template.xlsx",
    include_lot = TRUE,
    version = package_version_label(),
    update_time = Sys.time()
) {
  dir.create(dirname(template_file), recursive = TRUE, showWarnings = FALSE)

  wb <- if (file.exists(template_file)) {
    openxlsx::loadWorkbook(template_file)
  } else {
    openxlsx::createWorkbook()
  }

  if (!"SUBMISSION" %in% openxlsx::sheets(wb)) {
    openxlsx::addWorksheet(wb, "SUBMISSION")
  }

  # SUBMISSION instructions are maintained manually in the workbook.
  # Only these fixed cells are updated:
  # A1 = version; A2 = Last update.
  update_fixed_cell(wb, "SUBMISSION", version, row = 1, col = 1)
  update_fixed_cell(
    wb,
    "SUBMISSION",
    paste0("Last update:", format(update_time, "%Y-%m-%d %H:%M:%S %Z")),
    row = 2,
    col = 1
  )

  if (isTRUE(include_lot) && !is.null(curated$lot)) {
    write_sheet_as_table(wb, "LOT", curated$lot)
  }

  purrr::iwalk(curated$tables, function(tbl, sheet) {
    empty_tbl <- tbl[
      0,
      setdiff(names(tbl), c("id", "ref_status", "ref_last_access")),
      drop = FALSE
    ]

    write_sheet_as_table(wb, sheet, empty_tbl)
  })

  openxlsx::saveWorkbook(wb, file = template_file, overwrite = TRUE)

  invisible(template_file)
}

lot_column_descriptions <- function(lot) {
  lot %>%
    dplyr::filter(.data$term_type == "column") %>%
    dplyr::transmute(
      column = as.character(.data$key),
      description = as.character(.data$description)
    ) %>%
    dplyr::filter(!is.na(.data$column), .data$column != "") %>%
    dplyr::distinct(.data$column, .keep_all = TRUE)
}

escape_roxygen <- function(x) {
  x <- as.character(x %||% "")
  x <- stringr::str_replace_all(x, "[\r\n]+", " ")
  x <- stringr::str_replace_all(x, "\\\\", "\\\\\\\\")
  x <- stringr::str_replace_all(x, "%", "\\\\%")
  x
}

read_readme_table_descriptions <- function(
    file,
    sheet = "README",
    range = "A7:B100"
) {
  if (!sheet %in% readxl::excel_sheets(file)) {
    return(tibble::tibble(table = character(0), description = character(0)))
  }

  readxl::read_xlsx(
    file,
    sheet = sheet,
    range = range,
    col_names = c("table", "description"),
    col_types = "text"
  ) %>%
    dplyr::mutate(
      table = janitor::make_clean_names(.data$table),
      description = stringr::str_squish(as.character(.data$description))
    ) %>%
    dplyr::filter(
      !is.na(.data$table),
      .data$table != "",
      !is.na(.data$description),
      .data$description != ""
    ) %>%
    dplyr::distinct(.data$table, .keep_all = TRUE)
}

format_roxygen_data_doc <- function(object_name, title, description, columns = NULL) {
  lines <- c(
    paste0("#' ", title),
    "#'",
    paste0("#' ", description),
    "#'",
    "#' @format A data frame."
  )

  if (!is.null(columns) && nrow(columns) > 0) {
    lines <- c(lines, "#' @details Columns:")

    lines <- c(
      lines,
      paste0(
        "#' \\describe{\\item{",
        escape_roxygen(columns$column),
        "}{",
        escape_roxygen(columns$description),
        "}}"
      )
    )
  }

  c(lines, paste0('"', object_name, '"'), "")
}

write_data_documentation <- function(
    curated,
    source_file,
    out_file = "R/data.R",
    readme_sheet = "README",
    readme_description_range = "A7:B100"
) {
  dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)

  column_docs <- lot_column_descriptions(curated$lot)
  table_docs <- read_readme_table_descriptions(
    file = source_file,
    sheet = readme_sheet,
    range = readme_description_range
  )

  table_description <- function(sheet) {
    object_name <- janitor::make_clean_names(sheet)
    description <- table_docs$description[table_docs$table == object_name][1]

    if (is.na(description) || description == "") {
      return(paste0("Curated PARAMETRA records from the ", sheet, " sheet."))
    }

    description
  }

  docs <- c(
    "# This file is generated by data-raw/write_parametra_outputs.R.",
    "# Do not edit manually.",
    ""
  )

  purrr::iwalk(curated$tables, function(tbl, sheet) {
    object_name <- janitor::make_clean_names(sheet)

    docs <<- c(
      docs,
      format_roxygen_data_doc(
        object_name = object_name,
        title = paste0("PARAMETRA ", sheet, " data"),
        description = table_description(sheet),
        columns = column_docs %>% dplyr::filter(.data$column %in% names(tbl))
      )
    )
  })

  docs <- c(
    docs,
    format_roxygen_data_doc(
      object_name = "parametra_long",
      title = "PARAMETRA long-format data",
      description = "Curated PARAMETRA records from all parameter sheets combined in long format.",
      columns = column_docs %>% dplyr::filter(.data$column %in% names(curated$parametra_long))
    )
  )

  if (!is.null(curated$crossref)) {
    docs <- c(
      docs,
      format_roxygen_data_doc(
        object_name = "parametra_crossref",
        title = "PARAMETRA Crossref metadata",
        description = "Crossref metadata for DOI references used in PARAMETRA.",
        columns = NULL
      )
    )
  }

  writeLines(docs, out_file, useBytes = TRUE)

  invisible(out_file)
}

write_parametra_outputs <- function(
    file,
    curated,
    out_dir = "data-raw/tables",
    rda_dir = "data",
    data_doc_file = "R/data.R",
    backup_dir = "data-raw/backups",
    write_excel_updated = TRUE,
    write_template = TRUE,
    template_file = "data-raw/parametra_template.xlsx",
    crossref_sheet = "Crossref"
) {
  dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)

  timestamp <- format(Sys.time(), "%Y%m%d-%H%M%S")
  backup_file <- file.path(backup_dir, paste0("parametra_backup_", timestamp, ".xlsx"))
  curated_xlsx <- file.path("data-raw", paste0("parametra_curated_", timestamp, ".xlsx"))

  file.copy(file, backup_file, overwrite = FALSE)

  write_csv_outputs(curated, out_dir = out_dir)
  write_rda_outputs(curated, rda_dir = rda_dir)
  write_data_documentation(curated, source_file = file, out_file = data_doc_file)

  if (isTRUE(write_excel_updated)) {
    write_updated_excel(
      file = file,
      curated = curated,
      out_file = curated_xlsx,
      crossref_sheet = crossref_sheet
    )
  }

  if (isTRUE(write_template)) {
    create_parametra_template(
      curated,
      template_file = template_file,
      include_lot = TRUE
    )
  }

  invisible(list(
    backup = backup_file,
    curated_xlsx = if (isTRUE(write_excel_updated)) curated_xlsx else NULL,
    template = if (isTRUE(write_template)) template_file else NULL,
    data_doc = data_doc_file
  ))
}

update_parametra_from_template <- function(
    master_file,
    template_file,
    out_file = file.path(
      "data-raw",
      paste0("parametra_with_submission_", format(Sys.time(), "%Y%m%d-%H%M%S"), ".xlsx")
    ),
    crossref = NULL,
    url_check = NULL,
    url_download = FALSE,
    archive_dir = "data-raw/archive_refs",
    pubmed_resolve = TRUE
) {
  master_sheets <- readxl::excel_sheets(master_file)
  template_sheets <- setdiff(
    readxl::excel_sheets(template_file),
    c("SUBMISSION", "README", "Crossref")
  )

  wb <- openxlsx::loadWorkbook(master_file)

  purrr::walk(intersect(template_sheets, master_sheets), function(sheet) {
    submitted <- readxl::read_xlsx(template_file, sheet = sheet, col_types = "text")
    submitted <- submitted[rowSums(is.na(submitted)) != ncol(submitted), , drop = FALSE]

    if (nrow(submitted) == 0) return(invisible(NULL))

    existing <- readxl::read_xlsx(master_file, sheet = sheet, col_types = "text")

    combined <- dplyr::bind_rows(
      coerce_all_character(existing),
      coerce_all_character(submitted)
    )

    write_sheet_as_table(wb, sheet, combined)
    invisible(NULL)
  })

  openxlsx::saveWorkbook(wb, file = out_file, overwrite = TRUE)

  curated <- curate_parametra(
    out_file,
    crossref = crossref,
    url_check = url_check,
    url_download = url_download,
    archive_dir = archive_dir,
    pubmed_resolve = pubmed_resolve
  )

  write_parametra_outputs(
    file = out_file,
    curated = curated,
    write_excel_updated = TRUE,
    write_template = TRUE
  )

  invisible(list(file = out_file, curated = curated))
}

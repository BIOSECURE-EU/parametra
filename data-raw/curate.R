# PARAMETRA curation pipeline.
#
# Source this after data-raw/helpers.R.

validate_parametra_tables <- function(
    tables,
    lot,
    required_cols = c("parameter", "ref", "filled_by"),
    term_check_cols = c("parameter", "study_type", "pathogen")
) {
  lot_columns <- lot %>%
    dplyr::filter(.data$term_type == "column") %>%
    dplyr::pull(.data$key) %>%
    unique()

  used_columns <- unique(unlist(purrr::map(tables, names), use.names = FALSE))

  issues <- list(
    missing_required_columns = list(),
    columns_not_in_lot = list(),
    lot_columns_not_used = setdiff(lot_columns, used_columns),
    terms_not_in_lot = list(),
    non_numeric_value = list(),
    invalid_year = list()
  )

  purrr::iwalk(tables, function(tbl, sheet) {
    missing_cols <- setdiff(required_cols, names(tbl))
    if (length(missing_cols) > 0) {
      issues$missing_required_columns[[sheet]] <<- missing_cols
    }

    bad_cols <- setdiff(names(tbl), lot_columns)
    if (length(bad_cols) > 0) {
      issues$columns_not_in_lot[[sheet]] <<- bad_cols
    }

    for (col in intersect(term_check_cols, names(tbl))) {
      values <- stringr::str_trim(as.character(tbl[[col]]))
      values <- values[!is.na(values) & values != ""]

      allowed <- lot %>%
        dplyr::filter(.data$term_type == col) %>%
        dplyr::pull(.data$key) %>%
        unique()

      not_allowed <- setdiff(unique(values), allowed)
      not_allowed <- setdiff(not_allowed, "O")

      if (length(not_allowed) > 0) {
        issues$terms_not_in_lot[[paste0(sheet, "::", col)]] <<- not_allowed
      }
    }

    if ("value" %in% names(tbl)) {
      value_num <- suppressWarnings(as.numeric(tbl$value))
      bad_idx <- which(!is.na(tbl$value) & tbl$value != "" & is.na(value_num))

      if (length(bad_idx) > 0) {
        issues$non_numeric_value[[sheet]] <<- list(
          n = length(bad_idx),
          examples = unique(head(as.character(tbl$value[bad_idx]), 10))
        )
      }
    }

    if ("year" %in% names(tbl)) {
      bad_idx <- which(!is.na(tbl$year) & tbl$year != "" & !is_valid_year(tbl$year))

      if (length(bad_idx) > 0) {
        issues$invalid_year[[sheet]] <<- list(
          n = length(bad_idx),
          examples = unique(head(as.character(tbl$year[bad_idx]), 10))
        )
      }
    }
  })

  issues
}

coerce_numeric_columns <- function(
    tables,
    numeric_cols = c("value", "lower_cl", "upper_cl", "year")
) {
  purrr::map(tables, function(tbl) {
    cols_to_coerce <- intersect(numeric_cols, names(tbl))

    if (length(cols_to_coerce) > 0) {
      tbl <- tbl %>%
        dplyr::mutate(
          dplyr::across(
            dplyr::all_of(cols_to_coerce),
            ~ suppressWarnings(as.numeric(.x))
          )
        )
    }

    tbl
  })
}

make_parametra_id <- function(tbl) {
  n <- nrow(tbl)
  if (n == 0) return(character(0))

  make_part <- function(x, fallback) {
    x <- stringr::str_to_lower(stringr::str_trim(as.character(x)))
    x[is.na(x) | x == "" | x %in% c("na", "n/a", "multiple", "various", "several")] <- fallback

    purrr::map_chr(x, function(value) {
      words <- stringr::str_extract_all(
        stringr::str_replace_all(value, "&", " and "),
        "[a-z0-9]+"
      )[[1]]

      words <- words[words != ""]

      code <- dplyr::case_when(
        length(words) >= 3 ~ paste0(substr(words[1:3], 1, 1), collapse = ""),
        length(words) == 2 ~ paste0(substr(words[1], 1, 2), substr(words[2], 1, 1)),
        length(words) == 1 ~ substr(stringr::str_pad(words[1], 3, side = "right", pad = "x"), 1, 3),
        TRUE ~ fallback
      )

      stringr::str_pad(substr(code, 1, 3), 3, side = "right", pad = "x")
    })
  }

  type_raw <- if ("parameter_type" %in% names(tbl)) tbl[["parameter_type"]] else rep(NA_character_, n)
  parameter_raw <- if ("parameter" %in% names(tbl)) tbl[["parameter"]] else rep("Other", n)
  pathogen_raw <- if ("pathogen" %in% names(tbl)) tbl[["pathogen"]] else rep(NA_character_, n)
  year_raw <- if ("year" %in% names(tbl)) tbl[["year"]] else rep(NA_character_, n)

  type_part <- make_part(type_raw, "typ")
  parameter_part <- make_part(parameter_raw, "par")
  pathogen_part <- make_part(pathogen_raw, "mul")
  year_part <- stringr::str_extract(as.character(year_raw), "[0-9]{4}")
  year_part[is.na(year_part) | year_part == ""] <- "0000"

  base_id <- paste(type_part, parameter_part, pathogen_part, year_part, sep = "-")
  suffix <- ave(seq_along(base_id), base_id, FUN = seq_along)

  paste0(base_id, "-", suffix)
}

build_ref_lookup <- function(
    tables,
    file,
    crossref = NULL,
    url_check = NULL,
    url_download = FALSE,
    archive_dir = "data-raw/archive_refs",
    pubmed_resolve = TRUE,
    ref_col = "ref",
    crossref_sheet = "Crossref"
) {
  refs_raw <- extract_refs(tables, ref_col = ref_col)

  pubmed_map <- if (isTRUE(pubmed_resolve)) {
    resolve_pubmed_to_doi(refs_raw)
  } else {
    tibble::tibble(pubmed_url = character(0), doi = character(0))
  }

  pubmed_lookup <- stats::setNames(pubmed_map$doi, pubmed_map$pubmed_url)

  refs <- tibble::tibble(
    ref_original = refs_raw,
    ref_norm = normalise_ref(refs_raw, pubmed_lookup = pubmed_lookup),
    ref_type = dplyr::case_when(
      looks_like_doi(ref_norm) ~ "doi",
      looks_like_url(ref_norm) ~ "url",
      TRUE ~ "other"
    ),
    ref_status = NA_character_,
    ref_last_access = as.Date(NA)
  ) %>%
    dplyr::distinct(.data$ref_original, .keep_all = TRUE)

  existing_crossref <- read_crossref_sheet(file, sheet = crossref_sheet)

  sheet_dois <- if (!is.null(existing_crossref) && "ref" %in% names(existing_crossref)) {
    unique(normalise_doi(existing_crossref$ref))
  } else {
    character(0)
  }

  doi_refs <- refs$ref_norm[refs$ref_type == "doi"]
  doi_missing_in_sheet <- setdiff(doi_refs, sheet_dois)

  fetched <- NULL
  crossref_table <- existing_crossref

  if (!identical(crossref, FALSE)) {
    dois_to_fetch <- if (isTRUE(crossref)) doi_refs else doi_missing_in_sheet
    fetched <- fetch_crossref_info_safe(dois_to_fetch)

    crossref_table <- dplyr::bind_rows(
      coerce_all_character(existing_crossref),
      coerce_all_character(fetched$crossref)
    )

    if (!is.null(crossref_table) && "ref" %in% names(crossref_table)) {
      crossref_table <- crossref_table %>%
        dplyr::distinct(.data$ref, .keep_all = TRUE)
    }
  }

  doi_found <- if (!is.null(crossref_table) && "ref" %in% names(crossref_table)) {
    unique(normalise_doi(crossref_table$ref))
  } else {
    character(0)
  }

  doi_not_found <- fetched$doi_not_found %||% character(0)
  doi_not_found <- setdiff(doi_not_found, doi_found)

  refs <- refs %>%
    dplyr::mutate(
      ref_status = dplyr::case_when(
        .data$ref_type == "doi" & .data$ref_norm %in% doi_found ~ "doi_found",
        .data$ref_type == "doi" & .data$ref_norm %in% doi_not_found ~ "doi_not_found",
        .data$ref_type == "doi" ~ "doi_invalid",
        .data$ref_type == "other" ~ "ref_not_checked",
        TRUE ~ .data$ref_status
      ),
      ref_last_access = dplyr::if_else(
        .data$ref_type == "doi" & !is.null(fetched),
        as.Date(substr(fetched$fetch_info$fetched_at, 1, 10)),
        .data$ref_last_access
      )
    )

  if (!identical(url_check, FALSE)) {
    urls_to_check <- if (isTRUE(url_check)) {
      refs$ref_norm[refs$ref_type == "url"]
    } else {
      extract_urls_with_missing_status(tables, ref_col = ref_col)
    }

    url_checked <- url_check_safe(
      urls = urls_to_check,
      download = url_download,
      archive_dir = archive_dir
    )

    if (nrow(url_checked) > 0) {
      url_status_lookup <- stats::setNames(url_checked$url_status, url_checked$ref_norm)
      url_date <- as.Date(substr(url_checked$checked_at[1], 1, 10))

      refs <- refs %>%
        dplyr::mutate(
          ref_status = dplyr::case_when(
            .data$ref_type == "url" & .data$ref_norm %in% names(url_status_lookup) ~ url_status_lookup[.data$ref_norm],
            .data$ref_type == "url" ~ "url_unchecked",
            TRUE ~ .data$ref_status
          ),
          ref_last_access = dplyr::if_else(
            .data$ref_type == "url" & .data$ref_norm %in% names(url_status_lookup),
            url_date,
            .data$ref_last_access
          )
        )
    }
  }

  refs <- refs %>%
    dplyr::mutate(
      ref_status = dplyr::if_else(
        .data$ref_type == "url" & is.na(.data$ref_status),
        "url_unchecked",
        .data$ref_status
      )
    )

  list(
    refs = refs,
    crossref = crossref_table,
    issues = list(
      doi_missing_in_sheet = doi_missing_in_sheet,
      doi_not_found = doi_not_found,
      pubmed_not_resolved = pubmed_map$pubmed_url[is.na(pubmed_map$doi) | pubmed_map$doi == ""],
      url_not_found = refs$ref_norm[refs$ref_status == "url_not_found"],
      ref_neither_doi_nor_url = refs$ref_original[refs$ref_type == "other"],
      crossref_fetch_info = fetched$fetch_info %||% NULL
    )
  )
}

add_ref_status_to_tables <- function(tables, refs, ref_col = "ref") {
  ref_status_lookup <- refs %>%
    dplyr::select(dplyr::all_of(c("ref_norm", "ref_status", "ref_last_access"))) %>%
    dplyr::filter(!is.na(.data$ref_norm), .data$ref_norm != "") %>%
    dplyr::distinct(.data$ref_norm, .keep_all = TRUE)

  purrr::imap(tables, function(tbl, sheet) {
    if (!ref_col %in% names(tbl)) return(tbl)

    # Drop existing status columns before joining. Otherwise dplyr creates
    # ref_status.x/ref_status.y, and ref_status is no longer available.
    tbl <- tbl %>%
      dplyr::select(-dplyr::any_of(c("ref_status", "ref_last_access")))

    tbl %>%
      dplyr::mutate(ref_norm_tmp = normalise_ref(.data[[ref_col]])) %>%
      dplyr::left_join(
        ref_status_lookup,
        by = c("ref_norm_tmp" = "ref_norm"),
        relationship = "many-to-one"
      ) %>%
      dplyr::select(-dplyr::all_of("ref_norm_tmp")) %>%
      dplyr::relocate(
        dplyr::all_of(c("ref_status", "ref_last_access")),
        .after = dplyr::all_of(ref_col)
      )
  })
}

finalise_tables <- function(tables) {
  tables %>%
    purrr::imap(function(tbl, sheet) {
      tbl <- tbl %>%
        dplyr::mutate(parameter_type = sheet)

      if ("parameter" %in% names(tbl)) {
        tbl <- tbl %>%
          dplyr::mutate(
            parameter = dplyr::if_else(
              is.na(.data$parameter) | stringr::str_trim(as.character(.data$parameter)) == "",
              "Other",
              as.character(.data$parameter)
            )
          )
      }

      tbl %>%
        dplyr::mutate(id = make_parametra_id(dplyr::pick(dplyr::everything()))) %>%
        dplyr::relocate("id", .before = dplyr::everything())
    })
}

make_parametra_long <- function(tables) {
  parametra_long <- dplyr::bind_rows(tables)

  if ("pathogen" %in% names(parametra_long)) {
    parametra_long <- parametra_long %>%
      dplyr::filter(!is.na(.data$pathogen))
  }

  parametra_long
}

warn_parametra_issues <- function(issues) {
  warning_if_non_empty <- function(x, message) {
    if (length(x) > 0) warning(message, call. = FALSE)
  }

  warning_if_non_empty(issues$missing_required_columns, "Missing required columns. See $issues$missing_required_columns.")
  warning_if_non_empty(issues$columns_not_in_lot, "Some column names are not in LOT. See $issues$columns_not_in_lot.")
  warning_if_non_empty(issues$terms_not_in_lot, "Some terms are not in LOT. See $issues$terms_not_in_lot.")
  warning_if_non_empty(issues$lot_columns_not_used, "Some LOT column keys are not used. See $issues$lot_columns_not_used.")
  warning_if_non_empty(issues$non_numeric_value, "Non-numeric value entries found. See $issues$non_numeric_value.")
  warning_if_non_empty(issues$invalid_year, "Invalid year entries found. See $issues$invalid_year.")
  warning_if_non_empty(issues$doi_missing_in_sheet, "Some DOI refs are missing from Crossref. See $issues$doi_missing_in_sheet.")
  warning_if_non_empty(issues$doi_not_found, "Some DOI refs were not found. See $issues$doi_not_found.")
  warning_if_non_empty(issues$pubmed_not_resolved, "Some PubMed refs could not be resolved. See $issues$pubmed_not_resolved.")
  warning_if_non_empty(issues$url_not_found, "Some URLs returned 404/410. See $issues$url_not_found.")
  warning_if_non_empty(issues$ref_neither_doi_nor_url, "Some refs are neither DOI nor URL. See $issues$ref_neither_doi_nor_url.")
}

curate_parametra <- function(
    file,
    lot_sheet = "LOT",
    required_cols = c("parameter", "ref", "filled_by"),
    term_check_cols = c("parameter", "study_type", "pathogen"),
    skip_sheets = DOC_SHEETS,
    crossref = NULL,
    crossref_sheet = "Crossref",
    url_check = NULL,
    url_download = FALSE,
    archive_dir = "data-raw/archive_refs",
    pubmed_resolve = TRUE,
    ref_col = "ref"
) {
  lot <- read_lot(file, lot_sheet = lot_sheet)
  tables <- read_parametra_tables(file, skip_sheets = skip_sheets)

  validation_issues <- validate_parametra_tables(
    tables = tables,
    lot = lot,
    required_cols = required_cols,
    term_check_cols = term_check_cols
  )

  tables <- coerce_numeric_columns(tables)

  ref_lookup <- build_ref_lookup(
    tables = tables,
    file = file,
    crossref = crossref,
    url_check = url_check,
    url_download = url_download,
    archive_dir = archive_dir,
    pubmed_resolve = pubmed_resolve,
    ref_col = ref_col,
    crossref_sheet = crossref_sheet
  )

  tables <- add_ref_status_to_tables(tables, ref_lookup$refs, ref_col = ref_col)
  tables <- finalise_tables(tables)

  parametra_long <- make_parametra_long(tables)

  issues <- c(validation_issues, ref_lookup$issues)
  warn_parametra_issues(issues)

  list(
    lot = lot,
    tables = tables,
    parametra_long = parametra_long,
    crossref = ref_lookup$crossref,
    issues = issues
  )
}

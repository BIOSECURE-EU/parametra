# data-raw/curate_parametra.R
#
# PARAMETRA curation + validation + reference handling
#
# Features implemented:
# - LOT-based column + term validation
# - Required column checks
# - Numeric coercion for `value` (keeps `value_original`)
# - Year validation
# - Crossref enrichment for DOI-like refs (NULL=fetch missing, TRUE=refetch all, FALSE=skip)
#   * Crossref table contains ONLY found rows
#   * Not-found DOIs are stored only in issues$doi_not_found
#   * issues$doi_missing_in_sheet: DOI-like refs not present in Crossref sheet
# - PubMed resolver: pubmed.ncbi.nlm.nih.gov/<pmid>/ -> DOI
#   * issues$pubmed_resolved (tibble pubmed_url, doi)
#   * issues$pubmed_not_resolved (vector of PubMed URLs)
# - URL checker for URL refs (NULL=check URLs missing from Crossref, TRUE=check all URLs, FALSE=skip)
#   * issues$url_checked (tibble)
#   * issues$url_not_found (vector)
# - Refs that are neither DOI nor URL:
#   * issues$ref_neither_doi_nor_url
#   * ref_status = "ref_not_checked"
# - Add to ALL parameter tables (+ parametra_long):
#   * ref_last_access (Date)
#   * ref_status (see below)
#
# ref_status values:
# - DOI refs: "doi_found", "doi_not_found", "doi_invalid"
# - URL refs: "url_ok", "url_not_found", "url_unchecked"
# - Other refs: "ref_not_checked"

suppressPackageStartupMessages({
  library(readxl)
  library(writexl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(rcrossref)
  library(janitor)
  library(tibble)
  library(httr)
})

DOC_SHEETS <- c(
  "README", "ChangesLog", "LOT",
  "Endemic_Pathogens", "Epidemic_Pathogens", "AMR_Pathogens",
  "Crossref"
)

`%||%` <- function(a, b) if (!is.null(a)) a else b

# ------------------------------------------------------------------------------
# Generic helpers
# ------------------------------------------------------------------------------

coerce_all_character <- function(df) {
  if (is.null(df)) return(NULL)
  df %>% dplyr::mutate(dplyr::across(dplyr::everything(), ~ as.character(.)))
}

extract_refs <- function(parametra_long, ref_col = "ref") {
  if (!ref_col %in% names(parametra_long)) return(character(0))
  x <- stringr::str_trim(as.character(parametra_long[[ref_col]]))
  unique(x[!is.na(x) & x != ""])
}

is_valid_year <- function(x) {
  x_chr <- as.character(x)
  ok <- !is.na(x_chr) & stringr::str_detect(x_chr, "^[0-9]{4}$")
  y <- suppressWarnings(as.integer(x_chr))
  ok & !is.na(y) & y >= 1800 & y <= (as.integer(format(Sys.Date(), "%Y")) + 1)
}

# ------------------------------------------------------------------------------
# LOT + Crossref sheet loaders
# ------------------------------------------------------------------------------

read_lot <- function(file, lot_sheet = "LOT") {
  readxl::read_xlsx(file, sheet = lot_sheet) %>%
    janitor::clean_names() %>%
    dplyr::rename(term_type = term_type, key = key, description = description) %>%
    dplyr::mutate(
      term_type = stringr::str_trim(as.character(term_type)),
      key = stringr::str_trim(as.character(key))
    ) %>%
    dplyr::filter(!is.na(term_type), !is.na(key), key != "")
}

read_crossref_sheet <- function(file, sheet = "Crossref") {
  shs <- readxl::excel_sheets(file)
  if (!sheet %in% shs) return(NULL)

  cr <- readxl::read_xlsx(file, sheet = sheet)
  names(cr) <- stringr::str_trim(names(cr))

  if (!"ref" %in% names(cr) && "doi" %in% names(cr)) cr <- dplyr::rename(cr, ref = doi)
  if (!"ref" %in% names(cr)) return(cr)

  cr %>%
    dplyr::mutate(ref = stringr::str_trim(as.character(ref))) %>%
    dplyr::filter(!is.na(ref), ref != "")
}

# ------------------------------------------------------------------------------
# Vector-safe DOI / URL helpers  (IMPORTANT: fixes the length-414 error)
# ------------------------------------------------------------------------------

normalise_doi <- function(x) {
  x <- as.character(x)
  x <- stringr::str_trim(x)

  empty <- is.na(x) | x == ""
  if (all(empty)) return(rep(NA_character_, length(x)))

  x[!empty] <- stringr::str_replace_all(x[!empty], "^doi:\\s*", "")
  x[!empty] <- stringr::str_replace_all(x[!empty], "^https?://(dx\\.)?doi\\.org/", "")
  x[!empty] <- stringr::str_replace_all(x[!empty], "%2F", "/")
  x[!empty] <- stringr::str_replace_all(x[!empty], "\\s+", "")
  x[!empty] <- stringr::str_replace(x[!empty], "[\\.,;\\)\\]]+$", "")

  x[empty] <- NA_character_
  x
}

looks_like_doi <- function(x) {
  x <- normalise_doi(x)
  !is.na(x) & stringr::str_detect(x, "^10\\.[0-9]{4,9}/\\S+$")
}

looks_like_url <- function(x) {
  x <- stringr::str_trim(as.character(x))
  !is.na(x) & stringr::str_detect(x, "^https?://")
}

is_pubmed_url <- function(x) {
  x <- stringr::str_trim(as.character(x))
  !is.na(x) & stringr::str_detect(x, "^https?://pubmed\\.ncbi\\.nlm\\.nih\\.gov/\\d+/?$")
}

# ------------------------------------------------------------------------------
# PubMed -> DOI resolver (single + vector wrapper)
# ------------------------------------------------------------------------------

resolve_pubmed_to_doi_one <- function(
    pubmed_url,
    timeout_sec = 20,
    user_agent = "PARAMETRA-curator/1.0 (httr)"
) {
  if (!isTRUE(is_pubmed_url(pubmed_url))) return(NA_character_)

  html <- tryCatch(
    {
      resp <- httr::GET(
        pubmed_url,
        httr::user_agent(user_agent),
        httr::timeout(timeout_sec),
        httr::followlocation()
      )
      if (httr::status_code(resp) >= 400) return(NA_character_)
      httr::content(resp, as = "text", encoding = "UTF-8")
    },
    error = function(e) NA_character_
  )

  if (is.na(html) || !nzchar(html)) return(NA_character_)

  m <- stringr::str_match(html, "(?i)doi\\s*[:]?\\s*(10\\.[0-9]{4,9}/[^\\s\"'<>]+)")
  if (!is.na(m[1, 2])) return(normalise_doi(m[1, 2]))

  m2 <- stringr::str_match(html, "(?i)doi\\.org/(10\\.[0-9]{4,9}/[^\\s\"'<>]+)")
  if (!is.na(m2[1, 2])) return(normalise_doi(m2[1, 2]))

  NA_character_
}

resolve_pubmed_to_doi <- function(urls, ...) {
  urls <- unique(stringr::str_trim(as.character(urls)))
  urls <- urls[!is.na(urls) & urls != ""]
  urls <- urls[is_pubmed_url(urls)]
  if (length(urls) == 0) return(tibble::tibble(pubmed_url = character(0), doi = character(0)))

  dois <- vapply(urls, resolve_pubmed_to_doi_one, FUN.VALUE = character(1), ...)
  tibble::tibble(pubmed_url = urls, doi = as.character(dois))
}

# ------------------------------------------------------------------------------
# Crossref fetch (safe): returns ONLY found rows + doi_not_found
# ------------------------------------------------------------------------------

fetch_crossref_info_safe <- function(dois) {
  dois_raw <- unique(stringr::str_trim(as.character(dois)))
  dois_raw <- dois_raw[!is.na(dois_raw) & dois_raw != ""]

  dois_norm <- unique(normalise_doi(dois_raw))
  dois_norm <- dois_norm[!is.na(dois_norm) & dois_norm != ""]
  dois_norm <- unique(dois_norm[looks_like_doi(dois_norm)])

  fetch_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  if (length(dois_norm) == 0) {
    return(list(
      crossref = tibble::tibble(),
      doi_not_found = character(0),
      fetch_info = list(fetched_at = fetch_time, n_requested = 0, n_returned = 0)
    ))
  }

  res <- tryCatch(rcrossref::cr_works(dois = dois_norm), error = function(e) NULL)

  if (is.null(res) || is.null(res$data)) {
    return(list(
      crossref = tibble::tibble(),
      doi_not_found = dois_norm,
      fetch_info = list(fetched_at = fetch_time, n_requested = length(dois_norm), n_returned = 0)
    ))
  }

  crossref_raw <- tryCatch(purrr::pluck(res$data), error = function(e) NULL)

  if (is.null(crossref_raw) || (is.data.frame(crossref_raw) && nrow(crossref_raw) == 0)) {
    return(list(
      crossref = tibble::tibble(),
      doi_not_found = dois_norm,
      fetch_info = list(fetched_at = fetch_time, n_requested = length(dois_norm), n_returned = 0)
    ))
  }

  doi_col_candidates <- intersect(c("DOI", "doi", "ref"), names(crossref_raw))
  found <- character(0)
  if (length(doi_col_candidates) > 0) {
    found <- unique(stringr::str_trim(as.character(crossref_raw[[doi_col_candidates[1]]])))
    found <- found[!is.na(found) & found != ""]
    found <- unique(normalise_doi(found))
    found <- found[!is.na(found) & found != ""]
  }

  doi_not_found <- setdiff(dois_norm, found)

  crossref_flat <- crossref_raw %>%
    dplyr::mutate(dplyr::across(where(is.list), ~ as.character(.))) %>%
    dplyr::mutate(
      fetched_at = fetch_time,
      fetch_status = "found"
    )

  if ("DOI" %in% names(crossref_flat)) {
    crossref_flat <- crossref_flat %>%
      dplyr::mutate(ref = normalise_doi(.data$DOI))
  } else if ("ref" %in% names(crossref_flat)) {
    crossref_flat <- crossref_flat %>%
      dplyr::mutate(ref = normalise_doi(.data$ref))
  }

  if ("ref" %in% names(crossref_flat)) {
    crossref_flat <- crossref_flat %>% dplyr::filter(!is.na(ref), ref != "")
  }

  list(
    crossref = crossref_flat,
    doi_not_found = doi_not_found,
    fetch_info = list(
      fetched_at = fetch_time,
      n_requested = length(dois_norm),
      n_returned = if (is.data.frame(crossref_raw)) nrow(crossref_raw) else NA_integer_
    )
  )
}

# ------------------------------------------------------------------------------
# URL checker (safe) + optional download
# ------------------------------------------------------------------------------

url_check_safe <- function(
    urls,
    timeout_sec = 15,
    user_agent = "PARAMETRA-curator/1.0 (httr)",
    download = FALSE,
    archive_dir = "data-raw/archive_refs"
) {
  urls <- unique(stringr::str_trim(as.character(urls)))
  urls <- urls[!is.na(urls) & urls != ""]
  urls <- urls[looks_like_url(urls)]
  if (length(urls) == 0) return(tibble::tibble())

  if (isTRUE(download)) dir.create(archive_dir, recursive = TRUE, showWarnings = FALSE)
  check_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  check_one <- function(u) {
    resp_head <- tryCatch(
      httr::HEAD(u, httr::user_agent(user_agent), httr::timeout(timeout_sec), httr::followlocation()),
      error = function(e) NULL
    )

    status <- NA_integer_
    ct <- NA_character_

    if (!is.null(resp_head)) {
      status <- httr::status_code(resp_head)
      ct <- httr::headers(resp_head)[["content-type"]]
    } else {
      resp_get <- tryCatch(
        httr::GET(u, httr::user_agent(user_agent), httr::timeout(timeout_sec), httr::followlocation()),
        error = function(e) NULL
      )
      if (!is.null(resp_get)) {
        status <- httr::status_code(resp_get)
        ct <- httr::headers(resp_get)[["content-type"]]
      }
    }

    is_pdf <- FALSE
    if (!is.na(ct) && stringr::str_detect(tolower(ct), "application/pdf")) is_pdf <- TRUE
    if (stringr::str_detect(tolower(u), "\\.pdf($|\\?)")) is_pdf <- TRUE
    kind <- ifelse(is_pdf, "pdf", "web")

    archived_path <- NA_character_
    download_status <- NA_character_

    if (isTRUE(download) && identical(kind, "pdf") && !is.na(status) && status >= 200 && status < 400) {
      safe_stub <- gsub("[^A-Za-z0-9]+", "_", u)
      safe_stub <- substr(safe_stub, 1, 120)
      dest <- file.path(archive_dir, paste0(safe_stub, ".pdf"))

      dl_ok <- tryCatch({
        utils::download.file(u, destfile = dest, mode = "wb", quiet = TRUE)
        TRUE
      }, error = function(e) FALSE)

      if (isTRUE(dl_ok) && file.exists(dest)) {
        archived_path <- dest
        download_status <- "downloaded"
      } else {
        download_status <- "download_failed"
      }
    }

    tibble::tibble(
      ref = u,
      url_status = status,
      content_type = ct,
      url_kind = kind,
      checked_at = check_time,
      archived_path = archived_path,
      download_status = download_status
    )
  }

  purrr::map_dfr(urls, check_one)
}

# ------------------------------------------------------------------------------
# MAIN
# ------------------------------------------------------------------------------

curate_parametra <- function(
    file,
    lot_sheet = "LOT",
    required_cols = c("parameter", "ref", "filled_by"),
    term_check_cols = c("parameter", "study_type", "pathogen"),
    skip_sheets = DOC_SHEETS,

    crossref = NULL,                # NULL(default)=fetch missing DOI-like; TRUE=fetch all DOI-like; FALSE=skip fetch
    crossref_sheet = "Crossref",
    ref_col = "ref",

    url_check = NULL,               # NULL(default)=check URL refs missing in Crossref; TRUE=check all URLs; FALSE=skip
    url_download = FALSE,
    archive_dir = "data-raw/archive_refs",

    pubmed_resolve = TRUE
) {

  lot <- read_lot(file, lot_sheet = lot_sheet)

  lot_columns <- lot %>%
    dplyr::filter(term_type == "column") %>%
    dplyr::pull(key) %>%
    unique()

  sheet_names <- setdiff(readxl::excel_sheets(file), skip_sheets)

  issues <- list(
    missing_required_columns = list(),
    columns_not_in_lot = list(),
    lot_columns_not_used = character(0),
    terms_not_in_lot = list(),
    non_numeric_value = list(),
    invalid_year = list(),

    crossref_missing_in_sheet = character(0),
    doi_missing_in_sheet = character(0),
    doi_not_found = character(0),
    crossref_sheet_problem = NULL,
    crossref_fetch_info = NULL,

    pubmed_resolved = NULL,        # tibble(pubmed_url, doi)
    pubmed_not_resolved = character(0),

    url_checked = NULL,            # tibble
    url_check_fetch_info = NULL,
    url_not_found = character(0),

    ref_neither_doi_nor_url = character(0)
  )

  tables <- list()
  used_columns <- character(0)

  for (sh in sheet_names) {
    tbl <- readxl::read_xlsx(file, sheet = sh)
    names(tbl) <- stringr::str_trim(names(tbl))

    # drop fully empty rows
    tbl <- tbl[rowSums(is.na(tbl)) != ncol(tbl), , drop = FALSE]

    used_columns <- union(used_columns, names(tbl))

    # Required columns
    missing_cols <- setdiff(required_cols, names(tbl))
    if (length(missing_cols) > 0) issues$missing_required_columns[[sh]] <- missing_cols

    # Column-name-in-LOT
    bad_cols <- setdiff(names(tbl), lot_columns)
    if (length(bad_cols) > 0) issues$columns_not_in_lot[[sh]] <- bad_cols

    # Term checks
    cols_to_check <- intersect(term_check_cols, names(tbl))
    for (col in cols_to_check) {
      x_chr <- stringr::str_trim(as.character(tbl[[col]]))
      x_chr <- x_chr[!is.na(x_chr) & x_chr != ""]
      if (length(x_chr) == 0) next

      allowed_terms <- lot %>%
        dplyr::filter(term_type == col) %>%
        dplyr::pull(key) %>%
        unique()

      not_in_lot <- setdiff(unique(x_chr), allowed_terms)
      not_in_lot <- setdiff(not_in_lot, "O")

      if (length(not_in_lot) > 0) {
        issues$terms_not_in_lot[[paste0(sh, "::", col)]] <- not_in_lot
      }
    }

    # value numeric coercion
    if ("value" %in% names(tbl)) {
      value_orig <- tbl$value
      value_num <- suppressWarnings(as.numeric(value_orig))
      bad_value_idx <- which(!is.na(value_orig) & value_orig != "" & is.na(value_num))

      if (length(bad_value_idx) > 0) {
        issues$non_numeric_value[[sh]] <- list(
          n = length(bad_value_idx),
          examples = unique(head(as.character(value_orig[bad_value_idx]), 10))
        )
      }

      tbl <- tbl %>% dplyr::mutate(value_original = value, value = value_num)
    }

    # year validity
    if ("year" %in% names(tbl)) {
      bad_year_idx <- which(!is.na(tbl$year) & as.character(tbl$year) != "" & !is_valid_year(tbl$year))
      if (length(bad_year_idx) > 0) {
        issues$invalid_year[[sh]] <- list(
          n = length(bad_year_idx),
          examples = unique(head(as.character(tbl$year[bad_year_idx]), 10))
        )
      }
    }

    # identifiers + ref tracking columns
    tbl <- tbl %>%
      dplyr::mutate(
        parameter_type = sh,
        id = paste0(parameter_type, "*", dplyr::row_number()),
        ref_last_access = as.Date(NA),
        ref_status = NA_character_
      )

    tables[[sh]] <- tbl
  }

  issues$lot_columns_not_used <- setdiff(lot_columns, used_columns)

  parametra_long <- dplyr::bind_rows(tables)

  if ("pathogen" %in% names(parametra_long)) {
    parametra_long <- parametra_long %>% dplyr::filter(!is.na(pathogen))
  }

  if ("parameter" %in% names(parametra_long)) {
    parametra_long <- parametra_long %>%
      dplyr::mutate(parameter = dplyr::if_else(
        is.na(parameter) | stringr::str_trim(as.character(parameter)) == "",
        "Other",
        as.character(parameter)
      ))
  }

  # ---------------------------------------------------------------------------
  # Refs + PubMed resolution
  # ---------------------------------------------------------------------------
  refs_raw <- extract_refs(parametra_long, ref_col = ref_col)

  pubmed_map <- tibble::tibble(pubmed_url = character(0), doi = character(0))
  if (isTRUE(pubmed_resolve)) {
    pubmed_map <- resolve_pubmed_to_doi(refs_raw)
    issues$pubmed_resolved <- pubmed_map
    issues$pubmed_not_resolved <- pubmed_map$pubmed_url[is.na(pubmed_map$doi) | pubmed_map$doi == ""]
  }
  pubmed_lookup <- setNames(pubmed_map$doi, pubmed_map$pubmed_url)

  # Normalised refs for logic:
  # - PubMed URL with resolved DOI -> use DOI
  # - DOI-like -> normalise
  # - URL -> keep URL
  # - other -> keep as-is
  refs_norm <- vapply(refs_raw, function(x) {
    x0 <- stringr::str_trim(as.character(x))
    if (is.na(x0) || x0 == "") return(NA_character_)

    if (isTRUE(pubmed_resolve) && isTRUE(is_pubmed_url(x0))) {
      doi_r <- pubmed_lookup[[x0]]
      if (!is.null(doi_r) && !is.na(doi_r) && doi_r != "") return(normalise_doi(doi_r))
    }

    if (isTRUE(looks_like_doi(x0))) return(normalise_doi(x0))
    x0
  }, FUN.VALUE = character(1))

  refs_norm <- unique(refs_norm[!is.na(refs_norm) & refs_norm != ""])
  issues$ref_neither_doi_nor_url <- refs_norm[!(looks_like_doi(refs_norm) | looks_like_url(refs_norm))]

  # ---------------------------------------------------------------------------
  # Crossref compare + fetch (DOIs only)
  # ---------------------------------------------------------------------------
  existing_crossref <- read_crossref_sheet(file, sheet = crossref_sheet)
  if (!is.null(existing_crossref) && !("ref" %in% names(existing_crossref))) {
    issues$crossref_sheet_problem <- paste0("Crossref sheet '", crossref_sheet, "' has no 'ref' (or 'doi') column.")
  }

  sheet_refs <- if (!is.null(existing_crossref) && "ref" %in% names(existing_crossref)) {
    sr <- stringr::str_trim(as.character(existing_crossref$ref))
    sr <- unique(normalise_doi(sr))
    sr <- sr[!is.na(sr) & sr != ""]
    sr
  } else {
    character(0)
  }

  issues$crossref_missing_in_sheet <- setdiff(refs_norm, sheet_refs)
  issues$doi_missing_in_sheet <- issues$crossref_missing_in_sheet[looks_like_doi(issues$crossref_missing_in_sheet)]

  crossref_table <- existing_crossref

  doi_found <- character(0)
  doi_not_found <- character(0)
  fetched_at_date <- as.Date(NA)

  if (!identical(crossref, FALSE)) {
    dois_to_fetch <- if (isTRUE(crossref)) {
      refs_norm[looks_like_doi(refs_norm)]
    } else {
      issues$doi_missing_in_sheet
    }

    fetched <- fetch_crossref_info_safe(dois_to_fetch)
    issues$doi_not_found <- fetched$doi_not_found
    issues$crossref_fetch_info <- fetched$fetch_info

    doi_found <- if (!is.null(fetched$crossref) && nrow(fetched$crossref) > 0 && "ref" %in% names(fetched$crossref)) {
      unique(stringr::str_trim(as.character(fetched$crossref$ref)))
    } else character(0)

    doi_not_found <- fetched$doi_not_found
    fetched_at_date <- as.Date(substr(fetched$fetch_info$fetched_at, 1, 10))

    # Crossref table: only found rows
    if (isTRUE(crossref)) {
      crossref_table <- fetched$crossref
    } else {
      crossref_table <- dplyr::bind_rows(
        coerce_all_character(existing_crossref),
        coerce_all_character(fetched$crossref)
      )
      if (!is.null(crossref_table) && "ref" %in% names(crossref_table)) {
        crossref_table <- crossref_table %>% dplyr::distinct(ref, .keep_all = TRUE)
      }
    }
  }

  # ---------------------------------------------------------------------------
  # URL check
  # ---------------------------------------------------------------------------
  urls_to_check <- character(0)
  url_checked_tbl <- tibble::tibble()
  url_checked_date <- as.Date(NA)

  if (!identical(url_check, FALSE)) {
    if (isTRUE(url_check)) {
      urls_to_check <- refs_norm[looks_like_url(refs_norm)]
    } else {
      urls_to_check <- issues$crossref_missing_in_sheet[looks_like_url(issues$crossref_missing_in_sheet)]
    }

    url_checked_tbl <- url_check_safe(
      urls = urls_to_check,
      download = url_download,
      archive_dir = archive_dir
    )

    issues$url_checked <- url_checked_tbl

    if (nrow(url_checked_tbl) > 0) {
      url_checked_date <- as.Date(substr(url_checked_tbl$checked_at[1], 1, 10))
      issues$url_not_found <- unique(url_checked_tbl$ref[
        is.na(url_checked_tbl$url_status) | url_checked_tbl$url_status >= 400
      ])
    } else {
      issues$url_not_found <- character(0)
    }

    issues$url_check_fetch_info <- list(
      checked_at = if (nrow(url_checked_tbl) > 0) url_checked_tbl$checked_at[1] else format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
      n_urls = length(urls_to_check),
      n_ok = if (nrow(url_checked_tbl) > 0) sum(!is.na(url_checked_tbl$url_status) & url_checked_tbl$url_status >= 200 & url_checked_tbl$url_status < 400) else 0,
      n_pdf = if (nrow(url_checked_tbl) > 0) sum(url_checked_tbl$url_kind == "pdf", na.rm = TRUE) else 0
    )
  }

  url_ok <- if (nrow(url_checked_tbl) > 0) {
    unique(url_checked_tbl$ref[!is.na(url_checked_tbl$url_status) & url_checked_tbl$url_status >= 200 & url_checked_tbl$url_status < 400])
  } else character(0)

  # ---------------------------------------------------------------------------
  # Fill ref_last_access + ref_status into all tables + parametra_long
  # ---------------------------------------------------------------------------

  classify_ref_status <- function(ref_value) {
    rv0 <- stringr::str_trim(as.character(ref_value))
    if (is.na(rv0) || rv0 == "") return(NA_character_)

    # map PubMed -> DOI (for status)
    rv <- rv0
    if (isTRUE(pubmed_resolve) && isTRUE(is_pubmed_url(rv))) {
      doi_r <- pubmed_lookup[[rv]]
      if (!is.null(doi_r) && !is.na(doi_r) && doi_r != "") rv <- as.character(normalise_doi(doi_r))[1]
    }

    if (isTRUE(looks_like_doi(rv))) rv <- as.character(normalise_doi(rv))[1]

    if (isTRUE(looks_like_doi(rv))) {
      if (rv %in% doi_found) return("doi_found")
      if (rv %in% doi_not_found) return("doi_not_found")
      return("doi_invalid")
    }

    if (isTRUE(looks_like_url(rv))) {
      if (rv %in% url_ok) return("url_ok")
      if (rv %in% issues$url_not_found) return("url_not_found")
      return("url_unchecked")
    }

    "ref_not_checked"
  }

  last_access_for_ref <- function(ref_value) {
    rv0 <- stringr::str_trim(as.character(ref_value))
    if (is.na(rv0) || rv0 == "") return(as.Date(NA))

    rv <- rv0
    if (isTRUE(pubmed_resolve) && isTRUE(is_pubmed_url(rv))) {
      doi_r <- pubmed_lookup[[rv]]
      if (!is.null(doi_r) && !is.na(doi_r) && doi_r != "") rv <- as.character(normalise_doi(doi_r))[1]
    }

    if (isTRUE(looks_like_doi(rv))) return(fetched_at_date)
    if (isTRUE(looks_like_url(rv))) return(url_checked_date)
    as.Date(NA)
  }

  tables <- purrr::imap(tables, function(tbl, sh) {
    if (!ref_col %in% names(tbl)) return(tbl)

    # Ensure ref is a plain character vector (not list-col)
    tbl[[ref_col]] <- as.character(unlist(tbl[[ref_col]]))

    rs <- vapply(tbl[[ref_col]], classify_ref_status, FUN.VALUE = character(1))
    rl <- vapply(tbl[[ref_col]], function(x) as.character(last_access_for_ref(x)), FUN.VALUE = character(1))

    tbl <- tbl %>%
      dplyr::mutate(
        ref_status = unname(rs),
        ref_last_access = as.Date(unname(rl))
      ) %>%
      dplyr::relocate(ref_status, ref_last_access, .after = dplyr::all_of(ref_col))

    tbl
  })

  if (ref_col %in% names(parametra_long)) {
    parametra_long[[ref_col]] <- as.character(unlist(parametra_long[[ref_col]]))

    rs <- vapply(parametra_long[[ref_col]], classify_ref_status, FUN.VALUE = character(1))
    rl <- vapply(parametra_long[[ref_col]], function(x) as.character(last_access_for_ref(x)), FUN.VALUE = character(1))

    parametra_long <- parametra_long %>%
      dplyr::mutate(
        ref_status = unname(rs),
        ref_last_access = as.Date(unname(rl))
      ) %>%
      dplyr::relocate(ref_status, ref_last_access, .after = dplyr::all_of(ref_col))
  }
  # ---------------------------------------------------------------------------
  # Warnings
  # ---------------------------------------------------------------------------
  if (length(issues$missing_required_columns) > 0) warning("Missing required columns in some sheets. See $issues$missing_required_columns")
  if (length(issues$columns_not_in_lot) > 0) warning("Some column names are not in LOT. See $issues$columns_not_in_lot")
  if (length(issues$terms_not_in_lot) > 0) warning("Some terms are not in LOT. See $issues$terms_not_in_lot")
  if (length(issues$lot_columns_not_used) > 0) warning("Some LOT 'column' keys are not used. See $issues$lot_columns_not_used")
  if (length(issues$non_numeric_value) > 0) warning("Non-numeric 'value' entries found. See $issues$non_numeric_value")
  if (length(issues$invalid_year) > 0) warning("Invalid 'year' entries found. See $issues$invalid_year")

  if (length(issues$crossref_missing_in_sheet) > 0) warning("Some refs are missing from the Crossref sheet. See $issues$crossref_missing_in_sheet")
  if (length(issues$doi_missing_in_sheet) > 0) warning("Some DOI-like refs are missing from the Crossref sheet. See $issues$doi_missing_in_sheet")
  if (length(issues$doi_not_found) > 0) warning("Some DOI-like refs were queried but not found. See $issues$doi_not_found")
  if (!is.null(issues$crossref_sheet_problem)) warning(issues$crossref_sheet_problem)

  if (!is.null(issues$url_checked) && nrow(issues$url_checked) > 0) warning("URL check completed. See $issues$url_checked (and $issues$url_check_fetch_info).")
  if (length(issues$url_not_found) > 0) warning("Some URLs were not accessible. See $issues$url_not_found")
  if (length(issues$ref_neither_doi_nor_url) > 0) warning("Some refs are neither DOI nor URL. See $issues$ref_neither_doi_nor_url")

  list(
    lot = lot,
    tables = tables,
    parametra_long = parametra_long,
    crossref = crossref_table,
    issues = issues
  )
}

# ------------------------------------------------------------------------------
# Backup + write outputs
# ------------------------------------------------------------------------------

backup_and_write_outputs <- function(
    file,
    curated,
    out_dir = "data-raw/tables",
    out_long = "data-raw/parametra_long.csv",
    backup_dir = "data-raw/backups",
    write_excel_updated = FALSE,
    crossref_sheet = "Crossref"
) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(backup_dir, recursive = TRUE, showWarnings = FALSE)

  ts <- format(Sys.time(), "%Y%m%d-%H%M%S")
  backup_file <- file.path(backup_dir, paste0("parametra_backup_", ts, ".xlsx"))
  file.copy(file, backup_file, overwrite = FALSE)

  purrr::iwalk(curated$tables, function(tbl, sh) {
    out_csv <- file.path(out_dir, paste0("parametra_", sh, ".csv"))
    write.csv(tbl, out_csv, row.names = FALSE)
  })

  write.csv(curated$parametra_long, out_long, row.names = FALSE)

  if (isTRUE(write_excel_updated)) {
    new_xlsx <- file.path("data-raw", paste0("parametra_curated_", ts, ".xlsx"))
    sheets_out <- curated$tables
    if (!is.null(sheets_out[[crossref_sheet]]) && "reference" %in% names(sheets_out[[crossref_sheet]])) {
      sheets_out[[crossref_sheet]] <- dplyr::select(sheets_out[[crossref_sheet]], -reference)
    }
    if (!is.null(curated$crossref)) sheets_out[[crossref_sheet]] <- curated$crossref
    writexl::write_xlsx(sheets_out, path = new_xlsx)
  }

  invisible(list(backup = backup_file))
}

# ------------------------------------------------------------------------------
# Example run
# ------------------------------------------------------------------------------
# path <- "data-raw/parametra-2026-06-01_EB_NC.xlsx"
# curated <- curate_parametra(
#   path,
#   crossref = NULL,         # NULL=fetch missing DOIs; TRUE=refetch all DOIs; FALSE=no fetch
#   url_check = NULL,        # NULL=check URL refs missing in Crossref; TRUE=check all URLs; FALSE=skip
#   url_download = FALSE,    # TRUE downloads PDFs into archive_dir
#   archive_dir = "data-raw/archive_refs",
#   pubmed_resolve = TRUE
# )
#
# curated$issues$doi_not_found
# curated$issues$url_not_found
# curated$issues$ref_neither_doi_nor_url
# curated$issues$pubmed_not_resolved
#
# backup_and_write_outputs(path, curated, write_excel_updated = TRUE)

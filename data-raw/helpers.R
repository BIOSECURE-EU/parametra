# Helper functions for PARAMETRA data maintenance.

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(stringr)
  library(purrr)
  library(tibble)
  library(httr)
  library(rcrossref)
  library(janitor)
})

DOC_SHEETS <- c(
  "README", "CHANGELOG", "LOT",
  "crossref"
)

# Compatibility with old R versions
`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

package_version_label <- function(prefix = "PARAMETRAv", description_file = "DESCRIPTION") {
  if (!file.exists(description_file)) return(paste0(prefix, "unknown"))

  desc <- tryCatch(
    utils::read.dcf(description_file),
    error = function(e) NULL
  )

  if (is.null(desc) || !"Version" %in% colnames(desc)) {
    return(paste0(prefix, "unknown"))
  }

  paste0(prefix, desc[1, "Version"])
}

coerce_all_character <- function(df) {
  if (is.null(df)) return(NULL)

  df %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
}

is_valid_year <- function(x) {
  x_chr <- as.character(x)
  valid_format <- !is.na(x_chr) & stringr::str_detect(x_chr, "^[0-9]{4}$")
  year <- suppressWarnings(as.integer(x_chr))

  valid_format &
    !is.na(year) &
    year >= 1800 &
    year <= as.integer(format(Sys.Date(), "%Y")) + 1
}

normalise_doi <- function(x) {
  x <- stringr::str_trim(as.character(x))
  empty <- is.na(x) | x == ""

  if (all(empty)) return(rep(NA_character_, length(x)))

  x[!empty] <- x[!empty] %>%
    stringr::str_replace_all(regex("^doi:\\s*", ignore_case = TRUE), "") %>%
    stringr::str_replace_all(regex("^https?://(dx\\.)?doi\\.org/", ignore_case = TRUE), "") %>%
    stringr::str_replace_all("%2F", "/") %>%
    stringr::str_replace_all("\\s+", "") %>%
    stringr::str_replace("[\\.,;\\)\\]]+$", "") %>%
    stringr::str_to_lower()

  x[empty] <- NA_character_
  x
}

looks_like_doi <- function(x) {
  x <- normalise_doi(x)
  !is.na(x) & stringr::str_detect(x, "^10\\.[0-9]{4,9}/\\S+$")
}

normalise_url <- function(x) {
  x <- stringr::str_trim(as.character(x))
  empty <- is.na(x) | x == ""

  x[!empty] <- x[!empty] %>%
    stringr::str_replace_all("\\s+", "") %>%
    stringr::str_replace("#.*$", "") %>%
    stringr::str_replace("/+$", "") %>%
    stringr::str_replace(regex("^http://", ignore_case = TRUE), "https://") %>%
    stringr::str_to_lower()

  x[empty] <- NA_character_
  x
}

looks_like_url <- function(x) {
  x <- stringr::str_trim(as.character(x))
  !is.na(x) & stringr::str_detect(x, "^https?://")
}

is_pubmed_url <- function(x) {
  x <- stringr::str_trim(as.character(x))
  !is.na(x) & stringr::str_detect(x, "^https?://pubmed\\.ncbi\\.nlm\\.nih\\.gov/\\d+/?$")
}

normalise_ref <- function(ref, pubmed_lookup = NULL) {
  ref <- stringr::str_trim(as.character(ref))

  purrr::map_chr(ref, function(x) {
    if (is.na(x) || x == "") return(NA_character_)

    if (!is.null(pubmed_lookup) && isTRUE(is_pubmed_url(x))) {
      doi <- pubmed_lookup[[x]]
      if (!is.null(doi) && !is.na(doi) && doi != "") return(normalise_doi(doi))
    }

    if (isTRUE(looks_like_doi(x))) return(normalise_doi(x))
    if (isTRUE(looks_like_url(x))) return(normalise_url(x))

    x
  })
}

read_lot <- function(file, lot_sheet = "LOT") {
  readxl::read_xlsx(file, sheet = lot_sheet) %>%
    janitor::clean_names() %>%
    dplyr::mutate(
      term_type = stringr::str_trim(as.character(.data$term_type)),
      key = stringr::str_trim(as.character(.data$key)),
      description = as.character(.data$description)
    ) %>%
    dplyr::filter(!is.na(.data$term_type), !is.na(.data$key), .data$key != "")
}

read_crossref_sheet <- function(file, sheet = "crossref") {
  if (!sheet %in% readxl::excel_sheets(file)) return(NULL)

  crossref <- readxl::read_xlsx(file, sheet = sheet)
  names(crossref) <- stringr::str_trim(names(crossref))

  if (!"ref" %in% names(crossref) && "doi" %in% names(crossref)) {
    crossref <- dplyr::rename(crossref, ref = doi)
  }

  if (!"ref" %in% names(crossref)) return(crossref)

  crossref %>%
    dplyr::mutate(ref = normalise_doi(.data$ref)) %>%
    dplyr::filter(!is.na(.data$ref), .data$ref != "")
}

read_parametra_tables <- function(file, skip_sheets = DOC_SHEETS) {
  sheet_names <- setdiff(readxl::excel_sheets(file), skip_sheets)

  purrr::set_names(sheet_names) %>%
    purrr::map(function(sheet) {
      tbl <- readxl::read_xlsx(file, sheet = sheet, col_types = "text")
      names(tbl) <- stringr::str_trim(names(tbl))
      tbl[rowSums(is.na(tbl)) != ncol(tbl), , drop = FALSE]
    })
}

extract_refs <- function(tables, ref_col = "ref") {
  tables %>%
    purrr::map(function(tbl) {
      if (!ref_col %in% names(tbl)) return(character(0))

      refs <- stringr::str_trim(as.character(tbl[[ref_col]]))
      refs[!is.na(refs) & refs != ""]
    }) %>%
    unlist(use.names = FALSE) %>%
    unique()
}

extract_urls_with_missing_status <- function(tables, ref_col = "ref", status_col = "ref_status") {
  tables %>%
    purrr::map(function(tbl) {
      if (!ref_col %in% names(tbl)) return(character(0))

      ref <- stringr::str_trim(as.character(tbl[[ref_col]]))
      status <- if (status_col %in% names(tbl)) {
        stringr::str_trim(as.character(tbl[[status_col]]))
      } else {
        rep(NA_character_, length(ref))
      }

      missing_status <- is.na(status) |
        status == "" |
        status %in% c("NA", "url_unchecked", "ref_not_checked")

      normalise_url(ref[looks_like_url(ref) & missing_status])
    }) %>%
    unlist(use.names = FALSE) %>%
    unique()
}

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

  doi <- stringr::str_match(html, "(?i)doi\\s*:?\\s*(10\\.[0-9]{4,9}/[^\\s\"'<>]+)")[1, 2]

  if (is.na(doi)) {
    doi <- stringr::str_match(html, "(?i)doi\\.org/(10\\.[0-9]{4,9}/[^\\s\"'<>]+)")[1, 2]
  }

  if (is.na(doi)) NA_character_ else normalise_doi(doi)
}

resolve_pubmed_to_doi <- function(urls, ...) {
  urls <- unique(stringr::str_trim(as.character(urls)))
  urls <- urls[!is.na(urls) & urls != "" & is_pubmed_url(urls)]

  if (length(urls) == 0) {
    return(tibble::tibble(pubmed_url = character(0), doi = character(0)))
  }

  tibble::tibble(
    pubmed_url = urls,
    doi = vapply(urls, resolve_pubmed_to_doi_one, FUN.VALUE = character(1), ...)
  )
}

fetch_crossref_info_safe <- function(dois) {
  dois <- unique(normalise_doi(dois))
  dois <- dois[!is.na(dois) & dois != "" & looks_like_doi(dois)]

  fetched_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  if (length(dois) == 0) {
    return(list(
      crossref = tibble::tibble(),
      doi_not_found = character(0),
      fetch_info = list(fetched_at = fetched_at, n_requested = 0, n_returned = 0)
    ))
  }

  res <- tryCatch(rcrossref::cr_works(dois = dois), error = function(e) NULL)

  if (is.null(res) || is.null(res$data) || nrow(res$data) == 0) {
    return(list(
      crossref = tibble::tibble(),
      doi_not_found = dois,
      fetch_info = list(fetched_at = fetched_at, n_requested = length(dois), n_returned = 0)
    ))
  }

  doi_col <- intersect(c("DOI", "doi", "ref"), names(res$data))[1]

  crossref <- res$data %>%
    dplyr::mutate(dplyr::across(where(is.list), as.character)) %>%
    dplyr::mutate(
      ref = normalise_doi(.data[[doi_col]]),
      fetched_at = fetched_at,
      fetch_status = "found"
    ) %>%
    dplyr::filter(!is.na(.data$ref), .data$ref != "") %>%
    dplyr::distinct(.data$ref, .keep_all = TRUE)

  list(
    crossref = crossref,
    doi_not_found = setdiff(dois, crossref$ref),
    fetch_info = list(
      fetched_at = fetched_at,
      n_requested = length(dois),
      n_returned = nrow(crossref)
    )
  )
}

url_check_safe <- function(
    urls,
    timeout_sec = 20,
    user_agent = "Mozilla/5.0 (compatible; PARAMETRA-curator/1.0)",
    download = FALSE,
    archive_dir = "data-raw/archive_refs"
) {
  urls <- unique(normalise_url(urls))
  urls <- urls[!is.na(urls) & urls != "" & looks_like_url(urls)]

  if (length(urls) == 0) return(tibble::tibble())

  if (isTRUE(download)) {
    dir.create(archive_dir, recursive = TRUE, showWarnings = FALSE)
  }

  checked_at <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  check_one <- function(url) {
    request_url <- utils::URLencode(url, reserved = TRUE)

    fetch <- function(verb) {
      tryCatch(
        {
          request <- switch(verb, HEAD = httr::HEAD, GET = httr::GET)

          request(
            request_url,
            httr::user_agent(user_agent),
            httr::add_headers(
              Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,application/pdf,*/*;q=0.8",
              `Accept-Language` = "en-US,en;q=0.9"
            ),
            httr::timeout(timeout_sec),
            httr::config(followlocation = TRUE, ssl_verifypeer = FALSE)
          )
        },
        error = function(e) NULL
      )
    }

    resp <- fetch("HEAD")
    status <- if (!is.null(resp)) httr::status_code(resp) else NA_integer_

    if (is.null(resp) || is.na(status) || status >= 400 || status %in% c(405L, 429L)) {
      Sys.sleep(0.25)
      resp <- fetch("GET")
      status <- if (!is.null(resp)) httr::status_code(resp) else NA_integer_
    }

    content_type <- if (!is.null(resp)) httr::headers(resp)[["content-type"]] else NA_character_
    is_pdf <- !is.na(content_type) && stringr::str_detect(tolower(content_type), "application/pdf")
    is_pdf <- is_pdf || stringr::str_detect(tolower(url), "\\.pdf($|\\?)")

    tibble::tibble(
      ref = url,
      ref_norm = normalise_url(url),
      http_status = status,
      url_status = dplyr::case_when(
        !is.na(status) & status >= 200 & status < 400 ~ "url_ok",
        !is.na(status) & status %in% c(404L, 410L) ~ "url_not_found",
        !is.na(status) & status %in% c(401L, 403L) ~ "url_access_restricted",
        !is.na(status) & status == 429L ~ "url_rate_limited",
        !is.na(status) & status >= 500 ~ "url_server_error",
        TRUE ~ "url_check_failed"
      ),
      content_type = content_type,
      url_kind = ifelse(is_pdf, "pdf", "web"),
      checked_at = checked_at
    )
  }

  purrr::map_dfr(urls, check_one)
}

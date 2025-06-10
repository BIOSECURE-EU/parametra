#' CrossRef Metadata for Parametra References
#'
#' A dataset containing metadata extracted from CrossRef using the rcrossref package
#' for scientific publications referenced in the parametra_long dataset.
#'
#' @format A data frame with 38 variables:
#' \describe{
#'   \item{container.title}{Title of the containing publication (e.g., journal name)}
#'   \item{created}{Creation date of the CrossRef record}
#'   \item{deposited}{Date the record was deposited in CrossRef}
#'   \item{published.print}{Print publication date}
#'   \item{doi}{Digital Object Identifier}
#'   \item{indexed}{Date the record was indexed}
#'   \item{issn}{International Standard Serial Number}
#'   \item{issue}{Issue number of the publication}
#'   \item{issued}{Date of issue}
#'   \item{member}{CrossRef member ID}
#'   \item{page}{Page numbers}
#'   \item{prefix}{DOI prefix}
#'   \item{publisher}{Name of the publisher}
#'   \item{score}{Relevance score}
#'   \item{source}{Source of the metadata}
#'   \item{reference.count}{Number of references}
#'   \item{references.count}{Count of references}
#'   \item{is.referenced.by.count}{Number of times cited}
#'   \item{title}{Title of the publication}
#'   \item{type}{Type of publication}
#'   \item{url}{URL of the publication}
#'   \item{volume}{Volume number}
#'   \item{abstract}{Publication abstract}
#'   \item{short.container.title}{Abbreviated container title}
#'   \item{author}{Author information}
#'   \item{link}{Associated links}
#'   \item{reference}{Reference information}
#'   \item{alternative.id}{Alternative identifiers}
#'   \item{published.online}{Online publication date}
#'   \item{language}{Publication language}
#'   \item{funder}{Funding information}
#'   \item{license}{License information}
#'   \item{update.policy}{Update policy details}
#'   \item{assertion}{Publication assertions}
#'   \item{archive}{Archive information}
#'   \item{subtitle}{Publication subtitle}
#'   \item{update_to}{Update information}
#'   \item{isbn}{International Standard Book Number}
#' }
#'
#' @source Data retrieved from CrossRef API using rcrossref package and parametra_long dois
"parametra_crossref"

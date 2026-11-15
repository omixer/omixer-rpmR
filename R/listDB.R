#' @rdname loadDB
#' @export
listDB <- function() {
  db.path <- system.file("extdata", package = "omixerRpm")
  sub("\\.txt$", "", dir(db.path, pattern = "\\.txt$"))
}

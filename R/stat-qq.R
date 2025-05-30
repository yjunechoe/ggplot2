#' @rdname Stat
#' @format NULL
#' @usage NULL
#' @export
StatQq <- ggproto(
  "StatQq", Stat,
  default_aes = aes(y = after_stat(sample), x = after_stat(theoretical)),

  required_aes = c("sample"),

  compute_group = function(self, data, scales, quantiles = NULL,
                           distribution = stats::qnorm, dparams = list(),
                           na.rm = FALSE) {

    sample <- sort(data$sample)
    n <- length(sample)

    # Compute theoretical quantiles
    if (is.null(quantiles)) {
      quantiles <- stats::ppoints(n)
    } else if (length(quantiles) != n) {
      cli::cli_abort("The length of {.arg quantiles} must match the length of the data.")
    }

    theoretical <- inject(distribution(p = quantiles, !!!dparams))

    data_frame0(sample = sample, theoretical = theoretical)
  }
)

#' A quantile-quantile plot
#'
#' `geom_qq()` and `stat_qq()` produce quantile-quantile plots. `geom_qq_line()` and
#' `stat_qq_line()` compute the slope and intercept of the line connecting the
#' points at specified quartiles of the theoretical and sample distributions.
#'
#' @aesthetics StatQq
#' @aesthetics StatQqLine
#' @param distribution Distribution function to use, if x not specified
#' @param dparams Additional parameters passed on to `distribution`
#'   function.
#' @inheritParams layer
#' @inheritParams geom_point
#' @eval rd_computed_vars(
#'  .details = "\\cr Variables computed by `stat_qq()`:",
#'  sample      = "Sample quantiles.",
#'  theoretical = "Theoretical quantiles."
#' )
#' @eval rd_computed_vars(
#'   .skip_intro = TRUE,
#'   .details = "Variables computed by `stat_qq_line()`:",
#'   x = "x-coordinates of the endpoints of the line segment connecting the
#'   points at the chosen quantiles of the theoretical and the sample
#'   distributions.",
#'   y = "y-coordinates of the endpoints.",
#'   slope     = "Amount of change in `y` across 1 unit of `x`.",
#'   intercept = "Value of `y` at `x == 0`."
#' )
#'
#' @export
#' @examples
#' \donttest{
#' df <- data.frame(y = rt(200, df = 5))
#' p <- ggplot(df, aes(sample = y))
#' p + stat_qq() + stat_qq_line()
#'
#' # Use fitdistr from MASS to estimate distribution params:
#' # if (requireNamespace("MASS", quietly = TRUE)) {
#' #   params <- as.list(MASS::fitdistr(df$y, "t")$estimate)
#' # }
#' # Here, we use pre-computed params
#' params <- list(m = -0.02505057194115, s = 1.122568610124, df = 6.63842653897)
#' ggplot(df, aes(sample = y)) +
#'   stat_qq(distribution = qt, dparams = params["df"]) +
#'   stat_qq_line(distribution = qt, dparams = params["df"])
#'
#' # Using to explore the distribution of a variable
#' ggplot(mtcars, aes(sample = mpg)) +
#'   stat_qq() +
#'   stat_qq_line()
#' ggplot(mtcars, aes(sample = mpg, colour = factor(cyl))) +
#'   stat_qq() +
#'   stat_qq_line()
#' }
geom_qq <- make_constructor(StatQq, geom = "point", omit = "quantiles")

#' @export
#' @rdname geom_qq
stat_qq <- geom_qq

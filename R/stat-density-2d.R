#' @rdname Stat
#' @format NULL
#' @usage NULL
#' @export
StatDensity2d <- ggproto(
  "StatDensity2d", Stat,
  default_aes = aes(colour = "#3366FF", size = 0.5),

  required_aes = c("x", "y"),
  # because of the chained calculation in compute_panel(),
  # which calls compute_panel() of a different stat, we declare
  # dropped aesthetics there
  dropped_aes = character(0),

  extra_params = c(
    "na.rm", "contour", "contour_var",
    "bins", "binwidth", "breaks"
  ),

  # when contouring is on, are we returning lines or bands?
  contour_type = "lines",

  compute_layer = function(self, data, params, layout) {
    check_installed("MASS", reason = "for calculating 2D density.")
    # first run the regular layer calculation to infer densities
    data <- ggproto_parent(Stat, self)$compute_layer(data, params, layout)
    if (empty(data)) {
      return(data_frame0())
    }

    # if we're not contouring we're done
    if (!isTRUE(params$contour %||% TRUE)) return(data)

    # set up data and parameters for contouring
    contour_var <- params$contour_var %||% "density"
    arg_match0(
      contour_var,
      c("density", "ndensity", "count")
    )
    data$z <- data[[contour_var]]
    z.range <- range(data$z, na.rm = TRUE, finite = TRUE)
    params <- params[intersect(names(params), c("bins", "binwidth", "breaks"))]
    params$z.range <- z.range

    if (isTRUE(self$contour_type == "bands")) {
      contour_stat <- ggproto(NULL, StatContourFilled)
    } else { # lines is the default
      contour_stat <- ggproto(NULL, StatContour)
    }
    # update dropped aes
    contour_stat$dropped_aes <- c(contour_stat$dropped_aes, "density", "ndensity", "count")

    dapply(data, "PANEL", function(data) {
      scales <- layout$get_scales(data$PANEL[1])
      try_fetch(
        inject(contour_stat$compute_panel(data = data, scales = scales, !!!params)),
        error = function(cnd) {
          cli::cli_warn("Computation failed in {.fn {snake_class(self)}}.", parent = cnd)
          data_frame0()
        }
      )
    })
  },

  compute_group = function(data, scales, na.rm = FALSE, h = NULL, adjust = c(1, 1),
                           n = 100, ...) {

    h <- precompute_2d_bw(data$x, data$y, h = h, adjust = adjust)

    # calculate density
    dens <- MASS::kde2d(
      data$x, data$y, h = h, n = n,
      lims = c(scales$x$dimension(), scales$y$dimension())
    )

    # prepare final output data frame
    nx <- nrow(data) # number of observations in this group
    df <- expand.grid(x = dens$x, y = dens$y)
    df$density <- as.vector(dens$z)
    df$group <- data$group[1]
    df$ndensity <- df$density / max(df$density, na.rm = TRUE)
    df$count <- nx * df$density
    df[["n"]] <- nx
    df$level <- 1
    df$piece <- 1
    df
  }
)

#' @rdname Stat
#' @format NULL
#' @usage NULL
#' @export
StatDensity2dFilled <- ggproto(
  "StatDensity2dFilled", StatDensity2d,
  default_aes = aes(colour = NA, fill = after_stat(level)),
  contour_type = "bands"
)

#' @export
#' @rdname geom_density_2d
#' @param contour If `TRUE`, contour the results of the 2d density
#'   estimation.
#' @param contour_var Character string identifying the variable to contour
#'   by. Can be one of `"density"`, `"ndensity"`, or `"count"`. See the section
#'   on computed variables for details.
#' @inheritDotParams geom_contour bins binwidth breaks
#' @param n Number of grid points in each direction.
#' @param h Bandwidth (vector of length two). If `NULL`, estimated
#'   using [MASS::bandwidth.nrd()].
#' @param adjust A multiplicative bandwidth adjustment to be used if 'h' is
#'    'NULL'. This makes it possible to adjust the bandwidth while still
#'    using the a bandwidth estimator. For example, `adjust = 1/2` means
#'    use half of the default bandwidth.
#' @eval rd_computed_vars(
#'   .details = "`stat_density_2d()` and `stat_density_2d_filled()` compute
#'   different variables depending on whether contouring is turned on or off.
#'   With contouring off (`contour = FALSE`), both stats behave the same, and
#'   the following variables are provided:",
#'   density  = "The density estimate.",
#'   ndensity = "Density estimate, scaled to a maximum of 1.",
#'   count    = "Density estimate * number of observations in group.",
#'   n        = "Number of observations in each group."
#' )
#'
#' @section Computed variables:
#' With contouring on (`contour = TRUE`), either [stat_contour()] or
#' [stat_contour_filled()] (for contour lines or contour bands,
#' respectively) is run after the density estimate has been obtained,
#' and the computed variables are determined by these stats.
#' Contours are calculated for one of the three types of density estimates
#' obtained before contouring, `density`, `ndensity`, and `count`. Which
#' of those should be used is determined by the `contour_var` parameter.
#'
#' @section Dropped variables:
#' \describe{
#'   \item{`z`}{After density estimation, the z values of individual data points are no longer available.}
#' }
#'
#' If contouring is enabled, then similarly `density`, `ndensity`, and `count`
#' are no longer available after the contouring pass.
#'
stat_density_2d <- make_constructor(
  StatDensity2d, geom = "density_2d",
  contour = TRUE, contour_var = "density"
)

#' @rdname geom_density_2d
#' @usage NULL
#' @export
stat_density2d <- stat_density_2d

#' @rdname geom_density_2d
#' @export
stat_density_2d_filled <- make_constructor(
  StatDensity2dFilled, geom = "density_2d_filled",
  contour = TRUE, contour_var = "density"
)

#' @rdname geom_density_2d
#' @usage NULL
#' @export
stat_density2d_filled <- stat_density_2d_filled

precompute_2d_bw <- function(x, y, h = NULL, adjust = 1) {

  if (is.null(h)) {
    # Note: MASS::bandwidth.nrd is equivalent to stats::bw.nrd * 4
    h <- c(MASS::bandwidth.nrd(x), MASS::bandwidth.nrd(y))
    # Handle case when when IQR == 0 and thus regular nrd bandwidth fails
    if (h[1] == 0 && length(x) > 1) h[1] <- stats::bw.nrd0(x) * 4
    if (h[2] == 0 && length(y) > 1) h[2] <- stats::bw.nrd0(y) * 4
    h <- h * adjust
  }

  check_numeric(h)
  check_length(h, 2L)

  if (any(is.na(h) | h <= 0)) {
    cli::cli_abort(c(
      "The bandwidth argument {.arg h} must contain numbers larger than 0.",
      i = "Please set the {.arg h} argument to stricly positive numbers manually."
    ))
  }

  h
}

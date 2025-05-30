#' @rdname Geom
#' @format NULL
#' @usage NULL
#' @export
GeomRibbon <- ggproto("GeomRibbon", Geom,

  default_aes = aes(
    colour = from_theme(colour %||% NA),
    fill = from_theme(fill %||% col_mix(ink, paper, 0.2)),
    linewidth = from_theme(borderwidth),
    linetype = from_theme(bordertype),
    alpha = NA
  ),

  required_aes = c("x|y", "ymin|xmin", "ymax|xmax"),

  setup_params = function(data, params) {
    params$flipped_aes <- has_flipped_aes(data, params, range_is_orthogonal = TRUE)
    params
  },

  extra_params = c("na.rm", "orientation"),

  setup_data = function(data, params) {
    data$flipped_aes <- params$flipped_aes
    data <- flip_data(data, params$flipped_aes)

    if (is.null(data$ymin) && is.null(data$ymax)) {
      cli::cli_abort("Either {.field {flipped_names(params$flipped_aes)$ymin}} or {.field {flipped_names(params$flipped_aes)$ymax}} must be given as an aesthetic.")
    }
    data <- data[order(data$PANEL, data$group, data$x), , drop = FALSE]
    data$y <- data$ymin %||% data$ymax
    flip_data(data, params$flipped_aes)
  },

  draw_key = draw_key_polygon,

  handle_na = function(self, data, params) {

    vars <- vapply(
      strsplit(self$required_aes, "|", fixed = TRUE),
      `[[`, i = 1, character(1)
    )
    if (isTRUE(params$flipped_aes || any(data$flipped_aes) %||% FALSE)) {
      vars <- switch_orientation(vars)
    }
    vars <- c(vars, self$non_missing_aes)

    missing <- detect_missing(data, vars, finite = FALSE)
    if (!any(missing)) {
      return(data)
    }
    # We're rearranging groups to account for missing values
    data$group <- vec_identify_runs(data_frame0(missing, data$group))
    data <- vec_slice(data, !missing)

    if (!params$na.rm) {
      cli::cli_warn(
        "Removed {sum(missing)} row{?s} containing missing values or values \\
          outside the scale range ({.fn {snake_class(self)}})."
      )
    }
    data
  },

  draw_group = function(self, data, panel_params, coord, lineend = "butt",
                        linejoin = "round", linemitre = 10, na.rm = FALSE,
                        flipped_aes = FALSE, outline.type = "both") {
    data <- fix_linewidth(data, snake_class(self))
    data <- flip_data(data, flipped_aes)
    data <- data[order(data$group), ]

    # Check that aesthetics are constant
    aes <- lapply(
      data[names(data) %in% c("colour", "fill", "linewidth", "linetype", "alpha")],
      unique0
    )
    non_constant <- names(aes)[lengths(aes) > 1]
    if (coord$is_linear()) {
      if (any(c("fill", "alpha") %in% non_constant)) {
        check_device("gradients", action = "abort", maybe = TRUE)
      }
      # For linear coords, we can make a fill/alpha gradient, so we allow
      # these to vary
      non_constant <- setdiff(non_constant, c("fill", "alpha"))
    }
    if (length(non_constant) > 0) {
      cli::cli_abort(
        "Aesthetics can not vary along a ribbon: {.and {.field {non_constant}}}."
      )
    }
    if ((length(aes$fill) > 1 || length(aes$alpha) > 1)) {
      transformed <- coord$transform(flip_data(data, flipped_aes), panel_params)
      if (flipped_aes) {
        keep <- is.finite(transformed$y)
        args <- list(
          colours = alpha(data$fill, data$alpha)[keep],
          stops = rescale(transformed$y)[keep],
          y1 = 0, y2 = 1, x1 = 0.5, x2 = 0.5
        )
      } else {
        keep <- is.finite(transformed$x)
        args <- list(
          colours = alpha(data$fill, data$alpha)[keep],
          stops = rescale(transformed$x)[keep],
          x1 = 0, x2 = 1, y1 = 0.5, y2 = 0.5
        )
      }
      aes$fill <- inject(linearGradient(!!!args))
      aes$alpha <- NA
    }

    # Instead of removing NA values from the data and plotting a single
    # polygon, we want to "stop" plotting the polygon whenever we're
    # missing values and "start" a new polygon as soon as we have new
    # values.  We do this by creating an id vector for polygonGrob that
    # has distinct polygon numbers for sequences of non-NA values and NA
    # for NA values in the original data.  Example: c(NA, 2, 2, 2, NA, NA,
    # 4, 4, 4, NA)
    missing_pos <- !stats::complete.cases(data[c("x", "ymin", "ymax")])
    ids <- cumsum(missing_pos) + 1
    ids[missing_pos] <- NA

    data <- unclass(data) #for faster indexing

    # In case the data comes from stat_align
    upper_keep <- if (is.null(data$align_padding)) TRUE else !data$align_padding

    # The upper line and lower line need to processed separately (#4023)
    positions_upper <- data_frame0(
      x = data$x[upper_keep],
      y = data$ymax[upper_keep],
      id = ids[upper_keep]
    )

    positions_lower <- data_frame0(
      x = rev(data$x),
      y = rev(data$ymin),
      id = rev(ids)
    )

    positions_upper <- flip_data(positions_upper, flipped_aes)
    positions_lower <- flip_data(positions_lower, flipped_aes)

    munched_upper <- coord_munch(coord, positions_upper, panel_params)
    munched_lower <- coord_munch(coord, positions_lower, panel_params)

    munched_poly <- vec_rbind0(munched_upper, munched_lower)

    is_full_outline <- identical(outline.type, "full")
    g_poly <- polygonGrob(
      munched_poly$x, munched_poly$y, id = munched_poly$id,
      default.units = "native",
      gp = gg_par(
        fill = fill_alpha(aes$fill, aes$alpha),
        col = if (is_full_outline) aes$colour else NA,
        lwd = if (is_full_outline) aes$linewidth else 0,
        lty = if (is_full_outline) aes$linetype else 1,
        lineend = lineend,
        linejoin = linejoin,
        linemitre = linemitre
      )
    )

    if (is_full_outline) {
      return(ggname("geom_ribbon", g_poly))
    }

    # Increment the IDs of the lower line so that they will be drawn as separate lines
    munched_lower$id <- munched_lower$id + max(ids, na.rm = TRUE)

    arg_match0(
      outline.type,
      c("both", "upper", "lower")
    )

    munched_lines <- switch(outline.type,
      both = vec_rbind0(munched_upper, munched_lower),
      upper = munched_upper,
      lower = munched_lower
    )
    g_lines <- polylineGrob(
      munched_lines$x, munched_lines$y, id = munched_lines$id,
      default.units = "native",
      gp = gg_par(
        col = aes$colour,
        lwd = aes$linewidth,
        lty = aes$linetype,
        lineend = lineend,
        linejoin = linejoin,
        linemitre = linemitre
      )
    )

    ggname("geom_ribbon", grobTree(g_poly, g_lines))
  },

  rename_size = TRUE
)

#' @rdname Geom
#' @format NULL
#' @usage NULL
#' @export
GeomArea <- ggproto("GeomArea", GeomRibbon,

  required_aes = c("x", "y"),

  setup_params = function(data, params) {
    params$flipped_aes <- has_flipped_aes(data, params, ambiguous = TRUE)
    params
  },

  setup_data = function(data, params) {
    data$flipped_aes <- params$flipped_aes
    data <- flip_data(data, params$flipped_aes)
    data <- transform(data[order(data$PANEL, data$group, data$x), ], ymin = 0, ymax = y)
    flip_data(data, params$flipped_aes)
  }
)

#' Ribbons and area plots
#'
#' For each x value, `geom_ribbon()` displays a y interval defined
#' by `ymin` and `ymax`. `geom_area()` is a special case of
#' `geom_ribbon()`, where the `ymin` is fixed to 0 and `y` is used instead
#' of `ymax`.
#'
#' An area plot is the continuous analogue of a stacked bar chart (see
#' [geom_bar()]), and can be used to show how composition of the
#' whole varies over the range of x. Choosing the order in which different
#' components is stacked is very important, as it becomes increasing hard to
#' see the individual pattern as you move up the stack. See
#' [position_stack()] for the details of stacking algorithm. To facilitate
#' stacking, the default `stat = "align"` interpolates groups to a common set
#' of x-coordinates. To turn off this interpolation, `stat = "identity"` can
#' be used instead.
#'
#' @eval rd_orientation()
#'
#' @aesthetics GeomRibbon
#' @seealso
#'   [geom_bar()] for discrete intervals (bars),
#'   [geom_linerange()] for discrete intervals (lines),
#'   [geom_polygon()] for general polygons
#' @inheritParams layer
#' @inheritParams geom_bar
#' @param linemitre Line mitre limit (number greater than 1).
#' @param outline.type Type of the outline of the area; `"both"` draws both the
#'   upper and lower lines, `"upper"`/`"lower"` draws the respective lines only.
#'   `"full"` draws a closed polygon around the area.
#' @export
#' @examples
#' # Generate data
#' huron <- data.frame(year = 1875:1972, level = as.vector(LakeHuron))
#' h <- ggplot(huron, aes(year))
#'
#' h + geom_ribbon(aes(ymin=0, ymax=level))
#' h + geom_area(aes(y = level))
#'
#' # Orientation cannot be deduced by mapping, so must be given explicitly for
#' # flipped orientation
#' h + geom_area(aes(x = level, y = year), orientation = "y")
#'
#' # Add aesthetic mappings
#' h +
#'   geom_ribbon(aes(ymin = level - 1, ymax = level + 1), fill = "grey70") +
#'   geom_line(aes(y = level))
#'
#' # The underlying stat_align() takes care of unaligned data points
#' df <- data.frame(
#'   g = c("a", "a", "a", "b", "b", "b"),
#'   x = c(1, 3, 5, 2, 4, 6),
#'   y = c(2, 5, 1, 3, 6, 7)
#' )
#' a <- ggplot(df, aes(x, y, fill = g)) +
#'   geom_area()
#'
#' # Two groups have points on different X values.
#' a + geom_point(size = 8) + facet_grid(g ~ .)
#'
#' # stat_align() interpolates and aligns the value so that the areas can stack
#' # properly.
#' a + geom_point(stat = "align", position = "stack", size = 8)
#'
#' # To turn off the alignment, the stat can be set to "identity"
#' ggplot(df, aes(x, y, fill = g)) +
#'   geom_area(stat = "identity")
#'
geom_ribbon <- make_constructor(
  GeomRibbon, orientation = NA,
  checks = exprs(
    outline.type <- arg_match0(outline.type, c("both", "upper", "lower", "full"))
  )
)

#' @rdname geom_ribbon
#' @export
geom_area <- make_constructor(
  GeomArea, stat = "align", position = "stack",
  orientation = NA, outline.type = "upper",
  checks = exprs(
    outline.type <- arg_match0(outline.type, c("both", "upper", "lower", "full"))
  )
)

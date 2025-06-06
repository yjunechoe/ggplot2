% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/guide-axis-theta.R
\name{guide_axis_theta}
\alias{guide_axis_theta}
\title{Angle axis guide}
\usage{
guide_axis_theta(
  title = waiver(),
  theme = NULL,
  angle = waiver(),
  minor.ticks = FALSE,
  cap = "none",
  order = 0,
  position = waiver()
)
}
\arguments{
\item{title}{A character string or expression indicating a title of guide.
If \code{NULL}, the title is not shown. By default
(\code{\link[=waiver]{waiver()}}), the name of the scale object or the name
specified in \code{\link[=labs]{labs()}} is used for the title.}

\item{theme}{A \code{\link[=theme]{theme}} object to style the guide individually or
differently from the plot's theme settings. The \code{theme} argument in the
guide partially overrides, and is combined with, the plot's theme.}

\item{angle}{Compared to setting the angle in \code{\link[=theme]{theme()}} / \code{\link[=element_text]{element_text()}},
this also uses some heuristics to automatically pick the \code{hjust} and \code{vjust} that
you probably want. Can be one of the following:
\itemize{
\item \code{NULL} to take the angles and \code{hjust}/\code{vjust} directly from the theme.
\item \code{waiver()} to allow reasonable defaults in special cases.
\item A number representing the text angle in degrees.
}}

\item{minor.ticks}{Whether to draw the minor ticks (\code{TRUE}) or not draw
minor ticks (\code{FALSE}, default).}

\item{cap}{A \code{character} to cut the axis line back to the last breaks. Can
be \code{"none"} (default) to draw the axis line along the whole panel, or
\code{"upper"} and \code{"lower"} to draw the axis to the upper or lower break, or
\code{"both"} to only draw the line in between the most extreme breaks. \code{TRUE}
and \code{FALSE} are shorthand for \code{"both"} and \code{"none"} respectively.}

\item{order}{A positive \code{integer} of length 1 that specifies the order of
this guide among multiple guides. This controls in which order guides are
merged if there are multiple guides for the same position. If 0 (default),
the order is determined by a secret algorithm.}

\item{position}{Where this guide should be drawn: one of top, bottom,
left, or right.}
}
\description{
This is a specialised guide used in \code{coord_radial()} to represent the theta
position scale.
}
\note{
The axis labels in this guide are insensitive to \code{hjust} and \code{vjust}
settings. The distance from the tick marks to the labels is determined by
the largest \code{margin} size set in the theme.
}
\examples{
# A plot using coord_radial
p <- ggplot(mtcars, aes(disp, mpg)) +
  geom_point() +
  coord_radial()

# The `angle` argument can be used to set relative angles
p + guides(theta = guide_axis_theta(angle = 0))
}

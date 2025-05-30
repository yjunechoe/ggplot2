% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/limits.R
\name{expand_limits}
\alias{expand_limits}
\title{Expand the plot limits, using data}
\usage{
expand_limits(...)
}
\arguments{
\item{...}{named list of aesthetics specifying the value (or values) that
should be included in each scale.}
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#superseded}{\figure{lifecycle-superseded.svg}{options: alt='[Superseded]'}}}{\strong{[Superseded]}}: It is recommended to pass a function to
the \code{limits} argument in scales instead. For example:
\code{scale_x_continuous(limits = ~range(.x, 0))} to include zero.\cr\cr
Sometimes you may want to ensure limits include a single value, for all
panels or all plots.  This function is a thin wrapper around
\code{\link[=geom_blank]{geom_blank()}} that makes it easy to add such values.
}
\examples{
p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()
p + expand_limits(x = 0)
p + expand_limits(y = c(1, 9))
p + expand_limits(x = 0, y = 0)

ggplot(mtcars, aes(mpg, wt)) +
  geom_point(aes(colour = cyl)) +
  expand_limits(colour = seq(2, 10, by = 2))
ggplot(mtcars, aes(mpg, wt)) +
  geom_point(aes(colour = factor(cyl))) +
  expand_limits(colour = factor(seq(2, 10, by = 2)))
}

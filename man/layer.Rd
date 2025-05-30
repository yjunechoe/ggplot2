% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/layer.R
\name{layer}
\alias{layer}
\title{Create a new layer}
\usage{
layer(
  geom = NULL,
  stat = NULL,
  data = NULL,
  mapping = NULL,
  position = NULL,
  params = list(),
  inherit.aes = TRUE,
  check.aes = TRUE,
  check.param = TRUE,
  show.legend = NA,
  key_glyph = NULL,
  layout = NULL,
  layer_class = Layer
)
}
\arguments{
\item{geom}{The geometric object to use to display the data for this layer.
When using a \verb{stat_*()} function to construct a layer, the \code{geom} argument
can be used to override the default coupling between stats and geoms. The
\code{geom} argument accepts the following:
\itemize{
\item A \code{Geom} ggproto subclass, for example \code{GeomPoint}.
\item A string naming the geom. To give the geom as a string, strip the
function name of the \code{geom_} prefix. For example, to use \code{geom_point()},
give the geom as \code{"point"}.
\item For more information and other ways to specify the geom, see the
\link[=layer_geoms]{layer geom} documentation.
}}

\item{stat}{The statistical transformation to use on the data for this layer.
When using a \verb{geom_*()} function to construct a layer, the \code{stat}
argument can be used to override the default coupling between geoms and
stats. The \code{stat} argument accepts the following:
\itemize{
\item A \code{Stat} ggproto subclass, for example \code{StatCount}.
\item A string naming the stat. To give the stat as a string, strip the
function name of the \code{stat_} prefix. For example, to use \code{stat_count()},
give the stat as \code{"count"}.
\item For more information and other ways to specify the stat, see the
\link[=layer_stats]{layer stat} documentation.
}}

\item{data}{The data to be displayed in this layer. There are three
options:

If \code{NULL}, the default, the data is inherited from the plot
data as specified in the call to \code{\link[=ggplot]{ggplot()}}.

A \code{data.frame}, or other object, will override the plot
data. All objects will be fortified to produce a data frame. See
\code{\link[=fortify]{fortify()}} for which variables will be created.

A \code{function} will be called with a single argument,
the plot data. The return value must be a \code{data.frame}, and
will be used as the layer data. A \code{function} can be created
from a \code{formula} (e.g. \code{~ head(.x, 10)}).}

\item{mapping}{Set of aesthetic mappings created by \code{\link[=aes]{aes()}}. If specified and
\code{inherit.aes = TRUE} (the default), it is combined with the default mapping
at the top level of the plot. You must supply \code{mapping} if there is no plot
mapping.}

\item{position}{A position adjustment to use on the data for this layer. This
can be used in various ways, including to prevent overplotting and
improving the display. The \code{position} argument accepts the following:
\itemize{
\item The result of calling a position function, such as \code{position_jitter()}.
This method allows for passing extra arguments to the position.
\item A string naming the position adjustment. To give the position as a
string, strip the function name of the \code{position_} prefix. For example,
to use \code{position_jitter()}, give the position as \code{"jitter"}.
\item For more information and other ways to specify the position, see the
\link[=layer_positions]{layer position} documentation.
}}

\item{params}{Additional parameters to the \code{geom} and \code{stat}.}

\item{inherit.aes}{If \code{FALSE}, overrides the default aesthetics,
rather than combining with them. This is most useful for helper functions
that define both data and aesthetics and shouldn't inherit behaviour from
the default plot specification, e.g. \code{\link[=annotation_borders]{annotation_borders()}}.}

\item{check.aes, check.param}{If \code{TRUE}, the default, will check that
supplied parameters and aesthetics are understood by the \code{geom} or
\code{stat}. Use \code{FALSE} to suppress the checks.}

\item{show.legend}{logical. Should this layer be included in the legends?
\code{NA}, the default, includes if any aesthetics are mapped.
\code{FALSE} never includes, and \code{TRUE} always includes.
It can also be a named logical vector to finely select the aesthetics to
display. To include legend keys for all levels, even
when no data exists, use \code{TRUE}.  If \code{NA}, all levels are shown in legend,
but unobserved levels are omitted.}

\item{key_glyph}{A legend key drawing function or a string providing the
function name minus the \code{draw_key_} prefix. See \link{draw_key} for details.}

\item{layout}{Argument to control layout at the layer level. Consult the
faceting documentation to view appropriate values.}

\item{layer_class}{The type of layer object to be constructed. This is
intended for ggplot2 internal use only.}
}
\description{
A layer is a combination of data, stat and geom with a potential position
adjustment. Usually layers are created using \verb{geom_*} or \verb{stat_*}
calls but it can also be created directly using this function.
}
\examples{
# geom calls are just a short cut for layer
ggplot(mpg, aes(displ, hwy)) + geom_point()
# shortcut for
ggplot(mpg, aes(displ, hwy)) +
  layer(
    geom = "point", stat = "identity", position = "identity",
    params = list(na.rm = FALSE)
  )

# use a function as data to plot a subset of global data
ggplot(mpg, aes(displ, hwy)) +
  layer(
    geom = "point", stat = "identity", position = "identity",
    data = head, params = list(na.rm = FALSE)
  )

}
\seealso{
The \href{https://ggplot2-book.org/layers}{plot building chapter} and \href{https://ggplot2-book.org/individual-geoms}{geoms chapter} of the online ggplot2 book.

Other layer documentation: 
\code{\link{layer_geoms}},
\code{\link{layer_positions}},
\code{\link{layer_stats}}
}
\concept{layer documentation}
\keyword{internal}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/diff.R
\name{git_diff}
\alias{git_diff}
\alias{git_diff_patch}
\title{Git Diff}
\usage{
git_diff(ref = NULL, repo = ".")

git_diff_patch(ref = NULL, repo = ".")
}
\arguments{
\item{ref}{a reference such as \code{"HEAD"}, or a commit id, or \code{NULL}
to the diff the working directory against the repository index.}

\item{repo}{The path to the git repository. If the directory is not a
repository, parent directories are considered (see \link{git_find}). To disable
this search, provide the filepath protected with \code{\link[=I]{I()}}. When using this
parameter, always explicitly call by name (i.e. \verb{repo = }) because future
versions of gert may have additional parameters.}
}
\description{
View changes in a commit or in the current working directory.
}
\seealso{
Other git: 
\code{\link{git_archive}},
\code{\link{git_branch}()},
\code{\link{git_commit}()},
\code{\link{git_config}()},
\code{\link{git_fetch}()},
\code{\link{git_ignore}},
\code{\link{git_merge}()},
\code{\link{git_rebase}()},
\code{\link{git_remote}},
\code{\link{git_repo}},
\code{\link{git_reset}()},
\code{\link{git_signature}()},
\code{\link{git_stash}},
\code{\link{git_tag}}
}
\concept{git}

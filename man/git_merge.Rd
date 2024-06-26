% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/merge.R
\name{git_merge}
\alias{git_merge}
\alias{git_merge_stage_only}
\alias{git_merge_find_base}
\alias{git_merge_analysis}
\alias{git_merge_abort}
\title{Merging tools}
\usage{
git_merge(ref, commit = TRUE, squash = FALSE, repo = ".")

git_merge_stage_only(ref, squash = FALSE, repo = ".")

git_merge_find_base(ref, target = "HEAD", repo = ".")

git_merge_analysis(ref, repo = ".")

git_merge_abort(repo = ".")
}
\arguments{
\item{ref}{branch or commit that you want to merge}

\item{commit}{automatically create a merge commit if the merge succeeds without
conflicts. Set this to \code{FALSE} if you want to customize your commit message/author.}

\item{squash}{omits the second parent from the commit, which make the merge a regular
single-parent commit.}

\item{repo}{The path to the git repository. If the directory is not a
repository, parent directories are considered (see \link{git_find}). To disable
this search, provide the filepath protected with \code{\link[=I]{I()}}. When using this
parameter, always explicitly call by name (i.e. \verb{repo = }) because future
versions of gert may have additional parameters.}

\item{target}{the branch where you want to merge into. Defaults to current \code{HEAD}.}
}
\description{
Use \code{git_merge} to merge a branch into the current head. Based on how the branches
have diverged, the function will select a fast-forward or merge-commit strategy.
}
\details{
By default \code{git_merge} automatically commits the merge commit upon success.
However if the merge fails with merge-conflicts, or if \code{commit} is set to
\code{FALSE}, the changes are staged and the repository is put in merging state,
and you have to manually run \code{git_commit} or \code{git_merge_abort} to proceed.

Other functions are more low-level tools that are used by \code{git_merge}.
\code{git_merge_find_base} looks up the commit where two branches have diverged
(i.e. the youngest common ancestor). The \code{git_merge_analysis} is used to
test if a merge can simply be fast forwarded or not.

The \code{git_merge_stage_only} function applies and stages changes, without
committing or fast-forwarding.
}
\seealso{
Other git: 
\code{\link{git_archive}},
\code{\link{git_branch}()},
\code{\link{git_commit}()},
\code{\link{git_config}()},
\code{\link{git_diff}()},
\code{\link{git_fetch}()},
\code{\link{git_ignore}},
\code{\link{git_rebase}()},
\code{\link{git_remote}},
\code{\link{git_repo}},
\code{\link{git_reset}()},
\code{\link{git_signature}()},
\code{\link{git_stash}},
\code{\link{git_tag}}
}
\concept{git}

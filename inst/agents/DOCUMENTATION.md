# pladdrr Documentation Convention

**Purpose:** How to write roxygen2 doc blocks for the shared-dispatch-table wrapper types (Sound, Formant, Pitch, etc. — see `ARCHITECTURE.md` § Dispatch Patterns). `Sound` (`R/sound-wrapper.R`) is the reference implementation; copy its shape.

## Why this file exists

`DESCRIPTION` does **not** set `Roxygen: list(markdown = TRUE)`. Markdown-style
doc text (`` - `method()` - description ``, backticks for code) is not
processed by roxygen2 in this package — it is emitted into the `.Rd` file as
literal text. Rd's plain-text renderer collapses adjacent lines into a single
flowed paragraph, so a hand-written bullet list renders as one run-on
paragraph with literal backticks/asterisks in both `?Sound` and pkgdown/HTML
output. This was the root cause of the "confusing docs" report that started
this convention (see git history around the `Sound` pilot).

**Fix: write real Rd markup in the roxygen comment, not markdown.** Roxygen
passes `@section` body text through mostly unprocessed, so `\itemize`,
`\enumerate`, `\code{}`, `\url{}`, `\preformatted{}` all work directly inside
`#'` comments.

## Doc block shape (mirror `Sound`)

```r
#' ClassName
#'
#' One-sentence description of the underlying Praat object.
#'
#' A short paragraph of detail: what it holds, what it's used for.
#' Only include a section like "File I/O" if the class actually has
#' nontrivial construction logic worth explaining.
#'
#' @section Usage:
#' \preformatted{
#' obj <- Sound$create_tone(440, 1.0)$to_pitch()
#' }
#'
#' @section Query methods:
#' \itemize{
#'   \item \code{get_mean()} - mean pitch in Hz
#'   \item \code{get_minimum()}, \code{get_maximum()} - range
#' }
#'
#' @section <Other category>:
#' \itemize{
#'   \item ...
#' }
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   object; set internally when a method returns a new object.
#' @return A ClassName object.
#'
#' @examples
#' pitch <- Sound$create_tone(220, 0.5)$to_pitch()
#' pitch$get_mean()
#'
#' @seealso [Sound], [Formant]
#' @name ClassName
NULL
```

Rules, in order of how often they're missed:

1. **Lists are `\itemize`/`\enumerate`, never `- ` markdown bullets.** One
   `\item` per method. Method/argument names go in `\code{}`, not backticks.
2. **Section headers are sentence case** (`Query methods`, not
   `Query Methods`) — Title Case in headings is an AI-writing tell, not
   R house style.
3. **No duplicate explanations.** If a `@section` already explains something
   in detail (e.g. supported file formats), the matching `@param` gets one
   short sentence and a pointer to the section, not the same paragraph
   twice.
4. **Internal-only params get "Not for direct use."** Dispatch-table objects
   carry a `.xptr` (or similarly dot-prefixed) constructor arg that end users
   never set themselves. It still needs a documented `@param` (R CMD check
   flags undocumented arguments), but say plainly that it's internal and
   what sets it — don't let it read like a normal user-facing argument.
5. **No stale/marketing markers.** Cut `**NEW**`, "cutting-edge",
   version-bragging, or anything whose real home is `HISTORY.md`/the
   changelog, not the reference doc a user opens mid-analysis. If a fact
   about *why* something exists matters, it belongs in `ARCHITECTURE.md` or
   `HISTORY.md`, not repeated in every method's Rd page.
6. **Humanize the prose.** No em dashes, no `**bold** \n**bold**` inline-header
   lists, no hedging/filler. Plain, direct, friendly-scientific register —
   write like the `Sound` doc reads. Run non-trivial rewrites past the
   `humanizer` skill patterns (AI Vocabulary, Overuse of Boldface, Em Dashes,
   Title Case in Headings are the ones that show up most in this codebase).

## Verifying a doc block

After editing, regenerate and spot-check the specific topic — don't just
trust that `roxygenise()` exiting 0 means the rendered page is right, since
malformed markdown-as-text degrades silently (no warning, just a run-on
paragraph):

```r
roxygen2::roxygenise()
tools::Rd2HTML("man/ClassName.Rd", out = "/tmp/ClassName.html")  # eyeball the <ul>/<ol> actually list
# or, plain-text:
# R CMD Rdconv -t txt man/ClassName.Rd | less
```

Confirm method-list sections render as one bullet per line (`<li>` per method,
or `•` per method in text mode), not one flowed paragraph.

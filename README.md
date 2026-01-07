# split-tweets.el
Split Emacs buffer into chunks for tweeting

# Installation

Drop `split-tweets.el` into `~/elisp` or any other location where emacs can find it. Add
```
(load-library "split-tweets")
```
to your `.emacs`

# Usage

In any buffer invoke `M-x split-into-tweets`, a new buffer `*Tweets*` will appear, containing chunks of the original buffer text. The split occurs at whitespace. Empty lines internal to a chunk are preserved. Empty lines in the beginning and in the end are eliminated. A line containing only "--" means mandatory split (the line itself is eliminated from the output). The chunks are unfilled. Use `C-c C-c` to copy a chunk under cursor to clipboard.

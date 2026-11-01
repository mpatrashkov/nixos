; Fold heading sections, not code blocks or lists. Keep trailing blank lines visible.
((section
  [(atx_heading) (setext_heading)]) @fold
  (#trim! @fold))

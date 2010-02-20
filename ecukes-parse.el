;;; ecukes-parse.el --- Parser stuff

(defstruct ecukes-feature intro background)
(defstruct ecukes-intro header description)
(defstruct ecukes-background steps)
(defstruct ecukes-step name)

(defvar ecukes-feature-re "Feature: *\\(.+[^ ]\\) *$"
  "Regular expression matching a feature header.")

(defvar ecukes-background-re "Background:"
  "Regular expression matching a background.")

(defun ecukes-parse-feature (feature-file)
  (with-temp-buffer
    (insert-file-contents-literally feature-file)

    (let ((intro (ecukes-parse-intro))
          (background (ecukes-parse-background)))
      (make-ecukes-feature :intro intro :background background)
      )

    )
  )

(defun ecukes-parse-intro ()
  "Parses the intro of a feature."
  (goto-char (point-min))
  (when (re-search-forward ecukes-feature-re nil t)
    (let ((header (match-string-no-properties 1))
          (description (list)))
      (forward-line 1)
      (while (not (string= (ecukes-line) ""))
        (add-to-list 'description (ecukes-line) t)
        (forward-line 1))
      (make-ecukes-intro :header header :description description))))

(defun ecukes-parse-background ()
  "Parses a feature background."
  (goto-char (point-min))
  (when (re-search-forward ecukes-background-re nil t)
    (forward-line 1)
    (let ((steps (list)))
      (ecukes-parse-block
       (lambda (step)
         (add-to-list 'steps step t)))
      (make-ecukes-background :steps steps))))

(defun ecukes-parse-block (fn)
  "Parses a block.

This function assumes that the cursor is at the top
position. It the above example that is on the \"Header:\" line."
  (while (not (string= (ecukes-line) ""))
    (let ((step (ecukes-parse-step)))
      (funcall fn step))
    (forward-line 1)))

(defun ecukes-parse-step ()
  ""
  (make-ecukes-step :name (ecukes-line))
  )

(defun ecukes-line (&optional n)
  "Returns the current line +-N at point with removed leading and
trailing whitespace."
  (forward-line (or n 0))
  (let ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
    (string-match "^ *\\(.*\\) *$" line)
    (match-string-no-properties 1 line)))

(provide 'ecukes-parse)

;;; ecukes-parse.el ends here

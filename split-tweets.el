;;; split-tweets.el --- split buffer into chunks for tweeting

(defun copy-tweet-at-point ()
  "Copies the tweet at point to the kill ring, excluding the separator."
  (interactive)
  (save-excursion
    (let (start end)
      ;; 1. Find the end: look for the next separator
      (setq end (if (re-search-forward "^--- [0-9]+" nil t)
                    (progn (beginning-of-line) (point))
                  (point-max)))
      ;; 2. Find the start: look for the previous separator
      (goto-char (if (re-search-backward "^--- [0-9]+" nil t)
                     (progn (forward-line 2) (point))
                   (point-min)))
      (setq start (point))
      
      (let ((tweet (string-trim (buffer-substring-no-properties start end))))
        (if (string-empty-p tweet)
            (message "No tweet found at point.")
          (kill-new tweet)
          (message "Copied tweet (%d chars) to clipboard." (length tweet)))))))

(defun split-into-tweets ()
  "Splits buffer into chunks < 280 chars. 
Single newlines become spaces. Blank lines are preserved internal to chunks.
'--' lines are obligatory breaks. Output is unfilled with numbering and C-c C-c to copy."
  (interactive)
  (let ((max-chars 280)
        (chunks '())
        (current-chunk ""))
    
    (cl-labels ((flush-chunk ()
                  (let ((trimmed (string-trim current-chunk)))
                    (unless (string-empty-p trimmed)
                      (push trimmed chunks))
                    (setq current-chunk "")))
                
                (add-to-chunk (text)
                  (let ((separator (if (or (string-empty-p current-chunk)
                                           (string-suffix-p "\n\n" current-chunk)
                                           (string-prefix-p "\n\n" text))
                                       "" 
                                     " ")))
                    (if (> (+ (length current-chunk) (length separator) (length text)) max-chars)
                        (progn
                          (flush-chunk)
                          (setq current-chunk (string-trim-left text)))
                      (setq current-chunk (concat current-chunk separator text))))))

      (save-excursion
        (goto-char (point-min))
        (let ((sections (split-string (buffer-string) "^--$" t)))
          (dolist (section sections)
            (flush-chunk)
            (let ((paragraphs (split-string section "\n[ \t]*\n" t)))
              (dolist (para paragraphs)
                (let ((unfilled-para (replace-regexp-in-string "[ \t\n\r]+" " " (string-trim para))))
                  (if (<= (length unfilled-para) max-chars)
                      (add-to-chunk unfilled-para)
                    (let ((words (split-string unfilled-para " " t)))
                      (dolist (word words)
                        (add-to-chunk word))))
                (unless (equal para (car (last paragraphs)))
                  (setq current-chunk (concat current-chunk "\n\n"))))))
          (flush-chunk))))

    (let* ((output-buffer (get-buffer-create "*Tweets*"))
           (ordered-chunks (reverse chunks))
           (total (length ordered-chunks))
           (current-idx 1))
      (with-current-buffer output-buffer
        (erase-buffer)
        (dolist (chunk ordered-chunks)
          (let ((final-text (string-trim chunk)))
            (insert final-text 
                    "\n\n--- " (number-to-string (length final-text)) 
                    " [" (number-to-string current-idx) "/" (number-to-string total) "]\n\n"))
          (setq current-idx (1+ current-idx)))
        (visual-line-mode 1)
        (local-set-key (kbd "C-c C-c") 'copy-tweet-at-point))
      (switch-to-buffer-other-window output-buffer)
      (message "Split into %d tweets. Use C-c C-c to copy the one under cursor." total)))))

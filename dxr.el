;;; dxr.el --- Convenient access to a DXR server -*-lexical-binding:t-*-

;; Author: Tom Tromey <tom@tromey.com>
;; Version: 1.0

(eval-when-compile
  (require 'compile)
  (require 'thingatpt)
  (require 'browse-url))

;; Copied from Emacs 25.
(unless (fboundp 'vc-root-dir)
  (require 'vc)
  (defun vc-root-dir ()
    "Return the root directory for the current VC tree.
Return nil if the root directory cannot be identified."
    (let ((backend (vc-deduce-backend)))
      (if backend
	  (condition-case err
	      (vc-call-backend backend 'root default-directory)
	    (vc-not-supported
	     (unless (eq (cadr err) 'root)
	       (signal (car err) (cdr err)))
	     nil))))))

(defvar dxr-server "http://dxr.mozilla.org/"
  "The DXR server to use.")

(defvar dxr-tree "mozilla-central"
  "The DXR source tree to use.")

;; It would be nice not to have to use the command, but this would
;; mean writing our own thing like compilation-mode and (the easy
;; part) interfacing to next-error.
(defvar dxr-cmd "dxr"
  "The local DXR command to invoke.")

(defun dxr--url-representing-point ()
  (unless (buffer-file-name)
    (error "Buffer is not visiting a file"))
  (let ((root (or (vc-root-dir)
		  (error "Could not find VC root directory"))))
    (concat dxr-server
	    dxr-tree
	    "/source/"
	    (file-relative-name (buffer-file-name) root)
	    "#"
	    (int-to-string (line-number-at-pos)))))

;;;###autoload
(defun dxr-browse-url ()
  "Open a DXR page for the source at point in a web browser.
This uses `dxr-server' and `dxr-tree' to compute the URL, and `browse-url'
to open the page in the browser."
  (interactive)
  (browse-url (dxr--url-representing-point)))

;;;###autoload
(defun dxr-kill-ring-save ()
  "Save a DXR URL for the source at point in the kill ring.
This uses `dxr-server' and `dxr-tree' to compute the URL."
  (interactive)
  (kill-new (dxr--url-representing-point)))

;;;###autoload
(defun dxr (args)
  "Run a DXR query and put the results into a buffer.
The results can be stepped through using `next-error'."
  (interactive (list
		(read-string (concat "Run dxr (with args): ")
			     (thing-at-point 'symbol))))
  (let* ((compile-command nil)
	 ;; It's nicer to start at the VC root.
	 (compilation-directory (or (vc-root-dir)
				    default-directory))
	 (default-directory compilation-directory))
    (compilation-start (concat dxr-cmd
			       " --grep --no-highlight"
			       " --server=" dxr-server
			       " --tree=" dxr-tree
			       " " args))))

(provide 'dxr)

;;; dxr.el ends here

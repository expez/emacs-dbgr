;;; Copyright (C) 2010, 2012 Rocky Bernstein <rocky@gnu.org>
;;; Debugger location
;;; Commentary:

;; This describes a debugger location structure and has code for
;; working with them.

(require 'load-relative)
(require 'loc-changes)
(require-relative-list '("fringe") "dbgr-")

(defstruct dbgr-loc
"Our own location type. Even though a mark contains a
file-name (via a buffer) and a line number (via an offset), we
want to save the values that were seen/requested originally."
   num           ;; If there is a number such as a breakpoint or frame
		 ;; number associated with this location, this is set.
		 ;; nil otherwise.
   filename  
   line-number
   column-number ;; Column offset within line
   marker        ;; Position in source code
   cmd-marker    ;; Position in command process buffer
)

(defalias 'dbgr-loc? 'dbgr-loc-p)

(defun dbgr-loc-describe (loc)
  "Display dbgr-cmdcbuf-info.
Information is put in an internal buffer called *Describe*."
  (interactive "")
  (switch-to-buffer (get-buffer-create "*Describe*"))
  (mapc 'insert
	(list 
	 (format "    num          : %s\n" (dbgr-loc-num loc))
	 (format "    filename     : %s\n" (dbgr-loc-filename loc))
	 (format "    line number  : %s\n" (dbgr-loc-line-number loc))
	 (format "    column number: %s\n" (dbgr-loc-column-number loc))
	 (format "    source marker: %s\n" (dbgr-loc-marker loc))
	 (format "    cmdbuf marker: %s\n" (dbgr-loc-cmd-marker loc))
	 ))
  )

(defun dbgr-loc-current(source-buffer cmd-marker)
  "Create a location object for the point in the current buffer."
  (with-current-buffer source-buffer
    (make-dbgr-loc 
     :filename (buffer-file-name source-buffer)
     :column-number (current-column)
     :line-number (line-number-at-pos) 
     :marker (point-marker)
     :cmd-marker cmd-marker
    )))

(defun dbgr-loc-marker=(loc marker)
  (setf (dbgr-loc-marker loc) marker))

(defun dbgr-loc-goto(loc)
  "Position point in the buffer referred to by LOC. This may
involve reading in a file.In the process, the marker inside loc
may be updated.

The buffer containing the location referred to, the source-code
buffer, is returned if LOC is found. nil is returned if LOC is
not not found"
  (if (dbgr-loc? loc) 
      (let* ((filename    (dbgr-loc-filename loc))
	     (line-number (dbgr-loc-line-number loc))
	     (column-number (dbgr-loc-column-number loc))
	     (marker      (dbgr-loc-marker loc))
	     (cmd-marker  (dbgr-loc-cmd-marker loc))
	     (src-buffer  (marker-buffer (or marker (make-marker)))))
	(if (and (not src-buffer) filename)
	    (setq src-buffer (find-file-noselect filename)))
	(if cmd-marker
	    (with-current-buffer (marker-buffer cmd-marker)
	      (goto-char cmd-marker)))
	(if src-buffer
	    (with-current-buffer src-buffer
	      (if (and marker (marker-position marker))
		  ;; A marker has been set in loc, so use that.
		  (goto-char (marker-position marker))
		;; We don't have a position set in the source buffer
		;; so find it and go there. We use `loc-changes-goto'
		;; to find that spot. `loc-changes-goto' keeps a
		;; record of the first time we went to that spot, so
		;; in the face of buffer modifications, it may be more
		;; reliable.
		(let ((src-marker))
		  (loc-changes-goto line-number)
		  (setq src-marker (point-marker))
		  (dbgr-loc-marker= loc src-marker)
		  ))))
	src-buffer )))

(provide-me "dbgr-")

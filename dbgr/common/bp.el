;; Copyright (C) 2010, 2012 Rocky Bernstein <rocky@gnu.org>
;; Code associated with breakpoints

(require 'image)
(require 'load-relative)
(require-relative-list '("loc" "bp-image-data") "dbgr-")

(defvar dbgr-bp-enabled-icon nil
  "Icon for an enabled breakpoint in display margin.")
      
(defvar dbgr-bp-disabled-icon nil
  "Icon for a disabled breakpoint in display margin.")

(defun set-bp-icons()
  (if (display-images-p)
      (progn
	;; NOTE: if you don't see the icon, check the that the window margin
	;; is not nil.
	(setq dbgr-bp-enabled-icon
	      (find-image `((:type xpm :data
				   ,dbgr-bp-xpm-data
				   :ascent 100 :pointer hand)
			    (:type svg :data
				   ,dbgr-bp-enabled-svg-data
				   :ascent 100 :pointer hand)
			    (:type tiff :data
				   ,dbgr-bp-enabled-tiff-data
				   :ascent 100 :pointer hand)
			    (:type pbm :data
				   ,dbgr-bp-enabled-pbm-data
				   :ascent 100 :pointer hand)
			    )))
	
	;; For seeing what dbgr-bp-enabled-icon looks like:
	;; (insert-image dbgr-bp-enabled-icon)
	
	(setq dbgr-bp-disabled-icon
	      (find-image `((:type xpm :data
				   ,dbgr-bp-xpm-data
				   :conversion disabled ;; different than 'enabled'
				   :ascent 100 :pointer hand)
			    (:type svg :data
				   ,dbgr-bp-disabled-svg-data
				   :ascent 100 :pointer hand)
			    (:type tiff :data
				   ,dbgr-bp-disabled-tiff-data
				   :ascent 100 :pointer hand)
			    (:type pbm :data
				   ,dbgr-bp-disabled-pbm-data
				   :ascent 100 :pointer hand)
			    (:type svg :data
				   ,dbgr-bp-disabled-svg-data
				   :ascent 100 :pointer hand)
			    )))
	;; For seeing what dbgr-bp-enabled-icon looks like:
	;; (insert-image dbgr-bp-disabled-icon)
	)
    (message "Display doesn't support breakpoint images in fringe")
    )
  )


(defun dbgr-bp-add-info (loc)
  "Record bp information for location LOC."
  (if (dbgr-loc? loc) 
      (let* ((marker (dbgr-loc-marker loc))
             (bp-num (dbgr-loc-num loc))
             )
        (dbgr-bp-put-icon marker 't bp-num)
        )
    )
)

(defun dbgr-bp-put-icon (pos enabled bp-num &optional opt-buf)
  "Add a breakpoint icon in the left margin at POS via a `put-image' overlay.
The alternate string name for the image is created from the value
of ENABLED and BP-NUM.  In particular, if ENABLED is 't and
BP-NUM is 5 the overlay string is be 'B5:' If ENABLED is false
then the overlay string is 'b5:'. Breakpoint text properties are
also attached to the icon via its display string."
  (let ((enabled-str)
        (buf (or opt-buf (current-buffer)))
        (bp-num-str
         (cond 
          ((or (not bp-num) (not (numberp bp-num))) ":")
          ('t (format "%d:" bp-num))))
        (brkpt-icon)
        (bp-str)
        (help-string "mouse-1: enable/disable bkpt")
        )
    (with-current-buffer buf
      (unless dbgr-bp-enabled-icon (set-bp-icons))
      (if enabled 
          (progn 
            (setq enabled-str "B")
            (setq brkpt-icon dbgr-bp-enabled-icon)
            )
        (progn
          (setq enabled-str "b")
          (setq brkpt-icon dbgr-bp-disabled-icon)
          ))
      ;; Create alternate display string and attach
      ;; properties it.
      (setq bp-str (concat enabled-str bp-num-str))
      (add-text-properties
       0 1 `(dbgr-bptno ,bp-num enabled ,enabled) bp-str)
      (add-text-properties
       0 1 (list 'help-echo (format "%s %s" bp-str help-string))
       bp-str)
      
      ;; Display breakpoint icon or display string.  If the window is
      ;; nil, the image doesn't get displayed, so make sure it is large
      ;; enough.
      (let ((window (get-buffer-window (current-buffer) 0)))
        (if window
            (set-window-margins window 2)
          ;; FIXME: This is all crap, but I don't know how to fix.
          (let ((buffer-save (window-buffer (selected-window))))
            (set-window-buffer (selected-window) (current-buffer))
            (set-window-margins (selected-window) 2)
            (set-window-buffer (selected-window) buffer-save))
          ))
      (dbgr-bp-remove-icons pos)
      (if brkpt-icon
          (put-image brkpt-icon pos bp-str 'left-margin))
      )
    )
  )

(defun dbgr-bp-remove-icons (&optional opt-begin-pos opt-end-pos)
  "Remove dbgr breakpoint icons (overlays) in the region
OPT-BEGIN-POS to OPT-END-POS. The default value for OPT-BEGIN-POS
is `point'.  The default value for OPT-END-POS is OPT-BEGIN-POS.

The way we determine if an overlay is ours is by inspecting the
overlay for a before-string property containing one we normally set.
"
  (interactive "r")
  (let* ((begin-pos (or opt-begin-pos (point)))
         (end-pos (or opt-end-pos begin-pos))
        )
    (dolist (overlay (overlays-in begin-pos end-pos))
      ;; We determine if this overlay is one we set by seeing if the 
      ;; string in its 'before-string property has a 'dbgr-bptno property
      (let ((before-string (overlay-get overlay 'before-string)))
        (when (and before-string (get-text-property 0 'dbgr-bptno before-string))
          (delete-overlay overlay)
          )
        )
      )
    )
  )

(provide-me "dbgr-")

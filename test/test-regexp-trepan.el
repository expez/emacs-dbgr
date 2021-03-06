(require 'test-simple)
(load-file "../dbgr/debugger/trepan/init.el")
(load-file "./regexp-helper.el")

(test-simple-start)

(set (make-local-variable 'bps-pat)
     (gethash "brkpt-set"          dbgr-trepan-pat-hash))
(set (make-local-variable 'dbg-bt-pat)
     (gethash "debugger-backtrace" dbgr-trepan-pat-hash))
(set (make-local-variable 'prompt-pat)
     (gethash "prompt"             dbgr-trepan-pat-hash))
(set (make-local-variable 'lang-bt-pat)
     (gethash "lang-backtrace"     dbgr-trepan-pat-hash))
(set (make-local-variable 'ctrl-pat)
     (gethash "control-frame"      dbgr-trepan-pat-hash))

;; FIXME: we get a void variable somewhere in here when running
;;        even though we define it in lexical-let. Dunno why.
;;        setq however will workaround this.
(set (make-local-variable 'text)
 "	from /usr/local/bin/irb:12:in `<main>'")

(note "traceback location matching")

(setq text "	from /usr/local/bin/irb:12:in `<main>'")

(assert-t (numberp (loc-match text lang-bt-pat)) 
	  "basic traceback location")
(assert-equal "/usr/local/bin/irb"
	      (match-string (dbgr-loc-pat-file-group lang-bt-pat) text) 
	      "extract traceback file name")

(assert-equal "12"
	      (match-string (dbgr-loc-pat-line-group 
			     lang-bt-pat) text) 
	      "extract traceback line number")

(note "debugger-backtrace")
(set (make-local-variable 's1)
     "--> #0 METHOD Object#require(path) in file <internal:lib/require> at line 28
    #1 TOP Object#<top /tmp/linecache.rb> in file /tmp/linecache.rb
")

(set (make-local-variable 'frame-re)
     (dbgr-loc-pat-regexp dbg-bt-pat))
(set (make-local-variable 'num-group)
     (dbgr-loc-pat-num dbg-bt-pat))
(set (make-local-variable 'file-group)
     (dbgr-loc-pat-file-group dbg-bt-pat))
(set (make-local-variable 'line-group)
     (dbgr-loc-pat-line-group dbg-bt-pat))

(assert-equal 0 (string-match frame-re s1))
(assert-equal "0" (substring s1 
			     (match-beginning num-group)
			     (match-end num-group)))
(assert-equal "<internal:lib/require>"
	      (substring s1 
			 (match-beginning file-group)
			 (match-end file-group)))
(assert-equal "28"
	      (substring s1 
			 (match-beginning line-group)
			 (match-end line-group)))
(setq pos (match-end 0))

(assert-equal 77 (string-match frame-re s1 pos))
(assert-equal "1" (substring s1 
			     (match-beginning num-group)
			     (match-end num-group)))
(assert-equal "/tmp/linecache.rb"
	      (substring s1 
			 (match-beginning file-group)
			 (match-end file-group)))

(note "prompt")
(prompt-match "(trepan): ")
(prompt-match "((trepan)): " nil "nested debugger prompt: %s")
(prompt-match "((trepan@55)): " "@55" "nested debugger prompt with addr: %s")
(prompt-match "((trepan@main)): " "@main" 
	      "nested debugger prompt with method: %s")
(setq prompt-str "trepan:")
(assert-nil (loc-match prompt-str prompt-pat)
	    (format "invalid prompt %s" prompt-str))


(note "control-frame")
(assert-equal 0 (loc-match 
		 "c:0026 p:0181 s:0136 b:0136 l:000135 d:000135 METHOD /trepan-0.0.1/app/frame.rb:132 "
		 ctrl-pat)
	      )
(assert-equal 0 (loc-match 
		 "c:0030 p:0041 s:0144 b:0144 l:00226c d:00226c METHOD /gems/trepan-0.0.1/processor/eval.rb:15 "
		 ctrl-pat)
	      )
(assert-equal 0 (loc-match 
		 "c:0015 p:0139 s:0070 b:0070 l:000063 d:000069 BLOCK  /gems/app/core.rb:121"
		 ctrl-pat)
	      )

(setq text "Breakpoint 1 set at VM offset 2 of instruction sequence \"<top /usr/local/bin/irb>\",
	line 9 in file /usr/local/bin/irb.
")


(assert-t (numberp (loc-match text bps-pat))
	  "basic breakpoint location")


(assert-equal "/usr/local/bin/irb"
	      (match-string (dbgr-loc-pat-file-group 
			     bps-pat) text) 
	      "extract breakpoint file name")

(assert-equal "9"
	      (match-string (dbgr-loc-pat-line-group 
			     bps-pat) text) 
	      "extract breakpoint line number")

(end-tests)


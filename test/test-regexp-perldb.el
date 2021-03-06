(require 'test-simple)
(load-file "../dbgr/common/buffer/command.el")
(load-file "../dbgr/debugger/perldb/init.el")
(load-file "./regexp-helper.el")

(test-simple-start)

; Some setup usually done in setting up the buffer.
; We customize this for this debugger.
; FIXME: encapsulate this.
(setq dbg-name "perldb")
(set (make-local-variable 'loc-pat)
     (gethash "loc"    (gethash dbg-name dbgr-pat-hash)))
(set (make-local-variable 'prompt-pat)
     (gethash "prompt" dbgr-perldb-pat-hash))

(setq dbgr (make-dbgr-cmdbuf-info
		  :debugger-name dbg-name
		  :loc-regexp (dbgr-loc-pat-regexp loc-pat)
		  :file-group (dbgr-loc-pat-file-group loc-pat)
		  :line-group (dbgr-loc-pat-line-group loc-pat)))

(note "prompt")
(prompt-match "  DB<2> "  "2")
(prompt-match "[pid=6489->6502]  DB<1> " "1")

(assert-equal 0 (string-match dbgr-perl-ignore-file-re
			      "(eval 1006)[../example/eval.pl:5]")
	      "perldb file ignore matching")

(setq text "main::(/usr/bin/latex2html:102):")
	 
(assert-t (numberp (cmdbuf-loc-match text dbgr)) "basic location")
(assert-equal "/usr/bin/latex2html"
	      (match-string (dbgr-cmdbuf-info-file-group dbgr) text)
	      "extract file name")

(setq text "main::((eval 6)[eval.pl:5]:2):	$x = 2;")
	 
(assert-t (numberp (cmdbuf-loc-match text dbgr)) "eval location")
(assert-equal "(eval 6)[eval.pl:5]"
	      (match-string (dbgr-cmdbuf-info-file-group dbgr) text)
	      "extract file name")

(assert-equal "2"
	      (match-string (dbgr-cmdbuf-info-line-group dbgr)
			    text) "extract line number")

(note "location for with CODE in it")
(setq text "main::CODE(0x9407ac8)(l2hconf.pm:6):")
(assert-t (numberp (cmdbuf-loc-match text dbgr)))
(assert-equal "l2hconf.pm"
	      (match-string (dbgr-cmdbuf-info-file-group dbgr)
			    text))
(assert-equal "6"
	      (match-string (dbgr-cmdbuf-info-line-group dbgr)
			    text))

(note "debugger-backtrace")
(setq dbgr-bt-pat  (gethash "debugger-backtrace"  
			    dbgr-perldb-pat-hash))
(setq s1
      "$ = main::top_navigation_panel called from file `./latex2html' line 7400
p")
(setq dbgr-bt-re (dbgr-loc-pat-regexp dbgr-bt-pat))
(setq file-group (dbgr-loc-pat-file-group dbgr-bt-pat))
(setq line-group (dbgr-loc-pat-line-group dbgr-bt-pat))
(assert-equal 30 (string-match dbgr-bt-re s1))
(assert-equal "./latex2html"
	      (substring s1 
			 (match-beginning file-group)
			 (match-end file-group)))
(assert-equal "7400"
	      (substring s1 
			 (match-beginning line-group)
			 (match-end line-group)))

(note "debugger-errmsg")
(setq dbgr-bt-pat  (gethash "perl-errmsg"  
			    dbgr-perldb-pat-hash))
(setq s1
      "Use of uninitialized value $lines[0] in join or string at bin/../lib/LineCache.pm line 548.")
(setq dbgr-bt-re (dbgr-loc-pat-regexp dbgr-bt-pat))
(setq file-group (dbgr-loc-pat-file-group dbgr-bt-pat))
(setq line-group (dbgr-loc-pat-line-group dbgr-bt-pat))
(assert-equal 54 (string-match dbgr-bt-re s1))
(assert-equal "bin/../lib/LineCache.pm"
	      (substring s1 
			 (match-beginning file-group)
			 (match-end file-group)))
(assert-equal "548"
	      (substring s1 
			 (match-beginning line-group)
			 (match-end line-group)))

(note "carp-backtrace")
(setq s1
      " at /tmp/foo.pl line 7
 	main::__ANON__('Illegal division by zero at /tmp/foo.pl line 4.\x{a}') called at foo2.pl line 5
 	main::foo(3) called at foo3.pl line 8
")
(setq lang-bt-pat (gethash "lang-backtrace"  
			   dbgr-perldb-pat-hash))
(setq carp-bt-re (dbgr-loc-pat-regexp lang-bt-pat))
(setq file-group (dbgr-loc-pat-file-group lang-bt-pat))
(setq line-group (dbgr-loc-pat-line-group lang-bt-pat))
(assert-equal 0 (string-match carp-bt-re s1))
(assert-equal "/tmp/foo.pl"
	      (substring s1 
			 (match-beginning file-group)
			 (match-end file-group)))
(assert-equal "7"
	      (substring s1 
			 (match-beginning line-group)
			 (match-end line-group)))
(setq pos (match-end 0))

(assert-equal 22 (string-match carp-bt-re s1 pos))
(assert-equal "foo2.pl"
	      (substring s1 
			 (match-beginning file-group)
			 (match-end file-group)))
(assert-equal "5"
	      (substring s1 
			 (match-beginning line-group)
			 (match-end line-group)))

(setq pos (match-end 0))
(assert-equal 119 (string-match carp-bt-re s1 pos))
(assert-equal "foo3.pl"
	      (substring s1 
			 (match-beginning file-group)
			 (match-end file-group)))
(assert-equal "8"
	      (substring s1 
			 (match-beginning line-group)
			 (match-end line-group)))

(end-tests)


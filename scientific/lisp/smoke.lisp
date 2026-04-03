(let ((root (make-pathname :name nil :type nil :defaults *load-truename*)))
  (load (merge-pathnames "package.lisp" root))
  (load (merge-pathnames "symbolic-rules.lisp" root)))

(format t "Breakdex Lisp smoke: ~a~%" (breakdex-science:classify-move-notes "freeze entry"))

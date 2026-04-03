(in-package #:breakdex-science)

(defun classify-move-notes (text)
  (cond
    ((search "freeze" text :test #'char-equal) :freeze)
    ((search "footwork" text :test #'char-equal) :footwork)
    ((search "toprock" text :test #'char-equal) :toprock)
    (t :unknown)))

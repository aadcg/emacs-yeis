;;; x-leim-list.el -- Extended LEIM (Library of Emacs Input Method)

;; Copyright © 2020 André A. Gomes <andremegafone@gmail.com>

;; This file complements the list of LEIM (Library of Emacs Input
;; Method) that comes with GNU Emacs.
;;
;; Have a look at the function ‘register-input-method’ for more info.
;;
;; The following additional input methods will be loaded at startup time.

(register-input-method
 "robin-russian"
 "Russian"
 'robin-use-package
 modeline-ru-identifier
 "ЙЦУКЕН Russian computer layout")

(register-input-method
 "robin-russian-dvorak"
 "Russian Dvorak"
 'robin-use-package
 modeline-ru-identifier
 "ЙЦУКЕН Russian Dvorak computer layout")

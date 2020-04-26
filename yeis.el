;;; yeis.el --- Yeis's Emacs' Input Switcher

;; Copyright © 2020 André A Gomes <andremegafone@gmail.com>

;; Version: 0.0.1
;; URL: https://github.com/?

;; Yeis is NOT part of GNU Emacs.

;; Yeis is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.

;; Yeis is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
;; for more details.

;; For a full copy of the GNU General Public License see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Yeis's Emacs' Input Switcher. It should be pronounced as yes.
;; It has two goals.
;; 1) Provide an easy way to convert text to and from a given input method;
;; 2) Provide a minor mode that makes that conversion automatically.

;; http://www-personal.umich.edu/~jlawler/wordlist.html
;; added i'm you're he's she's it's we're they're

;;; Code:

(require 'robin)
(require 'ispell)

(defcustom modeline-ru-identifier "RU"
  "String to show in the mode line when the russian input method
  is active.")

(defcustom toggle-input-method-after-translation t
  "Whether to toggle the input method after a translation.")

;; useless
;; (add-hook 'input-method-activate-hook
;;           (lambda () (change-to-dict default-russian-dict)))

;; (add-hook 'input-method-deactivate-hook
;;           (lambda () (change-to-dict default-english-dict)))

;; (defun change-to-dict (dict)
;;   "Change to the dictionary given by string DICT."
;;   (let ((inhibit-message t))
;;     (ispell-change-dictionary dict)))

;; (defvar default-russian-dict "ru"
;;   "String that identifies the russian dictionary to use.")

;; (defvar default-english-dict "en"
;;   "String that identifies the english dictionary to use.")

;; as the number of input methods grow, this should be moved to another file
(robin-define-package "robin/russian"
		      "ЙЦУКЕН Russian computer layout

    1!  2\"  3№  4;  5%  6:  7?  8*  9(  0)  -_  =+  \\/  ёЁ
     йЙ  цЦ  уУ  кК  еЕ  нН  гГ  шШ  щЩ  зЗ  хХ  ъЪ
      фФ  ыЫ  вВ  аА  пП  рР  оО  лЛ  дД  жЖ  эЭ
       яЯ  чЧ  сС  мМ  иИ  тТ  ьЬ  бБ  юЮ  .,"

                      ("`" ?ё)
                      ("@" ?\")
                      ("#" ?№)
                      ("$" ?\;)
                      ("^" ?:)
                      ("&" ??)
                      ("~" ?Ё)
                      ("q" ?й)
                      ("w" ?ц)
                      ("e" ?у)
                      ("r" ?к)
                      ("t" ?е)
                      ("y" ?н)
                      ("u" ?г)
                      ("i" ?ш)
                      ("o" ?щ)
                      ("p" ?з)
                      ("[" ?х)
                      ("]" ?ъ)
                      ("Q" ?Й)
                      ("W" ?Ц)
                      ("E" ?У)
                      ("R" ?К)
                      ("T" ?Е)
                      ("Y" ?Н)
                      ("U" ?Г)
                      ("I" ?Ш)
                      ("O" ?Щ)
                      ("P" ?З)
                      ("{" ?Х)
                      ("}" ?Ъ)
                      ("|" ?/)
                      ("a" ?ф)
                      ("s" ?ы)
                      ("d" ?в)
                      ("f" ?а)
                      ("g" ?п)
                      ("h" ?р)
                      ("j" ?о)
                      ("k" ?л)
                      ("l" ?д)
                      (";" ?ж)
                      ("'" ?э)
                      ("A" ?Ф)
                      ("S" ?Ы)
                      ("D" ?В)
                      ("F" ?А)
                      ("G" ?П)
                      ("H" ?Р)
                      ("J" ?О)
                      ("K" ?Л)
                      ("L" ?Д)
                      (":" ?Ж)
                      ("\"" ?Э)
                      ("z" ?я)
                      ("x" ?ч)
                      ("c" ?с)
                      ("v" ?м)
                      ("b" ?и)
                      ("n" ?т)
                      ("m" ?ь)
                      ("," ?б)
                      ("." ?ю)
                      ("/" ?.)
                      ("Z" ?Я)
                      ("X" ?Ч)
                      ("C" ?С)
                      ("V" ?М)
                      ("B" ?И)
                      ("N" ?Т)
                      ("M" ?Ь)
                      ("<" ?Б)
                      (">" ?Ю)
                      ("?" ?,))

(register-input-method
 "robin/russian"
 "Russian"
 'robin-use-package
 modeline-ru-identifier
 "ЙЦУКЕН Russian computer layout")

(defun point-last-whitespace (arg)
  "Returns the point after the last whitespace.

With prefix argument ARG, returns the above after going back to
the previous whitespace ARG times."
  (let ((regex "[\n[:space:]][^[:space:]\n]"))
    (save-excursion
      (re-search-backward regex nil t arg))))

;; if the selected input method is flawed, then this is flawed
;; if current-input-method is ru and ";;"
;; I could check the last char if >127
(defun translate-current-word (arg)
  "Translate the current word to the other input method.

The current word is the word at or neat point."
  (interactive "p")
  (let ((beg (or (point-last-whitespace arg) (point-min)))
        (end (point)))
    (if current-input-method
        (robin-invert-region beg end)
      (robin-convert-region beg end))
    (when toggle-input-method-after-translation
      (toggle-input-method))))

(defun nonsense-word-p ()
  "
;; Check if last word contains only latin letters or numbers.

;; Let's break the following regex down:
;; []}{[<>`~]\\|[.,;:][^ \n]

;; There are actually 2 regex pieces so let's analyze each one.

;; [.,;:][^ \n]

;; This part guarantees that a punction mark doesn't occur at the
;; end of a word.

;; [][{}<>\\|`~]

;; A regex for '\" (эЭ) is missing.
"
  (unless current-input-method
    (let ((regex "[]}{[<>`~]\\|[.,;:][^ \n]"))
      (save-excursion
        (re-search-backward regex (point-last-whitespace 1) t)))))

(defun length-one-rule ()
  "Translates a word of length one.

English has two words of length one - \"a\" and \"I\".

The necessary translations are done, taking into account the
input method at use."
  (let ((word (yeis-current-word)))
    (and
     (eq (length word) 1)
     (if current-input-method
         ;; "a" before "i" since it is more common in English
         (or (equalp word "a") (equalp word "i"))
       (not (or (equalp word "a") (equalp word "i")))))))

;; TODO method to download wordlist
;; escape [ character when using grep
(defun check-prefixed-word ()
  "Test."
  (let ((ispell-alternate-dictionary
         "/home/aadcg/repos/yeis/wordlist")
        (inhibit-message t)
        ;; (ispell-lookup-words "-Fi")
        (word (yeis-current-word)))
    (and
     (and (>= (length word) 3) (<= (length word) 4))
     (if current-input-method
         (ispell-lookup-words word)
       (not (ispell-lookup-words word))))))

(defun yeis-current-word ()
  "Return last word translated to the QWERTY layout as string.

Recall that a word is something that is surrounded by whitespaces.
Therefore \";tcnm\" (жесть) qualifies as a word.

Return last word as string.

Recall that a word is something that is surrounded by whitespaces.
Therefore \";tcnm\" (жесть) qualifies as a word."
  (let ((beg (point-last-whitespace 1))
        (end (point)))
    (if current-input-method
        (mapconcat
         (lambda (x)
           (get-char-code-property x (intern robin-current-package-name)))
         (buffer-substring beg end) "")
      (s-trim (buffer-substring beg end)))))

;; 13 return 10 newline 32 spc
(defun rules ()
  "Hook that decides wether or not to change last word."
  (let ((toggle-input-method-after-translation t)
        (inserted-whitespace-p (member (char-before) '(13 10 32))))
    (when (and inserted-whitespace-p (length-one-rule))
      (translate-current-word 1))
    (unless inserted-whitespace-p
      (when (or (nonsense-word-p) (check-prefixed-word))
        (translate-current-word 1)))))

(define-minor-mode yeis-mode
  "Activate yeis-mode."
  nil " Ye" nil
  (if yeis-mode
      (add-hook 'post-self-insert-hook #'rules nil t)
    (remove-hook 'post-self-insert-hook #'rules t)))

;;; yeis.el ends here

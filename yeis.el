;;; yeis.el --- Yeis's Emacs' Input Switcher

;; Copyright © 2020 André A. Gomes <andremegafone@gmail.com>

;; Version: 0.1
;; URL: https://github.com/aadcg/emacs-yeis

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

;; It pretends to:

;; 1) Translate text to and from non-CJK input methods;
;; 2) Auto translation and auto input method selection (yeis-mode).

;; Please note that IM stands for input method.

;;; Code:

(require 'robin)
(require 'ispell)

(defvar modeline-ru-identifier "RU"
  "Mode line IM string indicator.")

(defvar toggle-input-method-after-translation t
  "Whether to toggle the IM after a translation.")

(defvar yeis-nonsense-word-regex "[]}{[<>`~]\\|[.,;:][^ \n]"
  "Regex that matches a nonsense word in English.")

(defvar yeis-path-plain-word-list nil
  "Path for the plain english word-list.")

;; as the number of IMs grow, this should be moved to another file
(robin-define-package "robin/russian"
		      "ЙЦУКЕН Russian computer layout

    1!  2\"  3№  4;  5%  6:  7?  8*  9(  0)  -_  =+  \\/  ёЁ
     йЙ  цЦ  уУ  кК  еЕ  нН  гГ  шШ  щЩ  зЗ  хХ  ъЪ
      фФ  ыЫ  вВ  аА  пП  рР  оО  лЛ  дД  жЖ  эЭ
       яЯ  чЧ  сС  мМ  иИ  тТ  ьЬ  бБ  юЮ  .,"

                      ("1" ?1)
                      ("2" ?2)
                      ("3" ?3)
                      ("4" ?4)
                      ("5" ?5)
                      ("6" ?6)
                      ("7" ?7)
                      ("8" ?8)
                      ("9" ?9)
                      ("0" ?0)
                      ("-" ?-)
                      ("=" ?=)
                      ("|" ?/)
                      ("`" ?ё)
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
                      ("\\" ?\\)
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
                      ("!" ?!)
                      ("@" ?\")
                      ("#" ?№)
                      ("$" ?\;)
                      ("%" ?%)
                      ("^" ?:)
                      ("&" ??)
                      ("*" ?*)
                      ("(" ?\()
                      (")" ?\))
                      ("_" ?_)
                      ("+" ?+)
                      ("~" ?Ё)
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
                      ("|" ?|)
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

(defun yeis-last-whitespace (arg)
  "Return the point of the last whitespace.

With prefix argument ARG, do it ARG times."
  (let ((regex "[\n[:space:]][^[:space:]\n]"))
    (save-excursion
      (re-search-backward regex nil t arg))))

(defun yeis-translate-current-word (arg)
  "Translate the current word to the other IM.

Other IM means - if `current-input-method' is nil, then
translate the current word to a non-nil `current-input-method',
and vice-versa.

The current word is the closest set of characters delimited by a
whitespace character on the left.

With prefix argument ARG, translate ARG words from cursor
position."
  (interactive "p")
  (let ((beg (or (yeis-last-whitespace arg) (point-min)))
        (end (point)))
    (if current-input-method
        (robin-invert-region beg end)
      (robin-convert-region beg end))
    (when toggle-input-method-after-translation
      (toggle-input-method))))

;; The above suffices to achieve goal number one.

;; Users might find it useful to bind `yeis-translate-current-word' to "C-|".
;; (global-set-key (kbd "C-|") 'yeis-translate-current-word)

;; If you want this functionality for a different IM, please read the
;; section "How to define conversion rules" of the `robin' package.

;; What follows is a hacky suggestion to achieve goal number two.

;; If the user makes a typo while inserting an english word, then it gets
;; translated. That reflects the alpha state of what you'll find below.

(define-minor-mode yeis-mode
  "Toggle automatic IM selection (Yeis mode)."
  nil " Ye" nil
  (if yeis-mode
      (add-hook 'post-self-insert-hook #'yeis-rules nil t)
    (remove-hook 'post-self-insert-hook #'yeis-rules t)))

(defun yeis-rules ()
  "Translate the word at point and change IM automatically.

Conditions must be met to trigger `yeis-translate-current-word'.
Namely, there are two kinds of rules. Some run after pressing RET
or SPC. Others run otherwise."
  (let ((toggle-input-method-after-translation t)
        (inserted-whitespace-p (member (char-before) '(13 32))))
    (if inserted-whitespace-p
        (when (or (yeis-l1-p) (yeis-word-p))
          (yeis-translate-current-word 1))
      (when (or (yeis-nonsense-word-p) (yeis-prefix-p))
        (yeis-translate-current-word 1)))))

(defun yeis-nonsense-word-p ()
  "Return t if current word is nonsense.

The check only makes sense when no IM is selected. Nonsense means
that there's a match for the regex `yeis-nonsense-word-regex'.
That regex basically checks for the presence of characters that
don't constitute a well-formed word in english.

Let me provide some examples in the case of the traditional
йцукен keyboard.

[jhjij <-> хорошо
k.,k.  <-> люблю
;tcnm  <-> жесть"
  (unless current-input-method
    (save-excursion
      (re-search-backward yeis-nonsense-word-regex (yeis-last-whitespace 1) t))))

(defun yeis-l1-p ()
  "Return t if the current word of length 1 requires translation.

English only has two words of length one - \"a\" and \"I\".

The necessary boolean is computed, taking into account the
selected IM.

It could be argued that there are other length 1 words like \"w\"."
  (let ((word (yeis-current-word)))
    (and
     (eq (length word) 1)
     (if current-input-method
         ;; "a" before "i" since it is more common in English
         (or (equalp word "a") (equalp word "i"))
       (not (or (equalp word "a") (equalp word "i")))))))

(defun yeis-prefix-p ()
  "Return t if the current prefix requires translation.

A prefix is a word of length between 3 and 4.

The necessary boolean is computed, taking into account the
selected IM."
  (let ((inhibit-message t)
        (word (yeis-current-word))
        (wordlist yeis-path-plain-word-list))
    (and
     (>= (length word) 3)
     (<= (length word) 4)
     (not (string-match yeis-nonsense-word-regex word))
     (if current-input-method
         (ispell-lookup-words word wordlist)
       (not (ispell-lookup-words word wordlist))))))

(defun yeis-word-p ()
  "Return t if the current word requires translation.

This is similar to `yeis-word-p', whereas in this method the
boolean reflects the existence of a full word match."
  (let ((inhibit-message t)
        (word (downcase (yeis-current-word)))
        (wordlist yeis-path-plain-word-list))
    (and (>= (length word) 2)
         (if current-input-method
             (string-equal word (car (ispell-lookup-words word wordlist)))
           (not (string-equal word (car (ispell-lookup-words word wordlist))))))))

(defun yeis-current-word ()
  "Return the current word as string, as it is without an IM selected.

In short, regard the RULES of `robin-define-package' as a
bijection. This method provides the inverse function when an IM
is active.

When no IM is active, then the above is bypassed.

In either case, the word is stripped of punctuation for obvious
reasons.

Recall that a word, in the context of yeis, is a text string
composed by any non-whitespace characters and delimited by
whitespaces (or borders like the beginning/end of a buffer).

Notice that this contrasts with the Emacs' definition of a word.

Let me give you an example of a word that qualifies as such in
the context of yeis, but not in the context of Emacs' definiton.

Take \".kz\" (юля). Run `backward-word' with the cursor placed at
the end of the following line.

.kz"
  (let ((beg (or (yeis-last-whitespace 1) (point-min)))
        (end (point)))
    (if current-input-method
        (strip-punctuation
         (mapconcat
          (lambda (x)
            (get-char-code-property x (intern robin-current-package-name)))
          (buffer-substring beg end) ""))
      (strip-punctuation
       (s-trim
        (buffer-substring beg end))))))

(defun strip-punctuation (word)
  "Strip WORD from punctuation.

TODO extend this method to strip quotes"
  (if (string-match "[.,;:!?]$" word)
      (substring word 0 -1)
    word))

;;; yeis.el ends here

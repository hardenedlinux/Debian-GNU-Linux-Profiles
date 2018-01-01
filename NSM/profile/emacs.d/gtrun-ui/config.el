(which-function-mode)
( setq-default header-line-format
               '((which-func-mode ("" which-func-format " "))))
;; more useful frame title, that show either a file or a
;; buffer name (if the buffer isn't visiting a file)
(setq frame-title-format
      '("" " GTrun - "
        (:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name)) "%b"))))

(define-fringe-bitmap 'right-curly-arrow
  [#b00000000
   #b00000000
   #b00000000
   #b00000000
   #b01110000
   #b00010000
   #b00010000
   #b00000000])

(define-fringe-bitmap 'left-curly-arrow
  [#b00000000
   #b00001000
   #b00001000
   #b00001110
   #b00000000
   #b00000000
   #b00000000
   #b00000000])

(add-hook 'prog-mode-hook 'linum-mode)

;; http://stackoverflow.com/questions/3875213/turning-on-linum-mode-when-in-python-c-mode
(setq linum-mode-inhibit-modes-list '(eshell-mode
                                      shell-mode
                                      profiler-report-mode
                                      ffip-diff-mode
                                      dictionary-mode
                                      erc-mode
                                      browse-kill-ring-mode
                                      etags-select-mode
                                      dired-mode
                                      help-mode
                                      text-mode
                                      fundamental-mode
                                      jabber-roster-mode
                                      jabber-chat-mode
                                      inferior-js-mode
                                      inferior-python-mode
                                      inferior-scheme-mode
                                      twittering-mode
                                      compilation-mode
                                      weibo-timeline-mode
                                      woman-mode
                                      Info-mode
                                      calc-mode
                                      calc-trail-mode
                                      comint-mode
                                      gnus-group-mode
                                      inf-ruby-mode
                                      gud-mode
                                      org-mode
                                      org-agenda-mode
                                      vc-git-log-edit-mode
                                      log-edit-mode
                                      term-mode
                                      spacemacs-buffer-mode
                                      w3m-mode
                                      speedbar-mode
                                      gnus-summary-mode
                                      gnus-article-mode
                                      calendar-mode))
(defadvice linum-on (around linum-on-inhibit-for-modes)
  "Stop the load of linum-mode for some major modes."
  (unless (member major-mode linum-mode-inhibit-modes-list)
    ad-do-it))
(ad-activate 'linum-on)

;; (eval-after-load "linum"
;;   '(set-face-attribute 'linum nil :height 140))

;; updated line number every second
(setq linum-delay t)
(defadvice linum-schedule (around my-linum-schedule () activate)
  (run-with-idle-timer 0.1 nil #'linum-update-current))
(setq user-mail-address "gtrunhack@gmail.com")
(toggle-truncate-lines nil)

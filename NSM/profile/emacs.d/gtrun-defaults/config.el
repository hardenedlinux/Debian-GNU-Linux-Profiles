(setq-default pdf-view-display-size 'fit-page)
;; automatically annotate highlights
(setq pdf-annot-activate-created-annotations t)
;; use normal isearch
;; turn off cua so copy works

(defun my-ranger ()
  (interactive)
  (if golden-ratio-mode
      (progn
        (golden-ratio-mode -1)
        (ranger)
        (setq golden-ratio-previous-enable t))
    (progn
      (ranger)
      (setq golden-ratio-previous-enable nil))))

(defun my-quit-ranger ()
  (interactive)
  (if golden-ratio-previous-enable
      (progn
        (ranger-close)
        (golden-ratio-mode 1))
    (ranger-close)))

(with-eval-after-load 'ranger
  (progn
    (define-key ranger-normal-mode-map (kbd "q") 'my-quit-ranger)))

(spacemacs/set-leader-keys "ar" 'my-ranger)






;; Setting Chinese Font
(when (and (spacemacs/system-is-mswindows) window-system)
  (setq ispell-program-name "aspell")
  (setq w32-pass-alt-to-system nil)
  (setq w32-apps-modifier 'super)
  (dolist (charset '(kana han symbol cjk-misc bopomofo))
    (set-fontset-font (frame-parameter nil 'font)
                      charset
                      (font-spec :family "Monaco" :size 17))))


(setq-default TeX-PDF-mode t)
(add-hook 'org-mode-hook 'iimage-mode) ; enable iimage-mode for org-mode


(defun toggle-company-ispell ()
  (interactive)
  (cond
   ((memq 'company-ispell company-backends)
    (setq company-backends (delete 'company-ispell company-backends))
    (message "company-ispell disabled"))
   (t
    (add-to-list 'company-backends 'company-ispell)
    (message "company-ispell enabled!"))))
;;blog 
;; (setq op/theme 'wy)
;; (setq op/repository-directory "~/org-notes/gtrunsec.github.io")
;; (setq op/site-domain "https://gtrunsec.githun.io")
;; ;;; for commenting, you can choose either disqus, duoshuo or hashover
;; (setq op/personal-github-link "https://github.com/GTrunSec/")
;; (setq op/site-main-title "GTruN")
;; (setq op/site-sub-title "Security/Arch/Emacs/RTL_SDR")


;;xelatex
(setq tex-command "xelatex")
(setq-default TeX-engine 'xelatex)
(setq-default TeX-PDF-mode t)  
;;email
(setq wl-smtp-connection-type 'starttls
      wl-smtp-posting-port 587
      wl-smtp-authenticate-type "plain"
      wl-smtp-posting-user "gtrunhack"
      wl-smtp-posting-server "smtp.gmail.com"
      wl-local-domain "gmail.com"
      wl-message-id-domain "smtp.gmail.com")

;;  cnfonts-default

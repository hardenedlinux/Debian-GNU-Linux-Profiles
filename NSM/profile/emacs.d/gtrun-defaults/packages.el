(defconst gtrun-defaults-packages
  '(
    (dired-mode :location built-in)
    ;;(profiler :location built-in)
    (recentf :location built-in)
    )
  )

(defun gtrun-defaults/init-dired-mode ()
  (use-package dired-mode
    :defer t
    :init
    (progn
      ;; (require 'dired-x)
      
      (defun open-current-directory-with-external-program ()
        "Open current directory with external program."
        (interactive)
        (call-process "open" nil 0 nil (file-truename default-directory))
        )      
      (setq dired-listing-switches "-alh")
      (setq dired-omit-files "^\\...+$")
      (setq dired-guess-shell-alist-user
            '(("\\.pdf\\'" "open")
              ("\\.docx\\'" "open")
              ("\\.\\(?:djvu\\|eps\\)\\'" "open")
              ("\\.\\(?:jpg\\|jpeg\\|png\\|gif\\|xpm\\)\\'" "open")
              ("\\.\\(?:xcf\\)\\'" "open")
              ("\\.csv\\'" "open")
              ("\\.tex\\'" "open")
              ("\\.\\(?:mp4\\|mkv\\|avi\\|flv\\|ogv\\)\\(?:\\.part\\)?\\'"
               "open")
              ("\\.\\(?:mp3\\|flac\\)\\'" "open")
              ("\\.html?\\'" "open")
              ("\\.md\\'" "open")))

      (setq dired-omit-files
            (concat dired-omit-files "\\|^.DS_Store$\\|^.projectile$\\|\\.js\\.meta$\\|\\.meta$"))

      (defun my-dired-backward ()
        "Go back to the parent directory (..), and the cusor will be moved to where
          the previous directory."
        (interactive)
        (let* ((DIR (buffer-name)))
          (if (equal DIR "*Find*")
              (quit-window t)
            (progn (find-alternate-file "..")
                   (re-search-forward DIR nil :no-error)
                   (revert-buffer))))
        (define-key dired-mode-map (kbd "q") 'my-dired-backward)
        )
      (defvar v-dired-omit t
        "If dired-omit-mode enabled by default. Don't setq me.")
      (defun dired-omit-and-remember ()
        "This function is a small enhancement for `dired-omit-mode', which will
        \"remember\" omit state across Dired buffers."
        (interactive)
        (setq v-dired-omit (not v-dired-omit))
        (dired-omit-auto-apply)
        (revert-buffer))
      (defun dired-omit-auto-apply ()
        (setq dired-omit-mode v-dired-omit)
        (define-key dired-mode-map (kbd "C-x M-o") 'dired-omit-and-remember)
        (add-hook 'dired-mode-hook 'dired-omit-auto-apply)
        )

      ;; 和 KDE 的 Dolphin 一樣的檔案名過濾器，按 C-i 使用。 (by letoh)
      (defun dired-show-only (regexp)
        (interactive "sFiles to show (regexp): ")
        (dired-mark-files-regexp regexp)
        (dired-toggle-marks)
        (dired-do-kill-lines))
      )
    )
  )
(defun gtrun-defaults/post-init-recentf ()
  (progn
    (setq recentf-exclude
          '("COMMIT_MSG"
            "COMMIT_EDITMSG"
            "github.*txt$"
            "/tmp/"
            "/ssh:"
            "/sudo:"
            "/TAGS$"
            "/GTAGS$"
            "/GRAGS$"
            "/GPATH$"
            "\\.mkv$"
            "\\.mp[34]$"
            "\\.avi$"
            "\\.pdf$"
            "\\.sub$"
            "\\.srt$"
            "\\.ass$"
            ".*png$"))
    (setq recentf-max-saved-items 2048)))

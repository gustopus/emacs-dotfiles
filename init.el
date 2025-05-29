;;; init.el --- Gus's Emacs config -*- lexical-binding: t -*-

;; Add license later.

;;; Commentary:

;;; Code:

;;; Use-package settings
(setq use-package-always-ensure t
      use-package-enable-imenu-support t)

;;; Elpaca bootstrap and config
(defvar elpaca-installer-version 0.11)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
			                  :ref nil :depth 1 :inherit ignore
			                  :files (:defaults "elpaca-test.el" (:exclude "extensions"))
			                  :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
	    (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
		          ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
						                          ,@(when-let* ((depth (plist-get order :depth)))
						                              (list (format "--depth=%d" depth) "--no-single-branch"))
						                          ,(plist-get order :repo) ,repo))))
		          ((zerop (call-process "git" nil buffer t "checkout"
					                    (or (plist-get order :ref) "--"))))
		          (emacs (concat invocation-directory invocation-name))
		          ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
					                    "--eval" "(byte-recompile-directory \".\" 0 'force)")))
		          ((require 'elpaca))
		          ((elpaca-generate-autoloads "elpaca" repo)))
	        (progn (message "%s" (buffer-string)) (kill-buffer buffer))
	      (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support for Elpaca
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca
  (elpaca-use-package-mode))

;;; Write customizations to a seperate file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)

;;; Emacs settings
(use-package emacs
  :ensure nil
  :config
  (setq help-window-select t
        global-auto-revert-non-file-buffers t
        use-dialog-box nil
        show-paren-delay 0
        enable-recursive-minibuffers t
        read-extended-command-predicate #'command-completion-default-include-p
        kill-do-not-save-duplicates t
        eval-expression-print-length nil
        echo-keystrokes-help nil
        ;; better scrolling
        scroll-step 1
        scroll-conservatively 101
        next-screen-context-lines 5
        line-move-visual nil
        ;; disable file littering
        make-backup-files nil
        create-lockfiles nil)
  (setq-default indent-tabs-mode nil
                tab-width 4)
  :init
  (recentf-mode)
  (save-place-mode)
  (electric-pair-mode)
  (fringe-mode 0))

;; Enable savehist
(use-package savehist
  :ensure nil
  :init
  (savehist-mode)
  (add-to-list 'savehist-additional-variables 'global-mark-ring))

;; Dired tweaks
(use-package dired
  :ensure nil
  :hook
  ((dired-mode . dired-hide-details-mode)
   (dired-mode . hl-line-mode))
  :config
  (setq dired-recursive-copies 'always
	    dired-recursive-deletes 'always
	    delete-by-moving-to-trash t
	    dired-dwim-target t))

;;; Modeline

(use-package mini-modeline
  :config
  (setq mini-modeline-right-padding 7
	    mini-modeline-update-interval 0.1)
  :init
  (mini-modeline-mode 1))

;;; Minad packages

;; Orderless
(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
	    completion-category-overrides '((file (styles basic partial-completion)))))

;; Marginalia
(use-package marginalia
  :init
  (marginalia-mode))

;; Vertico
(use-package vertico
  :config
  (setq vertico-count 5)
  :init
  (vertico-mode))

;; Consult
(use-package consult
  :bind (
	     ("C-c m" . consult-man)
	     ("C-c i" . consult-info)
	     ("C-x C-b" . consult-buffer) ; why does this change C-x b too? cbl
	     ("M-g g" . consult-goto-line)
         ("M-g f" . consult-flymake)
	     ("M-g M-g" . consult-goto-line)
	     ("M-g i" . consult-imenu)
	     ("M-g I" . consult-imenu-multi)
	     ("M-s l" . consult-line)
	     ("M-s L" . consult-line-multi))) ; cbl with isearch integration

;; Embark
(use-package embark
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim)
   ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
	           '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
		         nil
		         (window-parameters (mode-line-format . none)))))

;; Consult integration for Embark
(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;;; Completion

;; Corfu
(use-package corfu
  :bind (:map corfu-map
	          ("RET" . nil))
  :config
  (setq corfu-auto t
	    corfu-auto-prefix 2
	    corfu-auto-delay 0.1
	    corfu-popupinfo-delay '(1 . 0.2))
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode))

;; Cape
(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-history)
  (add-hook 'completion-at-point-functions #'cape-file)
  (defun my/add-shell-completion ()
    (interactive)
    (add-to-list 'completion-at-point-functions 'cape-history)
    (add-to-list 'completion-at-point-functions 'pcomplete-completions-at-point))
  (add-hook 'shell-mode-hook #'my/add-shell-completion nil t)
  :config
  (advice-add #'eglot-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'comint-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify))

;;; IDE stuff

;; Flymake
(use-package flymake
  :ensure nil
  :hook (prog-mode . flymake-mode))

;; ;; Eglot
;; (use-package eglot
;;   :ensure nil
;;   :hook
;;   (sh-mode . eglot-ensure)
;;   (lua-mode . eglot-ensure))

;; ;; Lua-Mode
;; (use-package lua-mode)

;;; Eat terminal emulator
(use-package eat
  :hook (eshell-load . eat-eshell-mode))

;; ;;; Vundo
;; (use-package vundo)

;; ;;; Pass
;; (use-package pass)

;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved)
;; End:

(provide 'init)
;;; init.el ends here

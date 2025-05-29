;;; early-init.el --- Gus's Emacs config -*- lexical-binding: t -*-

;; Add license later.

;;; Commentary:

;;; Code:

;;; Settings that belong in early-init.el
(setq package-enable-at-startup nil
      frame-resize-pixelwise t
      frame-inhibit-implied-resize t
      frame-title-format '("%b")
      ring-bell-function 'ignore
      use-short-answers t
      inhibit-x-resources t
      initial-scratch-message nil
      initial-major-mode 'text-mode
      inhibit-startup-screen t
      gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.5)

;; Disable lame GUI
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;; Set GC back to normal levels
(add-hook 'emacs-startup-hook
	  (lambda ()
	    (setq gc-cons-threshold (* 100 100 8)
		  gc-cons-percentage 0.1)))

(provide 'early-init)
;;; early-init.el ends here

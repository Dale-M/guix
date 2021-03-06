;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2020 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2020 Jan (janneke) Nieuwenhuizen <janneke@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gnu system hurd)
  #:use-module (guix gexp)
  #:use-module (guix profiles)
  #:use-module (guix utils)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages cross-base)
  #:use-module (gnu packages file)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages guile-xyz)
  #:use-module (gnu packages hurd)
  #:use-module (gnu packages less)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu services hurd)
  #:use-module (gnu services shepherd)
  #:use-module (gnu system)
  #:use-module (gnu system shadow)
  #:use-module (gnu system vm)
  #:export (%base-packages/hurd
            %base-services/hurd
            %hurd-default-operating-system
            %hurd-default-operating-system-kernel))

;;; Commentary:
;;;
;;; This module provides system-specifics for the GNU/Hurd operating system
;;; and virtual machine.
;;;
;;; Code:

(define %hurd-default-operating-system-kernel
  (if (hurd-system?)
      gnumach
      ;; A cross-built GNUmach does not work
      (with-parameters ((%current-system "i686-linux")
                        (%current-target-system #f))
        gnumach)))

(define %base-packages/hurd
  (list hurd bash coreutils file findutils grep sed
        guile-3.0 guile-colorized guile-readline
        net-base inetutils less shepherd which))

(define %base-services/hurd
  (list (service hurd-console-service-type
                 (hurd-console-configuration (hurd hurd)))
        (service hurd-getty-service-type (hurd-getty-configuration
                                          (tty "tty1")))
        (service hurd-getty-service-type (hurd-getty-configuration
                                          (tty "tty2")))
        (service static-networking-service-type
                 (list (static-networking (interface "lo")
                                          (ip "127.0.0.1")
                                          (requirement '())
                                          (provision '(loopback))
                                          (name-servers '("10.0.2.3")))))
        (syslog-service)
        (service guix-service-type
                 (guix-configuration
                  (extra-options '("--disable-chroot"
                                   "--disable-deduplication"))))))

(define %hurd-default-operating-system
  (operating-system
    (kernel %hurd-default-operating-system-kernel)
    (kernel-arguments '())
    (hurd hurd)
    (bootloader (bootloader-configuration
                 (bootloader grub-minimal-bootloader)
                 (target "/dev/vda")))
    (initrd (lambda _ '()))
    (initrd-modules (lambda _ '()))
    (firmware '())
    (host-name "guixygnu")
    (file-systems '())
    (packages %base-packages/hurd)
    (timezone "GNUrope")
    (name-service-switch #f)
    (essential-services (hurd-default-essential-services this-operating-system))
    (pam-services '())
    (setuid-programs '())
    (sudoers-file #f)))

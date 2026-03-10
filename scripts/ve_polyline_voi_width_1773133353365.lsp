;;; ---------------------------------------------------------
;;; Lisp ve Polyline (Update ten lenh: PL0, PL30, PLN)
;;; ---------------------------------------------------------

;; Name: Polyline Width 0
;; Desc: Lệnh vẽ Polyline với Width 0
(defun c:PL0 ()
  (setvar "PLINEWID" 0)       ; Dat do rong mac dinh ve 0
  (princ "\n[PL0] Da set Width = 0. Bat dau ve PL...")
  (command "_.PLINE")         ; Goi lenh Polyline
  (while (> (getvar "CMDACTIVE") 0) (command pause)) ; Cho nguoi dung ve xong
  (princ)
)

;; Name: Polyline Width 30
;; Desc: Lệnh vẽ Polyline với Width 30
(defun c:PL30 ()
  (setvar "PLINEWID" 30)      ; Dat do rong mac dinh ve 30
  (princ "\n[PL30] Da set Width = 30. Bat dau ve PL...")
  (command "_.PLINE")
  (while (> (getvar "CMDACTIVE") 0) (command pause))
  (princ)
)

;;; Lenh PLN: Ve PL voi Width tuy chon (N = Number)
;; Name: Polyline Width Number
;; Desc: Lệnh vẽ Polyline với 1 Width bất kỳ
(defun c:PLN (/ w)
  (setq w (getreal "\n[PLN] Nhap do rong net (Width): ")) ; Hoi nguoi dung nhap so
  (if w
    (progn
      (setvar "PLINEWID" w)   ; Dat do rong theo so vua nhap
      (princ (strcat "\nDa set Width = " (rtos w 2 2) ". Bat dau ve PL..."))
      (command "_.PLINE")
      (while (> (getvar "CMDACTIVE") 0) (command pause))
    )
    (princ "\nBan chua nhap gia tri nao!")
  )
  (princ)
)
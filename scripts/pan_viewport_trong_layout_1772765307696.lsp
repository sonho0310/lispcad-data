;; =========================================================================
;; CHUONG TRINH: PAN VIEWPORT TRONG LAYOUT (Ho tro Viewport bi khoa)
;; PHIEN BAN: 2.0 (Cap nhat them tinh nang Pan theo 2 diem click chuot)
;; NGAY CAP NHAT: 05/03/2026
;; =========================================================================
;; CHUC NANG:
;; - Cho phep di chuyen (Pan) vung nhin Model ben trong Viewport cua Layout.
;; - Hoat dong mượt mà ngay ca khi Viewport dang bi khoa (DisplayLocked).
;; - Tu dong quy doi khoang cach Layout ra khoang cach Model (thong qua CustomScale).
;; - Khong can vao trong Model space (double click), giup bao ve ty le ban ve.
;; =========================================================================
;; HUONG DAN SU DUNG:
;; 1. Tai file Lisp vao AutoCAD bang lenh APPLOAD (AP).
;; 2. Co 2 lenh de ban su dung:
;;    + Lenh: VPAN   -> Chon Viewport va Nhap so khoang cach (dX, dY).
;;    + Lenh: VPAN2P -> Chon Viewport va Click chon 2 diem de Pan truc quan.
;; =========================================================================

(vl-load-com)

;; =========================================================================
;; [Lệnh 1]: VPAN - Nhap truc tiep khoang cach dX, dY ban muon di chuyen
;; =========================================================================
(defun c:VPAN (/ *error* acDoc ent vport isLocked targ newTarg dx dy)
  (setq acDoc (vla-get-ActiveDocument (vlax-get-acad-object)))

  ;; Ham xu ly loi
  (defun *error* (msg)
    (if (and vport isLocked (= isLocked :vlax-true))
      (vla-put-DisplayLocked vport :vlax-true)
    )
    (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*")))
      (princ (strcat "\nLoi: " msg))
    )
    (vla-EndUndoMark acDoc)
    (princ)
  )

  (vla-StartUndoMark acDoc)

  (setq ent (car (entsel "\nChon Viewport can Pan: ")))
  (if (and ent (= (cdr (assoc 0 (entget ent))) "VIEWPORT"))
    (progn
      (setq vport (vlax-ename->vla-object ent))
      
      (setq dx (getreal "\nNhap khoang cach X can Pan (Model units) <0>: "))
      (if (null dx) (setq dx 0.0))
      
      (setq dy (getreal "\nNhap khoang cach Y can Pan (Model units) <0>: "))
      (if (null dy) (setq dy 0.0))

      (if (or (/= dx 0.0) (/= dy 0.0))
        (progn
          (setq isLocked (vla-get-DisplayLocked vport))
          (if (= isLocked :vlax-true) (vla-put-DisplayLocked vport :vlax-false))

          (setq targ (vlax-get vport 'Target))
          ;; Camera (Target) se tinh tien theo gia tri nhap vao
          (setq newTarg (list (+ (car targ) dx) (+ (cadr targ) dy) (caddr targ)))
          
          (vlax-put vport 'Target newTarg)
          (vla-Update vport)

          (if (= isLocked :vlax-true) (vla-put-DisplayLocked vport :vlax-true))
          
          (princ (strcat "\n[+] Da Pan thanh cong! (dX=" (rtos dx 2 2) ", dY=" (rtos dy 2 2) ")"))
        )
        (princ "\n[-] Khong co su dich chuyen nao (dX=0, dY=0).")
      )
    )
    (princ "\n[!] Doi tuong duoc chon khong phai la Viewport.")
  )
  
  (vla-EndUndoMark acDoc)
  (princ)
)

;; =========================================================================
;; [Lệnh 2]: VPAN2P - Click chon 2 diem tren man hinh de tinh Vector Pan
;; =========================================================================
(defun c:VPAN2P (/ *error* acDoc ent vport isLocked targ newTarg pt1 pt2 scale dx_paper dy_paper dx_model dy_model)
  (setq acDoc (vla-get-ActiveDocument (vlax-get-acad-object)))

  ;; Ham xu ly loi
  (defun *error* (msg)
    (if (and vport isLocked (= isLocked :vlax-true))
      (vla-put-DisplayLocked vport :vlax-true)
    )
    (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*")))
      (princ (strcat "\nLoi: " msg))
    )
    (vla-EndUndoMark acDoc)
    (princ)
  )

  (vla-StartUndoMark acDoc)

  ;; B1: Chon Viewport
  (setq ent (car (entsel "\nChon Viewport can Pan: ")))
  (if (and ent (= (cdr (assoc 0 (entget ent))) "VIEWPORT"))
    (progn
      (setq vport (vlax-ename->vla-object ent))
      
      ;; B2: Lay Ty le hien thi cua Viewport (De quy doi don vi Paper -> Model)
      (setq scale (vla-get-CustomScale vport))
      
      ;; B3: Yeu cau nguoi dung click chon 2 diem de lay vector
      (setq pt1 (getpoint "\nChon diem goc (Base point): "))
      (if pt1
        (progn
          (setq pt2 (getpoint pt1 "\nChon diem den (Second point): "))
          (if pt2
            (progn
              ;; Tinh toan Vector di chuyen tren Layout (Paper Space)
              ;; Luu y: De model di chuyen theo huong pt1->pt2, Camera(Target) phai di chuyen theo huong nguoc lai (pt1 - pt2)
              (setq dx_paper (- (car pt1) (car pt2)))
              (setq dy_paper (- (cadr pt1) (cadr pt2)))
              
              ;; Quy doi khoang cach Layout ve khoang cach thuc trong Model
              (setq dx_model (/ dx_paper scale))
              (setq dy_model (/ dy_paper scale))

              ;; Mo khoa Viewport tam thoi
              (setq isLocked (vla-get-DisplayLocked vport))
              (if (= isLocked :vlax-true) (vla-put-DisplayLocked vport :vlax-false))

              ;; Lay toa do Target hien tai va cong don khoang cach
              (setq targ (vlax-get vport 'Target))
              (setq newTarg (list (+ (car targ) dx_model) (+ (cadr targ) dy_model) (caddr targ)))
              
              ;; Cap nhat Target va lam moi vung nhin
              (vlax-put vport 'Target newTarg)
              (vla-Update vport)

              ;; Khoa lai Viewport nhu nguyen trang
              (if (= isLocked :vlax-true) (vla-put-DisplayLocked vport :vlax-true))
              
              (princ "\n[+] Da Pan thanh cong bang cach click 2 diem!")
            )
            (princ "\n[-] Da huy: Khong chon diem thu 2.")
          )
        )
        (princ "\n[-] Da huy: Khong chon diem goc.")
      )
    )
    (princ "\n[!] Doi tuong duoc chon khong phai la Viewport.")
  )
  
  (vla-EndUndoMark acDoc)
  (princ)
)

;; =========================================================================
;; In ra man hinh Command Line huong dan khi vua Load Lisp thanh cong
;; =========================================================================
(princ "\n==============================================================")
(princ "\n  [Tien ich AutoCAD] - LISP PAN VIEWPORT (Phien ban 2.0)      ")
(princ "\n  Hoat dong ngay ca khi Viewport dang bi khoa.                ")
(princ "\n  >> Lenh 1: VPAN   (Nhap khoang cach dX, dY thu cong)        ")
(princ "\n  >> Lenh 2: VPAN2P (Click chon 2 diem tren man hinh)         ")
(princ "\n==============================================================")
(princ)
;;; Lisp: Xoay Text song song voi duong (Text Orient)
;;; Phien ban: AUTO (Khong hoi 2 diem)
;;; Lenh: TOR

(defun c:TOR (/ ent obj ang pickPt param deriv ss i txtObj)
  (vl-load-com)
  (princ "\nChon Line hoac Pline de lay goc: ")
  
  (if (setq ent (nentsel)) 
    (progn
      (setq obj (vlax-ename->vla-object (car ent)))
      (setq pickPt (cadr ent)) ; Lay toa do diem click chuot
      
      ;;; --- TỰ ĐỘNG TÍNH GÓC ---
      (cond
        ;; Truong hop 1: La Line thuan tuy
        ((= (vla-get-ObjectName obj) "AcDbLine")
         (setq ang (vla-get-Angle obj)))
         
        ;; Truong hop 2: La Polyline (hoac curve bat ky nhu Arc, Spline)
        ;; Dung ham vlax-curve de lay goc tai dung diem pick
        ((not (vl-catch-all-error-p (vl-catch-all-apply 'vlax-curve-getEndParam (list obj))))
         (setq param (vlax-curve-getParamAtPoint obj (vlax-curve-getClosestPointTo obj pickPt)))
         (setq deriv (vlax-curve-getFirstDeriv obj param))
         (setq ang (angle '(0 0 0) deriv)) ; Tinh goc vector
        )
        
        (t (setq ang nil) (princ "\nKhong lay duoc goc tu doi tuong nay."))
      )
      
      ;;; --- THUC HIEN XOAY ---
      (if ang
        (progn
           ;; Chuan hoa goc (de text khong bi lon nguoc)
           (if (and (> ang (/ pi 2)) (<= ang (* 1.5 pi)))
             (setq ang (- ang pi))
           )
           
           (princ "\nChon Text can xoay: ")
           (setq ss (ssget '((0 . "*TEXT"))))
           
           (if ss
             (progn
               (setq i 0)
               (repeat (sslength ss)
                 (setq txtObj (vlax-ename->vla-object (ssname ss i)))
                 (vla-put-Rotation txtObj ang)
                 (setq i (1+ i))
               )
               (princ "\nDa xoay Text xong!")
             )
             (princ "\nKhong chon duoc Text.")
           )
        )
      )
    )
    (princ "\nChua chon duoc doi tuong tham chieu!")
  )
  (princ)
)
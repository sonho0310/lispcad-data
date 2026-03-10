;;; ===============================================================
;;; LISP ADD VERTEX TO POLYLINE (THEM DINH CHO POLYLINE)
;;; Lenh tat: AV
;;; ===============================================================

(defun c:AV (/ *error* ent obj pt param idx coord-list new-coord-list i bulge-list new-bulge-list)
  
  (vl-load-com) ;; Load thu vien Visual Lisp

  ;; Ham xu ly loi
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*")))
      (princ (strcat "\nLoi: " msg))
    )
    (princ)
  )

  ;; 1. Chon doi tuong Polyline
  (while (not (and (setq ent (entsel "\nChon Polyline can them dinh: "))
                   (wcmatch (cdr (assoc 0 (entget (car ent)))) "*POLYLINE")))
    (princ "\nDoi tuong chon khong phai la Polyline. Vui long chon lai.")
  )
  
  (setq obj (vlax-ename->vla-object (car ent)))

  ;; 2. Vong lap de them nhieu diem lien tuc
  (while (setq pt (getpoint "\nClick chon vi tri can them dinh (hoac Enter de ket thuc): "))
    (progn
      ;; Tim diem gan nhat tren Polyline (de dam bao chinh xac)
      (setq pt (vlax-curve-getClosestPointTo obj pt))
      
      ;; Lay tham so tai diem do (Parameter)
      (setq param (vlax-curve-getParamAtPoint obj pt))
      
      ;; Xac dinh index cua segment (doan) ma diem do nam tren
      (setq idx (fix param))
      
      ;; Lay danh sach toa do hien tai
      (setq coord-list (vlax-safearray->list (vlax-variant-value (vla-get-coordinates obj))))
      
      ;; Xu ly danh sach toa do (LWPOLYLINE co 2 toa do x,y moi dinh)
      (setq new-coord-list '() i 0)
      
      ;; Tao danh sach toa do moi
      (repeat (/ (length coord-list) 2)
        (setq new-coord-list (append new-coord-list (list (nth i coord-list) (nth (1+ i) coord-list))))
        ;; Neu day la dinh ngay truoc vi tri them moi -> chen diem moi vao sau
        (if (= (/ i 2) idx)
          (setq new-coord-list (append new-coord-list (list (car pt) (cadr pt))))
        )
        (setq i (+ i 2))
      )

      ;; Cap nhat Polyline
      (vla-put-coordinates obj (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length new-coord-list)))) new-coord-list)))
      
      (princ "\nDa them dinh thanh cong.")
    )
  )
  (princ)
)

(princ "\nGo lenh AV de bat dau them dinh Polyline.")
(princ)
;;; ===============================================================
;;; LISP REMOVE VERTEX FROM POLYLINE (XOA DINH POLYLINE)
;;; Lenh tat: RV
;;; ===============================================================

(defun c:RV (/ *error* ent obj pt param idx coord-list new-coord-list i num-verts)
  
  (vl-load-com)

  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*")))
      (princ (strcat "\nLoi: " msg))
    )
    (princ)
  )

  ;; 1. Chon doi tuong Polyline
  (while (not (and (setq ent (entsel "\nChon Polyline can xoa dinh: "))
                   (wcmatch (cdr (assoc 0 (entget (car ent)))) "*POLYLINE")))
    (princ "\nDoi tuong chon khong phai la Polyline. Vui long chon lai.")
  )
  
  (setq obj (vlax-ename->vla-object (car ent)))

  ;; 2. Vong lap xoa
  (while (setq pt (getpoint "\nClick vao gan dinh can xoa (hoac Enter de ket thuc): "))
    (progn
      ;; Lay danh sach toa do hien tai de kiem tra so luong dinh
      (setq coord-list (vlax-safearray->list (vlax-variant-value (vla-get-coordinates obj))))
      (setq num-verts (/ (length coord-list) 2))

      ;; Kiem tra neu con it hon hoac bang 2 dinh thi khong xoa nua (de tranh loi mat doi tuong)
      (if (<= num-verts 2)
        (alert "Polyline phai co it nhat 2 diem. Khong the xoa them!")
        
        (progn
          ;; Tim diem gan nhat tren duong cong de xac dinh Index
          (setq pt (vlax-curve-getClosestPointTo obj pt))
          (setq param (vlax-curve-getParamAtPoint obj pt))
          
          ;; Lam tron Param de lay Index cua dinh gan nhat
          ;; Vi du: Click tai 1.1 hoac 0.9 deu se hieu la dinh so 1
          (setq idx (fix (+ param 0.5)))
          
          ;; Xu ly tao danh sach moi bo qua dinh tai Index da chon
          (setq new-coord-list '() i 0)
          
          (repeat num-verts
            ;; Neu khong phai la index can xoa thi them vao danh sach moi
            (if (/= (/ i 2) idx)
              (setq new-coord-list (append new-coord-list (list (nth i coord-list) (nth (1+ i) coord-list))))
            )
            (setq i (+ i 2))
          )

          ;; Cap nhat lai Polyline
          (vla-put-coordinates obj (vlax-make-variant (vlax-safearray-fill (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length new-coord-list)))) new-coord-list)))
          
          (princ "\nDa xoa dinh thanh cong.")
        )
      )
    )
  )
  (princ)
)

(princ "\nGo lenh RV de bat dau xoa dinh Polyline.")
(princ)
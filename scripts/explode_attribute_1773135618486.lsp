;;; Lisp pha vo Block Attribute giu nguyen gia tri Text
;;; Lenh: XAT

(defun c:XAT (/ ss i e obj atts att_val ins_pt rot hgt lay txt_obj doc spc expl_objs)
  (vl-load-com)
  ;; Lay khong gian lam viec hien tai (Model hoac Layout)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq spc (if (= (vla-get-ActiveSpace doc) 1) 
                (vla-get-ModelSpace doc) 
                (vla-get-PaperSpace doc)))
  
  (prompt "\nChon Block Attribute can pha vo: ")
  ;; Chon cac doi tuong la Block va co chua Attribute
  (if (setq ss (ssget '((0 . "INSERT") (66 . 1))))
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq e (ssname ss i))
        (setq obj (vlax-ename->vla-object e))
        
        ;; 1. Lay danh sach thuoc tinh (Attributes) cua Block
        (setq atts (vlax-invoke obj 'GetAttributes))
        (foreach att atts
          (setq att_val (vla-get-TextString att))
          (setq ins_pt (vla-get-InsertionPoint att))
          (setq rot (vla-get-Rotation att))
          (setq hgt (vla-get-Height att))
          (setq lay (vla-get-Layer att))
          
          ;; 2. Tao Text moi thay the tai dung vi tri do
          (setq txt_obj (vla-AddText spc att_val ins_pt hgt))
          (vla-put-Rotation txt_obj rot)
          (vla-put-Layer txt_obj lay)
          ;; (Tuy chon) Giu nguyen mau sac
          (vla-put-Color txt_obj (vla-get-Color att))
        )
        
        ;; 3. Pha vo (Explode) Block ban dau
        (setq expl_objs (vlax-invoke obj 'Explode))
        
        ;; 4. Xoa cac the ATTDEF (Attribute Definition) thua duoc tao ra sau khi explode
        (foreach ex_obj expl_objs
          (if (= (vla-get-ObjectName ex_obj) "AcDbAttributeDefinition")
            (vla-Delete ex_obj)
          )
        )
        
        ;; 5. Xoa Block goc
        (vla-Delete obj)
        
        (setq i (1+ i))
      )
      (princ "\nDa pha vo Block va chuyen Attribute thanh Text thanh cong!")
    )
    (princ "\nKhong tim thay Block Attribute nao.")
  )
  (princ)
)
(princ "\nDa load thanh cong! Go lenh XAT de su dung.")
(princ)
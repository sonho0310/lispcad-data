(defun c:RNL (/ *error* acDoc layouts layout_list method prefix startNum findStr repStr i newName oldName padding)
  (vl-load-com)

  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*")))
      (princ (strcat "\nLoi: " msg))
    )
    (vla-EndUndoMark (vla-get-ActiveDocument (vlax-get-acad-object)))
    (princ)
  )

  (setq acDoc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (vla-StartUndoMark acDoc)

  ;; 1. Lay danh sach Layout va sap xep theo thu tu hien thi (Tab Order)
  (setq layouts (vla-get-Layouts acDoc))
  (setq layout_list '())
  (vlax-for lay layouts
    (if (/= (vla-get-ModelType lay) :vlax-true) ; Bo qua Model
      (setq layout_list (cons lay layout_list))
    )
  )
  
  ;; Sap xep layout tu trai qua phai
  (setq layout_list 
    (vl-sort layout_list 
      '(lambda (a b) (< (vla-get-TabOrder a) (vla-get-TabOrder b)))
    )
  )

  ;; 2. Menu chon che do
  (initget "1 2")
  (setq method (getkword "\nChon che do: [1] Danh lai so thu tu (Reset) / [2] Tim va thay the (Replace) <1>: "))
  (if (null method) (setq method "1"))

  (cond
    ;; --- MODE 1: DANH SO LAI TU DAU (VD: LK-A2-01, LK-A2-02...) ---
    ((= method "1")
      (setq prefix (getstring T "\nNhap tien to (Prefix) <LK-A2->: "))
      (if (= prefix "") (setq prefix "LK-A2-"))
      
      (setq startNum (getint "\nSo bat dau <1>: "))
      (if (null startNum) (setq startNum 1))
      
      (setq i startNum)
      (princ "\nDang doi ten...")
      
      ;; Doi ten tam thoi de tranh trung lap
      (foreach lay layout_list
        (vla-put-Name lay (strcat "TEMP_RENAME_" (itoa i)))
        (setq i (1+ i))
      )
      
      ;; Doi ten chinh thuc
      (setq i startNum)
      (foreach lay layout_list
        (if (< i 10) (setq padding "0") (setq padding ""))
        (setq newName (strcat prefix padding (itoa i)))
        (vla-put-Name lay newName)
        (princ (strcat "\n + " newName))
        (setq i (1+ i))
      )
    )

    ;; --- MODE 2: TIM VA THAY THE (VD: Doi 'A2' thanh 'B5') ---
    ((= method "2")
      (setq findStr (getstring T "\nChuoi can tim (VD: A2): "))
      (setq repStr (getstring T "\nChuoi thay the (VD: B5): "))
      
      (if (/= findStr "")
        (foreach lay layout_list
          (setq oldName (vla-get-Name lay))
          ;; Kiem tra neu ten co chua chuoi can tim
          (if (vl-string-search findStr oldName)
            (progn
               ;; Thay the chuoi (chi thay the lan xuat hien dau tien)
               (setq newName (vl-string-subst repStr findStr oldName))
               (if (vl-catch-all-error-p (vl-catch-all-apply 'vla-put-Name (list lay newName)))
                 (princ (strcat "\n - Loi: Ten " newName " da ton tai!"))
                 (princ (strcat "\n + Doi: " oldName " -> " newName))
               )
            )
          )
        )
      )
    )
  )
  
  (vla-EndUndoMark acDoc)
  (vla-Regen acDoc acAllViewports)
  (princ "\n--- XONG! ---")
  (princ)
)
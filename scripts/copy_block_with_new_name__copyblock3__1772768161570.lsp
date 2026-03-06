;; ====================================
;; TITLE: Copy Block with New Name (CopyBlock3)
;; DESCRIPTION: Tạo bản sao của Block được chọn và gán tên mới (tự động đổi tên nếu là Block anonymous).
;; GUIDE: Load Lisp (AP) -> Gõ CopyBlock3 -> Chọn Block mẫu -> Nhập tên mới -> Chọn điểm chèn.
;; ====================================
 
;VVA
 
;make a copy of a block with a new name
 
;select block to copy
 
;enter new name unless anonymous block, then new name = ols name less *
 
;pick insertion point
 
(defun C:CopyBlock3 (/ *error* OldBlockName NewBlockName
 
rewind BlockName Info BlockInfo ent_name ent_info)
 
(defun *error* (Msg)
 
(cond
 
((or (not Msg)
 
(member Msg '("console break"
 
"Function cancelled"
 
"quit / exit abort"))))
 
((princ (strcat "\nError: " Msg)))
 
) ;cond
 
(princ)
 
) ;end error
 
(sssetfirst)
 
(setq OldBlockName (entsel "\nSelect Block to copy: "))
 
(while
 
(or
 
(null OldBlockName)
 
(/= "INSERT" (cdr (assoc 0 (entget (car OldBlockName)))))
 
)
 
(princ "\nSelection was not a block - try again...")
 
(setq OldBlockName (entsel "\nSelect Block to copy: "))
 
)
 
;block name
 
(setq OldBlockName (strcase (cdr (assoc 2 (entget (car OldBlockName))))))
 
(princ (strcat "\nSelected block name: " OldBlockName))
 
(if (= "*" (substr OldBlockName 1 1))
 
(setq NewBlockName (substr OldBlockName 2))
 
(setq NewBlockName (getstring T "\nEnter new block name: "))
 
)
 
(setq rewind T)
 
(while (setq Info (tblnext "BLOCK" rewind))
 
(setq BlockName (strcase (cdr (assoc 2 Info))))
 
(if (= OldBlockName BlockName)
 
(setq BlockInfo Info)
 
)
 
(setq rewind nil)
 
)
 
(if BlockInfo
 
(progn
 
(setq ent_name (cdr (assoc -2 BlockInfo)))
 
;header definition:
 
(entmake (list '(0 . "BLOCK")
 
(cons 2 NewBlockName)
 
'(70 . 2)
 
(cons 10 '(0 0 0))
 
)
 
)
 
;body definition:
 
(entmake (cdr (entget ent_name)))
 
(while (setq ent_name (entnext ent_name))
 
(setq ent_info (cdr (entget ent_name)))
 
(entmake ent_info)
 
)
 
;footer definition:
 
(entmake '((0 . "ENDBLK")))
 
(command "-INSERT" NewBlockName pause "1" "1" "0")
 
)
 
)
 
(*Error* nil)
 
(princ)
 
) ;end
;; =========================================================================
;; MasterBlock TOOLS - TÍCH HỢP TẤT CẢ TRONG MỘT
;; Chức năng: Quản lý toàn bộ các Lisp Block qua 1 giao diện (DCL)
;; Lệnh kích hoạt: MasterBlock
;; =========================================================================
(vl-load-com)

;;; =========================================================================
;;; PHẦN 1: MÃ NGUỒN CÁC LỆNH LẺ
;;; =========================================================================

;;; --- TỪ FILE: BlocktoColor8.lsp ---
(defun c:SBF (/ *error* doc sv_cmdecho mode sel blkNameQueue processedNames curName blkDef ent objType count origin delList item)
  (vl-load-com)
  (defun *error* (msg)
    (if sv_cmdecho (setvar 'cmdecho sv_cmdecho))
    (vla-EndUndoMark doc)
    (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*")))
      (princ (strcat "\nLỗi nhẹ (Đã bỏ qua): " msg))
    )
    (princ)
  )
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (vla-StartUndoMark doc)
  (setq sv_cmdecho (getvar 'cmdecho))
  (setvar 'cmdecho 0)
  (setq origin (vlax-3d-point 0 0 0))
  (setq blkNameQueue nil) 
  (setq processedNames nil)
  (setq count 0)
  (princ "\n[System] Đang mở khóa Layer...")
  (vlax-for lay (vla-get-layers doc)
    (vl-catch-all-apply 'vla-put-lock (list lay :vlax-false))
  )
  (defun Process-Block-Safe (blkDef / ent objType atts att)
    (setq delList nil) 
    (vlax-for ent blkDef
      (setq objType (vla-get-ObjectName ent))
      (cond
        ((wcmatch objType "*Dimension") (setq delList (cons ent delList)))
        (t
         (vl-catch-all-apply 'vla-put-Layer (list ent "0"))
         (vl-catch-all-apply 'vla-put-Color (list ent 8))
         (if (wcmatch objType "*MLeader") (vl-catch-all-apply 'vla-put-LeaderLineColor (list ent 8)))
         (if (wcmatch objType "AcDbLeader") (vl-catch-all-apply 'vla-put-Color (list ent 8)))
         (if (wcmatch objType "*Text") (vl-catch-all-apply 'vla-put-Color (list ent 8)))
         (if (and (wcmatch objType "*BlockReference*") (= (vla-get-HasAttributes ent) :vlax-true))
           (foreach att (vlax-safearray->list (vlax-variant-value (vla-GetAttributes ent)))
             (vl-catch-all-apply 'vla-put-Layer (list att "0"))
             (vl-catch-all-apply 'vla-put-Color (list att 8))
           )
         )
         (if (wcmatch objType "*AttributeDefinition")
           (progn
             (vl-catch-all-apply 'vla-put-Color (list ent 8))
             (vl-catch-all-apply 'vla-put-Layer (list ent "0"))
           )
         )
         (if (wcmatch objType "*BlockReference*,*MInsertBlock*")
           (progn
             (Add-To-Queue (vla-get-Name ent))
             (if (vlax-property-available-p ent 'EffectiveName) (Add-To-Queue (vla-get-EffectiveName ent)))
           )
         )
        )
      )
    )
    (foreach item delList (vl-catch-all-apply 'vla-Delete (list item)))
  )
  (defun Refresh-Block-Reference (obj)
    (vl-catch-all-apply 'vla-Update (list obj))
    (vl-catch-all-apply 'vla-Move (list obj origin origin))
  )
  (defun Add-To-Queue (bName)
    (if (and bName (/= bName "") (not (member bName processedNames)) (not (member bName blkNameQueue)))
      (setq blkNameQueue (append blkNameQueue (list bName)))
    )
  )
  (initget "Select All")
  (setq mode (getkword "\nChọn chế độ [Select/All] <Select>: "))
  (if (not mode) (setq mode "Select"))
  (cond
    ((= mode "Select")
     (princ "\n>>> Chế độ SELECT: Quét chọn Block (Xóa sạch Dim - An toàn)...")
     (if (setq sel (ssget '((0 . "INSERT,LEADER")))) 
       (progn
         (princ "\nĐang quét và xử lý...")
         (vlax-for obj (vla-get-ActiveSelectionSet doc)
           (if (wcmatch (vla-get-ObjectName obj) "*Dimension")
             (vl-catch-all-apply 'vla-Delete (list obj)) 
             (progn
               (vl-catch-all-apply 'vla-put-Layer (list obj "0"))
               (vl-catch-all-apply 'vla-put-Color (list obj 8))
               (if (wcmatch (vla-get-ObjectName obj) "*BlockReference*")
                 (progn
                   (Add-To-Queue (vla-get-Name obj))
                   (if (vlax-property-available-p obj 'EffectiveName) (Add-To-Queue (vla-get-EffectiveName obj)))
                 )
               )
             )
           )
         )
         (while (> (length blkNameQueue) 0)
           (setq curName (car blkNameQueue))
           (setq blkNameQueue (cdr blkNameQueue))
           (if (not (member curName processedNames))
             (progn
               (setq processedNames (cons curName processedNames))
               (setq count (1+ count))
               (if (not (vl-catch-all-error-p (setq blkDef (vl-catch-all-apply 'vla-item (list (vla-get-blocks doc) curName)))))
                 (Process-Block-Safe blkDef)
               )
             )
           )
         )
         (princ "\nĐang làm mới hiển thị...")
         (vlax-for obj (vla-get-ActiveSelectionSet doc)
           (if (not (vlax-erased-p obj)) (Refresh-Block-Reference obj))
         )
         (vla-Regen doc acAllViewports)
         (princ (strcat "\n[DONE] Đã xử lý " (itoa count) " định nghĩa. Dimension đã bị xóa an toàn!"))
       )
       (princ "\nKhông có gì được chọn.")
     )
    )
    ((= mode "All")
     (princ "\n>>> Chế độ ALL: Xử lý toàn bộ Database (An toàn)...")
     (vlax-for blk (vla-get-blocks doc)
       (if (= (vla-get-IsXref blk) :vlax-false) (Process-Block-Safe blk))
     )
     (vla-Regen doc acAllViewports)
     (princ "\n[DONE] Bản vẽ đã sạch bóng Dimension (Layer 0/Màu 8).")
    )
  )
  (setvar 'cmdecho sv_cmdecho)
  (vla-EndUndoMark doc)
  (princ)
)

;;; --- CÁC CÔNG CỤ CƠ BẢN ---
(defun c:BRN (/ ent obj oldName newName)
  (if (setq ent (car (entsel "\nChọn Block cần đổi tên: ")))
    (progn
      (setq obj (vlax-ename->vla-object ent))
      (if (= (vla-get-ObjectName obj) "AcDbBlockReference")
        (progn
          (setq oldName (vla-get-EffectiveName obj))
          (setq newName (getstring T (strcat "\nTên hiện tại <" oldName ">. Nhập tên mới: ")))
          (if (/= newName "")
            (if (tblsearch "BLOCK" newName)
              (princ "\nTên Block đã tồn tại! Vui lòng chọn tên khác.")
              (progn
                (vla-put-Name (vla-item (vla-get-Blocks (vla-get-ActiveDocument (vlax-get-acad-object))) oldName) newName)
                (princ (strcat "\nĐã đổi tên Block thành: " newName))
              )
            )
          )
        )
        (princ "\nĐối tượng chọn không phải là Block.")
      )
    )
  )
  (princ)
)

(defun c:BX ()
  (princ "\nChọn các Block cần phá (Explode):")
  (command "_.EXPLODE" (ssget) "")
  (princ)
)

(defun c:CBP (/ doituong1 doituong TENKHOI TENKHOIMOI DIEMCHENMOI luubatdiem TYLEX TYLEY DIEMTINH XDIEMTINH YDIEMTINH DIEMCHENTUONGDOI xx L M DTs DTMs TYLEX1 TYLEY1 DIEMDOI oldEco)
  (command "_.undo" "_be")
  (setq oldEco (getvar "cmdecho"))
  (setvar "cmdecho" 0)
  (setq doituong1 (entsel "\nChọn Block muốn chỉnh điểm chèn: "))
  (while (or (null doituong1) (/= "INSERT" (cdr (assoc 0 (entget (car doituong1))))))
    (princ "\nĐối tượng không phải là Block! Chọn lại.")
    (setq doituong1 (entsel "\nChọn Block muốn chỉnh điểm chèn: "))
  )
  (command "_.ucs" "_ob" (car doituong1))
  (setq luubatdiem (getvar "osmode"))
  (setvar "osmode" 511)
  (setq DIEMCHENMOI (getpoint "\nChọn điểm chèn MỚI cho Block này: "))
  (setvar "osmode" 0)
  (command "_.layer" "_s" "0" "")
  (setq doituong (entget (car doituong1)))
  (setq TENKHOI (cdr (assoc 2 doituong)))
  (setq TENKHOIMOI (strcat TENKHOI "_TEMP"))
  (setq TYLEX (cdr (assoc 41 doituong)))
  (setq TYLEY (cdr (assoc 42 doituong)))
  (setq DIEMTINH (list (/ (car DIEMCHENMOI) TYLEX) (/ (cadr DIEMCHENMOI) TYLEY)))
  (setq XDIEMTINH (car DIEMTINH)) (setq YDIEMTINH (cadr DIEMTINH))
  (setq DIEMCHENTUONGDOI (trans DIEMCHENMOI 1 0))
  (command "_.INSERT" TENKHOI (list 0 0 0) 1 1 0)
  (command "_.EXPLODE" "_last" "")
  (command "_.BLOCK" TENKHOIMOI DIEMCHENMOI "_P" "")
  (command "_.ucs" "_p")
  (setq xx (ssget "_X" (list '(0 . "INSERT") (cons 2 TENKHOI))))
  (if xx
    (progn
      (setq L 0) (setq M (sslength xx))
      (while (< L M)
        (setq DTs (ssname xx L)) (setq DTMs (entget DTs))
        (command "_.ucs" "_ob" DTs)
        (setq TYLEX1 (cdr (assoc 41 DTMs))) (setq TYLEY1 (cdr (assoc 42 DTMs)))
        (setq DIEMDOI (list (* XDIEMTINH TYLEX1) (* YDIEMTINH TYLEY1)))
        (setq DTMs (subst (cons 2 TENKHOIMOI) (assoc 2 DTMs) DTMs)) (entmod DTMs)
        (setq DIEMDOI (trans DIEMDOI 1 0))
        (setq DTMs (subst (cons 10 DIEMDOI) (assoc 10 DTMs) DTMs)) (entmod DTMs)
        (command "_.ucs" "_p")
        (setq L (1+ L))
      )
    )
  )
  (setvar "osmode" luubatdiem)
  (command "_.PURGE" "_B" TENKHOI "_N") 
  (command "_.RENAME" "_B" TENKHOIMOI TENKHOI)
  (setvar "cmdecho" oldEco)
  (command "_.undo" "_end")
  (princ (strcat "\nĐã chỉnh tâm của block <" TENKHOI "> thành công."))
  (princ)
)

(defun c:CPN ()
  (princ "\nChọn đối tượng bên trong Block để copy ra ngoài:")
  (if (getcname "NCOPY") 
    (command "_.NCOPY" pause "" "" "") 
    (princ "\nLệnh NCOPY không khả dụng trên phiên bản này.") 
  )
  (princ)
)

(defun c:QAB (/ bname p1 ss_all ss_geom textEnt elist tag val h rot wid style layer color p10 p11 justH justV new_elist att old_osmode etype mJust obj)
  (vl-load-com)
  (setvar "cmdecho" 0)
  (setq old_osmode (getvar "osmode"))
  (setq bname (getstring T "\nNhap ten Block: "))
  (if (tblsearch "BLOCK" bname)
    (alert (strcat "Ten Block '" bname "' da ton tai! Huy lenh."))
    (progn
      (setq p1 (getpoint "\nChon diem chen (Base Point): "))
      (setq ss_all (ssadd))
      (prompt "\n--- CHON TEXT/MTEXT DE CHUYEN THANH ATTRIBUTE ---")
      (while (setq textEnt (car (entsel "\n>> Pick chon Text hoac MText (Enter de dung): ")))
        (setq elist (entget textEnt))
        (setq etype (cdr (assoc 0 elist)))
        (if (or (= etype "TEXT") (= etype "MTEXT"))
          (progn
            (if (= etype "TEXT")
              (progn
                (setq val   (cdr (assoc 1 elist)))   
                (setq h     (cdr (assoc 40 elist)))  
                (setq p10   (cdr (assoc 10 elist)))  
                (setq p11   (cdr (assoc 11 elist)))  
                (setq rot   (cdr (assoc 50 elist)))  
                (setq wid   (cdr (assoc 41 elist)))  
                (setq justH (cdr (assoc 72 elist)))  
                (setq justV (cdr (assoc 73 elist)))
              )
              (progn
                (setq obj (vlax-ename->vla-object textEnt))
                (setq val (vla-get-textstring obj))
                (setq h     (cdr (assoc 40 elist)))
                (setq p10   (cdr (assoc 10 elist)))
                (setq p11   p10)
                (setq rot   (cdr (assoc 50 elist)))
                (setq wid   1.0)
                (setq mJust (cdr (assoc 71 elist)))
                (cond 
                  ((member mJust '(1 4 7)) (setq justH 0))
                  ((member mJust '(2 5 8)) (setq justH 1))
                  ((member mJust '(3 6 9)) (setq justH 2))
                  (t (setq justH 0))
                )
                (cond 
                  ((member mJust '(1 2 3)) (setq justV 3))
                  ((member mJust '(4 5 6)) (setq justV 2))
                  ((member mJust '(7 8 9)) (setq justV 1))
                  (t (setq justV 0))
                )
              )
            )
            (setq style (cdr (assoc 7 elist)))   
            (setq layer (cdr (assoc 8 elist)))   
            (setq color (assoc 62 elist))        
            (setq tag (getstring (strcat "\nNhap Tag cho '" (substr val 1 20) "...' <Enter lay mac dinh>: ")))
            (if (= tag "") (setq tag (vl-string-translate " " "_" val)))
            (while (vl-string-search "\r" tag) (setq tag (vl-string-subst "" "\r" tag)))
            (while (vl-string-search "\n" tag) (setq tag (vl-string-subst "" "\n" tag)))
            (setq new_elist (list 
                              '(0 . "ATTDEF") (cons 8 layer)
                              (if color color '(62 . 256)) 
                              (cons 10 p10) (cons 40 h) (cons 1 val)       
                              (cons 3 (strcat tag ":")) (cons 2 tag)       
                              (cons 70 0) (cons 7 style) (cons 41 wid)      
                              (cons 50 rot) (cons 72 justH) (cons 74 justV)    
                              (cons 11 p11) (cons 280 1)
                            ))
            (if (entmake new_elist)
              (progn
                (setq att (entlast))
                (ssadd att ss_all)   
                (entdel textEnt)     
                (princ (strcat " >> OK: " tag))
              )
              (princ "\n!! Loi tao Attribute.")
            )
          )
          (princ "\n!! Vui long chon TEXT hoac MTEXT.")
        )
      ) 
      (prompt "\n--- CHON HINH VE CON LAI ---")
      (setq ss_geom (ssget))
      (if ss_geom
        (progn
          (setq i 0)
          (repeat (sslength ss_geom)
            (ssadd (ssname ss_geom i) ss_all)
            (setq i (1+ i))
          )))
      (if (> (sslength ss_all) 0)
        (progn
          (setvar "osmode" 0)
          (command "_.BLOCK" bname p1 ss_all "")
          (command "_.INSERT" bname p1 "1" "1" "0")
          (setvar "osmode" old_osmode)
          (princ (strcat "\nDone! Block [" bname "] da Lock vi tri Attribute."))
        )
        (princ "\nHuy lenh.")
      )
    )
  )
  (setvar "cmdecho" 1)
  (princ)
)

(defun c:E2C (/ *error* xlApp xlSel rows rowCnt i val1 val2 dataList tagVal ss obj valCheck foundPair newVal count updated Get-Safe-Value Clean-String Find-Pair atts)
  (vl-load-com)
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*")))
      (princ (strcat "\nError: " msg))
    )
    (princ)
  )
  (defun Get-Safe-Value (rangeObj r c / cells item val)
    (setq cells (vlax-get-property rangeObj 'Cells))
    (setq item (vlax-variant-value (vlax-get-property cells 'Item r c)))
    (if (= (type item) 'VLA-OBJECT)
      (setq val (vlax-variant-value (vlax-get-property item 'Value2)))
      (setq val item) 
    )
    val
  )
  (defun Clean-String (str)
    (if (= (type str) 'STR)
      (vl-string-trim " \t\n\r" str)
      ""
    )
  )
  (defun Find-Pair (keyVal lst / res pair)
    (setq res nil)
    (foreach pair lst
      (if (= (strcase (car pair)) (strcase keyVal)) (setq res (cdr pair)))
      (if (= (strcase (cdr pair)) (strcase keyVal)) (setq res (car pair)))
    )
    res
  )
  
  (princ "\nDang ket noi Excel...")
  (setq xlApp (vlax-get-object "Excel.Application"))
  (if (not xlApp) (progn (alert "Hay mo Excel truoc!") (exit)))
  (if (vl-catch-all-error-p (setq xlSel (vlax-get-property (vlax-get-property xlApp 'ActiveWindow) 'RangeSelection)))
    (progn (alert "Loi! Hay boi den vung du lieu (2 cot) tren Excel.") (exit))
  )
  
  (setq rows (vlax-get-property xlSel 'Rows) rowCnt (vlax-get-property rows 'Count) dataList '())
  (setq i 1)
  (repeat rowCnt
    (setq val1 (Get-Safe-Value xlSel i 1))
    (setq val2 (Get-Safe-Value xlSel i 2))
    (if (= (type val1) 'Real) (setq val1 (rtos val1 2 0)))
    (if (= (type val2) 'Real) (setq val2 (rtos val2 2 0)))
    (if (null val1) (setq val1 ""))
    (if (null val2) (setq val2 ""))
    (setq val1 (Clean-String (vl-princ-to-string val1)))
    (setq val2 (Clean-String (vl-princ-to-string val2)))
    (if (or (/= val1 "") (/= val2 ""))
      (setq dataList (cons (cons val1 val2) dataList))
    )
    (setq i (1+ i))
  )
  (princ (strcat "\nExcel: Da nho " (itoa (length dataList)) " dong du lieu."))
  
  ;; --- PHẦN CẬP NHẬT: CLICK CHỌN TAG THAY VÌ GÕ TAY ---
  (setq tagVal (Pick-Attribute-Tag ">>> CLICK CHON VAO CHU (ATTRIBUTE) CAN DIEN DU LIEU TRONG BLOCK MAU: "))
  (princ (strcat "\n>>> Da chon Tag can dien: [" (strcase tagVal) "]"))
  ;; ----------------------------------------------------
  
  (princ (strcat "\n>>> Dang tim du lieu cho Tag [" (strcase tagVal) "] dua theo cac Tag con lai..."))
  (princ "\n>>> Quet chon vung Block can update: ")
  (setq ss (ssget '((0 . "INSERT") (66 . 1))))
  (if ss
    (progn
      (setq count 0 updated 0)
      (repeat (sslength ss)
        (setq obj (vlax-ename->vla-object (ssname ss count)))
        (setq atts (vlax-invoke obj 'GetAttributes))
        (setq newVal nil)
        (foreach att atts
           (if (/= (strcase (vlax-get-property att 'TagString)) (strcase tagVal))
             (progn
               (setq valCheck (Clean-String (vlax-get-property att 'TextString)))
               (if (setq foundPair (Find-Pair valCheck dataList))
                 (setq newVal foundPair) 
               )
             )
           )
        )
        (if newVal
          (foreach att atts
            (if (= (strcase (vlax-get-property att 'TagString)) (strcase tagVal))
              (progn
                (vlax-put-property att 'TextString newVal)
                (setq updated (1+ updated))
              )
            )
          )
        )
        (setq count (1+ count))
      )
      (alert (strcat "Hoan tat!\nQuet: " (itoa count) " blocks.\nDa dien duoc: " (itoa updated) " blocks."))
    )
    (princ "\nKhong chon duoc Block nao.")
  )
  (princ)
)

;;; --- XOAY - LẬT BLOCK ---
(defun c:R90 (/ ss i ent obj ip)
  (princ "\nChọn Block cần xoay +90 độ:")
  (setq ss (ssget '((0 . "INSERT"))))
  (if ss
    (repeat (setq i (sslength ss))
      (setq ent (ssname ss (setq i (1- i))))
      (setq obj (vlax-ename->vla-object ent))
      (setq ip (vla-get-InsertionPoint obj))
      (vla-Rotate obj ip (/ pi 2))
    )
  )
  (princ)
)

(defun c:R-90 (/ ss i ent obj ip)
  (princ "\nChọn Block cần xoay -90 độ:")
  (setq ss (ssget '((0 . "INSERT"))))
  (if ss
    (repeat (setq i (sslength ss))
      (setq ent (ssname ss (setq i (1- i))))
      (setq obj (vlax-ename->vla-object ent))
      (setq ip (vla-get-InsertionPoint obj))
      (vla-Rotate obj ip (/ pi -2))
    )
  )
  (princ)
)

(defun c:MX (/ ss i ent obj ip p1 p2)
  (princ "\nChọn Block để Mirror X (Lật trên/dưới):")
  (setq ss (ssget '((0 . "INSERT"))))
  (if ss
    (repeat (setq i (sslength ss))
      (setq ent (ssname ss (setq i (1- i))))
      (setq obj (vlax-ename->vla-object ent))
      (setq ip (vlax-safearray->list (vlax-variant-value (vla-get-InsertionPoint obj))))
      (setq p1 ip)
      (setq p2 (list (+ (car ip) 1.0) (cadr ip) (caddr ip)))
      (vla-Mirror obj (vlax-3d-point p1) (vlax-3d-point p2))
      (vla-Delete obj)
    )
  )
  (princ)
)

(defun c:MY (/ ss i ent obj ip p1 p2)
  (princ "\nChọn Block để Mirror Y (Lật trái/phải):")
  (setq ss (ssget '((0 . "INSERT"))))
  (if ss
    (repeat (setq i (sslength ss))
      (setq ent (ssname ss (setq i (1- i))))
      (setq obj (vlax-ename->vla-object ent))
      (setq ip (vlax-safearray->list (vlax-variant-value (vla-get-InsertionPoint obj))))
      (setq p1 ip)
      (setq p2 (list (car ip) (+ (cadr ip) 1.0) (caddr ip)))
      (vla-Mirror obj (vlax-3d-point p1) (vlax-3d-point p2))
      (vla-Delete obj)
    )
  )
  (princ)
)

;;; --- THAY THẾ - SCALE BLOCK ---
(defun c:SCB (/ entSource objSource sx sy sz ss i entTarget objTarget)
  (setq entSource (car (entsel "\nChọn Block MẪU (đã có scale chuẩn): ")))
  (if (and entSource (= (cdr (assoc 0 (entget entSource))) "INSERT"))
    (progn
      (setq objSource (vlax-ename->vla-object entSource))
      (setq sx (vla-get-XScaleFactor objSource))
      (setq sy (vla-get-YScaleFactor objSource))
      (setq sz (vla-get-ZScaleFactor objSource))
      (princ (strcat "\nĐã copy Scale: X=" (rtos sx 2 2) " Y=" (rtos sy 2 2)))
      (princ "\nQuét chọn các Block cần áp dụng Scale này:")
      (setq ss (ssget '((0 . "INSERT"))))
      (if ss
        (progn
          (setq i 0)
          (repeat (sslength ss)
            (setq entTarget (ssname ss i))
            (setq objTarget (vlax-ename->vla-object entTarget))
            (vla-put-XScaleFactor objTarget sx)
            (vla-put-YScaleFactor objTarget sy)
            (vla-put-ZScaleFactor objTarget sz)
            (setq i (1+ i))
          )
          (princ (strcat "\nĐã cập nhật Scale cho " (itoa (sslength ss)) " block."))
        )
        (princ "\nKhông có Block nào được chọn.")
      )
    )
    (princ "\nĐối tượng chọn không phải là Block.")
  )
  (princ)
)

(defun c:RBS (/ entSource objSource sourceName ss i blkRef doc)
  (vl-load-com)
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (while (not entSource)
    (setq entSource (car (entsel "\n[RBS] Chọn Block NGUỒN (Mẫu mới): ")))
    (if entSource (if (/= (cdr (assoc 0 (entget entSource))) "INSERT") (setq entSource nil)))
  )
  (setq objSource (vlax-ename->vla-object entSource))
  (setq sourceName (if (vlax-property-available-p objSource 'EffectiveName) (vla-get-EffectiveName objSource) (vla-get-Name objSource)))
  
  (princ (strcat "\n[RBS] Quét chọn các Block CŨ cần thay thế bằng [" sourceName "]: "))
  (setq ss (ssget '((0 . "INSERT"))))
  
  (if ss
    (progn
      (vla-startundomark doc)
      (setq i 0)
      (repeat (sslength ss)
        (setq blkRef (vlax-ename->vla-object (ssname ss i)))
        (vl-catch-all-apply 'vla-put-Name (list blkRef sourceName))
        (setq i (1+ i))
      )
      (vla-endundomark doc)
      (princ (strcat "\nĐã thay thế " (itoa (sslength ss)) " block."))
    )
    (princ "\nKhông có Block nào được chọn.")
  )
  (princ)
)

(defun Get-Effective-Name (ent / blkname)
  (if (vlax-property-available-p (vlax-ename->vla-object ent) 'EffectiveName)
    (setq blkname (vla-get-EffectiveName (vlax-ename->vla-object ent)))
    (setq blkname (cdr (assoc 2 (entget ent))))
  )
  blkname
)

(defun Get-Attributes (obj / atts)
  (if (and (vlax-property-available-p obj 'HasAttributes) (= (vla-get-HasAttributes obj) :vlax-true))
    (vlax-safearray->list (vlax-variant-value (vla-GetAttributes obj)))
    nil
  )
)

(defun Pick-Attribute-Tag (msg / ent obj tag)
  (while (not ent)
    (setq ent (nentsel (strcat "\n" msg)))
    (if ent
      (progn
        (setq obj (vlax-ename->vla-object (car ent)))
        (if (= (vla-get-ObjectName obj) "AcDbAttribute")
          (setq tag (vla-get-TagString obj))
          (progn (princ "\nBan phai click vao mot ATTRIBUTE (chu viet trong Block).") (setq ent nil))
        )
      )
      (princ "\nChua chon doi tuong.")
    )
  )
  tag
)

(defun Pad-Number (num digits / str)
  (setq str (itoa num))
  (while (< (strlen str) digits) (setq str (strcat "0" str)))
  str
)

(defun Get-Blk-Pt (ent) (cdr (assoc 10 (entget ent))))

(defun Sort-Entities (entlist mode / )
  (cond
    ((or (= mode "Left-Right") (= mode "LR")) (vl-sort entlist '(lambda (e1 e2) (< (car (Get-Blk-Pt e1)) (car (Get-Blk-Pt e2))))))
    ((or (= mode "Right-Left") (= mode "RL")) (vl-sort entlist '(lambda (e1 e2) (> (car (Get-Blk-Pt e1)) (car (Get-Blk-Pt e2))))))
    ((or (= mode "Top-Bottom") (= mode "TB")) (vl-sort entlist '(lambda (e1 e2) (> (cadr (Get-Blk-Pt e1)) (cadr (Get-Blk-Pt e2))))))
    ((or (= mode "Bottom-Top") (= mode "BT")) (vl-sort entlist '(lambda (e1 e2) (< (cadr (Get-Blk-Pt e1)) (cadr (Get-Blk-Pt e2))))))
    (t entlist)
  )
)

(defun c:RBKR (/ source_ent source_blk_name ss i ent obj ins_pt old_rot lay doc space new_obj)
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (setq space (if (= (vla-get-activespace doc) 1) (vla-get-modelspace doc) (vla-get-paperspace doc)))
  (princ "\n--- REPLACE BLOCK (KEEP ROTATION) ---")
  (while (not source_ent) (setq source_ent (car (entsel "\n[RBKR] Chọn Block nguồn (Block mẫu): "))) (if (or (not source_ent) (/= (cdr (assoc 0 (entget source_ent))) "INSERT")) (setq source_ent nil)))
  (setq source_blk_name (Get-Effective-Name source_ent))
  (princ "\n[RBKR] Quét chọn các Block cần thay thế: ") (setq ss (ssget '((0 . "INSERT"))))
  (if ss (progn (vla-startundomark doc) (setq i 0) (repeat (sslength ss) (setq ent (ssname ss i)) (setq obj (vlax-ename->vla-object ent)) (setq ins_pt (vla-get-InsertionPoint obj)) (setq old_rot (vla-get-Rotation obj)) (setq lay (vla-get-Layer obj)) (setq new_obj (vla-InsertBlock space ins_pt source_blk_name 1.0 1.0 1.0 old_rot)) (vla-put-Layer new_obj lay) (vla-delete obj) (setq i (1+ i))) (vla-endundomark doc) (princ (strcat "\nĐã thay thế " (itoa i) " block.")))) (princ))

(defun c:RBKS (/ source_ent source_blk_name ss i ent obj ins_pt old_sx old_sy old_sz lay doc space new_obj)
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (setq space (if (= (vla-get-activespace doc) 1) (vla-get-modelspace doc) (vla-get-paperspace doc)))
  (princ "\n--- REPLACE BLOCK (KEEP SCALE) ---")
  (while (not source_ent) (setq source_ent (car (entsel "\n[RBKS] Chọn Block nguồn (Block mẫu): "))) (if (or (not source_ent) (/= (cdr (assoc 0 (entget source_ent))) "INSERT")) (setq source_ent nil)))
  (setq source_blk_name (Get-Effective-Name source_ent))
  (princ "\n[RBKS] Quét chọn các Block cần thay thế: ") (setq ss (ssget '((0 . "INSERT"))))
  (if ss (progn (vla-startundomark doc) (setq i 0) (repeat (sslength ss) (setq ent (ssname ss i)) (setq obj (vlax-ename->vla-object ent)) (setq ins_pt (vla-get-InsertionPoint obj)) (setq old_sx (vla-get-XScaleFactor obj)) (setq old_sy (vla-get-YScaleFactor obj)) (setq old_sz (vla-get-ZScaleFactor obj)) (setq lay (vla-get-Layer obj)) (setq new_obj (vla-InsertBlock space ins_pt source_blk_name old_sx old_sy old_sz 0.0)) (vla-put-Layer new_obj lay) (vla-delete obj) (setq i (1+ i))) (vla-endundomark doc) (princ (strcat "\nĐã thay thế " (itoa i) " block.")))) (princ))

;;; --- CÔNG CỤ ATTRIBUTE ---
(defun c:NUMBLK (/ target_tag prefix start_str start_num min_digits sort_mode ss ent_list i ent obj atts att final_val doc key)
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (princ "\n--- NUMBER BLOCK (SMART PADDING) ---")
  (setq target_tag (Pick-Attribute-Tag "Click vao Text thuoc tinh can danh so: "))
  (setq prefix (getstring t (strcat "\nNhap tien to (Enter de bo qua): ")))
  (setq start_str (getstring "\nNhap so bat dau (VD: '1' hoac '01' hoac '001'...): "))
  (if (= start_str "") (setq start_str "1")) 
  (setq start_num (atoi start_str))   
  (setq min_digits (strlen start_str)) 
  (initget "Left-Right Right-Left Top-Bottom Bottom-Top Manual")
  (setq key (getkword "\nChon kieu sap xep [Left-Right/Right-Left/Top-Bottom/Bottom-Top/Manual] <Left-Right>: "))
  (if (not key) (setq sort_mode "Left-Right") (setq sort_mode key))
  (princ (strcat "\nQuet chon cac Block (Se sap xep: " sort_mode "): "))
  (setq ss (ssget '((0 . "INSERT"))))
  (if ss
    (progn
      (vla-startundomark doc)
      (setq ent_list '())
      (setq i 0)
      (repeat (sslength ss) (setq ent_list (cons (ssname ss i) ent_list)) (setq i (1+ i)))
      (if (not (= sort_mode "Manual")) (setq ent_list (Sort-Entities ent_list sort_mode)) (setq ent_list (reverse ent_list)))
      (foreach ent ent_list
        (setq obj (vlax-ename->vla-object ent))
        (setq atts (Get-Attributes obj))
        (foreach att atts
          (if (= (strcase (vla-get-TagString att)) (strcase target_tag))
            (progn
              (setq final_val (strcat prefix (Pad-Number start_num min_digits)))
              (vla-put-TextString att final_val)
              (vla-update att)
            )
          )
        )
        (setq start_num (1+ start_num))
      )
      (vla-endundomark doc)
      (princ "\nDa danh so xong.")
    )
    (princ "\nKhong chon duoc Block nao.")
  )
  (princ)
)

;; --- LỆNH MỚI: CHÈN BLOCK VÀ ĐÁNH SỐ TĂNG DẦN (IBN) ---
(defun c:IBN (/ sel ent_att att_data ent_blk obj_blk bname target_tag prefix start_str start_num min_digits doc space pt new_obj atts att final_val loop)
  (vl-load-com)
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (setq space (if (= (vla-get-activespace doc) 1) (vla-get-modelspace doc) (vla-get-paperspace doc)))

  (princ "\n--- CHÈN BLOCK VÀ ĐÁNH SỐ TĂNG DẦN ---")
  (princ "\n>>> Click vào 1 Attribute của Block mẫu để lấy thông tin: ")
  (setq sel (nentsel))
  (if sel
    (progn
      (setq ent_att (car sel) att_data (entget ent_att))
      (if (= (cdr (assoc 0 att_data)) "ATTRIB")
        (progn
          (setq ent_blk (cdr (assoc 330 att_data)))
          (setq obj_blk (vlax-ename->vla-object ent_blk))
          (setq bname (Get-Effective-Name ent_blk))
          (setq target_tag (vla-get-TagString (vlax-ename->vla-object ent_att)))
          (princ (strcat "\nĐã chọn Block: [" bname "] | Tag: [" target_tag "]"))
        )
        (progn (princ "\nBạn phải chọn vào chữ (Attribute). Hủy lệnh.") (exit))
      )
    )
    (progn (princ "\nChưa chọn đối tượng. Hủy lệnh.") (exit))
  )

  (setq prefix (getstring t "\nNhập tiền tố (Enter để bỏ qua): "))
  (setq start_str (getstring "\nNhập số bắt đầu (VD: '1' hoặc '01' hoặc '001'...): "))
  (if (= start_str "") (setq start_str "1"))
  (setq start_num (atoi start_str))
  (setq min_digits (strlen start_str))

  (setq loop T)
  (vla-startundomark doc)
  (while loop
    (setq final_val (strcat prefix (Pad-Number start_num min_digits)))
    (setq pt (getpoint (strcat "\n>>> Chọn điểm chèn Block (Số tiếp theo sẽ là: " final_val ") [Nhấn Esc/Space/Enter để Dừng]: ")))
    (if pt
      (progn
        (setq new_obj (vla-InsertBlock space (vlax-3d-point pt) bname 1.0 1.0 1.0 0.0))
        (setq atts (Get-Attributes new_obj))
        (if atts
          (foreach att atts
            (if (= (strcase (vla-get-TagString att)) (strcase target_tag))
              (vla-put-TextString att final_val)
            )
          )
        )
        (vla-update new_obj)
        (setq start_num (1+ start_num))
      )
      (setq loop nil)
    )
  )
  (vla-endundomark doc)
  (princ "\nĐã hoàn tất chèn Block.")
  (princ)
)
;; ---------------------------------------------------------------------

(defun c:CLRATT (/ target_tag ss i ent obj atts att doc) (setq doc (vla-get-activedocument (vlax-get-acad-object))) (princ "\n--- CLEAR ATTRIBUTE ---") (setq target_tag (Pick-Attribute-Tag "Click vao Text thuoc tinh mau muon xoa trang: ")) (princ "\nQuet chon Block: ") (setq ss (ssget '((0 . "INSERT")))) (if ss (progn (vla-startundomark doc) (setq i 0) (repeat (sslength ss) (setq ent (ssname ss i)) (setq obj (vlax-ename->vla-object ent)) (setq atts (Get-Attributes obj)) (foreach att atts (if (= (strcase (vla-get-TagString att)) (strcase target_tag)) (vla-put-TextString att ""))) (setq i (1+ i))) (vla-endundomark doc) (princ "\nDone."))) (princ))
(defun c:CPYATT (/ source_ent source_obj source_atts target_atts ss i ent obj att_s att_t doc) (setq doc (vla-get-activedocument (vlax-get-acad-object))) (princ "\n--- COPY ATTRIBUTE ---") (while (not source_ent) (setq source_ent (car (entsel "\nChon Block nguon: "))) (if (or (not source_ent) (/= (cdr (assoc 0 (entget source_ent))) "INSERT")) (setq source_ent nil))) (setq source_obj (vlax-ename->vla-object source_ent)) (setq source_atts (Get-Attributes source_obj)) (princ "\nChon Block dich: ") (setq ss (ssget '((0 . "INSERT")))) (if ss (progn (vla-startundomark doc) (setq i 0) (repeat (sslength ss) (setq ent (ssname ss i)) (setq obj (vlax-ename->vla-object ent)) (setq target_atts (Get-Attributes obj)) (foreach att_t target_atts (foreach att_s source_atts (if (= (vla-get-TagString att_t) (vla-get-TagString att_s)) (vla-put-TextString att_t (vla-get-TextString att_s))))) (setq i (1+ i))) (vla-endundomark doc) (princ "\nDone."))) (princ))
(defun c:MOVATT (/ ent obj pt1 pt2 doc) (setq doc (vla-get-activedocument (vlax-get-acad-object))) (princ "\n--- MOVE ATTRIBUTE ---") (while (not ent) (setq ent (nentsel "\nChon Attribute: ")) (if ent (if (/= (cdr (assoc 0 (entget (car ent)))) "ATTRIB") (setq ent nil)))) (setq obj (vlax-ename->vla-object (car ent))) (setq pt1 (getpoint "\nBase point: ")) (if pt1 (progn (setq pt2 (getpoint pt1 "\nSecond point: ")) (if pt2 (progn (vla-startundomark doc) (vla-Move obj (vlax-3d-point pt1) (vlax-3d-point pt2)) (vla-update obj) (vla-endundomark doc))))) (princ))
(defun c:ROTATT (/ ent obj ang doc) (setq doc (vla-get-activedocument (vlax-get-acad-object))) (princ "\n--- ROTATE ATTRIBUTE ---") (while (not ent) (setq ent (nentsel "\nChon Attribute: ")) (if ent (if (/= (cdr (assoc 0 (entget (car ent)))) "ATTRIB") (setq ent nil)))) (setq obj (vlax-ename->vla-object (car ent))) (setq ang (getangle "\nGoc xoay: ")) (if ang (progn (vla-startundomark doc) (vla-put-Rotation obj ang) (vla-update obj) (vla-endundomark doc))) (princ))

;;; --- THỐNG KÊ - ĐẾM ---
(defun c:CBS (/ ss i)
  (princ "\nQuét chọn các đối tượng để đếm Block:")
  (setq ss (ssget '((0 . "INSERT"))))
  (if ss
    (alert (strcat "Số lượng Block trong vùng chọn là: " (itoa (sslength ss))))
    (princ "\nKhông có Block nào được chọn.")
  )
  (princ)
)

(defun c:TKATT (/ *error* AcDoc Space sel-blk ent-att att-data ent-blk obj-blk blk-name eff-name att-tags sel-set ss-len i ent-item obj-item item-name item-atts data-list key found sel-style ent-style style-data text-h text-style text-layer text-color text-width text-oblique pt-ins col-widths row-height headers row-data full-row count w len x y DrawCellText DrawBox)
  (vl-load-com)
  (setq AcDoc (vla-get-ActiveDocument (vlax-get-acad-object))
        Space (if (= (getvar "CVPORT") 1) (vla-get-PaperSpace AcDoc) (vla-get-ModelSpace AcDoc)))
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg) "*BREAK*,*CANCEL*,*EXIT*"))) (princ (strcat "\nLoi: " msg)))
    (vla-EndUndoMark AcDoc) (princ)
  )
  (vla-StartUndoMark AcDoc)
  (princ "\n>>> Chon mot dong chu (Attribute) thuoc Block mau: ")
  (setq sel-blk (nentsel))
  (if (null sel-blk) (progn (princ "\nBan chua chon doi tuong. Huy lenh.") (exit)))
  (setq ent-att (car sel-blk) att-data (entget ent-att))
  (if (or (= (cdr (assoc 0 att-data)) "ATTRIB") (= (cdr (assoc 0 att-data)) "MTEXT") (= (cdr (assoc 0 att-data)) "TEXT"))
      (progn
        (if (= (cdr (assoc 0 att-data)) "ATTRIB")
           (setq ent-blk (cdr (assoc 330 att-data)))
           (setq ent-blk (car (last sel-blk))) 
        )
      )
      (progn (princ "\nBan da click vao net ve. Hay click chinh xac vao chu (Attribute).") (exit))
  )
  (if (/= (cdr (assoc 0 (entget ent-blk))) "INSERT") (progn (princ "\nKhong tim thay Block cha hop le. Huy lenh.") (exit)))
  (setq obj-blk (vlax-ename->vla-object ent-blk))
  (if (vlax-property-available-p obj-blk 'EffectiveName) (setq eff-name (vla-get-EffectiveName obj-blk)) (setq eff-name (vla-get-Name obj-blk)))
  (princ (strcat "\nDa chon Block: " eff-name))
  (setq att-tags '())
  (foreach att (vlax-invoke obj-blk 'GetAttributes) (setq att-tags (append att-tags (list (vla-get-TagString att)))))
  (princ "\n>>> Quet chon vung can thong ke: ")
  (setq sel-set (ssget (list (cons 0 "INSERT"))))
  (if (null sel-set) (progn (princ "\nKhong chon duoc Block nao. Huy lenh.") (exit)))
  (setq data-list '() ss-len (sslength sel-set) i 0)
  (repeat ss-len
    (setq ent-item (ssname sel-set i) obj-item (vlax-ename->vla-object ent-item))
    (if (vlax-property-available-p obj-item 'EffectiveName) (setq item-name (vla-get-EffectiveName obj-item)) (setq item-name (vla-get-Name obj-item)))
    (if (= item-name eff-name)
      (progn
        (setq item-atts '())
        (foreach att (vlax-invoke obj-item 'GetAttributes) (setq item-atts (append item-atts (list (vla-get-TextString att)))))
        (if (= (length item-atts) (length att-tags))
          (progn
            (setq key item-atts found (assoc key data-list))
            (if found (setq data-list (subst (cons key (1+ (cdr found))) found data-list)) (setq data-list (append data-list (list (cons key 1)))))
          )
        )
      )
    )
    (setq i (1+ i))
  )
  (setq data-list (vl-sort data-list '(lambda (a b) (< (car (car a)) (car (car b))))))
  (if (null data-list) (progn (princ "\nKhong tim thay Block nao cung loai trong vung chon.") (exit)))
  (princ "\n>>> Chon Text mau (de lay Style, Layer, Mau sac...): ")
  (setq sel-style (nentsel))
  (if sel-style
    (progn
      (setq ent-style (car sel-style) style-data (entget ent-style) text-h (cdr (assoc 40 style-data)) text-style (cdr (assoc 7 style-data)) text-layer (cdr (assoc 8 style-data)) text-color (cdr (assoc 62 style-data)) text-width (cdr (assoc 41 style-data)) text-oblique (cdr (assoc 51 style-data)))     
      (if (null text-width) (setq text-width 1.0))        
      (if (null text-oblique) (setq text-oblique 0.0))    
    )
    (progn (setq text-h (getvar "TEXTSIZE") text-style (getvar "TEXTSTYLE") text-layer (getvar "CLAYER") text-color nil text-width 1.0 text-oblique 0.0))
  )
  (setq pt-ins (getpoint "\n>>> Chon diem dat bang thong ke: "))
  (if (null pt-ins) (exit))
  (defun DrawCellText (txt pt width height / ent-lst)
    (setq ent-lst (list '(0 . "TEXT") (cons 10 (list (+ (car pt) (/ width 2.0)) (- (cadr pt) (/ height 2.0)) 0.0)) (cons 40 text-h) (cons 1 txt) (cons 8 text-layer) (cons 7 text-style) (cons 41 text-width) (cons 51 text-oblique) (cons 72 1) (cons 73 2) (cons 11 (list (+ (car pt) (/ width 2.0)) (- (cadr pt) (/ height 2.0)) 0.0))))
    (if text-color (setq ent-lst (append ent-lst (list (cons 62 text-color)))))
    (entmake ent-lst)
  )
  (defun DrawBox (pt width height)
    (entmake (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity") '(100 . "AcDbPolyline") (cons 8 text-layer) '(90 . 4) '(70 . 1) (cons 10 (list (car pt) (cadr pt))) (cons 10 (list (+ (car pt) width) (cadr pt))) (cons 10 (list (+ (car pt) width) (- (cadr pt) height))) (cons 10 (list (car pt) (- (cadr pt) height)))))
  )
  (setq headers (append att-tags (list "QTY")))
  (setq col-widths (mapcar '(lambda (txt) (* (strlen txt) text-h text-width 1.2)) headers)) 
  (foreach row data-list
    (setq row-data (car row) count (itoa (cdr row)) full-row (append row-data (list count)) i 0 new-widths '())
    (foreach txt full-row
      (setq len (* (strlen txt) text-h text-width 1.0)) 
      (if (> len (nth i col-widths)) (setq new-widths (append new-widths (list len))) (setq new-widths (append new-widths (list (nth i col-widths)))))
      (setq i (1+ i))
    )
    (setq col-widths new-widths)
  )
  (setq col-widths (mapcar '(lambda (w) (+ w (* 2.0 text-h))) col-widths))
  (setq row-height (* 1.8 text-h))
  (setq x (car pt-ins) y (cadr pt-ins) i 0)
  (foreach h headers (setq w (nth i col-widths)) (DrawBox (list x y) w row-height) (DrawCellText h (list x y) w row-height) (setq x (+ x w) i (1+ i)))
  (setq y (- y row-height))
  (foreach row data-list
    (setq x (car pt-ins) row-data (car row) count (itoa (cdr row)) full-row (append row-data (list count)) i 0)
    (foreach txt full-row (setq w (nth i col-widths)) (DrawBox (list x y) w row-height) (DrawCellText txt (list x y) w row-height) (setq x (+ x w) i (1+ i)))
    (setq y (- y row-height))
  )
  (princ (strcat "\nDa thong ke xong " (itoa (length data-list)) " loai Block."))
  (vla-EndUndoMark AcDoc)
  (princ)
)

(defun Get-Text-Data (/ ss i obj str data lst-sorted val)
  (prompt "\n>>> Quet chon Text de thong ke (hoac Enter de chon tat ca): ")
  (if (null (setq ss (ssget '((0 . "TEXT")))))
    (setq ss (ssget "_X" (list (cons 0 "TEXT") (cons 410 (getvar "CTAB")))))
  )
  (if ss
    (progn
      (setq data '())
      (repeat (setq i (sslength ss))
        (setq obj (vlax-ename->vla-object (ssname ss (setq i (1- i)))))
        (setq str (vla-get-TextString obj))
        (setq str (vl-string-trim " " str)) 
        (if (and (/= str "") (null (distof str)))
          (if (setq entry (assoc str data))
            (setq data (subst (cons str (1+ (cdr entry))) entry data))
            (setq data (cons (cons str 1) data))
          )
        )
      )
      (if data (vl-sort data '(lambda (x y) (< (cdr x) (cdr y)))) (progn (alert "Khong tim thay Text mo ta.") nil))
    )
    nil
  )
)

(defun c:TKT (/ doc msp lst-sorted sample-ent sample-obj prop-layer prop-style prop-height prop-color prop-width pt ins-pt col-w row-h new-obj-count new-obj-content)
  (setq doc (vla-get-activedocument (vlax-get-acad-object))
        msp (vla-get-modelspace doc))
  (if (setq lst-sorted (Get-Text-Data))
    (progn
      (initget "Khong")
      (setq sample-ent (entsel "\n>>> Chon Text MAU [Enter de bo qua]: "))
      (if sample-ent
        (progn
          (setq sample-obj (vlax-ename->vla-object (car sample-ent)))
          (setq prop-layer  (vla-get-Layer sample-obj) prop-style  (vla-get-StyleName sample-obj) prop-height (vla-get-Height sample-obj) prop-color  (vla-get-Color sample-obj) prop-width  (vla-get-ScaleFactor sample-obj))
        )
        (progn
          (setq prop-layer  (getvar "CLAYER") prop-style  (getvar "TEXTSTYLE") prop-height (* (getvar "dimtxt") (getvar "dimscale")) prop-color  256 prop-width  1.0)
          (if (zerop prop-height) (setq prop-height (getvar "TEXTSIZE")))
        )
      )
      (if (setq pt (getpoint "\n>>> Chon diem dat Bang thong ke: "))
        (progn
          (setq col-w (* 4.0 prop-height) row-h (* 1.5 prop-height))
          (foreach item lst-sorted
            (setq ins-pt (vlax-3d-point pt))
            (setq new-obj-count (vla-addtext msp (itoa (cdr item)) ins-pt prop-height))
            (vla-put-Layer new-obj-count prop-layer) (vla-put-StyleName new-obj-count prop-style) (vla-put-Color new-obj-count prop-color) (vla-put-ScaleFactor new-obj-count prop-width)
            (setq new-obj-content (vla-addtext msp (car item) (vlax-3d-point (polar pt 0 col-w)) prop-height))
            (vla-put-Layer new-obj-content prop-layer) (vla-put-StyleName new-obj-content prop-style) (vla-put-Color new-obj-content prop-color) (vla-put-ScaleFactor new-obj-content prop-width)
            (setq pt (polar pt (/ pi -2) row-h))
          )
          (princ (strcat "\nDa ve xong bang voi " (itoa (length lst-sorted)) " muc."))
        )
      )
    )
  )
  (princ)
)

(defun c:TKE (/ ss i obj str pt y x data lst-sorted row-group row-y fuzz row-str full-str htmlfile ent-h)
  (princ "\n>>> Quet chon bang Text can xuat sang Excel...")
  (if (setq ss (ssget '((0 . "*TEXT"))))
    (progn
      (setq data '() i 0)
      (repeat (sslength ss)
        (setq obj (vlax-ename->vla-object (ssname ss i)))
        (setq str (vl-string-trim " " (vla-get-TextString obj)))
        (setq pt (vlax-get obj 'InsertionPoint))
        (setq data (cons (list (cadr pt) (car pt) str (vla-get-Height obj)) data))
        (setq i (1+ i))
      )
      (setq lst-sorted (vl-sort data '(lambda (a b) (> (car a) (car b)))))
      (setq fuzz (* (cadddr (car lst-sorted)) 0.6))
      (setq full-str "")
      (while lst-sorted
        (setq row-group (list (car lst-sorted)) row-y (caar lst-sorted) lst-sorted (cdr lst-sorted) temp-list '())
        (foreach item lst-sorted
          (if (< (abs (- (car item) row-y)) fuzz) (setq row-group (cons item row-group)) (setq temp-list (cons item temp-list)))
        )
        (setq lst-sorted (reverse temp-list))
        (setq row-group (vl-sort row-group '(lambda (a b) (< (cadr a) (cadr b)))))
        (setq row-str "")
        (foreach item row-group (setq row-str (strcat row-str (caddr item) "\t")))
        (setq full-str (strcat full-str row-str "\n"))
      )
      (if (setq htmlfile (vlax-create-object "htmlfile"))
        (progn
          (vlax-invoke (vlax-get (vlax-get htmlfile 'ParentWindow) 'ClipboardData) 'SetData "Text" full-str)
          (vlax-release-object htmlfile)
          (princ (strcat "\n>>> Da copy " (itoa (sslength ss)) " doi tuong! Hay mo Excel va nhan Ctrl+V."))
        )
        (princ "\nLoi: Khong the truy cap Clipboard.")
      )
    )
    (alert "Khong chon duoc Text nao.")
  )
  (princ)
)

;;; =========================================================================
;;; PHẦN 2: HÀM KHỞI TẠO UI (DCL) VÀ VÒNG LẶP ĐIỀU KHIỂN
;;; =========================================================================

(defun c:MasterBlock ( / dcl_file f dcl_lst dcl_id loop action_code acad_doc)
  (setq acad_doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  ;; 1. TẠO FILE DCL ĐỘNG VÀO THƯ MỤC TEMP
  (setq dcl_file (vl-filename-mktemp "MasterBlock_UI" nil ".dcl"))
  (setq f (open dcl_file "w"))
  
  (setq dcl_lst
    (list
      "MasterBlock_dlg : dialog {"
      "  label = \"MasterBlock Tools - Trình Quản Lý Tổng Hợp\";"
      "  : row {"
      "    : column {"
      "      : boxed_column { label = \"BlocktoColor8\";"
      "        : button { key = \"btn_SBF\"; label = \"Smart Block Fix (SBF)\"; }"
      "      }"
      "      : boxed_column { label = \"Công Cụ Cơ Bản\";"
      "        : button { key = \"btn_BRN\"; label = \"Đổi Tên Block (BRN)\"; }"
      "        : button { key = \"btn_BX\";  label = \"Phá Block (BX)\"; }"
      "        : button { key = \"btn_CBP\"; label = \"Đổi Điểm Chèn (CBP)\"; }"
      "        : button { key = \"btn_CPN\"; label = \"Copy Lõi Block (CPN)\"; }"
      "        : button { key = \"btn_QAB\"; label = \"Tạo Block ATT Nhanh (QAB)\"; }"
      "        : button { key = \"btn_E2C\"; label = \"Excel -> Block ATT (E2C)\"; }"
      "      }"
      "    }"
      "    : column {"
      "      : boxed_column { label = \"Xoay - Lật Block\";"
      "        : button { key = \"btn_R90\";  label = \"Xoay +90 Độ (R90)\"; }"
      "        : button { key = \"btn_R-90\"; label = \"Xoay -90 Độ (R-90)\"; }"
      "        : button { key = \"btn_MX\";   label = \"Lật Qua Trục X (MX)\"; }"
      "        : button { key = \"btn_MY\";   label = \"Lật Qua Trục Y (MY)\"; }"
      "      }"
      "      : boxed_column { label = \"Thay Thế - Scale\";"
      "        : button { key = \"btn_RBS\";  label = \"Replace Block (RBS)\"; }"
      "        : button { key = \"btn_RBKR\"; label = \"Replace Giữ Góc (RBKR)\"; }"
      "        : button { key = \"btn_RBKS\"; label = \"Replace Giữ Scale (RBKS)\"; }"
      "        : button { key = \"btn_SCB\";  label = \"Copy Scale Mẫu (SCB)\"; }"
      "      }"
      "    }"
      "    : column {"
      "      : boxed_column { label = \"Công Cụ Attribute (ATT)\";"
      "        : button { key = \"btn_IBN\";    label = \"Chèn Block Tăng Dần (IBN)\"; }"
      "        : button { key = \"btn_NUMBLK\"; label = \"Đánh Số Smart (NUMBLK)\"; }"
      "        : button { key = \"btn_CLRATT\"; label = \"Xóa Trắng ATT (CLRATT)\"; }"
      "        : button { key = \"btn_CPYATT\"; label = \"Copy ATT (CPYATT)\"; }"
      "        : button { key = \"btn_MOVATT\"; label = \"Di Chuyển ATT (MOVATT)\"; }"
      "        : button { key = \"btn_ROTATT\"; label = \"Xoay ATT (ROTATT)\"; }"
      "      }"
      "      : boxed_column { label = \"Thống Kê - Đếm\";"
      "        : button { key = \"btn_CBS\";   label = \"Đếm Số Lượng Block (CBS)\"; }"
      "        : button { key = \"btn_TKATT\"; label = \"Thống Kê ATT Ra Bảng (TKATT)\"; }"
      "        : button { key = \"btn_TKT\";   label = \"Thống Kê Text (TKT)\"; }"
      "        : button { key = \"btn_TKE\";   label = \"Xuất Text -> Excel (TKE)\"; }"
      "      }"
      "    }"
      "  }"
      "  spacer;"
      "  : row {"
      "    alignment = centered;"
      "    : button { key = \"cancel\"; label = \"Thoát Khỏi Bảng (Exit)\"; is_cancel = true; width = 20; fixed_width = true; }"
      "  }"
      "}"
    )
  )
  
  (foreach line dcl_lst (write-line line f))
  (close f)

  ;; 2. VÒNG LẶP GỌI BẢNG VÀ ĐIỀU HƯỚNG LỆNH
  (setq dcl_id (load_dialog dcl_file))
  (setq loop T)
  
  (while loop
    (if (not (new_dialog "MasterBlock_dlg" dcl_id))
      (progn (princ "\n[Lỗi] Không thể tải giao diện DCL!") (setq loop nil))
      (progn
        (action_tile "btn_SBF" "(done_dialog 1)")
        (action_tile "btn_BRN" "(done_dialog 2)")
        (action_tile "btn_BX"  "(done_dialog 3)")
        (action_tile "btn_CBP" "(done_dialog 4)")
        (action_tile "btn_CPN" "(done_dialog 5)")
        (action_tile "btn_R90" "(done_dialog 6)")
        (action_tile "btn_R-90" "(done_dialog 7)")
        (action_tile "btn_MX"  "(done_dialog 8)")
        (action_tile "btn_MY"  "(done_dialog 9)")
        (action_tile "btn_RBS" "(done_dialog 10)")
        (action_tile "btn_RBKR" "(done_dialog 11)")
        (action_tile "btn_RBKS" "(done_dialog 12)")
        (action_tile "btn_SCB" "(done_dialog 13)")
        (action_tile "btn_NUMBLK" "(done_dialog 14)")
        (action_tile "btn_CLRATT" "(done_dialog 15)")
        (action_tile "btn_CPYATT" "(done_dialog 16)")
        (action_tile "btn_MOVATT" "(done_dialog 17)")
        (action_tile "btn_ROTATT" "(done_dialog 18)")
        (action_tile "btn_CBS" "(done_dialog 19)")
        (action_tile "btn_TKATT" "(done_dialog 20)")
        (action_tile "btn_TKT" "(done_dialog 21)")
        (action_tile "btn_TKE" "(done_dialog 22)")
        
        ;; Gán mã lệnh cho 2 nút bấm mới thêm vào
        (action_tile "btn_QAB" "(done_dialog 23)")
        (action_tile "btn_E2C" "(done_dialog 24)")
        
        ;; Lệnh IBN mới
        (action_tile "btn_IBN" "(done_dialog 25)")
        
        (action_tile "cancel" "(done_dialog 0)") 
        
        (setq action_code (start_dialog))
        
        ;; 3. XỬ LÝ CHỨC NĂNG
        (cond
          ((= action_code 0) (setq loop nil)) 
          ((= action_code 1) (vl-catch-all-apply 'c:SBF))
          ((= action_code 2) (vl-catch-all-apply 'c:BRN))
          ((= action_code 3) (vl-catch-all-apply 'c:BX))
          ((= action_code 4) (vl-catch-all-apply 'c:CBP))
          ((= action_code 5) (vl-catch-all-apply 'c:CPN))
          ((= action_code 6) (vl-catch-all-apply 'c:R90))
          ((= action_code 7) (vl-catch-all-apply 'c:R-90))
          ((= action_code 8) (vl-catch-all-apply 'c:MX))
          ((= action_code 9) (vl-catch-all-apply 'c:MY))
          ((= action_code 10) (vl-catch-all-apply 'c:RBS))
          ((= action_code 11) (vl-catch-all-apply 'c:RBKR))
          ((= action_code 12) (vl-catch-all-apply 'c:RBKS))
          ((= action_code 13) (vl-catch-all-apply 'c:SCB))
          ((= action_code 14) (vl-catch-all-apply 'c:NUMBLK))
          ((= action_code 15) (vl-catch-all-apply 'c:CLRATT))
          ((= action_code 16) (vl-catch-all-apply 'c:CPYATT))
          ((= action_code 17) (vl-catch-all-apply 'c:MOVATT))
          ((= action_code 18) (vl-catch-all-apply 'c:ROTATT))
          ((= action_code 19) (vl-catch-all-apply 'c:CBS))
          ((= action_code 20) (vl-catch-all-apply 'c:TKATT))
          ((= action_code 21) (vl-catch-all-apply 'c:TKT))
          ((= action_code 22) (vl-catch-all-apply 'c:TKE))
          
          ;; Gọi thực thi 2 lệnh vừa thêm vào
          ((= action_code 23) (vl-catch-all-apply 'c:QAB))
          ((= action_code 24) (vl-catch-all-apply 'c:E2C))

          ;; Thực thi lệnh IBN
          ((= action_code 25) (vl-catch-all-apply 'c:IBN))
        )
        
        ;; Ép AutoCAD làm mới lại màn hình để bạn thấy ngay thay đổi trước khi bảng mở lại
        (if (and action_code (/= action_code 0))
          (vla-Regen acad_doc 0) ; 0 = acActiveViewport
        )
      )
    )
  )
  
  (unload_dialog dcl_id)
  (if (findfile dcl_file) (vl-file-delete dcl_file))
  (princ "\nĐã đóng MasterBlock Tools.")
  (princ)
)

(princ "\n>> Đã load siêu công cụ Block. Gõ lệnh MasterBlock để mở giao diện <<")
(princ)
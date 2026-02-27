(defun c:TL (/ ss i total ename len curve-obj)
  ;; Khoi tao moi truong Visual Lisp
  (vl-load-com)
  
  (princ "\nChon cac doi tuong can tinh chieu dai (Line, Pline, Arc, Circle...): ")
  
  ;; Loc cac doi tuong hop le de tranh loi
  (setq ss (ssget '((0 . "LINE,ARC,CIRCLE,ELLIPSE,SPLINE,*POLYLINE"))))
  
  (if ss
    (progn
      (setq total 0.0)
      (setq i 0)
      
      ;; Duyet qua tung doi tuong trong tap chon
      (repeat (sslength ss)
        (setq ename (ssname ss i))
        
        ;; Tinh chieu dai su dung ham vlax-curve (chinh xac nhat)
        ;; Lay khoang cach tai tham so cuoi cung cua duong cong
        (setq len (vlax-curve-getDistAtParam ename (vlax-curve-getEndParam ename)))
        
        (setq total (+ total len))
        (setq i (1+ i))
      )
      
      ;; Hien thi ket qua
      (princ (strcat "\n------------------------------------------"))
      (princ (strcat "\nTong so doi tuong da chon: " (itoa (sslength ss))))
      (princ (strcat "\nTONG CHIEU DAI = " (rtos total 2 2) " m (hoac don vi ban ve)"))
      (princ (strcat "\n------------------------------------------"))
      
      ;; Hien thi hop thoai thong bao cho de nhin
      (alert (strcat "Tong so doi tuong: " (itoa (sslength ss)) 
                     "\n\nTONG CHIEU DAI: " (rtos total 2 2)))
    )
    (princ "\nKhong co doi tuong hop le nao duoc chon.")
  )
  (princ)
)
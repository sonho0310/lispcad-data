;;; Lisp cat doi tuong tao thanh khoang ho co dinh
;;; Lenh: BG

(defun c:BG (/ sel ent pt dist pt1 pt2 gap_dist)
  (vl-load-com)
  
  ;; --- KHOANG CACH MAC DINH ---
  ;; Bro hoac ai do muon doi khoang ho, chi can sua so 100.0 o dong duoi nay
  (setq gap_dist 100.0) 
  ;; -----------------------------
  
  (prompt (strcat "\nLisp cat khoang ho co dinh la " (rtos gap_dist 2 2) ". Nhan ESC hoac Space de thoat."))
  
  ;; Vong lap while cho phep click cat lien tuc
  (while (setq sel (entsel "\nClick vao doi tuong de cat (hoac Enter/ESC de thoat): "))
    (progn
      (setq ent (car sel) pt (cadr sel))
      
      ;; Tinh toan 2 diem nam ve 2 phia cua diem click chuot
      (setq pt (vlax-curve-getclosestpointto ent pt))
      (setq dist (vlax-curve-getdistatpoint ent pt))
      
      (setq pt1 (vlax-curve-getpointatdist ent (- dist (/ gap_dist 2.0))))
      (setq pt2 (vlax-curve-getpointatdist ent (+ dist (/ gap_dist 2.0))))
      
      ;; Neu khoang cat to hon doan thang hien co, no se tu dong cat cut den hai dau
      (if (not pt1) (setq pt1 (vlax-curve-getStartPoint ent)))
      (if (not pt2) (setq pt2 (vlax-curve-getEndPoint ent)))
      
      ;; Thuc hien lenh cat
      (command "_.BREAK" sel "_F" "_non" pt1 "_non" pt2)
    )
  )
  (princ "\nDa thoat lenh BG.")
  (princ)
)
(princ "\nDa load Lisp! Go lenh BG de cat lien tuc.")
(princ)
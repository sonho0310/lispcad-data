(vl-load-com)

;; Hàm lấy danh sách tất cả Layer trong bản vẽ (Sắp xếp A-Z)
(defun get-all-layers (/ tbl lst)
  (while (setq tbl (tblnext "LAYER" (not tbl)))
    (setq lst (append lst (list (cdr (assoc 2 tbl)))))
  )
  (vl-sort lst '<)
)

;; Hàm tự động tạo file DCL giao diện 3 CỘT
(defun create-temp-dcl (/ fn f)
  (setq fn (vl-filename-mktemp "mep_dlg.dcl"))
  (setq f (open fn "w"))
  (write-line "mep_dlg : dialog { label = \"MEP Tag - Measure\";" f)
  (write-line " : row { " f)
  
  ;; Cột DUCT 
  (write-line "  : boxed_column { label = \"ỐNG GIÓ (DUCT)\"; width = 28; fixed_width = true;" f)
  (write-line "   : column { fixed_height = true; alignment = top;" f)
  (write-line "    : popup_list { key=\"d_lay\"; label=\"Layer Text:\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"d_pre\"; label=\"Tiền tố:\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"d_w\"; label=\"Rộng (W):\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"d_h\"; label=\"Cao (H):\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"d_th\"; label=\"Cao Text:\"; edit_width=14; }" f)
  (write-line "   }" f)
  (write-line "   spacer;" f)
  (write-line "   : button { key=\"btn_duct\"; label=\"=> GHI ỐNG GIÓ\"; is_default=true; }" f)
  (write-line "   : button { key=\"btn_m_duct\"; label=\"=> ĐO - GHI (KTO)\"; }" f)
  (write-line "  }" f)
  
  ;; Cột PIPE 
  (write-line "  : boxed_column { label = \"ỐNG NƯỚC (PIPE)\"; width = 28; fixed_width = true;" f)
  (write-line "   : column { fixed_height = true; alignment = top;" f)
  (write-line "    : popup_list { key=\"p_lay\"; label=\"Layer Text:\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"p_pre\"; label=\"Tiền tố:\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"p_dn\"; label=\"Đường kính:\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"p_th\"; label=\"Cao Text:\"; edit_width=14; }" f)
  (write-line "   }" f)
  (write-line "   spacer;" f)
  (write-line "   : button { key=\"btn_pipe\"; label=\"=> GHI ỐNG NƯỚC\"; }" f)
  (write-line "   : button { key=\"btn_m_pipe\"; label=\"=> ĐO - GHI (KTC)\"; }" f)
  (write-line "  }" f)

  ;; Cột TRAY (Máng Cáp)
  (write-line "  : boxed_column { label = \"MÁNG CÁP (TRAY)\"; width = 28; fixed_width = true;" f)
  (write-line "   : column { fixed_height = true; alignment = top;" f)
  (write-line "    : popup_list { key=\"t_lay\"; label=\"Layer Text:\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"t_pre\"; label=\"Tiền tố:\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"t_w\"; label=\"Rộng (W):\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"t_h\"; label=\"Cao (H):\"; edit_width=14; }" f)
  (write-line "    : edit_box { key=\"t_th\"; label=\"Cao Text:\"; edit_width=14; }" f)
  (write-line "   }" f)
  (write-line "   spacer;" f)
  (write-line "   : button { key=\"btn_tray\"; label=\"=> GHI MÁNG CÁP\"; }" f)
  (write-line "   spacer;" f) 
  (write-line "  }" f)
  
  (write-line " } " f)
  (write-line " errtile;" f)
  (write-line " : button { key=\"cancel\"; label=\"Thoát hẳn (ESC)\"; is_cancel=true; }" f)
  (write-line "}" f)
  (close f)
  fn
)

;; =========================================================================
;; HÀM RẢI TEXT: Dùng Getpoint, Hỗ trợ OSNAP, tự xoay theo nét vẽ
;; =========================================================================
(defun draw-text-loop (text_str layer_name text_h / pt ang obj ss half_box param deriv run_loop text_pt)
  (princ (strcat "\nĐang ghi: " text_str " | Click điểm chèn Text (Nhấn ESC hoặc Space/Enter để quay lại bảng)"))
  (setq run_loop T)
  (while run_loop
    (setq pt (vl-catch-all-apply 'getpoint (list "\nClick điểm chèn Text (Bật F3 để bắt điểm - ESC/Space quay lại bảng): ")))
    
    (cond
      ((vl-catch-all-error-p pt) (setq run_loop nil))
      ((null pt) (setq run_loop nil))
      ((listp pt)
        (setq ang 0.0) 
        
        ;; Tạo hộp chọn ẩn siêu nhỏ quét quanh điểm click để lấy nét vẽ
        (setq half_box (/ (getvar "VIEWSIZE") 100.0))
        (setq ss (ssget "C" 
                   (list (- (car pt) half_box) (- (cadr pt) half_box) 0.0) 
                   (list (+ (car pt) half_box) (+ (cadr pt) half_box) 0.0)
                 ))
        
        ;; Tính góc xoay
        (if ss
          (progn
            (setq obj (ssname ss 0))
            (if (not (vl-catch-all-error-p (vl-catch-all-apply 'vlax-curve-getendparam (list obj))))
              (progn
                (setq param (vlax-curve-getparamatpoint obj (vlax-curve-getclosestpointto obj pt)))
                (if param
                  (progn
                    (setq deriv (vlax-curve-getfirstderiv obj param))
                    (setq ang (angle '(0 0 0) deriv))
                    (if (and (> ang (/ pi 2)) (<= ang (+ pi (/ pi 2)))) (setq ang (- ang pi)))
                  )
                )
              )
            )
          )
        )
        
        ;; Dịch chữ lên trên điểm click
        (setq text_pt (polar pt (+ ang (/ pi 2)) (* text_h 0.3)))
        
        ;; Bung Text
        (entmake 
          (list '(0 . "TEXT") (cons 10 text_pt) (cons 11 text_pt) (cons 40 text_h) 
                (cons 1 text_str) (cons 50 ang) '(72 . 1) '(73 . 1) 
                (cons 8 layer_name)
          )
        )
      )
    )
  )
)

;; =========================================================================
;; LỆNH CHÍNH (MEPTag)
;; =========================================================================
(defun c:MEPTag ( / *error* dcl_file dcl_id layer_list res cur_d_lay cur_p_lay cur_t_lay d_text_str p_text_str t_text_str keep_running p1 p2 w h_input midpt ang text_str d th pre run_loop)
  
  ;; Hàm khử lỗi Function Cancelled
  (defun *error* (msg)
    (if (and msg (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*,*EXIT*")))
      (princ (strcat "\nLỗi: " msg))
    )
    (princ)
  )

  ;; 1. Nạp giá trị mặc định cho Duct
  (if (not *sl_d_pre*) (setq *sl_d_pre* "SAD-"))
  (if (not *sl_d_w*) (setq *sl_d_w* "600"))
  (if (not *sl_d_h*) (setq *sl_d_h* "400"))
  (if (not *sl_d_th*) (setq *sl_d_th* (rtos (getvar "TEXTSIZE") 2 0)))
  
  ;; 2. Nạp giá trị mặc định cho Pipe
  (if (not *sl_p_pre*) (setq *sl_p_pre* "CHWS-DN"))
  (if (not *sl_p_dn*) (setq *sl_p_dn* "100"))
  (if (not *sl_p_th*) (setq *sl_p_th* (rtos (getvar "TEXTSIZE") 2 0)))

  ;; 3. Nạp giá trị mặc định cho Tray
  (if (not *sl_t_pre*) (setq *sl_t_pre* "CT-"))
  (if (not *sl_t_w*) (setq *sl_t_w* "300"))
  (if (not *sl_t_h*) (setq *sl_t_h* "100"))
  (if (not *sl_t_th*) (setq *sl_t_th* (rtos (getvar "TEXTSIZE") 2 0)))

  (setq layer_list (get-all-layers))

  (setq dcl_file (create-temp-dcl))
  (setq dcl_id (load_dialog dcl_file))
  
  (setq keep_running T)
  
  (while keep_running
    (if (not (new_dialog "mep_dlg" dcl_id)) (exit))

    (start_list "d_lay") (mapcar 'add_list layer_list) (end_list)
    (start_list "p_lay") (mapcar 'add_list layer_list) (end_list)
    (start_list "t_lay") (mapcar 'add_list layer_list) (end_list)
    
    (if *sl_d_lay_idx* (set_tile "d_lay" *sl_d_lay_idx*) (set_tile "d_lay" "0"))
    (if *sl_p_lay_idx* (set_tile "p_lay" *sl_p_lay_idx*) (set_tile "p_lay" "0"))
    (if *sl_t_lay_idx* (set_tile "t_lay" *sl_t_lay_idx*) (set_tile "t_lay" "0"))

    (set_tile "d_pre" *sl_d_pre*)
    (set_tile "d_w" *sl_d_w*)
    (set_tile "d_h" *sl_d_h*)
    (set_tile "d_th" *sl_d_th*)

    (set_tile "p_pre" *sl_p_pre*)
    (set_tile "p_dn" *sl_p_dn*)
    (set_tile "p_th" *sl_p_th*)

    (set_tile "t_pre" *sl_t_pre*)
    (set_tile "t_w" *sl_t_w*)
    (set_tile "t_h" *sl_t_h*)
    (set_tile "t_th" *sl_t_th*)

    (action_tile "btn_duct" 
      "(setq *sl_d_lay_idx* (get_tile \"d_lay\") *sl_d_pre* (get_tile \"d_pre\") *sl_d_w* (get_tile \"d_w\") *sl_d_h* (get_tile \"d_h\") *sl_d_th* (get_tile \"d_th\")) (done_dialog 1)"
    )
    
    (action_tile "btn_pipe" 
      "(setq *sl_p_lay_idx* (get_tile \"p_lay\") *sl_p_pre* (get_tile \"p_pre\") *sl_p_dn* (get_tile \"p_dn\") *sl_p_th* (get_tile \"p_th\")) (done_dialog 2)"
    )

    (action_tile "btn_tray" 
      "(setq *sl_t_lay_idx* (get_tile \"t_lay\") *sl_t_pre* (get_tile \"t_pre\") *sl_t_w* (get_tile \"t_w\") *sl_t_h* (get_tile \"t_h\") *sl_t_th* (get_tile \"t_th\")) (done_dialog 3)"
    )

    (action_tile "btn_m_duct" 
      "(setq *sl_d_lay_idx* (get_tile \"d_lay\") *sl_d_pre* (get_tile \"d_pre\") *sl_d_th* (get_tile \"d_th\") *sl_d_h* (get_tile \"d_h\")) (done_dialog 4)"
    )
    
    (action_tile "btn_m_pipe" 
      "(setq *sl_p_lay_idx* (get_tile \"p_lay\") *sl_p_pre* (get_tile \"p_pre\") *sl_p_th* (get_tile \"p_th\")) (done_dialog 5)"
    )

    (action_tile "cancel" "(done_dialog 0)")

    (setq res (start_dialog))

    (cond 
      ;; --- RẢI TEXT ỐNG GIÓ ---
      ((= res 1)
        (setq cur_d_lay (nth (atoi *sl_d_lay_idx*) layer_list))
        (setq d_text_str (strcat *sl_d_pre* *sl_d_w* "x" *sl_d_h*))
        (draw-text-loop d_text_str cur_d_lay (atof *sl_d_th*))
      )
      ;; --- RẢI TEXT ỐNG NƯỚC ---
      ((= res 2)
        (setq cur_p_lay (nth (atoi *sl_p_lay_idx*) layer_list))
        (setq p_text_str (strcat *sl_p_pre* *sl_p_dn*))
        (draw-text-loop p_text_str cur_p_lay (atof *sl_p_th*))
      )
      ;; --- RẢI TEXT MÁNG CÁP ---
      ((= res 3)
        (setq cur_t_lay (nth (atoi *sl_t_lay_idx*) layer_list))
        (setq t_text_str (strcat *sl_t_pre* *sl_t_w* "x" *sl_t_h*))
        (draw-text-loop t_text_str cur_t_lay (atof *sl_t_th*))
      )
      ;; --- ĐO - GHI ỐNG GIÓ (Bẫy lỗi hoàn chỉnh) ---
      ((= res 4)
        (setq cur_d_lay (nth (atoi *sl_d_lay_idx*) layer_list))
        (setq pre *sl_d_pre*)
        (setq th (atof *sl_d_th*))
        (if (not *global_h*) (setq *global_h* (atoi *sl_d_h*)))
        
        (princ "\n[KTO] - Bắt đầu đo ỐNG GIÓ (Nhấn ESC hoặc Space/Enter để quay lại bảng)")
        (setq run_loop T)
        (while run_loop
          (setq p1 (vl-catch-all-apply 'getpoint (list "\nPick điểm mép 1 (Space/Enter/ESC để thoát): ")))
          (cond
            ((vl-catch-all-error-p p1) (setq run_loop nil)) ; Nếu bấm ESC
            ((null p1) (setq run_loop nil))                 ; Nếu bấm Space/Enter
            ((listp p1)
              (setq p2 (vl-catch-all-apply 'getpoint (list p1 "\nPick điểm mép 2: ")))
              (cond
                ((vl-catch-all-error-p p2) (setq run_loop nil))
                ((null p2) (setq run_loop nil))
                ((listp p2)
                  (setq w (fix (+ 0.5 (distance p1 p2))))
                  (setq w (* 10 (fix (/ (+ w 5) 10)))) 

                  (setq h_input (vl-catch-all-apply 'getint (list (strcat "\nNhập chiều cao ống H <" (itoa *global_h*) ">: "))))
                  (cond
                    ((vl-catch-all-error-p h_input) (setq run_loop nil))
                    (t
                      (if (and h_input (numberp h_input)) (setq *global_h* h_input))
                      (setq midpt (polar p1 (angle p1 p2) (/ (distance p1 p2) 2.0)))
                      (setq ang (+ (angle p1 p2) (/ pi 2))) 
                      (if (and (> ang (/ pi 2)) (<= ang (+ pi (/ pi 2)))) (setq ang (- ang pi)))

                      (setq text_str (strcat pre (itoa w) "x" (itoa *global_h*)))

                      (entmake (list '(0 . "TEXT") (cons 10 midpt) (cons 11 midpt) (cons 40 th) (cons 1 text_str) (cons 50 ang) '(72 . 1) '(73 . 2) (cons 8 cur_d_lay)))
                      (princ (strcat "\n=> Đã ghi: " text_str))
                    )
                  )
                )
              )
            )
          )
        )
      )
      ;; --- ĐO - GHI ỐNG NƯỚC (Bẫy lỗi hoàn chỉnh) ---
      ((= res 5)
        (setq cur_p_lay (nth (atoi *sl_p_lay_idx*) layer_list))
        (setq pre *sl_p_pre*)
        (setq th (atof *sl_p_th*))
        
        (princ "\n[KTC] - Bắt đầu đo ỐNG CHILLER (Nhấn ESC hoặc Space/Enter để quay lại bảng)")
        (setq run_loop T)
        (while run_loop
          (setq p1 (vl-catch-all-apply 'getpoint (list "\nPick điểm mép 1 (Space/Enter/ESC để thoát): ")))
          (cond
            ((vl-catch-all-error-p p1) (setq run_loop nil))
            ((null p1) (setq run_loop nil))
            ((listp p1)
              (setq p2 (vl-catch-all-apply 'getpoint (list p1 "\nPick điểm mép 2: ")))
              (cond
                ((vl-catch-all-error-p p2) (setq run_loop nil))
                ((null p2) (setq run_loop nil))
                ((listp p2)
                  (setq d (fix (+ 0.5 (distance p1 p2))))
                  (setq d (* 5 (fix (/ (+ d 2.5) 5)))) 

                  (setq midpt (polar p1 (angle p1 p2) (/ (distance p1 p2) 2.0)))
                  (setq ang (+ (angle p1 p2) (/ pi 2))) 
                  (if (and (> ang (/ pi 2)) (<= ang (+ pi (/ pi 2)))) (setq ang (- ang pi)))

                  (setq text_str (strcat pre (itoa d)))

                  (entmake (list '(0 . "TEXT") (cons 10 midpt) (cons 11 midpt) (cons 40 th) (cons 1 text_str) (cons 50 ang) '(72 . 1) '(73 . 2) (cons 8 cur_p_lay)))
                  (princ (strcat "\n=> Đã ghi: " text_str))
                )
              )
            )
          )
        )
      )
      ;; --- THOÁT HẲN ---
      (t 
        (setq keep_running nil)
      )
    )
  )

  (unload_dialog dcl_id)
  (vl-file-delete dcl_file)
  (princ "\nĐã thoát MEP Tag.")
  (princ)
)
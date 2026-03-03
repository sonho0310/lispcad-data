;;; Command: MasterMep

(vl-load-com)

;;; ==========================================================================
;;; PHAN 1: BIEN TOAN CUC & KHOI TAO
;;; ==========================================================================

;;; --- HVAC SINGLE LINE GLOBALS ---
(if (not *AR:LastMode*) (setq *AR:LastMode* "Step-Z-X")) 
(if (not *AR:Rad*)      (setq *AR:Rad* 50.0))
(if (not *AR:Gap*)      (setq *AR:Gap* 0.0))
(if (not *AR:LayerIdx*) (setq *AR:LayerIdx* 0)) 
(setq *AR:LayerName* "0") 

;;; --- PLUMBING GLOBALS ---
(if (not *DL:Mode*)     (setq *DL:Mode* "Vuong-45")) 
(if (not *DL:Len45*)    (setq *DL:Len45* 350.0))
(if (not *DL:LayerIdx*) (setq *DL:LayerIdx* 0)) 
(setq *DL:LayerName* "0")

;;; --- HVAC DOUBLE LINE (DT-1) GLOBALS ---
(if (null *mep_w*)   (setq *mep_w* "400"))
(if (null *mep_k*)   (setq *mep_k* "0.5"))
(if (null *mep_ang*) (setq *mep_ang* "ang_90"))

;;; ==========================================================================
;;; PHAN 2: HAM HO TRO CHUNG & XU LY DCL
;;; ==========================================================================

(defun AR:Get-Layers (/ lyr l-list)
  (setq l-list '())
  (while (setq lyr (tblnext "LAYER" (null l-list)))
    (setq l-list (cons (cdr (assoc 2 lyr)) l-list))
  )
  (vl-sort l-list '<) 
)

(defun MasterMep:Make-DCL (filename / fn)
  (setq fn (open filename "w"))
  (write-line "MasterMep_UI : dialog { label = \"MASTER MEP TOOLS\";" fn)
  
  (write-line "  : row {" fn)
  
  ;; >>> COT 1: HVAC SINGLE LINE
  (write-line "    : boxed_column {" fn)
  (write-line "      label = \"1. HVAC SINGLE\"; width = 28;" fn)
  (write-line "      : radio_column { key = \"ar_mode_group\";" fn)
  (write-line "        : radio_button { label = \"Step-Z-X (Ngang-Dung-Ngang)\"; key = \"Step-Z-X\"; }" fn)
  (write-line "        : radio_button { label = \"Step-Z-Y (Dung-Ngang-Dung)\"; key = \"Step-Z-Y\"; }" fn)
  (write-line "        : radio_button { label = \"L-X (Doc truoc)\"; key = \"L-X\"; }" fn)
  (write-line "        : radio_button { label = \"L-Y (Doc truoc)\"; key = \"L-Y\"; }" fn)
  (write-line "        : radio_button { label = \"Direct (Thang)\"; key = \"Direct\"; }" fn)
  (write-line "      }" fn)
  (write-line "      spacer_1;" fn)
  (write-line "      : edit_box { label = \"Ban kinh R:\"; key = \"e_rad\"; edit_width = 6; }" fn)
  (write-line "      : edit_box { label = \"Lech truc:\"; key = \"e_gap\"; edit_width = 6; }" fn)
  (write-line "      : popup_list { label = \"Layer Chung:\"; key = \"d_layer\"; edit_width = 15; }" fn)
  (write-line "      spacer_1;" fn)
  (write-line "      : button { label = \"VE SINGLE\"; key = \"btn_hvac\"; height = 2; fixed_width = true; alignment = centered; }" fn)
  (write-line "    }" fn)

  ;; >>> COT 2: HVAC DOUBLE LINE (DT-1)
  (write-line "    : boxed_column {" fn)
  (write-line "      label = \"2. HVAC DOUBLE\"; width = 28;" fn)
  (write-line "      : edit_box { label = \"Rong (W):\"; key = \"width_w\"; edit_width = 6; }" fn)
  (write-line "      : edit_box { label = \"He so (K):\"; key = \"k_factor\"; edit_width = 6; }" fn)
  (write-line "      spacer;" fn)
  (write-line "      : button { label = \"Auto Routing\"; key = \"btn_dt_auto\"; }" fn)
  (write-line "      spacer;" fn)
  (write-line "      : radio_column { label = \"Goc Co:\"; key = \"dt_ang_group\";" fn)
  (write-line "          : radio_button { label = \"90 Do\"; key = \"ang_90\"; }" fn)
  (write-line "          : radio_button { label = \"60 Do\"; key = \"ang_60\"; }" fn)
  (write-line "          : radio_button { label = \"45 Do\"; key = \"ang_45\"; }" fn)
  (write-line "          : radio_button { label = \"30 Do\"; key = \"ang_30\"; }" fn)
  (write-line "      }" fn)
  (write-line "      : row {" fn)
  (write-line "          : button { label = \"Ve Ong\"; key = \"btn_dt_ong\"; }" fn)
  (write-line "          : button { label = \"Ve Co\"; key = \"btn_dt_co\"; }" fn)
  (write-line "      }" fn)
  ;; UPDATE: Them nut Ve Ong Mem
  (write-line "      : button { label = \"Ve Ong Mem (Flex)\"; key = \"btn_dt_flex\"; }" fn)
  (write-line "      spacer;" fn)
  (write-line "      : button { label = \"Dao Got Giay\"; key = \"btn_dt_flip\"; }" fn)
  (write-line "      : text { label = \"*Go 'W' khi ve de tao Con Thu\"; }" fn)
  (write-line "    }" fn)
  
  ;; >>> COT 3: PLUMBING
  (write-line "    : boxed_column {" fn)
  (write-line "      label = \"3. PLUMBING\"; width = 28;" fn)
  (write-line "      : radio_column { key = \"dl_mode_group\";" fn)
  (write-line "        : radio_button { key = \"Vuong-45\"; label = \"Vuong + 45\"; }" fn)
  (write-line "        : radio_button { key = \"Thang-45\"; label = \"Xien 45\"; }" fn)
  (write-line "        : radio_button { key = \"Ban-Tia\";  label = \"Ban Tia\"; }" fn)
  (write-line "      }" fn)
  (write-line "      spacer_1;" fn)
  (write-line "      : edit_box { label = \"Dai 45:\"; key = \"txt_len\"; edit_width = 6; }" fn)
  (write-line "      : popup_list { label = \"Layer:\"; key = \"dl_layer\"; edit_width = 15; }" fn)
  (write-line "      spacer_1;" fn)
  (write-line "      : button { label = \"VE PLUMBING\"; key = \"btn_plumb\"; height = 2; fixed_width = true; alignment = centered; }" fn)
  (write-line "    }" fn)
  
  (write-line "  }" fn) 
  (write-line "  spacer_1;" fn)
  (write-line "  : button { label = \"THOAT CHUONG TRINH\"; key = \"cancel\"; is_cancel = true; height = 2; fixed_width = true; width = 30; alignment = centered; }" fn)
  (write-line "}" fn)
  (close fn)
)

;;; ==========================================================================
;;; PHAN 3: LOGIC HVAC SINGLE LINE (CORE)
;;; ==========================================================================

(defun AR:Draw-Poly (pts width / arr mspace pline ename cmdecho_old)
  (setq arr (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length pts)))))
  (vlax-safearray-fill arr pts)
  (setq mspace (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))))
  (setq pline (vla-AddLightWeightPolyline mspace arr))
  
  (vla-put-Layer pline *AR:LayerName*)
  (vla-put-Color pline 256) 
  
  (if (> width 0) (vla-put-ConstantWidth pline width))
  
  (if (and (> *AR:Rad* 0) (> (length pts) 4)) 
    (progn
      (setq ename (vlax-vla-object->ename pline))
      (setq cmdecho_old (getvar "CMDECHO")) (setvar "CMDECHO" 0)
      (command "_.FILLET" "_R" *AR:Rad*) (command "_.FILLET" "_P" ename)
      (setvar "CMDECHO" cmdecho_old)
    )
  )
  pline
)

(defun AR:Draw-Step-Z-X (p1 p2 width gap / mid-x pts)
  (setq mid-x (/ (+ (car p1) (car p2)) 2.0))
  (setq mid-x (+ mid-x gap))
  (setq pts (list (car p1) (cadr p1) mid-x (cadr p1) mid-x (cadr p2) (car p2) (cadr p2)))
  (AR:Draw-Poly pts width)
)

(defun AR:Draw-Step-Z-Y (p1 p2 width gap / mid-y pts)
  (setq mid-y (/ (+ (cadr p1) (cadr p2)) 2.0))
  (setq mid-y (+ mid-y gap))
  (setq pts (list (car p1) (cadr p1) (car p1) mid-y (car p2) mid-y (car p2) (cadr p2)))
  (AR:Draw-Poly pts width)
)

(defun AR:Draw-L-X (p1 p2 width / mid pts)
  (setq mid (list (car p2) (cadr p1) 0.0))
  (setq pts (list (car p1) (cadr p1) (car mid) (cadr mid) (car p2) (cadr p2)))
  (AR:Draw-Poly pts width)
)

(defun AR:Draw-L-Y (p1 p2 width / mid pts)
  (setq mid (list (car p1) (cadr p2) 0.0))
  (setq pts (list (car p1) (cadr p1) (car mid) (cadr mid) (car p2) (cadr p2)))
  (AR:Draw-Poly pts width)
)

(defun AR:Draw-Direct (p1 p2 width / pts)
  (setq pts (list (car p1) (cadr p1) (car p2) (cadr p2)))
  (AR:Draw-Poly pts width)
)

(defun AR:Execute-Draw (/ p1 p2 undo-mark)
  (setq undo-mark (vla-get-ActiveDocument (vlax-get-acad-object)))
  (vla-StartUndoMark undo-mark)
  (princ (strcat "\n[HVAC SINGLE] Mode: " *AR:LastMode* " | Layer: " *AR:LayerName*))
  (while (setq p1 (getpoint "\n[HVAC 1-LINE] Pick Diem 1 (Nguon): "))
    (if (setq p2 (getpoint p1 "\n[HVAC 1-LINE] Pick Diem 2 (Dich): "))
      (cond
        ((= *AR:LastMode* "Direct")   (AR:Draw-Direct p1 p2 0))
        ((= *AR:LastMode* "Step-Z-X") (AR:Draw-Step-Z-X p1 p2 0 *AR:Gap*))
        ((= *AR:LastMode* "Step-Z-Y") (AR:Draw-Step-Z-Y p1 p2 0 *AR:Gap*))
        ((= *AR:LastMode* "L-X")      (AR:Draw-L-X p1 p2 0))
        ((= *AR:LastMode* "L-Y")      (AR:Draw-L-Y p1 p2 0))
      )
      (princ "\n(Chua pick diem thu 2...)")
    )
  )
  (vla-EndUndoMark undo-mark)
)

;;; ==========================================================================
;;; PHAN 4: LOGIC HVAC DOUBLE LINE (DT-1 CORE & REDUCER & FLEX)
;;; ==========================================================================

;; --- MATH & HELPERS ---
(defun tan_mep (x) (if (not (equal (cos x) 0.0 1e-8)) (/ (sin x) (cos x)) 0.0))

(defun ang-mod-pi (pA pB / a)
  (setq a (angle pA pB))
  (while (>= a pi) (setq a (- a pi)))
  (while (< a 0.0) (setq a (+ a pi)))
  a
)

;; --- HELPER RIENG CHO FLEX TUBE (TU CODE NM) ---
(defun get-curve-pt (ent d len / pt pr)
  (cond
    ((<= d 1e-4) (vlax-curve-getStartPoint ent))
    ((>= d (- len 1e-4)) (vlax-curve-getEndPoint ent))
    ((setq pt (vlax-curve-getPointAtDist ent d)) pt) 
    (t 
      (setq pr (vl-catch-all-apply 'vlax-curve-getParamAtDist (list ent d)))
      (if (not (vl-catch-all-error-p pr))
        (vlax-curve-getPointAtParam ent pr)
        (if (< d (/ len 2.0)) (vlax-curve-getStartPoint ent) (vlax-curve-getEndPoint ent))
      )
    )
  )
)

(defun update-polar-angles (base_rad / base_deg polar_str abs_deg)
  (setq base_deg (* base_rad (/ 180.0 pi)))
  (setq polar_str "")
  (foreach offset '(0 30 45 60 90 270 300 315 330)
    (setq abs_deg (+ base_deg offset))
    (while (>= abs_deg 360.0) (setq abs_deg (- abs_deg 360.0)))
    (while (< abs_deg 0.0) (setq abs_deg (+ abs_deg 360.0)))
    (setq polar_str (strcat polar_str (if (= polar_str "") "" ";") (rtos abs_deg 2 4)))
  )
  (setvar "POLARADDANG" polar_str)
)

(defun check-touch (pt ignore_ent / p_min p_max ss i touching)
  (setq p_min (list (- (car pt) 5.0) (- (cadr pt) 5.0)))
  (setq p_max (list (+ (car pt) 5.0) (+ (cadr pt) 5.0)))
  (setq ss (ssget "c" p_min p_max '((0 . "LWPOLYLINE"))))
  (setq touching nil)
  (if ss
    (progn (setq i 0)
      (while (< i (sslength ss))
        (if (not (equal (ssname ss i) ignore_ent)) (setq touching T))
        (setq i (1+ i))
      )
    )
  )
  touching
)

(defun mep-draw-duct (pA pB width / ang p1_rect p2_rect p3_rect p4_rect)
  (setq ang (angle pA pB))
  (setq p1_rect (polar pA (+ ang (/ pi 2)) (/ width 2.0)))
  (setq p2_rect (polar pA (- ang (/ pi 2)) (/ width 2.0)))
  (setq p3_rect (polar pB (+ ang (/ pi 2)) (/ width 2.0)))
  (setq p4_rect (polar pB (- ang (/ pi 2)) (/ width 2.0)))
  (entmake (list '(0 . "LWPOLYLINE") (cons 8 *AR:LayerName*) '(100 . "AcDbEntity") '(100 . "AcDbPolyline") '(90 . 4) '(70 . 1)
          (cons 10 p1_rect) (cons 10 p3_rect) (cons 10 p4_rect) (cons 10 p2_rect)))
)

;; Hàm vẽ CÔN THU (REDUCER)
(defun mep-draw-reducer (pA pB w1 w2 / ang p1 p2 p3 p4)
  (setq ang (angle pA pB))
  (setq p1 (polar pA (+ ang (/ pi 2)) (/ w1 2.0)))
  (setq p2 (polar pA (- ang (/ pi 2)) (/ w1 2.0)))
  (setq p3 (polar pB (- ang (/ pi 2)) (/ w2 2.0)))
  (setq p4 (polar pB (+ ang (/ pi 2)) (/ w2 2.0)))
  (entmake
    (list '(0 . "LWPOLYLINE") (cons 8 *AR:LayerName*) '(100 . "AcDbEntity") '(100 . "AcDbPolyline")
          '(90 . 4) '(70 . 1)
          (cons 10 p1) (cons 10 p4) (cons 10 p3) (cons 10 p2)
    )
  )
)

(defun mep-draw-elbow (pt_corner ang_in ang_out w_num k_num / Rc pt_start pt_center turn_dir abs_turn a_to_start a_to_end Rin Rout p1_out p2_out p2_in p1_in bulge_out bulge_in T_dist)
  (setq Rc (* w_num (+ k_num 0.5)) Rin (* w_num k_num) Rout (* w_num (+ k_num 1.0)))
  (setq turn_dir (- ang_out ang_in))
  (while (> turn_dir pi) (setq turn_dir (- turn_dir (* 2 pi))))
  (while (< turn_dir (- pi)) (setq turn_dir (+ turn_dir (* 2 pi))))
  (setq abs_turn (abs turn_dir))
  (setq T_dist (* Rc (tan_mep (/ abs_turn 2.0))))
  (setq pt_start (polar pt_corner (+ ang_in pi) T_dist))
  (if (> turn_dir 0)
    (progn (setq pt_center (polar pt_start (+ ang_in (/ pi 2)) Rc) a_to_start (- ang_in (/ pi 2)) a_to_end (- ang_out (/ pi 2))))
    (progn (setq pt_center (polar pt_start (- ang_in (/ pi 2)) Rc) a_to_start (+ ang_in (/ pi 2)) a_to_end (+ ang_out (/ pi 2))))
  )
  (setq p1_out (polar pt_center a_to_start Rout) p2_out (polar pt_center a_to_end Rout) p2_in (polar pt_center a_to_end Rin) p1_in (polar pt_center a_to_start Rin))
  (setq bulge_out (tan_mep (/ turn_dir 4.0)) bulge_in (- 0.0 bulge_out))
  (entmake (list '(0 . "LWPOLYLINE") (cons 8 *AR:LayerName*) '(100 . "AcDbEntity") '(100 . "AcDbPolyline") '(90 . 4) '(70 . 1)
          (cons 10 p1_out) (cons 42 bulge_out) (cons 10 p2_out) '(42 . 0.0) (cons 10 p2_in)  (cons 42 bulge_in) (cons 10 p1_in)  '(42 . 0.0)))
)

(defun mep-draw-shoe (pA pB width / ang L_shoe p_base p1 p2 p3 p4)
  (setq ang (angle pA pB) L_shoe (* width 0.5)) 
  (if (< (distance pA pB) L_shoe) (mep-draw-duct pA pB width)
      (progn
          (setq p_base (polar pB (+ ang pi) L_shoe))
          (mep-draw-duct pA p_base width)
          (setq p1 (polar p_base (+ ang (/ pi 2)) (/ width 2.0)))
          (setq p2 (polar p_base (- ang (/ pi 2)) (/ width 2.0)))
          (setq p3 (polar pB (- ang (/ pi 2)) (/ width 2.0)))
          (setq p4 (polar pB (+ ang (/ pi 2)) (+ (/ width 2.0) L_shoe)))
          (entmake (list '(0 . "LWPOLYLINE") (cons 8 *AR:LayerName*) '(100 . "AcDbEntity") '(100 . "AcDbPolyline") '(90 . 4) '(70 . 1) (cons 10 p1) (cons 10 p4) (cons 10 p3) (cons 10 p2)))
      )
  )
)

(defun mep-draw-shoe-start (pA pB width / ang L_shoe p_base p1 p2 p3 p4)
  (setq ang (angle pA pB) L_shoe (* width 0.5)) 
  (if (< (distance pA pB) L_shoe) (mep-draw-duct pA pB width)
      (progn
          (setq p_base (polar pA ang L_shoe))
          (setq p1 (polar p_base (+ ang (/ pi 2)) (/ width 2.0)))
          (setq p2 (polar p_base (- ang (/ pi 2)) (/ width 2.0)))
          (setq p3 (polar pA (- ang (/ pi 2)) (/ width 2.0)))
          (setq p4 (polar pA (+ ang (/ pi 2)) (+ (/ width 2.0) L_shoe)))
          (entmake (list '(0 . "LWPOLYLINE") (cons 8 *AR:LayerName*) '(100 . "AcDbEntity") '(100 . "AcDbPolyline") '(90 . 4) '(70 . 1) (cons 10 p4) (cons 10 p1) (cons 10 p2) (cons 10 p3)))
          (mep-draw-duct p_base pB width)
      )
  )
)

(defun mep-flip-shoe (ent / elist pts p1 p2 p3 p4 a1 a2 a3 a4 base_edge M1 ang_base p_ax1 p_ax2 flipped)
  (setq elist (entget ent))
  (setq pts nil flipped nil)
  (foreach item elist (if (= (car item) 10) (setq pts (append pts (list (cdr item))))))
  (if (and pts (= (length pts) 4))
    (progn
      (setq p1 (nth 0 pts) p2 (nth 1 pts) p3 (nth 2 pts) p4 (nth 3 pts))
      (setq a1 (ang-mod-pi p1 p2) a2 (ang-mod-pi p2 p3) a3 (ang-mod-pi p3 p4) a4 (ang-mod-pi p4 p1))
      (setq base_edge nil)
      (if (equal a1 a3 0.01)
        (if (< (distance p1 p2) (distance p3 p4)) (setq base_edge (list p1 p2)) (setq base_edge (list p3 p4)))
        (if (equal a2 a4 0.01)
          (if (< (distance p2 p3) (distance p4 p1)) (setq base_edge (list p2 p3)) (setq base_edge (list p4 p1)))
        )
      )
      (if base_edge
        (progn
          (setq M1 (list (/ (+ (car (car base_edge)) (car (cadr base_edge))) 2.0) (/ (+ (cadr (car base_edge)) (cadr (cadr base_edge))) 2.0) ))
          (setq ang_base (angle (car base_edge) (cadr base_edge)))
          (setq p_ax1 M1 p_ax2 (polar M1 (+ ang_base (/ pi 2.0)) 10.0))
          (setvar "CMDECHO" 0)
          (command "_.MIRROR" ent "" "_non" p_ax1 "_non" p_ax2 "_Y")
          (setq flipped T)
        )
      )
    )
  )
  flipped
)

;; --- WRAPPER FUNCTIONS FOR MASTER MEP ---
(defun DT:Execute-Auto (/ w_num k_num Rc pt1 pt2 pt3 last_duct ang_prev ang_curr da abs_da is_valid_angle T_dist oldos oldpolaradd oldpolarmode oldautosnap pt1_mod pt2_mod drawing inp new_w dw L_red pt_red)
  (setq w_num (atof *mep_w*) k_num (atof *mep_k*) Rc (* w_num (+ k_num 0.5)))
  (setq oldos (getvar "OSMODE") oldpolaradd (getvar "POLARADDANG") oldpolarmode (getvar "POLARMODE") oldautosnap (getvar "AUTOSNAP"))
  (setvar "AUTOSNAP" (logior oldautosnap 8)) (setvar "POLARMODE" 6)

  (princ (strcat "\n[HVAC DOUBLE] Auto Route W=" *mep_w* " K=" *mep_k* " | Layer: " *AR:LayerName*))
  (if (setq pt1 (getpoint "\n[DT] Diem bat dau (ESC de thoat): "))
    (if (setq pt2 (getpoint pt1 "\n[DT] Diem tiep theo: "))
      (progn
        (setvar "OSMODE" 0)
        (setq ang_prev (angle pt1 pt2))
        (if (check-touch pt1 nil)
          (progn (mep-draw-shoe-start pt1 pt2 w_num) (setq last_duct (entlast))
            (if (>= (distance pt1 pt2) (* w_num 0.5)) (setq pt1 (polar pt1 ang_prev (* w_num 0.5))))
          )
          (progn (mep-draw-duct pt1 pt2 w_num) (setq last_duct (entlast)))
        )
        (update-polar-angles ang_prev)

        (setq drawing T)
        (while drawing
          (setvar "OSMODE" oldos)
          (initget "Width W")
          (setq inp (vl-catch-all-apply 'getpoint (list pt2 "\n[DT] Diem tiep theo [nhap W tao Con Thu] (Enter/ESC ket thuc): ")))
          
          (if (vl-catch-all-error-p inp) (setq drawing nil inp nil))

          (cond
            ;; --- NEU NHAP 'W' HOAC 'Width' -> VE CON THU ---
            ((or (= inp "Width") (= inp "W"))
              (setq new_w (getreal (strcat "\nNhap be rong ong moi <" (rtos w_num 2 0) ">: ")))
              (if (and new_w (> new_w 0) (/= new_w w_num))
                (progn
                  (setvar "OSMODE" 0)
                  (setq dw (abs (- w_num new_w)))
                  (setq L_red dw)
                  (if (< L_red 150) (setq L_red 150)) ; Chieu dai con thu toi thieu 150
                  (setq pt_red (polar pt2 ang_prev L_red))
                  
                  (mep-draw-reducer pt2 pt_red w_num new_w) ; Ve con thu
                  (setq last_duct (entlast))
                  
                  (setq w_num new_w) ; Cap nhat W moi
                  (setq Rc (* w_num (+ k_num 0.5))) ; Cap nhat ban kinh Co
                  
                  (setq pt1 pt_red)
                  (setq pt2 pt_red)
                )
                (princ "\nDa huy tao Con thu.")
              )
            )

            ;; --- NEU CLICK DIEM -> VE ONG TIEP ---
            ((= (type inp) 'LIST)
              (setq pt3 inp)
              (setvar "OSMODE" 0)
              (if (> (distance pt2 pt3) 0.1)
                (progn
                  (setq ang_curr (angle pt2 pt3) da (- ang_curr ang_prev))
                  (while (> da pi) (setq da (- da (* 2 pi)))) (while (< da (- pi)) (setq da (+ da (* 2 pi))))
                  (setq abs_da (abs da) is_valid_angle nil)
                  (foreach ang_val (list (/ pi 6.0) (/ pi 4.0) (/ pi 3.0) (/ pi 2.0))
                    (if (equal abs_da ang_val 0.05) (setq is_valid_angle T))
                  )
                  (if is_valid_angle
                    (progn (setq T_dist (* Rc (tan_mep (/ abs_da 2.0))))
                      (if (and (> (distance pt1 pt2) T_dist) (> (distance pt2 pt3) T_dist))
                        (progn
                          (entdel last_duct)
                          (setq pt1_mod (polar pt2 (+ ang_prev pi) T_dist))
                          (mep-draw-duct pt1 pt1_mod w_num)
                          (mep-draw-elbow pt2 ang_prev ang_curr w_num k_num)
                          (setq pt2_mod (polar pt2 ang_curr T_dist))
                          (mep-draw-duct pt2_mod pt3 w_num)
                          (setq last_duct (entlast) pt1 pt2_mod pt2 pt3 ang_prev ang_curr)
                        )
                        (progn (princ (strcat "\n[!] Qua ngan, can " (rtos T_dist 2 1) " de nhet Co!"))
                               (mep-draw-duct pt2 pt3 w_num) (setq last_duct (entlast) pt1 pt2 pt2 pt3 ang_prev ang_curr))
                      )
                    )
                    (progn (mep-draw-duct pt2 pt3 w_num) (setq last_duct (entlast) pt1 pt2 pt2 pt3 ang_prev ang_curr))
                  )
                  (update-polar-angles ang_prev)
                )
              )
            )
            ;; --- NEU ENTER/SPACE ---
            (t (setq drawing nil))
          )
        )
      )
    )
  )
  (if (and pt2 last_duct (> (distance pt1 pt2) 1.0)) 
    (if (check-touch pt2 last_duct) (progn (entdel last_duct) (mep-draw-shoe pt1 pt2 w_num)))
  )
  (if oldos (setvar "OSMODE" oldos)) (if oldpolaradd (setvar "POLARADDANG" oldpolaradd)) (if oldpolarmode (setvar "POLARMODE" oldpolarmode)) (if oldautosnap (setvar "AUTOSNAP" oldautosnap))
)

(defun DT:Execute-Flip (/ ss i flip_count)
  (princ "\n[HVAC DOUBLE] Chon/Quet Got Giay de dao (ESC de thoat): ")
  (while (setq ss (ssget '((0 . "LWPOLYLINE") (90 . 4))))
    (setq i 0 flip_count 0)
    (while (< i (sslength ss))
      (if (mep-flip-shoe (ssname ss i)) (setq flip_count (1+ flip_count)))
      (setq i (1+ i))
    )
    (if (> flip_count 0) (princ (strcat "\n==> Da lat " (itoa flip_count) " got giay.")) (princ "\n==> Khong co got hop le."))
  )
)

(defun DT:Execute-Pipe (/ w_num pt1 pt2 ang p1_rect p2_rect p3_rect p4_rect oldos)
  (setq w_num (atof *mep_w*) oldos (getvar "OSMODE"))
  (princ "\n[HVAC DOUBLE] Ve Ong Roi: Pick P1 -> P2")
  (setvar "CLAYER" *AR:LayerName*)
  (while (setq pt1 (getpoint "\n[DT] P1 (Enter/ESC ve bang): "))
    (if (setq pt2 (getpoint pt1 "\n[DT] P2: "))
      (progn (setvar "OSMODE" 0) (setq ang (angle pt1 pt2))
        (setq p1_rect (polar pt1 (+ ang (/ pi 2.0)) (/ w_num 2.0))) (setq p2_rect (polar pt1 (- ang (/ pi 2.0)) (/ w_num 2.0)))
        (setq p3_rect (polar pt2 (+ ang (/ pi 2.0)) (/ w_num 2.0))) (setq p4_rect (polar pt2 (- ang (/ pi 2.0)) (/ w_num 2.0)))
        (command "_.PLINE" p1_rect p3_rect p4_rect p2_rect "C")
        (setvar "OSMODE" oldos)
      )
    )
  )
  (if oldos (setvar "OSMODE" oldos))
)

(defun DT:Execute-Elbow (/ w_num k_num r_val theta bulge_val pt_center p2_arc p3_arc p4_arc p5_arc oldos)
  (setq w_num (atof *mep_w*) k_num (atof *mep_k*) r_val (* k_num w_num))
  (cond ((= *mep_ang* "ang_90") (setq theta (/ pi 2.0))) ((= *mep_ang* "ang_60") (setq theta (/ pi 3.0)))
        ((= *mep_ang* "ang_45") (setq theta (/ pi 4.0))) ((= *mep_ang* "ang_30") (setq theta (/ pi 6.0))))
  (setq bulge_val (tan_mep (/ theta 4.0)) oldos (getvar "OSMODE"))
  (princ (strcat "\n[HVAC DOUBLE] Ve Co Roi: " *mep_ang*))
  (while (setq pt_center (getpoint "\n[DT] Chon tam xoay (Enter/ESC ve bang): "))
    (setvar "OSMODE" 0)
    (setq p2_arc (polar pt_center 0 r_val)) (setq p3_arc (polar pt_center theta r_val))
    (setq p4_arc (polar pt_center theta (+ r_val w_num))) (setq p5_arc (polar pt_center 0 (+ r_val w_num)))
    (entmake (list '(0 . "LWPOLYLINE") (cons 8 *AR:LayerName*) '(100 . "AcDbEntity") '(100 . "AcDbPolyline") '(90 . 4) '(70 . 1)
          (cons 10 p2_arc) (cons 42 bulge_val) (cons 10 p3_arc) '(42 . 0.0)
          (cons 10 p4_arc) (cons 42 (- bulge_val)) (cons 10 p5_arc) '(42 . 0.0)))
    (setvar "OSMODE" oldos)
  )
  (if oldos (setvar "OSMODE" oldos))
)

;; --- UPDATE: LOGIC VE FLEX TUBE (TU NM) ---
(defun DT:Execute-Flex (/ w_num oldos D chon e pC pM xM L n S p01 x flag p02 a p1 p2 p3 p4 i p03 p5 p6 cmdList dist)
  (setq w_num (atof *mep_w*)) ; Lay W tu bang lam duong kinh
  (setq D w_num)
  (setq oldos (getvar "osmode"))
  (setvar "CLAYER" *AR:LayerName*) ; Set Layer
  
  (princ (strcat "\n[HVAC FLEX] Ve Ong Mem D=" (rtos D 2 0) " | Pick duong tam (Enter/ESC ve bang): "))
  
  (while (setq chon (entsel "\nChon duong tam (Polyline/Line/Arc): "))
    (setq e (car chon) pC (cadr chon))
    
    (if (vl-catch-all-error-p (vl-catch-all-apply 'vlax-curve-getEndParam (list e)))
      (princ "\nDoi tuong khong hop le!")
      (progn
        (setq pM (vlax-curve-getClosestPointTo e pC))
        (setq xM (vlax-curve-getDistAtPoint e pM))
        (if (not xM) (setq xM (vl-catch-all-apply 'vlax-curve-getDistAtParam (list e (vlax-curve-getParamAtPoint e pM)))))
        (if (or (not xM) (vl-catch-all-error-p xM)) (setq xM 0.0))

        (setq L (vlax-curve-getDistAtParam e (vlax-curve-getEndParam e)) n (fix (/ (* 4.0 L) D)))
        (if (< n 2) (setq n 2)) (setq S (/ L n))
              
        (if (<= xM (/ L 2.0)) (setq p01 (vlax-curve-getStartPoint e) x 0.0 flag 1) (setq p01 (vlax-curve-getEndPoint e) x L flag -1))
        
        (setq dist (min (max (+ x (* S flag)) 0.0) L))
        (setq p02 (get-curve-pt e dist L))
        
        (if p02
          (progn
            (setq a (angle p01 p02) p1 (polar p01 (- a (/ pi 2.0)) (/ D 2.0)) p2 (polar p1 (+ a (/ pi 2.0)) D)
                  p3 (polar p1 a S) p4 (polar p2 a S) i 2)
            (setvar "osmode" 0)
            (setq cmdList (list "_.pline" p3 p4 p2 p1 p3))
            
            (while (< i n)
               (setq dist (min (max (+ x (* i S flag)) 0.0) L))
               (setq p03 (get-curve-pt e dist L))
               (if p03
                 (progn (setq a (angle p02 p03) p5 (polar p03 (- a (/ pi 2.0)) (/ D 2.0)) p6 (polar p5 (+ a (/ pi 2.0)) D))
                   (if (= i 2) (setq cmdList (append cmdList (list "_A"))))
                   (setq cmdList (append cmdList (list "_A" -90 p5 "_L" p6 "_A" "_A" -90 p4 "_L" p3 "_A" "_A" -90 p5)))
                   (setq p02 p03 p3 p5 p4 p6)
                 )
               )
               (setq i (1+ i))
            )
            
            (setq dist (min (max (+ x (* n S flag)) 0.0) L))
            (setq p03 (get-curve-pt e dist L))
            (if p03
              (progn (setq a (angle p02 p03) p5 (polar p03 (- a (/ pi 2.0)) (/ D 2.0)) p6 (polar p5 (+ a (/ pi 2.0)) D))
                (if (= n 2) (setq cmdList (append cmdList (list p5 p6 p4 p3 p5 ""))) (setq cmdList (append cmdList (list "_L" p5 p6 p4 p3 p5 ""))))
              )
            )
            (apply 'vl-cmdf cmdList)
          )
          (princ "\nLoi: Duong hong cau truc.")
        )
        (setvar "osmode" oldos)
      )
    )
  )
  (if oldos (setvar "osmode" oldos))
)


;;; ==========================================================================
;;; PHAN 5: LOGIC PLUMBING (CORE)
;;; ==========================================================================

(defun DL:Draw-Poly (pts / arr mspace pline)
  (if (>= (length pts) 4)
    (progn (setq arr (vlax-make-safearray vlax-vbDouble (cons 0 (1- (length pts)))))
      (vlax-safearray-fill arr pts)
      (setq mspace (vla-get-ModelSpace (vla-get-ActiveDocument (vlax-get-acad-object))))
      (setq pline (vla-AddLightWeightPolyline mspace arr))
      (vla-put-Layer pline *DL:LayerName*) (vla-put-Color pline 256) 
    )
  )
)

(defun DL:Process-Point (mode mainEnt p_target p_dev / p_perp dx dy dir dist_perp k p_elbow p_conn ang_out)
  (setq p_perp (vlax-curve-getClosestPointTo mainEnt p_dev))
  (if p_perp
    (progn (setq dx (abs (- (car p_perp) (car p_target))) dy (abs (- (cadr p_perp) (cadr p_target))))
      (if (> dx dy) (if (> (car p_target) (car p_perp)) (setq dir 1) (setq dir -1)) (if (> (cadr p_target) (cadr p_perp)) (setq dir 1) (setq dir -1)))
      (cond
        ((= mode "Ban-Tia") (list (car p_dev) (cadr p_dev) (car p_perp) (cadr p_perp)))
        ((= mode "Thang-45") (setq dist_perp (distance p_dev p_perp))
           (if (> dx dy) (setq p_conn (list (+ (car p_perp) (* dist_perp dir)) (cadr p_perp))) (setq p_conn (list (car p_perp) (+ (cadr p_perp) (* dist_perp dir)))))
           (list (car p_dev) (cadr p_dev) (car p_conn) (cadr p_conn)))
        ((= mode "Vuong-45") (setq k (* *DL:Len45* (sin (/ pi 4.0)))) 
           (if (> dx dy) (setq p_conn (list (+ (car p_perp) (* k dir)) (cadr p_perp))) (setq p_conn (list (car p_perp) (+ (cadr p_perp) (* k dir)))))
           (setq ang_out (angle p_perp p_dev) p_elbow (polar p_perp ang_out k))
           (list (car p_dev) (cadr p_dev) (car p_elbow) (cadr p_elbow) (car p_conn) (cadr p_conn)))
      )
    )
    nil
  )
)

(defun DL:Execute-Action (/ sel mainObj mainEnt pickPt p_start p_end p_target p_dev pts oldOs)
  (setq oldOs (getvar "OSMODE"))
  (princ (strcat "\n[PLUMBING] Che Do: " *DL:Mode* " | Layer: " *DL:LayerName*))
  (setq sel (entsel "\n[PLUMBING] B1. Chon Ong Chinh (Gan phia Ha luu/Hop gen): "))
  (if sel
    (progn (setq mainObj (car sel) pickPt (cadr sel) mainEnt (vlax-ename->vla-object mainObj))
      (setq p_start (vlax-curve-getStartPoint mainEnt) p_end (vlax-curve-getEndPoint mainEnt))
      (if (< (distance pickPt p_end) (distance pickPt p_start)) (setq p_target p_end) (setq p_target p_start))
      (princ "\n[PLUMBING] B2. Pick tam Thiet bi (ESC ve bang)...")
      (while (setq p_dev (getpoint "\n[PLUMBING] Pick diem Thiet bi: "))
        (setq p_dev (list (car p_dev) (cadr p_dev) 0.0) p_target (list (car p_target) (cadr p_target) 0.0))
        (setq pts (DL:Process-Point *DL:Mode* mainEnt p_target p_dev))
        (if pts (DL:Draw-Poly pts))
      )
    )
    (princ "\nLoi: Chua chon duoc ong chinh.")
  )
  (setvar "OSMODE" oldOs)
)

;;; ==========================================================================
;;; PHAN 6: CHUONG TRINH CHINH
;;; ==========================================================================

(defun c:MasterMep (/ dcl_file dcl_id loop status layer_list)
  (princ "\n--- MASTER MEP TOOLS INTEGRATED v2.0 ---")
  
  (setq dcl_file (vl-filename-mktemp "MasterMep_Integrated.dcl"))
  (MasterMep:Make-DCL dcl_file)
  
  (setq dcl_id (load_dialog dcl_file))
  (setq layer_list (AR:Get-Layers))
  
  (setq loop T)
  (while loop
    (if (not (new_dialog "MasterMep_UI" dcl_id)) (setq loop nil))
    
    ;; --- INIT HVAC SINGLE ---
    (start_list "d_layer") (mapcar 'add_list layer_list) (end_list)
    (if (>= *AR:LayerIdx* (length layer_list)) (setq *AR:LayerIdx* 0))
    (set_tile "d_layer" (itoa *AR:LayerIdx*))
    (setq *AR:LayerName* (nth *AR:LayerIdx* layer_list))
    (set_tile "ar_mode_group" *AR:LastMode*)
    (set_tile "e_rad" (rtos *AR:Rad* 2 0))
    (set_tile "e_gap" (rtos *AR:Gap* 2 0))
    (if (or (= *AR:LastMode* "Step-Z-X") (= *AR:LastMode* "Step-Z-Y")) (mode_tile "e_gap" 0) (mode_tile "e_gap" 1))

    ;; --- INIT HVAC DOUBLE ---
    (set_tile "width_w" *mep_w*)
    (set_tile "k_factor" *mep_k*)
    (set_tile "dt_ang_group" *mep_ang*)

    ;; --- INIT PLUMBING ---
    (start_list "dl_layer") (mapcar 'add_list layer_list) (end_list)
    (if (>= *DL:LayerIdx* (length layer_list)) (setq *DL:LayerIdx* 0))
    (set_tile "dl_layer" (itoa *DL:LayerIdx*))
    (setq *DL:LayerName* (nth *DL:LayerIdx* layer_list))
    (set_tile "dl_mode_group" *DL:Mode*)
    (set_tile "txt_len" (rtos *DL:Len45* 2 0))
    
    ;; --- ACTIONS HVAC SINGLE ---
    (action_tile "Step-Z-X" "(setq *AR:LastMode* \"Step-Z-X\") (mode_tile \"e_gap\" 0)")
    (action_tile "Step-Z-Y" "(setq *AR:LastMode* \"Step-Z-Y\") (mode_tile \"e_gap\" 0)")
    (action_tile "L-X"      "(setq *AR:LastMode* \"L-X\")      (mode_tile \"e_gap\" 1)")
    (action_tile "L-Y"      "(setq *AR:LastMode* \"L-Y\")      (mode_tile \"e_gap\" 1)")
    (action_tile "Direct"   "(setq *AR:LastMode* \"Direct\")   (mode_tile \"e_gap\" 1)")
    (action_tile "btn_hvac" 
      "(progn (setq *AR:Rad* (atof (get_tile \"e_rad\"))) (setq *AR:Gap* (atof (get_tile \"e_gap\"))) (setq *AR:LayerIdx* (atoi (get_tile \"d_layer\"))) (done_dialog 1))")

    ;; --- ACTIONS HVAC DOUBLE ---
    ;; UPDATE: Them dong lay LayerIdx tu DCL vao cac nut bam
    (action_tile "dt_ang_group" "(setq *mep_ang* $value)")
    (action_tile "btn_dt_auto" 
      "(progn (setq *AR:LayerIdx* (atoi (get_tile \"d_layer\"))) (setq *mep_w* (get_tile \"width_w\")) (setq *mep_k* (get_tile \"k_factor\")) (done_dialog 3))")
    (action_tile "btn_dt_flip" 
      "(progn (done_dialog 4))")
    (action_tile "btn_dt_ong" 
      "(progn (setq *AR:LayerIdx* (atoi (get_tile \"d_layer\"))) (setq *mep_w* (get_tile \"width_w\")) (done_dialog 5))")
    (action_tile "btn_dt_co" 
      "(progn (setq *AR:LayerIdx* (atoi (get_tile \"d_layer\"))) (setq *mep_w* (get_tile \"width_w\")) (setq *mep_k* (get_tile \"k_factor\")) (done_dialog 6))")
    ;; UPDATE: Them action cho nut Flex
    (action_tile "btn_dt_flex" 
      "(progn (setq *AR:LayerIdx* (atoi (get_tile \"d_layer\"))) (setq *mep_w* (get_tile \"width_w\")) (done_dialog 7))")

    ;; --- ACTIONS PLUMBING ---
    (action_tile "dl_mode_group" "(setq *DL:Mode* $value)")
    (action_tile "txt_len" "(setq *DL:Len45* (atof $value))")
    (action_tile "btn_plumb" 
      "(progn (setq *DL:Len45* (atof (get_tile \"txt_len\"))) (setq *DL:LayerIdx* (atoi (get_tile \"dl_layer\"))) (done_dialog 2))")

    (action_tile "cancel" "(done_dialog 0)")
    
    (setq status (start_dialog))
    
    (cond
      ((= status 1) (setq *AR:LayerName* (nth *AR:LayerIdx* layer_list)) (vl-catch-all-apply 'AR:Execute-Draw))
      ((= status 2) (setq *DL:LayerName* (nth *DL:LayerIdx* layer_list)) (vl-catch-all-apply 'DL:Execute-Action))
      ;; UPDATE: Truoc khi chay Double Line, cap nhat LayerName tu bien toan cuc
      ((= status 3) (setq *AR:LayerName* (nth *AR:LayerIdx* layer_list)) (vl-catch-all-apply 'DT:Execute-Auto))
      ((= status 4) (vl-catch-all-apply 'DT:Execute-Flip))
      ((= status 5) (setq *AR:LayerName* (nth *AR:LayerIdx* layer_list)) (vl-catch-all-apply 'DT:Execute-Pipe))
      ((= status 6) (setq *AR:LayerName* (nth *AR:LayerIdx* layer_list)) (vl-catch-all-apply 'DT:Execute-Elbow))
      ;; UPDATE: Them handler cho Flex Tube
      ((= status 7) (setq *AR:LayerName* (nth *AR:LayerIdx* layer_list)) (vl-catch-all-apply 'DT:Execute-Flex))
      (t (setq loop nil))
    )
  )
  
  (unload_dialog dcl_id)
  (vl-file-delete dcl_file)
  (princ "\nDa thoat MasterMep Tools.")
  (princ)
)

(princ "\nGo lenh MasterMep de bat dau.")
(princ)
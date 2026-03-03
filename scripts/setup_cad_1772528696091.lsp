;; =======================================================
;; HAM CHAY NGAM: TU DONG THIET LAP KHI LOAD LISP
;; =======================================================
(defun Apply_Default_Settings ()
  (setvar "GRIDMODE" 0)          ; Tat F7
  (setvar "SNAPMODE" 0)          ; Tat F9
  (setvar "ORTHOMODE" 0)         ; Tat F8
  (setvar "MENUBAR" 0)           ; Tat MenuBar
  (setvar "TEXTSIZE" 200.0)      ; Chieu cao text
  (setvar "CURSORSIZE" 50)       ; Kich thuoc con tro
  (setvar "PICKBOX" 15)          ; O vuong bat diem
  (setvar "SAVETIME" 10)         ; Autosave 10 phut
  (setvar "UCSICON" 1)           ; UCS ON (Goc duoi trai)
  (setvar "LUNITS" 2)            ; Decimal
  (setvar "INSUNITS" 4)          ; Millimeters
  
  ;; OSMODE: 15295 (Tat Geometric Center va Insertion)
  (setvar "OSMODE" 15295)
  
  ;; AUTOSNAP: 63 la hien thi day du Marker, Tooltip, Magnet + Bat Polar (F10) + Bat OTrack (F11)
  (setvar "AUTOSNAP" 63)
  
  (princ "\n>> [Auto-Run] Da ap dung Thiet Lap CAD mac dinh! <<")
  (princ)
)

;; Thuc thi ham chay ngam ngay khi file LISP duoc load
(Apply_Default_Settings)

;; =======================================================
;; HAM GOI GIAO DIEN DCL KHI NGUOI DUNG GO LENH: SETUPCAD
;; =======================================================
(defun c:SETUPCAD ( / dcl_id dcl_fn f save_vars)
  (vl-load-com)
  
  ;; --- 1. TAO FILE DCL TAM THOI ---
  (setq dcl_fn (vl-filename-mktemp "setup_cad.dcl"))
  (setq f (open dcl_fn "w"))
  (foreach line
    '(
      "setup_dialog : dialog {"
      "  label = \"Thiet Lap AutoCAD Nhanh\";"
      "  : row {"
      "    // --- COT 1: CO BAN & HE THONG ---"
      "    : column {"
      "      : boxed_column {"
      "        label = \"Cai Dat Co Ban\";"
      "        : row {"
      "          : column {"
      "            : toggle { key = \"t_grid\"; label = \"Bat Grid (F7)\"; }"
      "            : toggle { key = \"t_ortho\"; label = \"Bat Ortho (F8)\"; }"
      "          }"
      "          : column {"
      "            : toggle { key = \"t_snap\"; label = \"Bat Snap (F9)\"; }"
      "            : toggle { key = \"t_polar\"; label = \"Bat Polar (F10)\"; }"
      "          }"
      "        }"
      "        : toggle { key = \"t_menu\"; label = \"Hien thi MenuBar\"; }"
      "        spacer;"
      "        : popup_list { key = \"p_ucs\"; label = \"Hien thi UCS:\"; edit_width = 18; }"
      "        : popup_list { key = \"p_lunits\"; label = \"Kieu chieu dai:\"; edit_width = 18; }"
      "        : popup_list { key = \"p_insunits\"; label = \"Don vi chen:\"; edit_width = 18; }"
      "        spacer;"
      "        : edit_box { key = \"e_text\"; label = \"Chieu cao Text:\"; edit_width = 8; }"
      "      }"
      "      : boxed_column {"
      "        label = \"Tuy Chinh Hien Thi & He Thong\";"
      "        : edit_box { key = \"e_cursor\"; label = \"Kich thuoc Crosshair (1-100):\"; edit_width = 8; }"
      "        : edit_box { key = \"e_pickbox\"; label = \"Kich thuoc Pickbox (0-50):\"; edit_width = 8; }"
      "        : edit_box { key = \"e_save\"; label = \"Thoi gian AutoSave (phut):\"; edit_width = 8; }"
      "      }"
      "    }"
      "    // --- COT 2: TRUY BAT DIEM ---"
      "    : boxed_column {"
      "      label = \"Truy Bat Diem (Osnap)\";"
      "      : row {"
      "        : toggle { key = \"t_osnap\"; label = \"Bat O.Snap (F3)\"; }"
      "        : toggle { key = \"t_otrack\"; label = \"Bat O.Snap Tracking (F11)\"; }"
      "      }"
      "      : row {"
      "        : column {"
      "          : toggle { key = \"os_end\"; label = \"Endpoint\"; }"
      "          : toggle { key = \"os_mid\"; label = \"Midpoint\"; }"
      "          : toggle { key = \"os_cen\"; label = \"Center\"; }"
      "          : toggle { key = \"os_gcen\"; label = \"Geometric Center\"; }"
      "          : toggle { key = \"os_nod\"; label = \"Node\"; }"
      "          : toggle { key = \"os_qua\"; label = \"Quadrant\"; }"
      "          : toggle { key = \"os_int\"; label = \"Intersection\"; }"
      "        }"
      "        : column {"
      "          : toggle { key = \"os_ext\"; label = \"Extension\"; }"
      "          : toggle { key = \"os_ins\"; label = \"Insertion\"; }"
      "          : toggle { key = \"os_per\"; label = \"Perpendicular\"; }"
      "          : toggle { key = \"os_tan\"; label = \"Tangent\"; }"
      "          : toggle { key = \"os_nea\"; label = \"Nearest\"; }"
      "          : toggle { key = \"os_app\"; label = \"Apparent Intersect\"; }"
      "          : toggle { key = \"os_par\"; label = \"Parallel\"; }"
      "        }"
      "      }"
      "      spacer;"
      "      : row {"
      "        : button { key = \"btn_selall\"; label = \"Select All\"; }"
      "        : button { key = \"btn_clrall\"; label = \"Clear All\"; }"
      "      }"
      "    }"
      "  }"
      "  ok_cancel;"
      "}"
    )
    (write-line line f)
  )
  (close f)

  ;; --- 2. LOAD VA KHOI TAO GIAO DIEN ---
  (setq dcl_id (load_dialog dcl_fn))
  (if (not (new_dialog "setup_dialog" dcl_id))
    (progn (princ "\nLoi: Khong the load DCL.") (exit))
  )

  ;; --- 3. NAP DU LIEU CHO BANG CHON ---
  (start_list "p_ucs") (mapcar 'add_list '("Tat (OFF)" "Goc duoi trai (ON)" "Tai goc toa do (Origin)")) (end_list)
  (start_list "p_lunits") (mapcar 'add_list '("Scientific" "Decimal" "Engineering" "Architectural" "Fractional")) (end_list)
  (start_list "p_insunits") (mapcar 'add_list '("Unitless (0)" "Inches (1)" "Millimeters (4)" "Centimeters (5)" "Meters (6)")) (end_list)

  ;; --- 4. GAN MAC DINH TREN GIAO DIEN ---
  (set_tile "t_grid" "0")
  (set_tile "t_snap" "0")
  (set_tile "t_ortho" "0")
  (set_tile "t_polar" "1")
  (set_tile "t_menu" "0")
  
  (set_tile "p_ucs" "1")        
  (set_tile "p_lunits" "1")     
  (set_tile "p_insunits" "2")   
  
  (set_tile "e_text" "200.00")
  (set_tile "e_cursor" "50")
  (set_tile "e_pickbox" "15")
  (set_tile "e_save" "10")

  (set_tile "t_osnap" "1")
  (set_tile "t_otrack" "1")
  
  ;; Bat het Osnap ngoai tru Geometric Center va Insertion
  (mapcar '(lambda (x) (set_tile x "1")) 
          '("os_end" "os_mid" "os_cen" "os_nod" "os_qua" "os_int" 
            "os_ext" "os_per" "os_tan" "os_nea" "os_app" "os_par"))
  (set_tile "os_gcen" "0")
  (set_tile "os_ins" "0")

  ;; --- 5. HANH DONG CUA NUT BAM ---
  (action_tile "t_ortho" "(if (= $value \"1\") (set_tile \"t_polar\" \"0\"))")
  (action_tile "t_polar" "(if (= $value \"1\") (set_tile \"t_ortho\" \"0\"))")
  (action_tile "btn_selall" "(mapcar '(lambda (x) (set_tile x \"1\")) '(\"os_end\" \"os_mid\" \"os_cen\" \"os_gcen\" \"os_nod\" \"os_qua\" \"os_int\" \"os_ext\" \"os_ins\" \"os_per\" \"os_tan\" \"os_nea\" \"os_app\" \"os_par\"))")
  (action_tile "btn_clrall" "(mapcar '(lambda (x) (set_tile x \"0\")) '(\"os_end\" \"os_mid\" \"os_cen\" \"os_gcen\" \"os_nod\" \"os_qua\" \"os_int\" \"os_ext\" \"os_ins\" \"os_per\" \"os_tan\" \"os_nea\" \"os_app\" \"os_par\"))")
  (action_tile "accept" "(save_vars) (done_dialog)")
  (action_tile "cancel" "(done_dialog)")

  ;; --- 6. HAM LUU BIEN (Chay khi bam OK) ---
  (defun save_vars ( / new_osm curr_asnap ucs_idx lu_idx ins_idx)
    (setvar "GRIDMODE" (atoi (get_tile "t_grid")))
    (setvar "SNAPMODE" (atoi (get_tile "t_snap")))
    (setvar "ORTHOMODE" (atoi (get_tile "t_ortho")))
    (setvar "MENUBAR" (atoi (get_tile "t_menu")))
    (setvar "TEXTSIZE" (atof (get_tile "e_text")))
    (setvar "CURSORSIZE" (atoi (get_tile "e_cursor")))
    (setvar "PICKBOX" (atoi (get_tile "e_pickbox")))
    (setvar "SAVETIME" (atoi (get_tile "e_save")))

    (setq ucs_idx (atoi (get_tile "p_ucs")))
    (cond ((= ucs_idx 0) (setvar "UCSICON" 0)) ((= ucs_idx 1) (setvar "UCSICON" 1)) ((= ucs_idx 2) (setvar "UCSICON" 3)))
    (setvar "LUNITS" (1+ (atoi (get_tile "p_lunits"))))
    
    (setq ins_idx (atoi (get_tile "p_insunits")))
    (cond ((= ins_idx 0) (setvar "INSUNITS" 0)) ((= ins_idx 1) (setvar "INSUNITS" 1)) ((= ins_idx 2) (setvar "INSUNITS" 4)) ((= ins_idx 3) (setvar "INSUNITS" 5)) ((= ins_idx 4) (setvar "INSUNITS" 6)))

    (setq new_osm 0)
    (if (= (get_tile "os_end") "1") (setq new_osm (+ new_osm 1)))
    (if (= (get_tile "os_mid") "1") (setq new_osm (+ new_osm 2)))
    (if (= (get_tile "os_cen") "1") (setq new_osm (+ new_osm 4)))
    (if (= (get_tile "os_nod") "1") (setq new_osm (+ new_osm 8)))
    (if (= (get_tile "os_qua") "1") (setq new_osm (+ new_osm 16)))
    (if (= (get_tile "os_int") "1") (setq new_osm (+ new_osm 32)))
    (if (= (get_tile "os_ins") "1") (setq new_osm (+ new_osm 64)))
    (if (= (get_tile "os_per") "1") (setq new_osm (+ new_osm 128)))
    (if (= (get_tile "os_tan") "1") (setq new_osm (+ new_osm 256)))
    (if (= (get_tile "os_nea") "1") (setq new_osm (+ new_osm 512)))
    (if (= (get_tile "os_gcen") "1") (setq new_osm (+ new_osm 1024)))
    (if (= (get_tile "os_app") "1") (setq new_osm (+ new_osm 2048)))
    (if (= (get_tile "os_ext") "1") (setq new_osm (+ new_osm 4096)))
    (if (= (get_tile "os_par") "1") (setq new_osm (+ new_osm 8192)))
    (if (= (get_tile "t_osnap") "0") (setq new_osm (+ new_osm 16384)))
    (setvar "OSMODE" new_osm)

    (setq curr_asnap (getvar "AUTOSNAP"))
    (if (= (get_tile "t_polar") "1") (if (= (logand curr_asnap 8) 0) (setq curr_asnap (+ curr_asnap 8))) (if (= (logand curr_asnap 8) 8) (setq curr_asnap (- curr_asnap 8))))
    (if (= (get_tile "t_otrack") "1") (if (= (logand curr_asnap 16) 0) (setq curr_asnap (+ curr_asnap 16))) (if (= (logand curr_asnap 16) 16) (setq curr_asnap (- curr_asnap 16))))
    (setvar "AUTOSNAP" curr_asnap)
  )

  ;; --- 7. HIEN THI GIAO DIEN & DON DEP ---
  (start_dialog)
  (unload_dialog dcl_id)
  (vl-file-delete dcl_fn)
  (princ "\n>> Thiet lap CAD da cap nhat! <<")
  (princ)
)
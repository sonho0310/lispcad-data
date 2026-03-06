;; ====================================
;; TITLE: Shrinkwrap MText Bounding Box (TxtBoxWidth)
;; DESCRIPTION: Tự động thu hẹp khung viền (bounding box) của các đối tượng MText sao cho vừa khít với chiều dài chữ thực tế.
;; GUIDE: Load Lisp (AP) -> Gõ TxtBoxWidth -> Quét chọn các MText cần thu gọn -> Enter.
;; ====================================
(defun mip-mtext-wrap-BB (en / el SetHandles CheckHandles sclst)
 
(vl-load-com)
 
;;; Argument: the ename of an mtext
 
;;; Shrinkwrap the bounding box of selected MText objects
 
;;; http://discussion.autodesk.com/forums/message.jspa?messageID=5734567
 
;;; ShrinkwrapMText v2a.lsp - Joe Burke - 10/13/2007 - Version 2a
 
;;;;;http://discussion.autodesk.com/forums/thread.jspa?threadID=448625
 
;;;; USE:
 
;;; (mip-mtext-wrap-BB (car(entsel)))
 
;;; !!!! AutoCAD 2010 2011 2012
 
;;; http://forums.autodesk.com/t5/Visual-LISP-AutoLISP-and-General/MTEXT-Column-property/m-p/2690952
 
;;;Need to change the column type from dynamic to not add the dxf group of 75 with 0
 
;;; http://www.theswamp.org/index.php?topic=28243.0
 
(defun GetAnnoScales (e / dict lst rewind res)
 
;;; Argument: the ename of an annotative object.
 
;;; Returns the annotative scales associated with the
 
;;; ename as a list of strings.
 
;;; Example: ("1:1" "1:16" "1:20" "1:30")
 
;;; Returns nil if the ename is not annotative.
 
;;; Can be used to test whether ename is annotative or not.
 
;;; Works with annotative objects: text, mtext, leader, mleader,
 
;;; dimension, block reference, tolerance and attribute.
 
;;; Based on code by Ian Bryant.
 
(if
 
(and
 
e
 
(setq dict (cdr (assoc 360 (entget e))))
 
(setq lst (dictsearch dict "AcDbContextDataManager"))
 
(setq lst
 
(dictsearch (cdr (assoc -1 lst)) "ACDB_ANNOTATIONSCALES")
 
) ;_ end of setq
 
(setq dict (cdr (assoc -1 lst)))
 
) ;_ end of and
 
(progn
 
(setq rewind t)
 
(while (setq lst (dictnext dict rewind))
 
(setq e (cdr (assoc 340 lst))
 
res (cons (cdr (assoc 300 (entget e))) res)
 
rewind nil
 
) ;_ end of setq
 
) ;_ end of while
 
) ;_ end of progn
 
) ;_ end of if
 
(reverse res)
 
) ;end
 
(defun CheckHandles (e / dict lst rewind nlst d42 d43 n p ptlst)
 
;;; Argument: the ename of annotative mtext object.
 
;;; Returns T if the object has only one scale or
 
;;; the handles for all scales are proportionally the
 
;;; same and all scales use the same insertion point.
 
(if
 
(and
 
e
 
(setq dict (cdr (assoc 360 (entget e))))
 
(setq lst (dictsearch dict "AcDbContextDataManager"))
 
(setq lst
 
(dictsearch (cdr (assoc -1 lst)) "ACDB_ANNOTATIONSCALES")
 
) ;_ end of setq
 
(setq dict (cdr (assoc -1 lst)))
 
) ;_ end of and
 
(progn
 
(setq rewind t)
 
(while (setq lst (dictnext dict rewind))
 
(setq nlst (cons lst nlst)
 
rewind nil
 
) ;_ end of setq
 
) ;_ end of while
 
(cond
 
((= 1 (length nlst)))
 
(t
 
;; lst is nil so reuse it.
 
(foreach x nlst
 
;Horizontal width. Can be zero, a null text string.
 
(setq d42 (cdr (assoc 42 x))
 
;Vertical height cannot be zero so a divide
 
;by zero error can't happen.
 
d43 (cdr (assoc 43 x))
 
n (/ d42 d43)
 
lst (cons n lst)
 
;Insertion point
 
p (cdr (assoc 11 x))
 
ptlst (cons p ptlst)
 
) ;_ end of setq
 
) ;_ end of foreach
 
(and
 
(vl-every '(lambda (x) (equal n x 1e-4)) lst)
 
(vl-every '(lambda (x) (equal p x 1e-4)) ptlst)
 
) ;_ end of and
 
)
 
) ;_ end of cond
 
) ;_ end of progn
 
) ;_ end of if
 
) ;end
 
(defun SetHandles (lst / oldlst charwidth ht pat)
 
;;; ;Argument: an entget list.
 
;;; ;Code 42 is the smallest width of the handles.
 
;;; ;If 41 is larger than 42 then the handles can be shrunk
 
;;; ;horizontally given a single line mtext object.
 
;;;
 
;;; ;Code 46 is the current height of the handles in 2007/2008.
 
;;; ;Substitute the actual height from the code 43 value.
 
;;;
 
;;; ;Used to determine number of objects modified.
 
(setq lst (entget (cdr(assoc -1 lst)) '("ACAD")))
 
;;; (setq oldlst lst)
 
(setq charwidth (* (cdr (assoc 42 lst)) 1.05) ;_1.035
 
ht (cdr (assoc 43 lst))
 
lst (subst (cons 41 charwidth) (assoc 41 lst) lst)
 
lst (subst (cons 46 ht) (assoc 46 lst) lst)
 
lst (if (assoc 75 lst) ;;; 75 - òèï êîëîíîê
 
(subst (cons 75 0) (assoc 75 0) lst)
 
(append lst (list(cons 75 0)))
 
)
 
) ;_ end of setq
 
;;;Code 46 is the current height of the handles in 2007/2008.
 
;;;Substitute the actual height from the code 43 value.
 
(if (and
 
(setq pat (assoc -3 lst))
 
(eq "ACAD" (caadr pat))
 
) ;_ end of and
 
(progn
 
(if (assoc 46 lst)
 
;;;Code 46 is the current height of the handles in 2007/2008.
 
;;; Remove extended data regarding height if found.
 
(setq pat '(-3 ("ACAD")))
 
(progn
 
(setq pat
 
(cons -3
 
(list (subst (cons 1040 ht)
 
(assoc 1040 (cdadr pat))
 
(cadr pat)
 
) ;_ end of subst
 
) ;_ end of list
 
) ;_ end of cons
 
) ;_ end of setq
 
) ;_ end of progn
 
) ;_ end of if
 
(setq lst (subst pat (assoc -3 lst) lst))
 
)
 
) ;_ end of if
 
(setq lst (entmod lst))
 
) ;end SetHandles
 
(if (= (cdr (assoc 0 (setq EL (entget en '("*"))))) "MTEXT")
 
(progn
 
(cond
 
((and
 
(setq sclst (GetAnnoScales en))
 
(CheckHandles en)
 
) ;_ end of and
 
(vl-cmdf "._chprop" en "" "_Annotative" "_No" "")
 
;(SetHandles (entget ename))
 
(SetHandles el)
 
(vl-cmdf "._chprop" en "" "_Annotative" "_Yes" "")
 
(foreach x sclst
 
(vl-cmdf "._objectscale" en "" "_Add" x "")
 
) ;_ end of foreach
 
)
 
((not (GetAnnoScales en))
 
(SetHandles el)
 
)
 
(t nil)
 
) ;_ end of cond
 
) ;_ end of progn
 
) ;_ end of if
 
) ;_ end of defun
 
(defun C:TxtBoxWidth (/ ss i)
 
(and (setq ss (ssget "_:L" '((0 . "MTEXT"))))
 
(repeat (setq i (sslength ss))
 
(mip-mtext-wrap-BB (ssname ss (setq i (1- i))))
 
)
 
(setq ss nil)
 
)
 
)
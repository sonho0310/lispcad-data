# -*- coding: utf-8 -*-
__title__ = "Auto CAD to MEP (Duct, Pipe, Family)"
from pyrevit import revit, DB, forms, script
import math
import re
import clr

doc = revit.doc

def get_cad_lines(import_instance, target_layer):
    lines = []
    geo_elem = import_instance.get_Geometry(DB.Options())
    if not geo_elem: return lines
    
    for geo_obj in geo_elem:
        if isinstance(geo_obj, DB.GeometryInstance):
            inst_geo = geo_obj.GetInstanceGeometry()
            for inst_obj in inst_geo:
                if isinstance(inst_obj, DB.Line):
                    gs = doc.GetElement(inst_obj.GraphicsStyleId)
                    if gs and gs.GraphicsStyleCategory and gs.GraphicsStyleCategory.Name == target_layer:
                        lines.append(inst_obj)
                elif isinstance(inst_obj, DB.PolyLine):
                     gs = doc.GetElement(inst_obj.GraphicsStyleId)
                     if gs and gs.GraphicsStyleCategory and gs.GraphicsStyleCategory.Name == target_layer:
                         pts = inst_obj.GetCoordinates()
                         for i in range(len(pts)-1):
                             try:
                                 lines.append(DB.Line.CreateBound(pts[i], pts[i+1]))
                             except:
                                 pass
    return lines

def get_cad_blocks(import_instance, target_layer):
    pts = []
    geo_elem = import_instance.get_Geometry(DB.Options())
    if not geo_elem: return []
    
    for geo_obj in geo_elem:
        if isinstance(geo_obj, DB.GeometryInstance):
            inst_geo = geo_obj.GetInstanceGeometry()
            for inst_obj in inst_geo:
                # 1. Quét Block (GeometryInstance)
                if isinstance(inst_obj, DB.GeometryInstance):
                    is_match = False
                    gs = doc.GetElement(inst_obj.GraphicsStyleId)
                    if gs and gs.GraphicsStyleCategory and gs.GraphicsStyleCategory.Name == target_layer:
                        is_match = True
                    else:
                        try:
                            for child_geo in inst_obj.GetInstanceGeometry():
                                child_gs = doc.GetElement(child_geo.GraphicsStyleId)
                                if child_gs and child_gs.GraphicsStyleCategory and target_layer in child_gs.GraphicsStyleCategory.Name:
                                    is_match = True
                                    break
                        except: pass
                        
                    if is_match:
                        tf = inst_obj.Transform
                        pts.append( (tf.Origin, math.atan2(tf.BasisX.Y, tf.BasisX.X)) )
                        
                # 2. Xúc luôn tất cả Line, Curve, Arc bị Explode rác rưởi
                elif hasattr(inst_obj, "GraphicsStyleId"):
                    gs = doc.GetElement(inst_obj.GraphicsStyleId)
                    if gs and gs.GraphicsStyleCategory and target_layer in gs.GraphicsStyleCategory.Name:
                        if isinstance(inst_obj, DB.Arc) and inst_obj.IsClosed:
                            pts.append( (inst_obj.Center, 0.0) )
                        elif isinstance(inst_obj, DB.Line):
                            pts.append( ((inst_obj.GetEndPoint(0) + inst_obj.GetEndPoint(1)) / 2.0, 0.0) )
                        elif isinstance(inst_obj, DB.PolyLine):
                            c_pts = inst_obj.GetCoordinates()
                            if c_pts: pts.append( (c_pts[0], 0.0) )
                            
    # 3. THUẬT TOÁN AI CLUSTERING: 
    # Nếu CAD bị nổ (Explode), 1 cái đèn sẽ túa ra 20 đường Line -> Nhóm tất cả lại thành 1 tọa độ trung tâm duy nhất!
    final_blocks = []
    used = set()
    for i, (p1, rot1) in enumerate(pts):
        if i in used: continue
        
        cluster_pts = [p1]
        cluster_rot = rot1
        used.add(i)
        
        for j, (p2, rot2) in enumerate(pts):
            if j in used: continue
            if p1.DistanceTo(p2) < (600 / 304.8): # Phạm vi gom cụm bán kính 600mm
                cluster_pts.append(p2)
                used.add(j)
                if rot2 != 0.0: cluster_rot = rot2 # Ưu tiên lấy góc xoay nếu có
                
        # Tính toán tọa độ hạt nhân của cụm
        avg_x = sum(p.X for p in cluster_pts) / len(cluster_pts)
        avg_y = sum(p.Y for p in cluster_pts) / len(cluster_pts)
        avg_z = sum(p.Z for p in cluster_pts) / len(cluster_pts)
        
        final_blocks.append( (DB.XYZ(avg_x, avg_y, avg_z), cluster_rot) )
        
    return final_blocks

def is_parallel(v1, v2):
    return v1.CrossProduct(v2).IsAlmostEqualTo(DB.XYZ.Zero, 0.01)

def project_point_on_line(pt, line):
    p1 = line.GetEndPoint(0)
    v = line.Direction
    return p1 + v * v.DotProduct(pt - p1)

def find_mep_pairs(lines):
    pairs = []
    used = set()
    for i, l1 in enumerate(lines):
        if i in used: continue
        best_l2 = None
        best_dist = 9999
        v1 = l1.Direction
        
        for j, l2 in enumerate(lines):
            if i == j or j in used: continue
            v2 = l2.Direction
            if is_parallel(v1, v2):
                p1 = l1.GetEndPoint(0)
                proj = project_point_on_line(p1, l2)
                dist = p1.DistanceTo(proj)
                
                # Filter distance (10mm to 5000mm)
                if (10 / 304.8) < dist < (5000 / 304.8): 
                    p1_end = l1.GetEndPoint(1)
                    mid1 = (p1 + p1_end) / 2.0
                    proj_mid = project_point_on_line(mid1, l2)
                    
                    dist_to_ends = proj_mid.DistanceTo(l2.GetEndPoint(0)) + proj_mid.DistanceTo(l2.GetEndPoint(1))
                    if abs(dist_to_ends - l2.Length) < 0.1:
                        if dist < best_dist:
                            best_dist = dist
                            best_l2 = j
                            
        if best_l2 is not None:
            pairs.append((l1, lines[best_l2], best_dist))
            used.add(i)
            used.add(best_l2)
            
    return pairs

def extract_size_from_text(text):
    match = re.search(r'\b(\d+)\s*[xX*×]\s*(\d+)\b', text)
    if match:
        return float(match.group(1)), float(match.group(2))
    return None, None

def get_connectors(element):
    connectors = []
    conn_manager = None
    if hasattr(element, "MEPModel") and getattr(element, "MEPModel"):
        conn_manager = element.MEPModel.ConnectorManager
    elif hasattr(element, "ConnectorManager"):
        conn_manager = element.ConnectorManager
        
    if conn_manager:
        for conn in conn_manager.Connectors:
            if conn.Domain in [DB.Domain.DomainHvac, DB.Domain.DomainPiping]:
                connectors.append(conn)
    return connectors

def safe_name(elem):
    try: return elem.Name
    except:
        try:
            p = elem.get_Parameter(DB.BuiltInParameter.SYMBOL_NAME_PARAM)
            if not p: p = elem.get_Parameter(DB.BuiltInParameter.ELEM_NAME_PARAM)
            if p: return p.AsString()
        except: pass
    return "Unknown_{}".format(elem.Id.IntegerValue)

def get_curve_size(element, is_duct=True):
    try:
        if is_duct: return element.get_Parameter(DB.BuiltInParameter.RBS_CURVE_WIDTH_PARAM).AsDouble()
        else: return element.get_Parameter(DB.BuiltInParameter.RBS_PIPE_DIAMETER_PARAM).AsDouble()
    except: return 0.0

def main():
    # 0. CHỌN CHẾ ĐỘ DỰNG BAO TRÙM MEP
    sys_mode = forms.SelectFromList.show(
        ['1. Dựng ỐNG GIÓ (Duct) qua nét biên Width', '2. Dựng ỐNG NƯỚC (Pipe) qua nét biên Diameter', '3. Dựng THIẾT BỊ / FAMILY TỪ BLOCK CAD'],
        title="BẠN MUỐN DỰNG HỆ THỐNG GÌ TỪ CAD?",
        button_name="Chọn Tính Năng Bắn Tên Lửa"
    )
    if not sys_mode: return
    
    mode_duct = "ỐNG GIÓ" in sys_mode
    mode_pipe = "ỐNG NƯỚC" in sys_mode
    mode_family = "FAMILY" in sys_mode

    selection = revit.get_selection()
    cad_links = [el for el in selection.elements if isinstance(el, DB.ImportInstance)]
    
    if not cad_links:
        forms.alert('Vui lòng CHỌN FILE CAD ĐƯỢC LINK trên mặt bằng trước!', exitscript=True)
        
    cad_link = cad_links[0]
    
    # 1. Đọc 100% Layer từ CAD Link bằng SubCategories (Siêu tốc, chính xác)
    layers = set()
    if cad_link.Category and cad_link.Category.SubCategories:
        for subcat in cad_link.Category.SubCategories:
            layers.add(subcat.Name)
                        
    if not layers:
        forms.alert('Không thể đọc được Layer nào từ file CAD này!', exitscript=True)
        
    target_layer = forms.SelectFromList.show(sorted(list(layers)), title="1. Chọn LAYER chứa nét CAD của ĐỐI TƯỢNG (Ống/Block):")
    if not target_layer: return
    
    # ==== FLOW 3: PLACING FAMILIES FROM CAD BLOCKS ====
    if mode_family:
        family_symbols = DB.FilteredElementCollector(doc).OfClass(DB.FamilySymbol).ToElements()
        dict_symbols = {"[{}] {}".format(safe_name(s.Family), safe_name(s)): s for s in family_symbols}
        
        sel_symbol_name = forms.SelectFromList.show(sorted(dict_symbols.keys()), title="2. Chọn LOẠI THIẾT BỊ (Family Type) Revit để ốp vào Block:")
        if not sel_symbol_name: return
        selected_symbol = dict_symbols[sel_symbol_name]
        
        levels = DB.FilteredElementCollector(doc).OfClass(DB.Level).ToElements()
        dict_levels = {safe_name(t): t for t in levels}
        sel_level_name = forms.SelectFromList.show(sorted(dict_levels.keys()), title="3. Chọn Level (Tầng):")
        if not sel_level_name: return
        selected_level = dict_levels[sel_level_name]
        
        offset_str = forms.ask_for_string(prompt="Cao độ Z (Elevation/Offset) là bao nhiêu (mm)?", title="Offset Z", default="0")
        if not offset_str: return
        try: offset_val = float(offset_str) / 304.8
        except: return
        
        blocks_in_cad = get_cad_blocks(cad_link, target_layer)
        if not blocks_in_cad: 
            forms.alert("CẢNH BÁO MÙ MÀU TỪ REVIT!\nRevit không thể đọc được cấu trúc Block lồng nhau của file CAD này.\n\nCÁCH DỄ NHẤT: Bật qua CAD -> Quét cái đầu phun -> gõ lệnh X (EXPLODE) đập vỡ nó ra -> Save CAD -> Về Revit bấm Reload là 100% tool sẽ quất sạch không trượt cái nào!", exitscript=True)
            
        count_fams = 0
        with revit.Transaction("Dựng Thiết bị từ Block CAD"):
            if not selected_symbol.IsActive:
                selected_symbol.Activate()
                
            for origin, rotation_angle in blocks_in_cad:
                try:
                    origin = DB.XYZ(origin.X, origin.Y, origin.Z + offset_val)
                    fam_inst = doc.Create.NewFamilyInstance(origin, selected_symbol, selected_level, DB.Structure.StructuralType.NonStructural)
                    if fam_inst:
                        count_fams += 1
                        if rotation_angle != 0.0:
                            axis = DB.Line.CreateBound(origin, origin + DB.XYZ.BasisZ)
                            DB.ElementTransformUtils.RotateElement(doc, fam_inst.Id, axis, rotation_angle)
                except Exception as e:
                    pass
                    
        forms.alert("\n🚀 Đã mọc thành công **{}** thiết bị `{}` tại mọi vị trí Block / Đường tròn của Layer `{}`!".format(
            count_fams, safe_name(selected_symbol), target_layer), title="Auto Block-To-Family")
        return

    # ==== FLOW 1 & 2: PLACING DUCTS OR PIPES ====
    if mode_duct:
        mep_types = DB.FilteredElementCollector(doc).OfClass(DB.MEPCurveType).OfCategory(DB.BuiltInCategory.OST_DuctCurves).ToElements()
        sys_types = DB.FilteredElementCollector(doc).OfClass(DB.Mechanical.MechanicalSystemType).ToElements()
    else:
        mep_types = DB.FilteredElementCollector(doc).OfClass(DB.MEPCurveType).OfCategory(DB.BuiltInCategory.OST_PipeCurves).ToElements()
        sys_types = DB.FilteredElementCollector(doc).OfClass(DB.Plumbing.PipingSystemType).ToElements()
        
    levels = DB.FilteredElementCollector(doc).OfClass(DB.Level).ToElements()
    
    if not mep_types or not sys_types or not levels:
        forms.alert('Chưa có Type hoặc System Type trong dự án Revit!', exitscript=True)
        
    dict_mep_types = {safe_name(t): t for t in mep_types}
    dict_sys_types = {safe_name(t): t for t in sys_types}
    dict_levels = {safe_name(t): t for t in levels}
    
    type_title = "Duct Type" if mode_duct else "Pipe Type"
    sel_mep_type_name = forms.SelectFromList.show(sorted(dict_mep_types.keys()), title="2. Chọn " + type_title + ":")
    if not sel_mep_type_name: return
    selected_mep_type = dict_mep_types[sel_mep_type_name]
    
    sel_sys_type_name = forms.SelectFromList.show(sorted(dict_sys_types.keys()), title="3. Chọn System Type:")
    if not sel_sys_type_name: return
    selected_sys_type = dict_sys_types[sel_sys_type_name]
    
    sel_level_name = forms.SelectFromList.show(sorted(dict_levels.keys()), title="4. Chọn Level:")
    if not sel_level_name: return
    selected_level = dict_levels[sel_level_name]
    
    def_h_val = 0.0
    if mode_duct:
        default_h_str = forms.ask_for_string(prompt="Text CAD có rác/vỡ? Cần Nhập Chiều Cao H mặc định (mm):", title="Default Height", default="300")
        if not default_h_str: return
        try: def_h_val = float(default_h_str) / 304.8
        except: return
    
    offset_str = forms.ask_for_string(prompt="Cao độ Z (Elevation) là bao nhiêu (mm)?", title="Offset Z", default="2800")
    if not offset_str: return
    try: offset_val = float(offset_str) / 304.8
    except: return
        
    text_data = []
    if mode_duct:
        all_texts = DB.FilteredElementCollector(doc, doc.ActiveView.Id).OfCategory(DB.BuiltInCategory.OST_TextNotes).WhereElementIsNotElementType().ToElements()
        for t in all_texts:
            try:
                txt_str = t.Text.replace('\r', '').replace('\n', '')
                w_mm, h_mm = extract_size_from_text(txt_str)
                if w_mm and h_mm:
                    text_data.append({
                        'point': t.Coord,
                        'width': w_mm / 304.8,
                        'height': h_mm / 304.8,
                        'text': txt_str
                    })
            except: pass

    lines = get_cad_lines(cad_link, target_layer)
    if not lines: forms.alert("Không có line ống trong layer!", exitscript=True)
        
    pairs = find_mep_pairs(lines)
    if not pairs: forms.alert("Không bắt được cặp ống nào!", exitscript=True)
        
    created_elements = []
    texts_matched = 0
    
    with revit.Transaction("Dựng MEP thông minh từ CAD"):
        mep_infos = []
        for l1, l2, w_feet in pairs:
            p1 = l1.GetEndPoint(0)
            p2 = l1.GetEndPoint(1)
            
            proj1 = project_point_on_line(p1, l2)
            proj2 = project_point_on_line(p2, l2)
            
            c1 = (p1 + proj1) / 2.0
            c2 = (p2 + proj2) / 2.0
            c1 = DB.XYZ(c1.X, c1.Y, c1.Z + offset_val)
            c2 = DB.XYZ(c2.X, c2.Y, c2.Z + offset_val)
            
            if c1.DistanceTo(c2) < 0.1: continue
                
            closest_h = def_h_val
            
            if mode_duct:
                mid_point = (c1 + c2) / 2.0
                best_text_dist = 20.0 
                matched = False
                for t in text_data:
                    dist = DB.XYZ(t['point'].X, t['point'].Y, c1.Z).DistanceTo(mid_point)
                    if dist < best_text_dist:
                        best_text_dist = dist
                        w_val = t['width']
                        h_val = t['height']
                        
                        if abs(h_val - w_feet) < abs(w_val - w_feet):
                            w_val = t['height']
                            h_val = t['width']
                            
                        closest_h = h_val
                        w_feet = w_val
                        matched = True
                
                if matched: texts_matched += 1
            
            mep_infos.append({'p1': c1, 'p2': c2, 'w': w_feet, 'h': closest_h})

        for i in range(len(mep_infos)):
            for j in range(i+1, len(mep_infos)):
                info1 = mep_infos[i]
                info2 = mep_infos[j]
                
                if abs(info1['w'] - info2['w']) > 0.05: continue
                if mode_duct and abs(info1['h'] - info2['h']) > 0.05: continue
                    
                c1_i = info1['p1']
                c2_i = info1['p2']
                c1_j = info2['p1']
                c2_j = info2['p2']
                
                line1 = DB.Line.CreateBound(c1_i, c2_i)
                line2 = DB.Line.CreateBound(c1_j, c2_j)
                
                if is_parallel(line1.Direction, line2.Direction): continue
                
                line1_unbound = DB.Line.CreateUnbound(line1.GetEndPoint(0), line1.Direction)
                line2_unbound = DB.Line.CreateUnbound(line2.GetEndPoint(0), line2.Direction)
                
                res = clr.Reference[DB.IntersectionResultArray]()
                if line1_unbound.Intersect(line2_unbound, res) == DB.SetComparisonResult.Overlap:
                    int_pt = res.Value.get_Item(0).XYZPoint
                    
                    d1_0 = int_pt.DistanceTo(c1_i)
                    d1_1 = int_pt.DistanceTo(c2_i)
                    d2_0 = int_pt.DistanceTo(c1_j)
                    d2_1 = int_pt.DistanceTo(c2_j)
                    
                    tol = 5.0 
                    if min(d1_0, d1_1) < tol and min(d2_0, d2_1) < tol:
                        if d1_0 < d1_1: mep_infos[i]['p1'] = int_pt
                        else: mep_infos[i]['p2'] = int_pt
                        if d2_0 < d2_1: mep_infos[j]['p1'] = int_pt
                        else: mep_infos[j]['p2'] = int_pt
                        
        for info in mep_infos:
            try:
                if info['p1'].DistanceTo(info['p2']) > 0.1:
                    if mode_duct:
                        duct = DB.Mechanical.Duct.Create(doc, selected_sys_type.Id, selected_mep_type.Id, selected_level.Id, info['p1'], info['p2'])
                        if duct:
                            param_h = duct.get_Parameter(DB.BuiltInParameter.RBS_CURVE_HEIGHT_PARAM)
                            if param_h and not param_h.IsReadOnly: param_h.Set(info['h'])
                            param_w = duct.get_Parameter(DB.BuiltInParameter.RBS_CURVE_WIDTH_PARAM)
                            if param_w and not param_w.IsReadOnly: param_w.Set(info['w'])
                            created_elements.append(duct)
                    else:
                        pipe = DB.Plumbing.Pipe.Create(doc, selected_sys_type.Id, selected_mep_type.Id, selected_level.Id, info['p1'], info['p2'])
                        if pipe:
                            param_d = pipe.get_Parameter(DB.BuiltInParameter.RBS_PIPE_DIAMETER_PARAM)
                            if param_d and not param_d.IsReadOnly: param_d.Set(info['w'])
                            created_elements.append(pipe)
            except: pass
            
        doc.Regenerate()
        
        fitting_count = 0
        for i in range(len(created_elements)):
            for j in range(i+1, len(created_elements)):
                elem1 = created_elements[i]
                elem2 = created_elements[j]
                
                conns1 = [c for c in get_connectors(elem1) if not c.IsConnected]
                conns2 = [c for c in get_connectors(elem2) if not c.IsConnected]
                
                connected = False
                for c1 in conns1:
                    for c2 in conns2:
                        if c1.Origin.DistanceTo(c2.Origin) < 0.1:
                            try:
                                doc.Create.NewElbowFitting(c1, c2)
                                fitting_count += 1
                                doc.Regenerate()
                                connected = True
                                break
                            except: pass
                    if connected: break
                            
    sys_name = "ỐNG GIÓ" if mode_duct else "ỐNG NƯỚC"
    msg = "TÊN LỬA {} ĐÃ PHÓNG THÀNH CÔNG!\n\n🛠 Đã tạo ra {} đoạn cáp/ống.".format(sys_name, len(created_elements))
    if mode_duct:
        msg += "\n🎯 Đã đọc được {} Text Kích thước H (WxH).".format(texts_matched)
    msg += "\n🧩 Đã ép mượt {} Co/Cút vuông góc!".format(fitting_count)
    
    forms.alert(msg, title="Báo cáo Tự Động")

if __name__ == '__main__':
    main()
# -*- coding: utf-8 -*-
__title__ = "CAD to Ducts (Double Line)"
from pyrevit import revit, DB, forms, script
import math

doc = revit.doc

def get_cad_lines(import_instance, target_layer):
    lines = []
    geo_elem = import_instance.get_Geometry(DB.Options())
    if not geo_elem: return lines
    
    for geo_obj in geo_elem:
        # Nếu CAD đang được link vào
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

def is_parallel(v1, v2):
    return v1.CrossProduct(v2).IsAlmostEqualTo(DB.XYZ.Zero, 0.01)

def project_point_on_line(pt, line):
    p1 = line.GetEndPoint(0)
    v = line.Direction
    return p1 + v * v.DotProduct(pt - p1)

def find_duct_pairs(lines):
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
                
                # Chiều RỘNG thực tế của ống: Lọc từ 50mm đến 5000mm
                if (50 / 304.8) < dist < (5000 / 304.8): 
                    # Kéo 1 điểm chiếu để xem 2 đường có nằm gối lấp cùng 1 tọa độ không
                    p1_end = l1.GetEndPoint(1)
                    mid1 = (p1 + p1_end) / 2.0
                    proj_mid = project_point_on_line(mid1, l2)
                    
                    dist_to_ends = proj_mid.DistanceTo(l2.GetEndPoint(0)) + proj_mid.DistanceTo(l2.GetEndPoint(1))
                    len2 = l2.Length
                    
                    if abs(dist_to_ends - len2) < 0.1:
                        if dist < best_dist:
                            best_dist = dist
                            best_l2 = j
                            
        if best_l2 is not None:
            pairs.append((l1, lines[best_l2], best_dist))
            used.add(i)
            used.add(best_l2)
            
    return pairs

def main():
    # 0. Yêu cầu người dùng chọn bản CAD Link
    selection = revit.get_selection()
    cad_links = [el for el in selection.elements if isinstance(el, DB.ImportInstance)]
    
    if not cad_links:
        forms.alert('Vui lòng CHỌN FILE CAD ĐƯỢC LINK trên mặt bằng trước khi chạy lệnh!', exitscript=True)
        
    cad_link = cad_links[0]
    
    # 1. Quét tìm toàn bộ Layer có đường nét (Line) trong file CAD đó
    geo_elem = cad_link.get_Geometry(DB.Options())
    layers = set()
    for geo_obj in geo_elem:
        if isinstance(geo_obj, DB.GeometryInstance):
            inst_geo = geo_obj.GetInstanceGeometry()
            for inst_obj in inst_geo:
                if isinstance(inst_obj, DB.Curve) or isinstance(inst_obj, DB.PolyLine):
                    gs = doc.GetElement(inst_obj.GraphicsStyleId)
                    if gs and gs.GraphicsStyleCategory:
                        layers.add(gs.GraphicsStyleCategory.Name)
                        
    if not layers:
        forms.alert('Không tìm thấy hình học (Line) nào trên mặt CAD này!', exitscript=True)
        
    target_layer = forms.SelectFromList.show(sorted(list(layers)), title="1. Chọn LAYER chứa nét biên Ống Gió trong CAD:")
    if not target_layer: return
    
    # 2. Thu thập Settings để đẻ ra ống Revit
    duct_types = DB.FilteredElementCollector(doc).OfClass(DB.MEPCurveType).OfCategory(DB.BuiltInCategory.OST_DuctCurves).ToElements()
    sys_types = DB.FilteredElementCollector(doc).OfClass(DB.MechanicalSystemType).ToElements()
    levels = DB.FilteredElementCollector(doc).OfClass(DB.Level).ToElements()
    
    if not duct_types or not sys_types or not levels:
        forms.alert('Lỗi: Dự án của bản chưa có Duct Type hoặc System Type!', exitscript=True)
        
    dict_duct_types = {str(DB.Element.Name.GetValue(t)): t for t in duct_types}
    dict_sys_types = {str(DB.Element.Name.GetValue(t)): t for t in sys_types}
    dict_levels = {str(DB.Element.Name.GetValue(t)): t for t in levels}
    
    sel_duct_type_name = forms.SelectFromList.show(sorted(dict_duct_types.keys()), title="2. Chọn Duct Type (Loại Ống):")
    if not sel_duct_type_name: return
    selected_duct_type = dict_duct_types[sel_duct_type_name]
    
    sel_sys_type_name = forms.SelectFromList.show(sorted(dict_sys_types.keys()), title="3. Chọn System Type (Hệ thống, VD: Supply Air):")
    if not sel_sys_type_name: return
    selected_sys_type = dict_sys_types[sel_sys_type_name]
    
    sel_level_name = forms.SelectFromList.show(sorted(dict_levels.keys()), title="4. Chọn Level muốn đặt ống:")
    if not sel_level_name: return
    selected_level = dict_levels[sel_level_name]
    
    # 3. Yêu cầu nhập CAO ĐỘ và CHIỀU CAO (Height)
    # Vì thuật toán có thể đo chiều Rộng bằng cách đo khoảng cách 2 nét, nhưng không biết độ dày chìm (Height)
    height_mm = forms.ask_for_string(prompt="CAD Vẽ 2 nét nên tool tự đo Width được.\nCòn CHIỀU CAO (Height) ống mặc định là bao nhiêu (mm)?", title="Chiều cao (H)", default="300")
    if not height_mm: return
    
    offset_mm = forms.ask_for_string(prompt="Cao độ (Elevation / Offset) của ống so với tầng là bao nhiêu (mm)?", title="Offset (Z)", default="2800")
    if not offset_mm: return
    
    try:
        height_val = float(height_mm) / 304.8
        offset_val = float(offset_mm) / 304.8
    except:
        forms.alert("Vui lòng nhập số hợp lệ!")
        return
        
    # PROCESS: BẮT ĐẦU DỰNG
    lines = get_cad_lines(cad_link, target_layer)
    if not lines:
        forms.alert("Không lấy được nét vẽ nào từ Layer '{}'!".format(target_layer), exitscript=True)
        
    pairs = find_duct_pairs(lines)
    if not pairs:
        forms.alert("Tool chạy thất bại do ống trong CAD của bạn không phải loại ống vẽ bằng 2 NÉT thẳng song song (Double Line), hoặc bản vẽ quá nhiễu nét rác.", exitscript=True)
        
    count = 0
    with revit.Transaction("Vẽ Ống Gió từ CAD"):
        for l1, l2, w_feet in pairs:
            try:
                # Tìm Center Line
                p1 = l1.GetEndPoint(0)
                p2 = l1.GetEndPoint(1)
                
                proj1 = project_point_on_line(p1, l2)
                proj2 = project_point_on_line(p2, l2)
                
                c1 = (p1 + proj1) / 2.0
                c2 = (p2 + proj2) / 2.0
                
                # Đẩy lên cao độ offset (Z)
                c1 = DB.XYZ(c1.X, c1.Y, c1.Z + offset_val)
                c2 = DB.XYZ(c2.X, c2.Y, c2.Z + offset_val)
                
                if c1.DistanceTo(c2) > (50 / 304.8):  # Bỏ những đoạn tuyến rác quá ngắn < 50mm
                    duct = DB.Mechanical.Duct.Create(doc, selected_sys_type.Id, selected_duct_type.Id, selected_level.Id, c1, c2)
                    
                    if duct:
                        # Gán Height
                        param_h = duct.get_Parameter(DB.BuiltInParameter.RBS_CURVE_HEIGHT_PARAM)
                        if param_h and not param_h.IsReadOnly: 
                            param_h.Set(height_val)
                            
                        # Gán Width y chang CAD đo được
                        param_w = duct.get_Parameter(DB.BuiltInParameter.RBS_CURVE_WIDTH_PARAM)
                        if param_w and not param_w.IsReadOnly: 
                            param_w.Set(w_feet)
                            
                        count += 1
            except Exception as e:
                print("Lỗi tạo đoạn ống: {}".format(e))
                
    if count > 0:
        forms.alert("Magic! Tool đã tự động vẽ thành công {} đoạn ống gió Revit dựa trên khoảng hở biên 2 nét của CAD Layer '{}'!".format(count, target_layer), title="Hoàn tất")
    else:
        forms.alert("Không tạo được ống nào.", title="Thông báo")


if __name__ == '__main__':
    main()
# -*- coding: utf-8 -*-

from Autodesk.Revit.DB import *

from Autodesk.Revit.UI import *

from Autodesk.Revit.UI.Selection import ObjectType, ISelectionFilter

from pyrevit import forms # Dùng thư viện chuẩn của pyRevit



uidoc = __revit__.ActiveUIDocument

doc = __revit__.ActiveUIDocument.Document



# --- 1. CÁC BỘ LỌC CHỌN (FILTERS) ---

# Giữ nguyên bộ lọc để chọn chính xác



class GroupOnlyFilter(ISelectionFilter):

    """Chỉ cho phép chọn Group"""

    def AllowElement(self, elem):

        return isinstance(elem, Group)

    def AllowReference(self, reference, position):

        return False



class ElementInSpecificGroupFilter(ISelectionFilter):

    """Chỉ cho phép chọn Element thuộc Group đích"""

    def __init__(self, target_group_id):

        self.target_group_id = target_group_id



    def AllowElement(self, elem):

        # Chặn chọn vỏ group -> Buộc user phải Tab vào trong

        if elem.Id == self.target_group_id:

            return False 

        if elem.GroupId == self.target_group_id:

            return True

        return False

    def AllowReference(self, reference, position):

        return False



# --- 2. LOGIC CHÍNH ---



def main():

    # BƯỚC 1: KIỂM TRA SELECTION (Chọn trước)

    selection_ids = uidoc.Selection.GetElementIds()

    if not selection_ids or len(selection_ids) < 2:

        forms.alert("Vui lòng quét chọn các đối tượng MỚI vẽ xong trước khi chạy tool!", title="Thiếu đối tượng")

        return



    # BƯỚC 2: CHỌN MỐC TRONG ĐÁM MỚI

    # Sử dụng WarningBar của pyRevit như code mẫu bạn gửi

    anchor_new = None

    prompt_1 = "BƯỚC 1/3: Kích chọn 1 vật làm MỐC trong đám đối tượng đang sáng (nhấn ESC để hủy)"

    

    with forms.WarningBar(title=prompt_1):

        try:

            ref_new = uidoc.Selection.PickObject(ObjectType.Element, prompt_1)

            if ref_new.ElementId not in selection_ids:

                forms.alert("Vật mốc bạn chọn không nằm trong đám đối tượng ban đầu!", title="Sai mốc")

                return

            anchor_new = doc.GetElement(ref_new)

        except:

            return # User nhấn ESC



    # BƯỚC 3: CHỌN GROUP CŨ

    old_group_instance = None

    prompt_2 = "BƯỚC 2/3: Chọn GROUP CŨ cần thay thế (Chỉ kích được vào Group)"

    

    with forms.WarningBar(title=prompt_2):

        try:

            ref_group = uidoc.Selection.PickObject(ObjectType.Element, GroupOnlyFilter(), prompt_2)

            old_group_instance = doc.GetElement(ref_group)

        except:

            return # User nhấn ESC



    # BƯỚC 4: CHỌN MỐC TRONG GROUP CŨ

    anchor_old = None

    prompt_3 = "BƯỚC 3/3: Rê chuột vào Group cũ -> Nhấn TAB -> Chọn vật MỐC tương ứng"

    

    with forms.WarningBar(title=prompt_3):

        try:

            filter_inside = ElementInSpecificGroupFilter(old_group_instance.Id)

            ref_old = uidoc.Selection.PickObject(ObjectType.Element, filter_inside, prompt_3)

            anchor_old = doc.GetElement(ref_old)

        except:

            return # User nhấn ESC



    # BƯỚC 5: XỬ LÝ (TRANSACTION)

    # Khi code chạy tới đây nghĩa là WarningBar đã tự tắt

    if anchor_new and old_group_instance and anchor_old:

        t = Transaction(doc, "Smart Replace Group")

        t.Start()

        

        try:

            # A. Vector cũ

            old_grp_origin = old_group_instance.Location.Point

            try: 

                pos_old = anchor_old.Location.Point

            except: 

                # Fallback cho Line/Curve

                c = anchor_old.Location.Curve

                pos_old = (c.GetEndPoint(0) + c.GetEndPoint(1)) / 2

            vec_old = pos_old - old_grp_origin



            # B. Tạo Group Mới

            new_grp = doc.Create.NewGroup(selection_ids)

            try: 

                new_grp.GroupType.Name = old_group_instance.GroupType.Name + "_Updated"

            except: 

                pass

            

            doc.Regenerate()



            # C. Vector mới

            new_grp_origin = new_grp.Location.Point

            try: 

                pos_new = anchor_new.Location.Point

            except:

                 c = anchor_new.Location.Curve

                 pos_new = (c.GetEndPoint(0) + c.GetEndPoint(1)) / 2

            vec_new = pos_new - new_grp_origin



            # D. Correction Vector

            correction = vec_new - vec_old



            # E. Replace Hàng Loạt

            old_type_id = old_group_instance.GroupType.Id

            collector = FilteredElementCollector(doc).OfClass(Group)

            

            count = 0

            for grp in collector:

                # Thay thế các group cùng loại (trừ group mới tạo)

                if grp.GroupType.Id == old_type_id and grp.Id != new_grp.Id:

                    grp.GroupType = new_grp.GroupType

                    ElementTransformUtils.MoveElement(doc, grp.Id, -correction)

                    count += 1



            t.Commit()

            

            # Thông báo kết quả

            forms.alert("Đã thay thế và căn chỉnh {} Group thành công.".format(count), title="Kết quả", warn_icon=False)



        except Exception as e:

            t.RollBack()

            forms.alert(str(e), title="Lỗi Transaction")



# Chạy script

if __name__ == '__main__':

    main()
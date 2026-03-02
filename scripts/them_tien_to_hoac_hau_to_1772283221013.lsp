Sub ThemTienToHauTo_FixLoiFont()
    Dim cell As Range
    Dim chuoiThem As Variant
    Dim luaChon As Variant
    
    ' Buoc 1: Hien bang hoi noi dung muon them (Dung Application.InputBox de ho tro Tieng Viet co dau)
    chuoiThem = Application.InputBox("Nhap noi dung ban muon them vao (vi du: Nhân viên - hoac @gmail.com):", "Nhap van ban", Type:=2)
    
    ' Neu nguoi dung bam Cancel (tra ve False) hoac khong nhap gi thi thoat luon
    If chuoiThem = False Or chuoiThem = "" Then Exit Sub
    
    ' Buoc 2: Hien bang hoi muon them vao vi tri nao
    luaChon = Application.InputBox("Ban muon them vao vi tri nao?" & vbCrLf & vbCrLf & _
                           "Nhap so 1: Them vao DAU (Tien to)" & vbCrLf & _
                           "Nhap so 2: Them vao CUOI (Hau to)", "Chon vi tri", "1", Type:=2)
                           
    ' Neu bam Cancel thi thoat
    If luaChon = False Then Exit Sub
                           
    ' Neu nguoi dung khong nhap 1 hoac 2 thi bao loi va thoat
    If CStr(luaChon) <> "1" And CStr(luaChon) <> "2" Then
        MsgBox "Lua chon khong hop le, vui long thu lai!", vbExclamation, "Loi"
        Exit Sub
    End If
    
    ' Buoc 3: Chay vong lap de them chu vao cac o dang boi den
    For Each cell In Selection
        If cell.Value <> "" Then
            If CStr(luaChon) = "1" Then
                ' Them vao dau
                cell.Value = chuoiThem & cell.Value
            Else
                ' Them vao cuoi
                cell.Value = cell.Value & chuoiThem
            End If
        End If
    Next cell
    
    MsgBox "Da xu ly xong!", vbInformation, "Thanh cong"
End Sub

Sub ThemTienToHauTo_KhongDau()
    Dim cell As Range
    Dim chuoiThem As String
    Dim luaChon As String
    
    ' Buoc 1: Hien bang hoi noi dung muon them
    chuoiThem = InputBox("Nhap noi dung ban muon them vao (vi du: NV- hoac @gmail.com):", "Nhap van ban")
    
    ' Neu nguoi dung khong nhap gi hoac bam Cancel thi thoat luon
    If chuoiThem = "" Then Exit Sub
    
    ' Buoc 2: Hien bang hoi muon them vao vi tri nao
    luaChon = InputBox("Ban muon them vao vi tri nao?" & vbCrLf & vbCrLf & _
                       "Nhap so 1: Them vao DAU (Tien to)" & vbCrLf & _
                       "Nhap so 2: Them vao CUOI (Hau to)", "Chon vi tri", "1")
                       
    ' Neu nguoi dung khong nhap 1 hoac 2 thi bao loi va thoat
    If luaChon <> "1" And luaChon <> "2" Then
        MsgBox "Lua chon khong hop le, vui long thu lai!", vbExclamation, "Loi"
        Exit Sub
    End If
    
    ' Buoc 3: Chay vong lap de them chu vao cac o dang boi den
    For Each cell In Selection
        If cell.Value <> "" Then
            If luaChon = "1" Then
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


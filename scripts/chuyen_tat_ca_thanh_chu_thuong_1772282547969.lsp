Sub ChuyenChuThuong()
    Dim cell As Range
    For Each cell In Selection
        If cell.Value <> "" Then
            cell.Value = LCase(cell.Value)
        End If
    Next cell
End Sub
Sub VietHoaChuCaiDau()
    Dim cell As Range
    For Each cell In Selection
        If cell.Value <> "" Then
            cell.Value = StrConv(cell.Value, vbProperCase)
        End If
    Next cell
End Sub
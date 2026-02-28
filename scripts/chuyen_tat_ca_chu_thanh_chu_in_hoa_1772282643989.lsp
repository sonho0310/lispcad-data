Sub ChuyenChuHoa()
    Dim cell As Range
    For Each cell In Selection
        cell.Value = UCase(cell.Value)
    Next cell
End Sub
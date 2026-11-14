computer = "."

Set wmiService = GetObject("winmgmts:\\" & computer & "\root\CIMV2")

Set items = wmiService.ExecQuery( _
    "SELECT IPAddress FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled=True")

For Each item In items

    If Not IsNull(item.IPAddress) Then

        For Each Address In item.IPAddress

            If InStr(Address, ".") > 0 Then

                If Left(Address, 8) <> "169.254." Then
                    Echo Address
                End If

            End If

        Next

    End If

Next
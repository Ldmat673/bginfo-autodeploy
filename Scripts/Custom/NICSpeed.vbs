Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")

Set colFiles = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_NetworkAdapter WHERE NetEnabled=True")

For Each objFile In colFiles

    If Not IsNull(objFile.Speed) Then
        Echo Round(objFile.Speed / 1000000000, 2) & " Gb/s"
    End If

Next
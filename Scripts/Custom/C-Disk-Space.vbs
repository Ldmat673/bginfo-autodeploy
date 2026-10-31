Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

Set colDisks = objWMIService.ExecQuery( _
    "SELECT Size, FreeSpace FROM Win32_LogicalDisk WHERE DeviceID='C:'" _
)

For Each objDisk In colDisks

    FreeGB = Round(objDisk.FreeSpace / 1073741824, 0)
    TotalGB = Round(objDisk.Size / 1073741824, 0)

    Echo FreeGB & " GB free / " & TotalGB & " GB"

Next
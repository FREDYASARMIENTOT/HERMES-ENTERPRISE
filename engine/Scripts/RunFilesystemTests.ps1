# Run filesystem tests as per protocol
$repo='D:/HERMES-ENTERPRISE'
$reports=Join-Path $repo 'reports'
if(-not (Test-Path $reports)){ New-Item -ItemType Directory -Path $reports | Out-Null }
$outs=@()
# TEST1
$t1 = Test-Path 'D:/Proyectos'
$outs+=[ordered]@{ Test='TestPath_Proyectos'; Result = $t1 }
# TEST2
try{ New-Item -ItemType Directory -Path 'D:/Proyectos/TestFilesystem' -Force; $outs+=[ordered]@{ Test='CreateDirectory'; ExitCode=0; Stdout='Created'; Stderr=''} } catch { $outs+=[ordered]@{ Test='CreateDirectory'; ExitCode=1; Stdout=''; Stderr=$_.Exception.Message }; $outs | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'FilesystemTest.json') -Encoding utf8; exit 1 }
# TEST3
$t3=Test-Path 'D:/Proyectos/TestFilesystem'
$outs+=[ordered]@{ Test='TestPath_TestFilesystem'; Result=$t3 }
# TEST4 create file
try{ Set-Content -Path 'D:/Proyectos/TestFilesystem/test.txt' -Value 'hello' -Encoding utf8; $outs+=[ordered]@{ Test='CreateFile'; ExitCode=0; Stdout='Wrote'; Stderr=''} } catch { $outs+=[ordered]@{ Test='CreateFile'; ExitCode=1; Stdout=''; Stderr=$_.Exception.Message }; $outs | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'FilesystemTest.json') -Encoding utf8; exit 1 }
# TEST5 read
try{ $c = Get-Content -Path 'D:/Proyectos/TestFilesystem/test.txt' -Raw; $outs+=[ordered]@{ Test='ReadFile'; ExitCode=0; Stdout=$c; Stderr=''} } catch { $outs+=[ordered]@{ Test='ReadFile'; ExitCode=1; Stdout=''; Stderr=$_.Exception.Message }; $outs | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'FilesystemTest.json') -Encoding utf8; exit 1 }
# TEST6 delete file
try{ Remove-Item -Path 'D:/Proyectos/TestFilesystem/test.txt' -Force; $outs+=[ordered]@{ Test='DeleteFile'; ExitCode=0; Stdout='Deleted'; Stderr=''} } catch { $outs+=[ordered]@{ Test='DeleteFile'; ExitCode=1; Stdout=''; Stderr=$_.Exception.Message }; $outs | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'FilesystemTest.json') -Encoding utf8; exit 1 }
# TEST7 delete dir
try{ Remove-Item -Path 'D:/Proyectos/TestFilesystem' -Recurse -Force; $outs+=[ordered]@{ Test='DeleteDirectory'; ExitCode=0; Stdout='DeletedDir'; Stderr=''} } catch { $outs+=[ordered]@{ Test='DeleteDirectory'; ExitCode=1; Stdout=''; Stderr=$_.Exception.Message }; $outs | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'FilesystemTest.json') -Encoding utf8; exit 1 }
$outs | ConvertTo-Json -Depth 5 | Out-File (Join-Path $reports 'FilesystemTest.json') -Encoding utf8
$outs | Format-Table | Out-String | Out-File (Join-Path $reports 'FilesystemTest.md') -Encoding utf8
Write-Output 'Filesystem tests completed'

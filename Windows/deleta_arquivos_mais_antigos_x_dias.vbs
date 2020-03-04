set FSo = CreateObject("Scripting.FileSystemObject")
set folder = FSO.getFolder ("C:\Users\Eduardo Jonck\Desktop\teste")
for each file in folder.files
if (dateDiff("d", file.DateLastModified, now) >1) then
File.delete
end if
next
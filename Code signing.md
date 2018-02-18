!Sign the code of the oraPowerShell library

To sign the code you can use the helper script certScripts.ps1.

Please open a administrative PowerShell Session to use the script.

Options of the script:

# A - create private certificate
# B - export certificate
# C - import certificate
# D - show all possilbe certificates
# E - sign all ps1 scripts in the script library
# F - show the security settings
# G - set the security settings
# I - set the security settings to nothing
# J - remove the signature
# K - create MD5 Checksums for all ps1 and sql files
# X - exit the script

Code sign process:

# Create a certificate, best over a central CA, if you not have a CA, please download the exe for a self signed certificate from Microsoft ( makecert.exe from http://www.microsoft.com/en-us/download/details.aspx?id=8279 ) and use the option A of the certScripts.ps1
# Sign the code with your certificate, use the option B of the certScripts.p1
# Set the security settings to allSigned wiht the option G of the certScripts.ps1



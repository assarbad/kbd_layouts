!include "MUI2.nsh"
!include "x64.nsh"
!include "Sections.nsh"
!include "kbdus_xx.strings" ; LOCALIZED_STRINGS is undefined

Name "${PRODUCT_NAME}"
BrandingText "${PRODUCT_WEBSITE}"
OutFile "${INSTALLER_EXE_NAME}"
SetDatablockOptimize on
SetCompress force
SetCompressor /SOLID /FINAL lzma
CRCCheck force
XPStyle on
LicenseForceSelection checkbox
RequestExecutionLevel admin
ShowInstDetails hide

Var bIsNT
Var dwMajorVersion
Var dwMinorVersion

!insertmacro MUI_PAGE_INSTFILES
!define MUI_LANGDLL_ALLLANGUAGES
!insertmacro MUI_LANGUAGE "English"

VIProductVersion "${FILE_PRODUCT_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${AUTHOR_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "${COPYRIGHT_YEAR} ${AUTHOR_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "${PRODUCT_NAME} ${DISPLAY_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${DISPLAY_VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "InternalName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "OriginalFilename" "${INSTALLER_EXE_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "Website" "${PRODUCT_WEBSITE}"

Icon "kbdus_xx.ico"
Section "${PRODUCT_NAME} ${FILE_PRODUCT_VERSION}"
  SectionIn RO
  SetOutPath "$TEMP\${INSTALLER_EXE_NAME}"

  File /r "${BASENAME}\*"
  ExecWait "$TEMP\${INSTALLER_EXE_NAME}\setup.exe"
  RMDir /r /REBOOTOK $OUTDIR
  SetRebootFlag false
  Quit
SectionEnd

Function .onInit
  Call CheckOS
  StrCmp $bIsNT "0" FailInstall 0
  IntCmpU $dwMajorVersion 4 FailInstall FailInstall AllFine
FailInstall:
  Quit
AllFine:
FunctionEnd

Function CheckOS
  Push $0
  Push $1
  System::Call 'kernel32::GetVersion() i .r0'
  IntOp $1 $0 & 0xFFFF
  IntOp $dwMajorVersion $1 & 0xFF
  IntOp $dwMinorVersion $1 >> 8
  IntOp $0 $0 & 0x80000000
  IntCmpU $0 0 IsNT Is9x Is9x
Is9x:
  StrCpy $bIsNT "0"
  Goto AfterOsCheck
IsNT:
  StrCpy $bIsNT "1"
AfterOsCheck:
  Pop $1
  Pop $0
FunctionEnd

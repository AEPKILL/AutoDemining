.386
.model flat,stdcall
option casemap:none


include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib

_FunProc	typedef proto :DWORD,:DWORD,:DWORD,:DWORD
FunProc		typedef ptr _FunProc
_FunProc2	typedef proto :dword,:dword
FunProc2	typedef ptr _FunProc2

IDR_MENU1 	equ	10000
IDM_AepKill 	equ	10001
IDM_LOAD 	equ	10004
IDM_AUTODO 	equ	10002
IDM_FLAG 	equ	10003
IDM_ABOUT 	equ	10005
IDM_EXIT	equ	10006
.const
szTips		db	'提示：',0
szDllLoad	db	'DLL已经载入！',0
szDllUninstall	db	'Dll已经卸载！',0
szRepProc	db	'替换窗口过程失败！',0
DllHaveJection	db	'Dll已经注入，请勿重复操作！',0
szGame		db	'扫雷',0
szInfo		db	'Make By ：AepKill',0
szMenu		db	'启动',0
szFormat	db	'%x',0
szFormat2	db	'X:%d  Y:%d',0
PanAddress	dd	1005361h
.data?
hDll		dd	?
FirstFlag	dd	?
hInstance	dd	?
hwnd		dd	?
hMenu		dd	?
OldFunProc	FunProc		?
ChickCall	FunProc2	?
MakeFlag	FunProc2	?
szBuffer	db	2000	dup(?)
.code

AutoDo	proc uses esi edi ecx,mark
	LOCAL @x,@y
	mov @y,0
	mov esi,1005338h
	mov edi,dword ptr [esi]
	.while @y<edi
		mov @x,0
		.while @x<32
			mov esi,PanAddress
			
			mov eax,32
			mul @y
			add eax,@x
			
			add esi,eax
			.break .if byte ptr [esi]==10h
			.if byte ptr [esi]==0fh || byte ptr [esi]==8fh
				mov eax,@y
				inc eax
				push eax
				mov eax,@x
				inc eax
				push eax
				
				.if mark==0 && byte ptr [esi]==0fh
					call ChickCall
				.elseif mark==1 && byte ptr [esi]==8fh
					call MakeFlag
				.endif
				;invoke wsprintf,offset szBuffer,offset szFormat2,@x,edi
				;invoke MessageBox,hwnd,offset szBuffer,offset szTips,MB_OK
			.endif
			;invoke wsprintf,offset szBuffer,offset szFormat,esi
			;invoke MessageBox,NULL,offset szBuffer,offset szTips,MB_OK
			inc @x
		.endw
		inc @y
	.endw
	ret

AutoDo endp


UnloadDll proc
	
	invoke FreeLibraryAndExitThread,hDll,0
	ret

UnloadDll endp


FilterProc proc hWnd,uMsg,wParam,lParam
	mov eax,uMsg
	.if eax==WM_COMMAND;接管菜单消息
		mov eax,wParam
		.if ax==IDM_ABOUT
			invoke MessageBox,hwnd,offset szInfo,offset szTips,MB_OK
		.elseif ax==IDM_AUTODO
			invoke AutoDo,0
		.elseif ax==IDM_FLAG
			invoke AutoDo,1
		.elseif ax==IDM_EXIT
			invoke CreateThread,NULL,0,UnloadDll,0,0,0
		.else
			invoke OldFunProc,hWnd,uMsg,wParam,lParam
		.endif
	.elseif eax==WM_LBUTTONDOWN;接管鼠标左键消息
		mov eax,lParam
		
		invoke OldFunProc,hWnd,uMsg,wParam,lParam
		ret
	.else
		invoke OldFunProc,hWnd,uMsg,wParam,lParam
		ret
	.endif
	
	xor eax,eax
	ret

FilterProc endp


DllEntry	proc hDllInstance,dwReason,dwReserved;reason理由  
	mov eax,dwReason
	
	.if eax==DLL_PROCESS_ATTACH
		
		.if !FirstFlag
			mov FirstFlag,1
		.else
			invoke MessageBox,hwnd,offset DllHaveJection,offset szTips,MB_OK or MB_ICONERROR
			mov eax,TRUE
			ret
		.endif 
		
		push hDllInstance
		pop hDll
		invoke GetModuleHandle,NULL
		mov hInstance,eax
		
		invoke FindWindow,NULL,offset szGame
		mov hwnd,eax
		invoke GetMenu,eax
		mov hMenu,eax
		
		invoke LoadMenu,hDll,IDR_MENU1
		invoke GetSubMenu,eax,0
		invoke AppendMenu,hMenu,MF_POPUP,eax,offset szMenu;添加新的菜单
		
		invoke SetWindowLong,hwnd,GWL_WNDPROC,offset FilterProc;替换窗口过程
		mov OldFunProc,01001BC9h;旧的dialog过程地址
		mov ChickCall,1003512h;扫雷Call
		mov MakeFlag,0100374fh;插旗Call
		invoke wsprintf,offset szBuffer,offset szFormat,eax
		invoke MessageBox,NULL,offset szBuffer,offset szTips,MB_OK;显示SetWindowLong返回的地址。

	.elseif eax==DLL_PROCESS_DETACH
		invoke SetWindowLong,hwnd,GWL_WNDPROC,OldFunProc
		invoke DeleteMenu,hMenu,2,MF_BYPOSITION
		invoke MessageBox,NULL,offset szDllUninstall,offset szTips,MB_OK
	.endif
	
	mov eax,TRUE
	ret

DllEntry endp


end DllEntry
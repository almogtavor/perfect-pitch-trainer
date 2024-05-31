IDEAL
MODEL small
STACK 100h
DATASEG
	Note dw ?
	NoteC4 dw 11D1h ; 1193180 / 261.626 note C4 -> (hex)
	NoteCS4 dw 10D1h ; 1193180 / 277.183 note C#4 -> (hex)
	NoteD4 dw 0FDFh ; 1193180 / 293.665 note D4 -> (hex)
	NoteDS4 dw 0EFBh ; 1193180 / 311.127 note D#4 -> (hex)
	NoteE4 dw 0E24h ; 1193180 / 329.628 note E4 -> (hex)
	NoteF4 dw 0D59h ; 1193180 / 349.228 note F4 -> (hex)
	NoteFS4 dw 0C99h ; 1193180 / 369.994 note F#4 -> (hex)
	NoteG4 dw 0BE4h ; 1193180 / 391.995 note G4 -> (hex)
	NoteGS4 dw 0B39h ; 1193180 / 415.305 note G#4 -> (hex)
	NoteA4 dw 0A98h ; 1193180 / 440.000 note A4 -> (hex)
	NoteAS4 dw 0A00h ; 1193180 / 466.164 note A#4 -> (hex)
	NoteB4 dw 0970h ; 1193180 / 493.883 note B4 -> (hex)
	message db 'Almog Piano',13,10,'$'
	;Code for a message if ill ever want to:
	;mov dx, offset message
	;mov ah, 9h
	;int 21h
	; Regular Piano Picture
	filename db 'Pictures\ai3.bmp', 0
	FILE db 'Pictures\ai3.bmp', 0
	;Pressed Note Picture
	PictureC db 'Pictures\C33.bmp', 0
	PictureCs db 'Pictures\Cs3.bmp', 0
	PictureD db 'Pictures\D33.bmp', 0
	PictureDs db 'Pictures\Ds3.bmp', 0
	PictureE db 'Pictures\E33.bmp', 0
	PictureF db 'Pictures\F33.bmp', 0
	PictureG db 'Pictures\G33.bmp', 0
	PictureGb db 'Pictures\Gb3.bmp', 0
	PictureA db 'Pictures\A33.bmp', 0
	PictureAb db 'Pictures\Ab3.bmp', 0
	PictureB db 'Pictures\B33.bmp', 0
	PictureBb db 'Pictures\Bb3.bmp', 0
	;Wrong Note Picture
	WrongPictureC db 'Pictures\WC3.bmp', 0
	WrongPictureCs db 'Pictures\WCs.bmp', 0
	WrongPictureD db 'Pictures\WD3.bmp', 0
	WrongPictureDs db 'Pictures\WDs.bmp', 0
	WrongPictureE db 'Pictures\WE3.bmp', 0
	WrongPictureF db 'Pictures\WF3.bmp', 0
	WrongPictureG db 'Pictures\WG3.bmp', 0
	WrongPictureGb db 'Pictures\WGb.bmp', 0
	WrongPictureA db 'Pictures\WA3.bmp', 0
	WrongPictureAb db 'Pictures\WAb.bmp', 0
	WrongPictureB db 'Pictures\WB3.bmp', 0
	WrongPictureBb db 'Pictures\WBb.bmp', 0
	;Right Note Picture
	RightPictureC db 'Pictures\RC3.bmp', 0
	RightPictureCs db 'Pictures\RCs.bmp', 0
	RightPictureD db 'Pictures\RD3.bmp', 0
	RightPictureDs db 'Pictures\RDs.bmp', 0
	RightPictureE db 'Pictures\RE3.bmp', 0
	RightPictureF db 'Pictures\RF3.bmp', 0
	RightPictureG db 'Pictures\RG3.bmp', 0
	RightPictureGb db 'Pictures\RGb.bmp', 0
	RightPictureA db 'Pictures\RA3.bmp', 0
	RightPictureAb db 'Pictures\RAb.bmp', 0
	RightPictureB db 'Pictures\RB3.bmp', 0
	RightPictureBb db 'Pictures\RBb.bmp', 0
	
	RandomNote dw ?
	Bool dw ?
	filehandle dw ?
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg db 'Error', 13, 10,'$'
	MAX_TICKS db 6; length of break --> 18 is 1 sec
	lastTick db 0 ; for waiting proc
	TickCounter db 0 ; for waiting proc
CODESEG
proc OpenFile
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax
	ret
openerror:
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	ret
	endp OpenFile
proc ReadHeader
	; Read BMP file header, 54 bytes
	mov ah,3fh
	mov bx, [filehandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	ret
	endp ReadHeader
proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	ret
endp ReadPalette
proc CopyPal
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
	; Copy starting color to port 3C8h
	out dx,al
	; Copy palette itself to port 3C9h
	inc dx
	PalLoop:
	; Note: Colors in a BMP file are saved as BGR values rather than RGB.
	mov al,[si+2] ; Get red value.
	shr al,2 ; Max. is 255, but video palette maximal
	; value is 63. Therefore dividing by 4.
	out dx,al ; Send it.
	mov al,[si+1] ; Get green value.
	shr al,2
	out dx,al ; Send it.
	mov al,[si] ; Get blue value.
	shr al,2
	out dx,al ; Send it.
	add si,4 ; Point to next color.
	; (There is a null chr. after every color.)
	loop PalLoop
	ret
endp CopyPal

proc CopyBitmap
	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx, 200
	PrintBMPLoop:
	push cx
	; di = cx*320, point to the correct screen line
	mov di, cx
	shl cx, 6
	shl di, 8
	add di, cx
	; Read one line
	mov ah, 3fh
	mov cx, 320
	mov dx, offset ScrLine
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx, 320
	mov si, offset ScrLine
	rep movsb ; Copy line to the screen
	;rep movsb is same as the following code:
	;mov es:di, ds:si
	;inc si
	;inc di
	;dec cx
	;loop until cx=0
	pop cx
	loop PrintBMPLoop
	ret
endp CopyBitmap

proc CloseBmpFile near
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
	ret
endp CloseBmpFile

proc Ktovet
	push bp
	mov bp, sp
	mov si, [bp+4]
	mov di, offset filename
	mov cx, 17
looper:
	mov al, [si]
	mov [di], al
	inc si
	inc di
	loop looper
	pop bp
	ret 2
endp Ktovet
	

proc read_clock
	;keep registers
	push ax
	mov  ah, 2ch
	int	 21h	; clock interrupt
	;keep registers
	pop	 ax
	ret
endp read_clock
		
; wait_ticks - the below procedure waits for 
; MAX_TICKS clock ticks  -  this is done by reading the clock
; and counting tick changes in dl
proc wait_ticks
	; keep registers
	push	dx
	push 	cx
	push 	ax
	
	mov al, [MAX_TICKS]
	; read clock to initiate lastTick
	call	read_clock
	mov		[lastTick], dl
	mov		[tickCounter], 0
	
ticksLoop:
	;read the clock and check if it was changed
	call	read_clock
	cmp		[lastTick], dl
	je		ticksLoop 		; no tick - do nothing - jump back to ticksLoop
	
	; clock was changed - a new tick
	inc		[tickCounter]
	cmp		[tickCounter], al
	je		timeover
	
    ; MAX_TICK was not reached
	mov		[lastTick], dl
	jmp		ticksLoop
timeover:
	;keep registers
	pop		ax
	pop		cx
	pop		dx
	ret
endp wait_ticks

proc NotePlaying
	;readlines
	mov ah, 08h ;Function to read a char from keyboard
	int 21h ;the char saved in al
	;mov ah, 0h
	;int 16h
	cmp al, 'a'
	je NoteCPress
	cmp al, 'w'
	je NoteCSPress
	cmp al, 's'
	je NoteDPress
	cmp al, 'e'
	je NoteDSPress
	cmp al, 'd'
	je NoteEPress
	cmp al, 'f'
	je NoteFPress
	cmp al, 't'
	je NoteFSPress
	cmp al, 'g'
	je NoteGPress
	cmp al, 'y'
	je NoteGSPress
	cmp al, 'h'
	je NoteAPress
	cmp al, 'u'
	je NoteASPress
	cmp al, 'j'
	je NoteBPress
	jmp GetOut ;a char that is not a note
NoteCPress:
	mov ax, [NoteC4]
	mov bx, offset PictureC
	jmp sound ; avoid changing the frequency of 'Note'
NoteCSPress:
	mov ax, [NoteCS4]
	mov bx, offset PictureCs
	jmp sound ; avoid changing the frequency of 'Note'
NoteDPress:
	mov ax, [NoteD4]
	mov bx, offset PictureD
	jmp sound ; avoid changing the frequency of 'Note'
NoteDSPress:
	mov ax, [NoteDS4]
	mov bx, offset PictureDs
	jmp sound ; avoid changing the frequency of 'Note'
NoteEPress:
	mov ax, [NoteE4]
	mov bx, offset PictureE
	jmp sound ; avoid changing the frequency of 'Note'
NoteFPress:
	mov ax, [NoteF4]
	mov bx, offset PictureF
	jmp sound ; avoid changing the frequency of 'Note'
NoteFSPress:
	mov ax, [NoteFS4]
	mov bx, offset PictureGb
	jmp sound ; avoid changing the frequency of 'Note'
NoteGPress:
	mov ax, [NoteG4]
	mov bx, offset PictureG
	jmp sound ; avoid changing the frequency of 'Note'
NoteGSPress:
	mov ax, [NoteGS4]
	mov bx, offset PictureAb
	jmp sound ; avoid changing the frequency of 'Note'
NoteAPress:
	mov ax, [NoteA4]
	mov bx, offset PictureA
	jmp sound ; avoid changing the frequency of 'Note'
NoteASPress:
	mov ax, [NoteAS4]
	mov bx, offset PictureBb
	jmp sound ; avoid changing the frequency of 'Note'
NoteBPress:
	mov ax, [NoteB4]
	mov bx, offset PictureB
	jmp sound ; avoid changing the frequency of 'Note'
	
sound:
	mov [Note], ax
	; Process BMP file
	mov [filehandle], ?
	push bx
	call Ktovet
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseBmpFile
	
	; open speaker
	in al, 61h
	or al, 00000011b
	out 61h, al
	; send control word to change frequency
	mov al, 0B6h
	out 43h, al
	; play frequency
	mov ax, [Note]
	out 42h, al ; Sending lower byte
	mov al, ah
	out 42h, al ; Sending upper byte
	; wait 1 sec
	call wait_ticks
	; close the speaker
	in al, 61h
	and al, 11111100b
	out 61h, al
	
	mov ax, [Note]
	cmp ax, [NoteC4]
	je CPress
	cmp ax, [NoteCS4]
	je CSPress
	cmp ax, [NoteD4]
	je DPress
	cmp ax, [NoteDS4]
	je DSPress
	cmp ax, [NoteE4]
	je EP
	cmp ax, [NoteF4]
	je FP
	cmp ax, [NoteFS4]
	je FSP
	cmp ax, [NoteG4]
	je GP
	cmp ax, [NoteGS4]
	je GSP
	cmp ax, [NoteA4]
	je AP
	cmp ax, [NoteAS4]
	je ASP
	cmp ax, [NoteB4]
	je BBP
	
CPress:
	cmp [RandomNote], 'c'
	jne cfalse
ctrue:
	mov bx, offset RightPictureC
	jmp continue
cfalse:
	mov bx, offset WrongPictureC
	jmp continue
CSPress:
	cmp [RandomNote], 'cs'
	jne csfalse
cstrue:
	mov bx, offset RightPictureCs
	jmp continue
csfalse:
	mov bx, offset WrongPictureCs
	jmp continue
DPress:
	cmp [RandomNote], 'd'
	jne dfalse
dtrue:
	mov bx, offset RightPictureD
	jmp continue
dfalse:
	mov bx, offset WrongPictureD
	jmp continue
DSPress:
	cmp [RandomNote], 'ds'
	jne dsfalse
dstrue:
	mov bx, offset RightPictureDs
	jmp continue
dsfalse:
	mov bx, offset WrongPictureDs
	jmp continue
EP:
	jmp EPress
FP:
	jmp FPress
FSP:
	jmp FSPress
GP:
	jmp GPress
GSP:
	jmp GSPress
AP:
	jmp APress
ASP:
	jmp ASPress
BBP:
	jmp BPress
EPress:
	cmp [RandomNote], 'e'
	jne efalse
etrue:
	mov bx, offset RightPictureE
	jmp continue
efalse:
	mov bx, offset WrongPictureE
	jmp continue
FPress:
	cmp [RandomNote], 'f'
	jne ffalse
ftrue:
	mov bx, offset RightPictureF
	jmp continue
ffalse:
	mov bx, offset WrongPictureF
	jmp continue
FSPress:
	cmp [RandomNote], 'fs'
	jne fsfalse
fstrue:
	mov bx, offset RightPictureGb
	jmp continue
fsfalse:
	mov bx, offset WrongPictureGb
	jmp continue
GPress:
	cmp [RandomNote], 'g'
	jne gfalse
gtrue:
	mov bx, offset RightPictureG
	jmp continue
gfalse:
	mov bx, offset WrongPictureG
	jmp continue
GSPress:
	cmp [RandomNote], 'gs'
	jne gsfalse
gstrue:
	mov bx, offset RightPictureAb
	jmp continue
gsfalse:
	mov bx, offset WrongPictureAb
	jmp continue
APress:
	cmp [RandomNote], 'a'
	jne afalse
atrue:
	mov bx, offset RightPictureA
	jmp continue
afalse:
	mov bx, offset WrongPictureA
	jmp continue
ASPress:
	cmp [RandomNote], 'as'
	jne asfalse
astrue:
	mov bx, offset RightPictureBb
	jmp continue
asfalse:
	mov bx, offset WrongPictureBb
	jmp continue
BPress:
	cmp [RandomNote], 'b'
	jne bfalse
btrue:
	mov bx, offset RightPictureB
	jmp continue
bfalse:
	mov bx, offset WrongPictureB
	jmp continue

continue:
	; print red or green
	push bx
	call Ktovet
	; print the original piano again
	; Process BMP file
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseBmpFile
	call wait_ticks
	call wait_ticks
	
	mov bx, offset FILE
	push bx
	call Ktovet
	; print the original piano again
	; Process BMP file
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseBmpFile
GetOut:
	ret
endp NotePlaying
	
start:
	mov ax, @data
	mov ds, ax
	; Graphic mode
	mov ax, 13h
	int 10h
	; Process BMP file
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
	call CloseBmpFile
	infiniteLoop:
		Rand:
			; Random number from 0-15. Not from 1- 12 to prevent cases of same pattern repeating
			mov ax, 40h
			mov es, ax
			mov ax, [es:6Ch]
			and al, 00001111b
			cmp al, 1b;c=1
			je PutC
			cmp al, 10b;c#=2
			je PutCs
			cmp al, 11b;d=1
			je PutD
			cmp al, 100b;d#=2
			je PutDs
			cmp al, 101b;e=1
			je PutE
			cmp al, 110b;f=2
			je PutF
			cmp al, 111b;f#=1
			je PutFs
			cmp al, 1000b;g=2
			je PutG
			cmp al, 1001b;g#=1
			je PGs
			cmp al, 1010b;a=2
			je PA
			cmp al, 1011b;a#=1
			je PAs
			cmp al, 1100b;b=2
			je PB
			cmp al, 1101b;again
			je Rand
			cmp al, 1110b;again
			je Rand
			cmp al, 1111b;again
			je Rand
		PutC:
			mov [RandomNote], 'c'
			mov ax, [NoteC4]
			jmp go
		PutCs:
			mov [RandomNote], 'cs'
			mov ax, [NoteCS4]
			jmp go
		PutD:
			mov [RandomNote], 'd'
			mov ax, [NoteD4]
			jmp go
		PutDs:
			mov [RandomNote], 'ds'
			mov ax, [NoteDS4]
			jmp go
		PutE:
			mov [RandomNote], 'e'
			mov ax, [NoteE4]
			jmp go
		PutF:
			mov [RandomNote], 'f'
			mov ax, [NoteF4]
			jmp go
		PutFs:
			mov [RandomNote], 'fs'
			mov ax, [NoteFS4]
			jmp go
		PutG:
			mov [RandomNote], 'g'
			mov ax, [NoteG4]
			jmp go
		PGs:
			jmp PutGs
		PA:
			jmp PutA
		PAs:
			jmp PutAs
		PB:
			jmp PutB
		PutGs:
			mov [RandomNote], 'gs'
			mov ax, [NoteGS4]
			jmp go
		PutA:
			mov [RandomNote], 'a'
			mov ax, [NoteA4]
			jmp go
		PutAs:
			mov [RandomNote], 'as'
			mov ax, [NoteAS4]
			jmp go
		PutB:
			mov [RandomNote], 'b'
			mov ax, [NoteB4]
			jmp go
		go:
			mov [Note], ax
			; open speaker
			in al, 61h
			or al, 00000011b
			out 61h, al
			; send control word to change frequency
			mov al, 0B6h
			out 43h, al
			; play frequency 261.626Hz
			mov ax, [Note]
			out 42h, al ; Sending lower byte
			mov al, ah
			out 42h, al ; Sending upper byte
			; wait 1 sec
			call wait_ticks
			; close the speaker
			in al, 61h
			and al, 11111100b
			out 61h, al
			call NotePlaying
			jmp infiniteLoop
	; Wait for key press
	mov ah,1
	int 21h
	; Back to text mode
	mov ah, 0
	mov al, 2
	int 10h
	
exit:
	mov ax, 4C00h
	int 21h
END start
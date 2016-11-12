;==================================================
; Removes small lakes and island form the land see mask
; Usage:
;   # edit the filename in 'fich1` below
;   idl
;   > initrmnlib
;   > masq, in = "filename", out = "filename"
;==================================================
pro masq, in = fich1, out = fileout
;
;fich1='/users/dor/armn/sch/datap2/work_genesis/walser/champs_geo.std'
fileouttmp=STRING(fileout,'tmp')
print,'INPUT FILE :',fich1
print,'OUTPUT FILE:',fileout,fileouttmp

iun=fstouv(unit=1,file=fich1)
iun=fstouv(unit=2,file=fileouttmp)
iun=fstouv(unit=3,file=fileout)

;me=fltarr(ni,nj)
;Obtenir la structure
ref_mg=fstinf(unit=1,nomvar='MG')
struc_mg=fstprm(ref=ref_mg)

print, 'Structure du champ'
print, struc_mg.ni, struc_mg.nj, struc_mg.ip1, struc_mg.ip2, struc_mg.ip3
print, struc_mg.nbits, ' ', struc_mg.grtyp
print, struc_mg.ig1, struc_mg.ig2, struc_mg.ig3, struc_mg.ig4

mg=fltarr(struc_mg.ni,struc_mg.nj)
mg_1=fltarr(struc_mg.ni,struc_mg.nj)
mg_2=fltarr(struc_mg.ni,struc_mg.nj)
mg_3=fltarr(struc_mg.ni,struc_mg.nj)

mg=fstluk(ref=ref_mg)
mg_1=mg
; Passe #1
	print,'Passe #1'
	for j=0,struc_mg.nj-1 do begin
        	for i=0,struc_mg.ni-1 do begin
                        mg_1(i,j)=0.0
			if (mg(i,j) gt .5) then mg_1(i,j)=1.0
 	  	endfor
	endfor

mg_2=mg_1
mg_3=mg_1
; Passe #2

removecorner=1

for ipasse=0,1 do begin
print,'Passe #',ipasse
irayon=3

;	print,'Passe #2'
	itotalchange=0
        itotalchange_t=0
	for j=0,struc_mg.nj-1 do begin
        	for i=0,struc_mg.ni-1 do begin

;                       Debut du scan
;			'Scan pour les points d eau'
			ieau=0
			if (mg_1(i,j) lt .5) then begin
				i1=i-1
                                i2=i+1
				if (i1 lt 0) then i1=0
                                if (i2 gt struc_mg.ni-1) then i2=struc_mg.ni-1
				j1=j-1
                                j2=j+1
				if (j1 lt 0) then j1=0
                                if (j2 gt struc_mg.nj-1) then j2=struc_mg.nj-1
				
                                for i3=i1,i2 do begin
					for j3=j1,j2 do begin
                                           if (mg_1(i3,j3) lt 0.5) then begin
						if (removecorner eq 1) then begin
						   if ((i3 eq i) and (j3 eq j)) then ieau=ieau+1
						   if ((i3 eq i+1) and (j3 eq j)) then ieau=ieau+1
						   if ((i3 eq i) and (j3 eq j+1)) then ieau=ieau+1
                                                   if ((i3 eq i-1) and (j3 eq j)) then ieau=ieau+1
                                                   if ((i3 eq i) and (j3 eq j-1)) then ieau=ieau+1
                                                endif else begin
                                                   ieau=ieau+1
                                                endelse 
                                           endif
                                        endfor
                                endfor

;                       Modifications
                        if (ieau lt irayon) then begin
                             itotalchange=itotalchange+1
                             mg_2(i,j)=1.0
                        endif
                        
                        endif
                       
                        mg_1=mg_2

                        ;'Scan pour les points de terre'
			iterre=0
			if (mg_1(i,j) gt .5) then begin
				i1=i-1
                                i2=i+1
				if (i1 lt 0) then i1=0
                                if (i2 gt struc_mg.ni-1) then i2=struc_mg.ni-1
				j1=j-1
                                j2=j+1
				if (j1 lt 0) then j1=0
                                if (j2 gt struc_mg.nj-1) then j2=struc_mg.nj-1
				
                                for i3=i1,i2 do begin
					for j3=j1,j2 do begin
                                              if (mg_1(i3,j3) gt 0.5) then begin
                                                if (removecorner eq 1) then begin
                                                   if ((i3 eq i) and (j3 eq j)) then iterre=iterre+1
						   if ((i3 eq i+1) and (j3 eq j)) then iterre=iterre+1
						   if ((i3 eq i) and (j3 eq j+1)) then iterre=iterre+1
                                                   if ((i3 eq i-1) and (j3 eq j)) then iterre=iterre+1
                                                   if ((i3 eq i) and (j3 eq j-1)) then iterre=iterre+1
                                                endif else begin
                                                   iterre=iterre+1
                                                endelse
                                              endif 
                                        endfor
                                endfor

;                       Modifications
                        if (iterre lt irayon) then begin
                             itotalchange_t=itotalchange_t+1
                             mg_2(i,j)=0.0
                        endif
                        
                        endif
 	  	endfor
	endfor

print, 'Points d eau modifies=',itotalchange
print, 'Points de terre modifies=',itotalchange_t

mg_1=mg_2
endfor

iun=fstecr(u=2,DESCR=struc_mg,data=mg_3)
iun=fstecr(u=3,DESCR=struc_mg,data=mg_2)


; Copier tictac dans les fichiers de sorties
tic=fltarr(struc_mg.ni,1)
tac=fltarr(1,struc_mg.nj)

ref_tic=fstinf(unit=1,nomvar='>>')
struc_tic=fstprm(ref=ref_tic)
tic=fstluk(ref=ref_tic)
iun=fstecr(u=2,DESCR=struc_tic,data=tic)
iun=fstecr(u=3,DESCR=struc_tic,data=tic)

ref_tac=fstinf(unit=1,nomvar='^^')
struc_tac=fstprm(ref=ref_tac)
tac=fstluk(ref=ref_tac)
iun=fstecr(u=2,DESCR=struc_tac,data=tac)
iun=fstecr(u=3,DESCR=struc_tac,data=tac)


ier=fstfrm(u=3)
ier=fstfrm(u=2)
ier=fstfrm(u=1)


end



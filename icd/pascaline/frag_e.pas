{******************************************************************************

LATE COMPATIBILITY DEFINITIONS

Routines forwarded in the base layer whose implementations depend on the
ported layers above.

******************************************************************************}

{ find bounding box view of sheet (from icda.pas) }

procedure fndbnd(sp: shtptr; var x, y, s: integer);

var an: real;

begin

   if not boundset(sp) then begin { bounds not set }

      x := 0; { set default view coordinates for empty sheet }
      y := 0;
      s := normscale*scalem

   end else begin { bounds set }

      { find box diagonal }
      if (sp^.bbsx <> sp^.bbex) and (sp^.bbsy <> sp^.bbey) then
         an := arctan(abs(sp^.bbex-sp^.bbsx)/abs(sp^.bbey-sp^.bbsy));
      if ((an < curwin^.aa) or (sp^.bbsx = sp^.bbex)) and not
         (sp^.bbsy = sp^.bbey) then begin { y dominated }

         s := round((abs(sp^.bbey-sp^.bbsy)/
                     (abs(curwin^.cs^.vp.v.e.y-curwin^.cs^.vp.v.s.y)-
                      (2*bbborder)))*scalem);
         x := round(sp^.bbsx - (((abs(sp^.bbey-sp^.bbsy)/2)/tan((pi/2)-curwin^.aa))-
                    (abs(sp^.bbex-sp^.bbsx)/2)));
         y := sp^.bbsy { set origins }

      end else begin { x dominated }

         s := round((abs(sp^.bbex-sp^.bbsx)/
                     (abs(curwin^.cs^.vp.v.e.x-curwin^.cs^.vp.v.s.x)-
                      (2*bbborder)))*scalem);
         x := sp^.bbsx; { set origins }
         y := round(sp^.bbsy - (((abs(sp^.bbex-sp^.bbsx)/2)/tan(curwin^.aa))-
                   (abs(sp^.bbey-sp^.bbsy)/2)))

      end;
      { offset by margins }
      x := x - realdist(bbborder, s);
      y := y - realdist(bbborder, s)

   end

end;

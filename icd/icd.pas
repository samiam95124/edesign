{******************************************************************************
*                                                                             *
*                     ICD SCHEMATIC/LAYOUT EDITOR                             *
*                                                                             *
*                        Pascaline port main program                          *
*                                                                             *
* Replaces the DOS/SVS Pascal main (icd.pas 1992). The initialization and    *
* all state live in the icdui module (see the toolchain note in             *
* PORTING-SPEC.md for why the program module does not touch the globals     *
* directly). This main is only the event pump: the original polled loop     *
* (updptr/kbdrdy) becomes a graphics event loop feeding the icdui event     *
* entries, which emulate the puck communication flags the tablet driver     *
* produced.                                                                  *
*                                                                             *
******************************************************************************}

program icd(input, output);

joins graphics;

uses icdui;

var er: graphics.evtrec; { event record }

begin

   iniicd; { initialize the ICD user interface }
   repeat { main event loop }

      graphics.event(er);
      if er.etype = graphics.etmoumovg then
         evmove(er.moupxg, er.moupyg) { mouse moved, pixels }
      else if er.etype = graphics.etmouba then
         evbut(er.amoubn, true) { mouse button assert }
      else if er.etype = graphics.etmoubd then
         evbut(er.dmoubn, false) { mouse button deassert }
      else if er.etype = graphics.etchar then
         evkey(er.echar) { keyboard input }
      else if er.etype = graphics.etredraw then
         evredraw { window redraw request }
      else if er.etype = graphics.etresize then
         evresize(er.rszxg, er.rszyg) { window was resized }
      else if er.etype = graphics.etterm then
         evterm { window close }

   until termreq { until terminate requested }

end.

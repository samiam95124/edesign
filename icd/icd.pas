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
      { port: mouse events on the drawing subwindow (winid 2) arrive
        subwindow relative; translate them back to main window
        coordinates. All other handling is identical for both
        windows: buttons carry no coordinates, keyboard events follow
        focus, and a redraw request on either window repaints through
        the same path (each draw routes to its own window). The
        subwindow is never resized by the window manager, only by
        chksub below. }
      if er.etype = graphics.etmoumovg then begin

         if er.winid = 2 then evsubmove(er.moupxg, er.moupyg)
         else evmove(er.moupxg, er.moupyg) { mouse moved, pixels }

      end else if er.etype = graphics.etmouba then
         evbut(er.amoubn, true) { mouse button assert }
      else if er.etype = graphics.etmoubd then
         evbut(er.dmoubn, false) { mouse button deassert }
      else if er.etype = graphics.etchar then
         evkey(er.echar, chr(0)) { keyboard input }
      { port: the Ami library reports the editing keys as their own
        events; translate them to the legacy DOS (char, scan) pairs the
        keyboard layer expects. ESC is etcan (Ami wants it pressed
        twice), Return etenter, backspace etdelcb, and the extended
        keys arrive as chr(0) plus the DOS scan code }
      else if er.etype = graphics.etenter then
         evkey(chr(13), chr(0)) { return/enter }
      else if er.etype = graphics.etdelcb then
         evkey(chr(8), chr(0)) { backspace }
      else if er.etype = graphics.ettab then
         evkey(chr(9), chr(0)) { tab, restore field default }
      else if er.etype = graphics.etcan then
         evkey(chr(27), chr(0)) { escape, cancel activity }
      else if er.etype = graphics.etdelcf then
         evkey(chr(0), chr(83)) { delete }
      else if er.etype = graphics.etleft then
         evkey(chr(0), chr(75)) { left arrow }
      else if er.etype = graphics.etright then
         evkey(chr(0), chr(77)) { right arrow }
      else if (er.etype = graphics.ethome) or
              (er.etype = graphics.ethomel) then
         evkey(chr(0), chr(71)) { home }
      else if (er.etype = graphics.etend) or
              (er.etype = graphics.etendl) then
         evkey(chr(0), chr(79)) { end }
      else if er.etype = graphics.etinsertt then
         evkey(chr(0), chr(82)) { insert }
      else if er.etype = graphics.etredraw then
         evredraw { window redraw request }
      else if er.etype = graphics.etresize then begin

         { main window resized (subwindow resizes come from chksub
           and need no action) }
         if er.winid <> 2 then evresize(er.rszxg, er.rszyg)

      end else if er.etype = graphics.etterm then
         evterm { window close }
      ;
      { open or re-place the drawing subwindow after any layout
        change }
      chksub

   until termreq { until terminate requested }

end.

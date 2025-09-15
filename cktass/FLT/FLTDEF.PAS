{**************************************************************
*                                                             *
*                 NET FLATTENER                               *
*                                                             *
*                 6/89 S. A. Moore                            *
*                                                             *
* Converts a tree structured netlist down to a flat           *
* structured netlist. the circuit tree is loaded, then a tree *
* walk performed to generate the flat net.                    *
*                                                             *
**************************************************************}
{}
const linmax = 80; { maximum command line }
      labmax = 20; { maximum characters per label }

type 
     nodadr  = 0..2147483647; { node address. Maximum unsigned
                                value in 32 bit signed word }
     byte    = 0..255;   { type of byte }
     bytfil  = file of byte; { byte file }
     labinx  = 1..labmax; { index for label }
     nodlab  = packed array [labinx] of char; { label for node }
     { transistor type }
     trntyp  = (nmos,             { n-channel }
                pmos,             { p-channel }
                wnmos,            { weak n-channel }
                wpmos,            { weak p-channel }
                res,              { resistor }
                cap,              { capacitor }
                cellr);           { cell }
     parptr  = ^par;              { parameter pointer }
     par     = record             { parameter }

                  num: word;      { correspondence number }
                  next: parptr    { next entry }

               end;
     single  = array [1..4] of byte; { literal store for single real }
     fetptr  = ^fet;              { pointer to fet }
     fet     = record

                  typet:     trntyp; { transistor type }
                  source:    word;   { source node connect }
                  gate:      word;   { gate node connect }
                  drain:     word;   { drain node connect }
                  width:     single; { width }
                  length:    single; { length }
                  num:       word;   { cell number }
                  par:       parptr; { parameter list }
                  next:      fetptr; { next in list }

               end;
    celptr   = ^cell; { pointer to cell }
    cell     = record

                  dev: fetptr; { device list }
                  next: celptr { next in list }

               end;
    lininx   = 1..linmax; { command line index }
    errcod   = (eilovf,   { input line too long }
                ecfns,    { circuit file not specified }
                eivopt,   { invalid option }
                ecfnf,    { circuit file not found }
                einvnff,  { invalid input file format }
                elabtl,   { label too long }
                eivlor,   { input value out of range }
                esys);    { system error }
    line     = packed array [lininx] of char;   { input line buffer }

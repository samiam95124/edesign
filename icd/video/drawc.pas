module drawc;

uses {$U ..\common.j} common;

{}
{**************************************************************

INITALIZE CHARACTER WIDTH ARRAY

Initalizes the character widths, which are the exact number of
pixels in x that the character occupies.

**************************************************************}

procedure iniwidth;

begin

   alphal[$00] := 10; { copyright }
   alphal[$01] :=  9; { micro }
   alphal[$02] :=  0;
   alphal[$03] :=  0;
   alphal[$04] :=  0;
   alphal[$05] :=  0;
   alphal[$06] :=  0;
   alphal[$07] :=  0;
   alphal[$08] :=  0;
   alphal[$09] :=  0;
   alphal[$0a] :=  0;
   alphal[$0b] :=  0;
   alphal[$0c] :=  0;
   alphal[$0d] :=  0;
   alphal[$0e] :=  0;
   alphal[$0f] :=  0;
   alphal[$10] :=  0; 
   alphal[$11] :=  0;
   alphal[$12] :=  0;
   alphal[$13] :=  0;
   alphal[$14] :=  0;
   alphal[$15] :=  0;
   alphal[$16] :=  0;
   alphal[$17] :=  0;
   alphal[$18] :=  0;
   alphal[$19] :=  0;
   alphal[$1a] :=  0;
   alphal[$1b] :=  0;
   alphal[$1c] :=  0;
   alphal[$1d] :=  0;
   alphal[$1e] :=  0;
   alphal[$1f] :=  0;
   alphal[$20] :=  6; { ' ' }
   alphal[$21] :=  2; { '!' }
   alphal[$22] :=  5; { '"' }
   alphal[$23] :=  9; { '#' }
   alphal[$24] :=  6; { '$' }
   alphal[$25] := 11; { '%' }
   alphal[$26] :=  7; { '&' }
   alphal[$27] :=  4; { ''' }
   alphal[$28] :=  3; { '(' }
   alphal[$29] :=  3; { ')' }
   alphal[$2a] :=  6; { '*' }
   alphal[$2b] :=  6; { '+' }
   alphal[$2c] :=  3; { ',' }
   alphal[$2d] :=  4; { '-' }
   alphal[$2e] :=  2; { '.' }
   alphal[$2f] :=  4; { '/' }
   alphal[$30] :=  6; { '0' }
   alphal[$31] :=  4; { '1' }
   alphal[$32] :=  6; { '2' }
   alphal[$33] :=  6; { '3' }
   alphal[$34] :=  6; { '4' }
   alphal[$35] :=  6; { '5' }
   alphal[$36] :=  6; { '6' }
   alphal[$37] :=  6; { '7' }
   alphal[$38] :=  6; { '8' }
   alphal[$39] :=  6; { '9' }
   alphal[$3a] :=  2; { ':' }
   alphal[$3b] :=  3; { ';' }
   alphal[$3c] :=  6; { '<' }
   alphal[$3d] :=  6; { '=' }
   alphal[$3e] :=  6; { '>' }
   alphal[$3f] :=  6; { '?' }
   alphal[$40] := 13; { '@' }
   alphal[$41] :=  8; { 'A' }
   alphal[$42] :=  8; { 'B' }
   alphal[$43] :=  7; { 'C' }
   alphal[$44] :=  8; { 'D' }
   alphal[$45] :=  7; { 'E' }
   alphal[$46] :=  7; { 'F' }
   alphal[$47] :=  8; { 'G' }
   alphal[$48] :=  8; { 'H' }
   alphal[$49] :=  2; { 'I' }
   alphal[$4a] :=  6; { 'J' }
   alphal[$4b] :=  8; { 'K' }
   alphal[$4c] :=  7; { 'L' }
   alphal[$4d] := 10; { 'M' }
   alphal[$4e] :=  8; { 'N' }
   alphal[$4f] :=  8; { 'O' }
   alphal[$50] :=  8; { 'P' }
   alphal[$51] :=  8; { 'Q' }
   alphal[$52] :=  9; { 'R' }
   alphal[$53] :=  7; { 'S' }
   alphal[$54] :=  8; { 'T' }
   alphal[$55] :=  8; { 'U' }
   alphal[$56] :=  8; { 'V' }
   alphal[$57] := 14; { 'W' }
   alphal[$58] :=  9; { 'X' }
   alphal[$59] := 10; { 'Y' }
   alphal[$5a] :=  9; { 'Z' }
   alphal[$5b] :=  3; { '[' }
   alphal[$5c] :=  4; { '\' }
   alphal[$5d] :=  3; { ']' }
   alphal[$5e] :=  5; { '^' }
   alphal[$5f] :=  8; { '_' }
   alphal[$60] :=  3; { '`' }
   alphal[$61] :=  6; { 'a' }
   alphal[$62] :=  6; { 'b' }
   alphal[$63] :=  6; { 'c' }
   alphal[$64] :=  6; { 'd' }
   alphal[$65] :=  6; { 'e' }
   alphal[$66] :=  4; { 'f' }
   alphal[$67] :=  6; { 'g' }
   alphal[$68] :=  6; { 'h' }
   alphal[$69] :=  2; { 'i' }
   alphal[$6a] :=  3; { 'j' }
   alphal[$6b] :=  6; { 'k' }
   alphal[$6c] :=  2; { 'l' }
   alphal[$6d] := 10; { 'm' }
   alphal[$6e] :=  6; { 'n' }
   alphal[$6f] :=  6; { 'o' }
   alphal[$70] :=  6; { 'p' }
   alphal[$71] :=  6; { 'q' }
   alphal[$72] :=  4; { 'r' }
   alphal[$73] :=  6; { 's' }
   alphal[$74] :=  4; { 't' }
   alphal[$75] :=  6; { 'u' }
   alphal[$76] :=  8; { 'v' }
   alphal[$77] := 10; { 'w' }
   alphal[$78] :=  8; { 'x' }
   alphal[$79] :=  8; { 'y' }
   alphal[$7a] :=  6; { 'z' }
   alphal[$7b] :=  4; { left comment }
   alphal[$7c] :=  2; { '|' }
   alphal[$7d] :=  4; { right comment }
   alphal[$7e] :=  5; { '~' }
   alphal[$7f] :=  0  { del }

end;
{}
end. { module }

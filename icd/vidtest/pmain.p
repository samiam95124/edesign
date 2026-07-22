{ pmain.p of 07-Oct91 }

{ SVS C3 Pascal and MASM example. }

{ This program calls a MASM function _rotl() to do a left rotation of bits. }
{ Note: 1. MASM prepends an '_' to all EXTERNAL and PUBLIC identifiers.     }

program pmain(input,output);

var shift: integer; value,result: longint;

function _rotl(value:longint; shift: integer):longint; cexternal;

begin
shift := 9;
value := 2;
result := _rotl(value, shift);
writeln(value, ' rotated ', shift, ' bits is ', result);
end. {pmain}

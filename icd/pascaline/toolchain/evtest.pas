program evtest(input, output);

uses graphics;

var er: evtrec;
    f:  text;
    n:  integer;

begin

   assign(f, 'events.log');
   rewrite(f);
   auto(false);
   frect(10, 10, 50, 50); { force window display }
   n := 0;
   repeat

      n := n+1;

      event(er);
      case er.etype of

         etmouba:   writeln(f, 'ASSERT m=', er.amoun:1, ' b=', er.amoubn:1);
         etmoubd:   writeln(f, 'DEASSERT m=', er.dmoun:1, ' b=', er.dmoubn:1);
         etchar:    writeln(f, 'CHAR ', er.echar);
         etmoumovg: writeln(f, 'MOVE ', er.moupxg:1, ',', er.moupyg:1)
         else writeln(f, 'OTHER ', ord(er.etype):1)

      end

   until (er.etype = etterm) or (n >= 60) or (er.etype = etmouba);
   close(f)

end.

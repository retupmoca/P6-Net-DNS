use v6;
use Test;

use Net::DNS::Type;

is Net::DNS::Type.new("A").type, 1, "A resolves properly to 1";
is ~Net::DNS::Type.new("A"), "A", "A named A";
is Net::DNS::Type.new(1).type, 1, "1 resolves properly to 1";
is ~Net::DNS::Type.new(1), "A", "1 named A";
is Net::DNS::Type.new("PTR").type, 12, "PTR resolves properly to 12";
is ~Net::DNS::Type.new("PTR"), "PTR", "PTR named A";
is Net::DNS::Type.new(12).type, 12, "12 resolves properly to 12";
is ~Net::DNS::Type.new(12), "PTR", "12 named PTR";
is Net::DNS::Type.new(0).type, 0, "0 resolves properly to 0";
is ~Net::DNS::Type.new(0), 0, "0 named 0";

done-testing;

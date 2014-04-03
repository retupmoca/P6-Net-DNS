use v6;
use Test;

plan 4;

use Net::DNS;

ok True, "Module loaded";

my $resolver;
ok ($resolver = Net::DNS.new('8.8.8.8')), "Created a resolver";

my $response;
ok ($response = $resolver.lookup("A", "perl6.org")), "Lookup A record for perl6.org...";
ok ($response[0] eq "193.200.132.142"), "...Got a valid response!"; # this will probably need to change in the future

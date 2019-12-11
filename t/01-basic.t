use v6;
use Test;

my $server = %*ENV<DNS_TEST_HOST> // '8.8.8.8';

use Net::DNS;

ok True, "Module loaded";

my $resolver;
say '# using %*ENV<DNS_TEST_HOST> = '~$server if $server ne '8.8.8.8';
ok ($resolver = Net::DNS.new($server)), "Created a resolver";

my $response;
ok ($response = $resolver.lookup("A", "dns.google")), "Lookup A record for raku.org...";

ok ($response[0] eq "8.8.4.4"), "...Got a valid response!"; # this will probably need to change in the future
ok ($response[1] eq "8.8.8.8"), "...Got a valid response!"; # this will probably need to change in the future

ok ($response = $resolver.lookup("A", "dns.google.")), "Lookup A record for raku.org. (with trailing dot)...";
ok ($response[0] eq "8.8.4.4"), "...Got a valid response!"; # this will probably need to change in the future
ok ($response[1] eq "8.8.8.8"), "...Got a valid response!"; # this will probably need to change in the future

done-testing;

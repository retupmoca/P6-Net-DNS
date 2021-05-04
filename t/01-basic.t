use v6;

use Test;

plan 6;

my $server = %*ENV<DNS_TEST_HOST> // '8.8.8.8';

use Net::DNS;

unless %*ENV<NETWORK_TESTING> {
    diag "NETWORK_TESTING was not set";
    skip-rest("NETWORK_TESTING was not set");
    exit;
}

ok True, "Module loaded";

my $resolver;
diag '# using %*ENV<DNS_TEST_HOST> = '~$server if $server ne '8.8.8.8';
ok ($resolver = Net::DNS.new($server)), "Created a resolver";

my $response;
ok ($response = $resolver.lookup("A", "dns.google")), "Lookup A record for dns.google...";

is $response.sort, ["8.8.4.4", "8.8.8.8"], "...Got a valid response!"; # this will probably need to change in the future

ok ($response = $resolver.lookup("A", "dns.google.")), "Lookup A record for dns.google. (with trailing dot)...";
is $response.sort, ["8.8.4.4", "8.8.8.8"], "...Got a valid response!"; # this will probably need to change in the future

done-testing;

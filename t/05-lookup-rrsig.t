use v6;
use Test;

plan 8;

my $server = %*ENV<DNS_TEST_HOST> // '8.8.8.8';

use Net::DNS;

unless %*ENV<NETWORK_TESTING> {
    diag "NETWORK_TESTING was not set";
    skip-rest("NETWORK_TESTING was not set");
    exit;
}

my $resolver;
diag '# using %*ENV<DNS_TEST_HOST> = '~$server if $server ne '8.8.8.8';
ok ($resolver = Net::DNS.new($server)), "Created a resolver";

my $response;
ok ($response = $resolver.lookup("RRSIG", "dns.google")), "Lookup rrsig for dns.google...";
ok $response.elems > 1, "More than one dns.google RRSIG present";

my $sorted = $response.sort({$^a.type-covered.type <=> $^b.type-covered.type});
ok $sorted[0].Str, "...Got a valid response!";
is $response[0].type-covered.Str, "A", "Covered type is A";
ok $response[0].signature-inception < $response[0].signature-expiration, "Dates decoded";
ok $response[0].signature.elems > 0, "Signature exists";

my $mx = $resolver.lookup("RRSIG", "junk.rrr");
ok $mx ~~ Failure, 'Failure Response';

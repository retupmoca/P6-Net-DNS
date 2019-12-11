use v6;
use Test;

plan 3;

my $server = %*ENV<DNS_TEST_HOST> // '8.8.8.8';

use Net::DNS;

unless %*ENV<NETWORK_TESTING> {
    diag "NETWORK_TESTING was not set";
    skip-rest("NETWORK_TESTING was not set");
    exit;
}

my $resolver;
say '# using %*ENV<DNS_TEST_HOST> = '~$server if $server ne '8.8.8.8';
ok ($resolver = Net::DNS.new($server)), "Created a resolver";

my $response;
ok ($response = $resolver.lookup-ips("raku.org")), "Lookup ips for raku.org...";
ok ($response[2].Str ~~ ("104.18.58.39", '104.18.59.39').any), "...Got a valid response!"; # this will probably need to change in the future

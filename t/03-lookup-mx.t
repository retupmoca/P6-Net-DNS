use v6;
use Test;

plan 4;

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
ok ($response = $resolver.lookup-mx("raku.org")), "Lookup mx for raku.org...";
ok ($response[0] eq "80.127.186.58"), "...Got a valid response!"; # this will probably need to change in the future

my $mx = $resolver.lookup-mx('junk.rrr');
ok $mx ~~ Failure, 'Failure Response';

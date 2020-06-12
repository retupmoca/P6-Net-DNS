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

my $resolver;
say '# using %*ENV<DNS_TEST_HOST> = '~$server if $server ne '8.8.8.8';
ok ($resolver = Net::DNS.new($server)), "Created a resolver";

my @response;
ok (@response = $resolver.lookup-ips("raku.org")), "Lookup ips for raku.org...";

# Find the first A record.
my $a-rec = @response.grep(Net::DNS::A).first.Str;
ok $a-rec.defined, "Got an A record";
ok $a-rec ~~ ('104.18.58.39', '172.67.215.46', '104.18.59.39').any, "...Got an expected A record";

# Find the first AAAA record.
my $aaaa-rec = @response.grep(Net::DNS::AAAA).first.Str;
ok $aaaa-rec.defined, "Got an AAAA record";
ok $aaaa-rec ~~ ('2606:4700:3037:0000:0000:0000:ac43:d72e', '2606:4700:3037:0000:0000:0000:6812:3a27', '2606:4700:3032:0000:0000:0000:6812:3b27').any, "...Got an expected AAAA record";



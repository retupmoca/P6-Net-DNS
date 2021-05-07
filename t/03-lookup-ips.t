use v6;
use Test;

plan 12;

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

my @response;
ok (@response = $resolver.lookup-ips("raku.org")), "Lookup ips for raku.org...";

# Define an IPv4 Regex
my @octet = ^256;
my $ipv4 = / ^ @octet**4 % '.' $ /;

# Find the first A record.
my $a-rec = @response.grep(Net::DNS::A).first.Str;
ok $a-rec.defined, "Got an A record";
like $a-rec, $ipv4, "...Got an expected A record";

# Define an IPv6 grammar
# Based on Rosetacode
#   https://rosettacode.org/wiki/Parse_an_IP_Address#Perl_6
grammar IPv6 {
    token TOP { ^ <IPv6Addr> $ }

    token IPv6Addr {
        | <h16> +% ':' <?{ $<h16> == 8}>
        | [ (<h16>) +% ':']? '::' [ (<h16>) +% ':' ]? <?{ @$0 + @$1 ≤ 8 }>
    }

    token h16 { (<:hexdigit>+) <?{ @$0 ≤ 4 }> }
}

# Find the first AAAA record.
my $aaaa-rec = @response.grep(Net::DNS::AAAA).first.Str;
ok $aaaa-rec.defined, "Got an AAAA record";
ok IPv6.parse($aaaa-rec), "...Got an expected AAAA record";


# Lookup Failure
my $lookup = $resolver.lookup('A', 'mqkjqwew.rrr');
ok $lookup ~~ Failure, 'Failure';
ok $lookup.exception.server-message.defined, 'Server Message provided';
is $lookup.exception.rcode-value, 3, 'RCode Value set';
is $lookup.exception.rcode-name, 'NXDOMAIN', 'RCode Name set';
ok $lookup.exception.message.defined, 'Error message set';

my $ips = $resolver.lookup-ips('266.266.266.266');
ok $ips ~~ Failure, 'Failure IPs';

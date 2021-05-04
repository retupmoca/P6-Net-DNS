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

# Define an IPv4/IPv6 grammar
# IPv6 part based on Rosetacode
#   https://rosettacode.org/wiki/Parse_an_IP_Address#Perl_6
my @octet = ^256;
grammar IP {
    token TOP {
        | ^ <IPv6Addr> $
        | ^ <IPv4Addr> $
    }

    token IPv6Addr {
        | <h16> +% ':' <?{ $<h16> == 8}>
        | [ (<h16>) +% ':']? '::' [ (<h16>) +% ':' ]? <?{ @$0 + @$1 ≤ 8 }>
    }

    token IPv4Addr { @octet**4 % '.' }

    token h16 { (<:hexdigit>+) <?{ @$0 ≤ 4 }> }
}

my $resolver;
diag '# using %*ENV<DNS_TEST_HOST> = '~$server if $server ne '8.8.8.8';
ok ($resolver = Net::DNS.new($server)), "Created a resolver";

my $response;
ok ($response = $resolver.lookup-mx("raku.org")), "Lookup mx for raku.org...";
ok IP.parse($response[0].Str), "...Got a valid response!"; # this will probably need to change in the future

my $mx = $resolver.lookup-mx('junk.rrr');
ok $mx ~~ Failure, 'Failure Response';

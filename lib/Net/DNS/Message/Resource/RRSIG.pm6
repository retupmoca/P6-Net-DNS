unit role Net::DNS::Message::Resource::RRSIG;

use experimental :pack;

use Net::DNS::Type;

my class Net::DNS::RRSIG {
    has @.owner-name;
    has $.type-covered;
    has $.algorithm;
    has $.labels;
    has $.original-ttl;
    has $.signature-expiration;
    has $.signature-inception;
    has $.key-tag;
    has $.signer-name;
    has $.signature;


    # From Rosetta Code Base64 Encode Data
    my @base64map = flat 'A' .. 'Z', 'a' .. 'z', ^10, '+', '/';
    sub buf-to-Base64($buf) {
        join '', gather for $buf.list -> $a, $b = [], $c = [] {
            my $triplet = ($a +< 16) +| ($b +< 8) +| $c;
            take @base64map[($triplet +> (6 * 3)) +& 0x3F];
            take @base64map[($triplet +> (6 * 2)) +& 0x3F];
            if $c.elems {
                take @base64map[($triplet +> (6 * 1)) +& 0x3F];
                take @base64map[($triplet +> (6 * 0)) +& 0x3F];
            }
            elsif $b.elems {
                take @base64map[($triplet +> (6 * 1)) +& 0x3F];
                take '=';
            }
            else { take '==' }
        }
    }

    method Str {
        return (
            $!type-covered,
            $!algorithm,
            $!labels,
            $!original-ttl,
            $!signature-expiration,
            $!signature-inception,
            $!key-tag,
            $!signer-name,
            buf-to-Base64($!signature),
        ).join(" ");
    }
}

method rdata-parsed {
    my $rdata-length = $.rdata.elems;

    # all the fixed length components plus two 0 length
    die("Invalid rdata length") unless $rdata-length ≥ 20;

    my (
        $raw-type-covered,
        $algorithm,
        $labels,
        $original-ttl,
        $raw-signature-expiration,
        $raw-signature-inception,
        $key-tag,
    ) = $.rdata.unpack('nCCNNNn');

    my $type-covered = Net::DNS::Type.new($raw-type-covered);
    my $signature-expiration = DateTime.new($raw-signature-expiration);
    my $signature-inception = DateTime.new($raw-signature-inception);

    my %signer-parsed = self.parse-domain-name(
        Buf.new($.rdata[18..*]),
        %.name-offsets,
        0,
        :allow-compression(False),
    );
    my $signer-name = %signer-parsed<name>.join(".") ~ ".";
    my $signer-length = %signer-parsed<bytes>;

    my $sig-offset = 18+$signer-length;

    die("Invalid rdata length") unless $rdata-length > $sig-offset;
    my $signature = Buf.new($.rdata[$sig-offset..*]);

    return Net::DNS::RRSIG.new(
        :owner-name(@.name),
        :$type-covered,
        :$algorithm,
        :$labels,
        :$original-ttl,
        :$signature-expiration,
        :$signature-inception,
        :$key-tag,
        :$signer-name,
        :$signature
    );
}

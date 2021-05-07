unit class Net::DNS::Type;

my %types =
    A     => 1,
    AAAA  => 28,
    CNAME => 5,
    MX    => 15,
    NS    => 2,
    PTR   => 12,
    RRSIG => 46,
    SPF   => 99,
    SRV   => 33,
    TXT   => 16,
    SOA   => 6,
    AXFR  => 252;

my %names = %types.invert;

has $.type;

method new($type is copy) {
    $type = %types{$type} if %types{$type}:exists;
    self.bless(:$type);
}

method Str() {
    if %names{$.type}:exists {
        return %names{$.type};
    } else {
        return $.type;
    }
}

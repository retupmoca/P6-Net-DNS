use Net::DNS::Message::DomainName;

class Net::DNS::Message::Resource does Net::DNS::Message::DomainName;

has Str @.name is rw;
has Int $.type is rw = 0;
has Int $.class is rw = 0;
has Int $.ttl is rw = 0;
has Buf $.rdata = Buf.new;
has $.rdata-str;

has Int $.parsed-bytes;

multi method new($data is copy, %name-offsets is rw, $start-offset){
    my $domain-name = self.parse-domain-name($data, %name-offsets, $start-offset);
    my @name = $domain-name<name>.list;
    my $parsed-bytes = $domain-name<bytes>;

    $data = Buf.new($data[$parsed-bytes..*]);

    my ($type, $class, $ttl, $rdlength) = $data.unpack('nnNn');
    $parsed-bytes += 10;
    $parsed-bytes += $rdlength;
    $data = Buf.new($data[10..*]);
    my $rdata = Buf.new($data[0..^$rdlength]);

    my $rdata-str;
    given $type {
        when 1 { # A
            $rdata-str = $rdata[0] ~ '.' ~ $rdata[1] ~ '.' ~ $rdata[2] ~ '.' ~ $rdata[3];
        }
        when 28 { # AAAA
            for 0..^$rdata.list.elems {
                $rdata-str ~= $rdata[$_].fmt("%02x");
                if $_ && $_ % 2 && $_ != ($rdata.list.elems - 1) {
                    $rdata-str ~= ':';
                }
            }
        }
        when 5 { # CNAME
            my $name = self.parse-domain-name($data,
                                              %name-offsets,
                                              $start-offset + $parsed-bytes);
            $rdata-str = $name<name>.join('.');
        }
        when 15 { # MX
            # first two bytes is priority - we only care about the domain for now
            my $name = self.parse-domain-name(Buf.new($data[2..*]),
                                                %name-offsets,
                                                $start-offset + $parsed-bytes);
            $rdata-str = $name<name>.join('.');
        }
        when 2 { # NS
            my $name = self.parse-domain-name($data,
                                                %name-offsets,
                                                $start-offset + $parsed-bytes);
            $rdata-str = $name<name>.join('.');
        }
        when 12 { # PTR
            my $name = self.parse-domain-name($data,
                                                %name-offsets,
                                                $start-offset + $parsed-bytes);
            $rdata-str = $name<name>.join('.');
        }
        when 99 { # SPF

        }
        when 33 { # SRV

        }
        when 16 { # TXT
            my $tmpdata = Buf.new($rdata[1..*]);
            $rdata-str = $tmpdata.decode('ascii');
        }
    }

    self.bless(:@name, :$type, :$class, :$ttl, :$rdata, :$rdata-str, :$parsed-bytes);
}

multi method new () {
    self.bless();
}

method Buf {
    my $out = Buf.new;
    for @.qname {
        my $len = pack('C', $_.chars);
        my $str = $_.encode('ascii');
        $out = $out ~ $len ~ $str;
    }
    return $out ~ pack('CnnNn', (0, $.type, $.class, $.ttl, $.rdata.elems)) ~ $.rdata;
}

method Blob {
    Blob.new(self.Buf);
}

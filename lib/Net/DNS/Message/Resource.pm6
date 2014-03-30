class Net::DNS::Message::Resource;

has Str @.name is rw;
has Int $.type is rw = 0;
has Int $.class is rw = 0;
has Int $.ttl is rw = 0;
has Buf $.rdata = Buf.new;

has Int $.parsed-bytes;

multi method new($data is copy){
    my $parsed-bytes = 1;
    my $len = $data.unpack('C');
    my @name;
    while $len > 0 {
        $parsed-bytes += $len;
        @name.push(Buf.new($data[1..$len]).decode('ascii'));
        $data = Buf.new($data[$len^..*]);
        $len = $data.unpack('C');
        $parsed-bytes += 1;
    }
    $data = Buf.new($data[1..*]);
    my ($type, $class, $ttl, $rdlength) = $data.unpack('nnNn');
    $parsed-bytes += 10;
    $parsed-bytes += $rdlength;
    $data = Buf.new($data[10..*]);
    my $rdata = Buf.new($data[0..^$rdlength]);
    self.bless(:@name, :$type, :$class, :$ttl, :$rdata :$parsed-bytes);
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
